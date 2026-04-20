<?php
namespace App\EventListener;

use App\Exception\ParkingException;
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * Converts all exceptions to consistent JSON responses for API routes.
 */
class ExceptionListener
{
    public function __construct(private readonly LoggerInterface $logger) {}

    public function onKernelException(ExceptionEvent $event): void
    {
        $request = $event->getRequest();

        // Only handle API routes
        if (!str_starts_with($request->getPathInfo(), '/api')) {
            return;
        }

        $exception = $event->getThrowable();

        [$statusCode, $message, $extra] = match (true) {
            $exception instanceof ParkingException => [
                max(400, $exception->getCode()),
                $exception->getMessage(),
                ['error_code' => $exception->getErrorCode()],
            ],
            $exception instanceof NotFoundHttpException => [
                Response::HTTP_NOT_FOUND,
                'Resource not found',
                [],
            ],
            $exception instanceof AccessDeniedHttpException => [
                Response::HTTP_FORBIDDEN,
                'Access denied. Insufficient permissions.',
                [],
            ],
            $exception instanceof HttpExceptionInterface => [
                $exception->getStatusCode(),
                $exception->getMessage(),
                [],
            ],
            default => [
                Response::HTTP_INTERNAL_SERVER_ERROR,
                'An unexpected error occurred',
                [],
            ],
        };

        // Log server errors
        if ($statusCode >= 500) {
            $this->logger->error('API Exception', [
                'message'   => $exception->getMessage(),
                'trace'     => $exception->getTraceAsString(),
                'path'      => $request->getPathInfo(),
            ]);
        }

        $response = new JsonResponse(array_merge([
            'error'   => $message,
            'status'  => $statusCode,
            'path'    => $request->getPathInfo(),
        ], $extra), $statusCode);

        $event->setResponse($response);
    }
}


<?php
namespace App\Controller;

use App\Entity\Payment;
use App\Entity\ParkingLot;
use App\Entity\ParkingSession;
use App\Exception\ParkingException;
use App\Repository\ParkingLotRepository;
use App\Repository\ParkingSessionRepository;
use App\Service\ParkingService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/sessions', name: 'session_')]
class SessionController extends AbstractController
{
    public function __construct(
        private readonly ParkingService           $parkingService,
        private readonly ParkingLotRepository     $lotRepository,
        private readonly ParkingSessionRepository $sessionRepository,
    ) {}

    /**
     * POST /api/sessions/entry
     * Register vehicle entry.
     * Body: { lot_id, vehicle_number, vehicle_type, payment_method? }
     */
    #[Route('/entry', name: 'entry', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function entry(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        $required = ['lot_id', 'vehicle_number', 'vehicle_type'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return $this->json(['error' => "Field '{$field}' is required"], Response::HTTP_BAD_REQUEST);
            }
        }

        $lot = $this->lotRepository->find($data['lot_id']);
        if (!$lot || !$lot->isActive()) {
            return $this->json(['error' => 'Parking lot not found or inactive'], Response::HTTP_NOT_FOUND);
        }

        $validTypes = ['car', 'bike', 'truck'];
        if (!in_array($data['vehicle_type'], $validTypes)) {
            return $this->json(['error' => 'vehicle_type must be: car, bike, or truck'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $session = $this->parkingService->registerEntry(
                $lot,
                $data['vehicle_number'],
                $data['vehicle_type']
            );

            return $this->json([
                'message' => 'Vehicle entry registered successfully',
                'data'    => $this->serializeSession($session),
            ], Response::HTTP_CREATED);

        } catch (ParkingException $e) {
            $code = $e->getErrorCode() === ParkingException::NO_SLOT_AVAILABLE
                ? Response::HTTP_UNPROCESSABLE_ENTITY
                : Response::HTTP_CONFLICT;
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], $code);
        }
    }

    /**
     * POST /api/sessions/{id}/exit
     * Process vehicle exit and generate invoice.
     * Body: { payment_method? }
     */
    #[Route('/{id}/exit', name: 'exit', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function exit(ParkingSession $session, Request $request): JsonResponse
    {
        $data   = json_decode($request->getContent(), true) ?? [];
        $method = $data['payment_method'] ?? Payment::METHOD_CASH;

        try {
            $payment = $this->parkingService->processExit($session, $method);

            return $this->json([
                'message' => 'Vehicle exit processed successfully',
                'data'    => $this->serializeExitResponse($session, $payment),
            ]);

        } catch (ParkingException $e) {
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * POST /api/sessions/{id}/pay
     * Confirm payment for a session (after gateway callback).
     */
    #[Route('/{id}/pay', name: 'pay', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function confirmPayment(ParkingSession $session, Request $request): JsonResponse
    {
        $data          = json_decode($request->getContent(), true) ?? [];
        $transactionId = $data['transaction_id'] ?? ('TXN' . strtoupper(substr(md5(uniqid()), 0, 10)));

        $payment = $session->getPayment();
        if (!$payment) {
            return $this->json(['error' => 'No payment record found for this session'], Response::HTTP_NOT_FOUND);
        }

        if ($payment->getStatus() === Payment::STATUS_PAID) {
            return $this->json(['error' => 'Payment already confirmed'], Response::HTTP_CONFLICT);
        }

        $this->parkingService->confirmPayment($payment, $transactionId);

        return $this->json([
            'message' => 'Payment confirmed',
            'invoice' => $this->serializeInvoice($session, $payment),
        ]);
    }

    /**
     * GET /api/sessions
     * List active sessions (with optional lot_id filter).
     */
    #[Route('', name: 'list', methods: ['GET'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function list(Request $request): JsonResponse
    {
        $lotId    = $request->query->get('lot_id');
        $sessions = $this->sessionRepository->findActiveSessions($lotId ? (int)$lotId : null);

        return $this->json([
            'data'  => array_map([$this, 'serializeSession'], $sessions),
            'total' => count($sessions),
        ]);
    }

    /**
     * GET /api/sessions/{id}
     * Get session details.
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function show(ParkingSession $session): JsonResponse
    {
        return $this->json(['data' => $this->serializeSession($session)]);
    }

    // ── Serializers ──────────────────────────────────────────────────────────

    private function serializeSession(ParkingSession $s): array
    {
        $now      = new \DateTimeImmutable();
        $duration = (int) round(
            ($s->getExitTime() ?? $now)->getTimestamp() - $s->getEntryTime()->getTimestamp()
        ) / 60;

        return [
            'id'               => $s->getId(),
            'status'           => $s->getStatus(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'vehicle_type'     => $s->getVehicle()->getVehicleType(),
            'parking_lot'      => $s->getParkingLot()->getName(),
            'slot_number'      => $s->getSlot()->getSlotNumber(),
            'floor'            => $s->getSlot()->getFloor(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()?->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes() ?? (int)$duration,
            'total_fee'        => $s->getTotalFee(),
            'payment_status'   => $s->getPayment()?->getStatus(),
        ];
    }

    private function serializeExitResponse(ParkingSession $s, Payment $p): array
    {
        return [
            'session_id'       => $s->getId(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes(),
            'duration_readable'=> floor($s->getDurationMinutes() / 60) . 'h ' . ($s->getDurationMinutes() % 60) . 'm',
            'total_fee'        => $s->getTotalFee(),
            'payment_id'       => $p->getId(),
            'payment_status'   => $p->getStatus(),
            'payment_method'   => $p->getPaymentMethod(),
        ];
    }

    private function serializeInvoice(ParkingSession $s, Payment $p): array
    {
        return [
            'invoice_no'       => 'INV-' . str_pad((string)$p->getId(), 8, '0', STR_PAD_LEFT),
            'session_id'       => $s->getId(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'vehicle_type'     => $s->getVehicle()->getVehicleType(),
            'parking_lot'      => $s->getParkingLot()->getName(),
            'slot_number'      => $s->getSlot()->getSlotNumber(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()?->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes(),
            'total_fee'        => $p->getAmount(),
            'payment_method'   => $p->getPaymentMethod(),
            'transaction_id'   => $p->getTransactionId(),
            'paid_at'          => $p->getPaidAt()?->format('Y-m-d H:i:s'),
            'generated_at'     => (new \DateTimeImmutable())->format('Y-m-d H:i:s'),
        ];
    }
}


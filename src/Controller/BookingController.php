<?php
namespace App\Controller;

use App\Entity\Booking;
use App\Entity\ParkingLot;
use App\Entity\User;
use App\Exception\ParkingException;
use App\Repository\BookingRepository;
use App\Repository\ParkingLotRepository;
use App\Service\BookingService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/bookings', name: 'booking_')]
#[IsGranted('ROLE_USER')]
class BookingController extends AbstractController
{
    public function __construct(
        private readonly BookingService      $bookingService,
        private readonly BookingRepository   $bookingRepository,
        private readonly ParkingLotRepository $lotRepository,
    ) {}

    /**
     * POST /api/bookings
     * Create a pre-booking.
     */
    #[Route('', name: 'create', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];
        /** @var User $user */
        $user = $this->getUser();

        $required = ['lot_id', 'vehicle_type', 'start_time', 'end_time'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return $this->json(['error' => "Field '{$field}' is required"], Response::HTTP_BAD_REQUEST);
            }
        }

        $lot = $this->lotRepository->find($data['lot_id']);
        if (!$lot) {
            return $this->json(['error' => 'Parking lot not found'], Response::HTTP_NOT_FOUND);
        }

        try {
            $startTime = new \DateTimeImmutable($data['start_time']);
            $endTime   = new \DateTimeImmutable($data['end_time']);
        } catch (\Exception $e) {
            return $this->json(['error' => 'Invalid date format. Use: Y-m-d H:i:s'], Response::HTTP_BAD_REQUEST);
        }

        if ($startTime >= $endTime) {
            return $this->json(['error' => 'start_time must be before end_time'], Response::HTTP_BAD_REQUEST);
        }

        if ($startTime < new \DateTimeImmutable()) {
            return $this->json(['error' => 'start_time must be in the future'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $booking = $this->bookingService->createBooking(
                $user, $lot, $data['vehicle_type'], $startTime, $endTime,
                $data['vehicle_number'] ?? null
            );

            return $this->json([
                'message' => 'Booking confirmed',
                'data'    => $this->serializeBooking($booking),
            ], Response::HTTP_CREATED);

        } catch (ParkingException $e) {
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
    }

    /**
     * GET /api/bookings
     * List current user's bookings.
     */
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        /** @var User $user */
        $user    = $this->getUser();
        $page    = max(1, (int)$request->query->get('page', 1));
        $bookings = $this->bookingRepository->findByUserPaginated($user->getId(), $page);

        return $this->json([
            'data' => array_map([$this, 'serializeBooking'], $bookings),
            'page' => $page,
        ]);
    }

    /**
     * GET /api/bookings/{id}
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(Booking $booking): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        if ($booking->getUser()->getId() !== $user->getId() && !$this->isGranted('ROLE_ADMIN')) {
            return $this->json(['error' => 'Access denied'], Response::HTTP_FORBIDDEN);
        }

        return $this->json(['data' => $this->serializeBooking($booking)]);
    }

    /**
     * DELETE /api/bookings/{id}
     * Cancel a booking.
     */
    #[Route('/{id}', name: 'cancel', methods: ['DELETE'])]
    public function cancel(Booking $booking): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        try {
            $this->bookingService->cancelBooking($booking, $user);
            return $this->json(['message' => 'Booking cancelled successfully']);
        } catch (ParkingException $e) {
            $code = $e->getCode() === 403 ? Response::HTTP_FORBIDDEN : Response::HTTP_BAD_REQUEST;
            return $this->json(['error' => $e->getMessage()], $code);
        }
    }

    private function serializeBooking(Booking $b): array
    {
        return [
            'id'                 => $b->getId(),
            'booking_reference'  => $b->getBookingReference(),
            'status'             => $b->getStatus(),
            'parking_lot'        => $b->getParkingLot()->getName(),
            'vehicle_type'       => $b->getVehicleType(),
            'vehicle_number'     => $b->getVehicleNumber(),
            'slot_number'        => $b->getSlot()?->getSlotNumber(),
            'start_time'         => $b->getStartTime()->format('Y-m-d H:i:s'),
            'end_time'           => $b->getEndTime()->format('Y-m-d H:i:s'),
            'expires_at'         => $b->getExpiresAt()?->format('Y-m-d H:i:s'),
            'estimated_fee'      => $b->getEstimatedFee(),
            'is_expired'         => $b->isExpired(),
            'created_at'         => $b->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }
}


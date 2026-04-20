<?php
namespace App\Service;

use App\Entity\Booking;
use App\Entity\ParkingLot;
use App\Entity\User;
use App\Exception\ParkingException;
use App\Repository\BookingRepository;
use App\Repository\ParkingSlotRepository;
use App\Repository\PricingRuleRepository;
use Doctrine\ORM\EntityManagerInterface;

class BookingService
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly BookingRepository $bookingRepository,
        private readonly ParkingSlotRepository $slotRepository,
        private readonly PricingRuleRepository $pricingRepository,
        private readonly int $expiryMinutes = 15,
    ) {}

    public function createBooking(
        User $user,
        ParkingLot $lot,
        string $vehicleType,
        \DateTimeImmutable $startTime,
        \DateTimeImmutable $endTime,
        ?string $vehicleNumber = null
    ): Booking {
        $availableSlot = $this->slotRepository->findAvailableForBooking(
            $lot->getId(), $vehicleType, $startTime, $endTime
        );

        if (!$availableSlot) {
            throw new ParkingException(
                "No {$vehicleType} slots available for selected time",
                ParkingException::NO_SLOT_AVAILABLE
            );
        }

        $durationMinutes = (int) round(($endTime->getTimestamp() - $startTime->getTimestamp()) / 60);
        $rule = $this->pricingRepository->findActiveRule($lot->getId(), $vehicleType);
        $estimatedFee = $rule ? $rule->calculateFee($durationMinutes) : null;

        $booking = new Booking();
        $booking->setUser($user);
        $booking->setParkingLot($lot);
        $booking->setSlot($availableSlot);
        $booking->setVehicleType($vehicleType);
        $booking->setVehicleNumber($vehicleNumber);
        $booking->setStartTime($startTime);
        $booking->setEndTime($endTime);
        $booking->setExpiresAt($startTime->modify("+{$this->expiryMinutes} minutes"));
        $booking->setStatus(Booking::STATUS_CONFIRMED);
        $booking->setEstimatedFee($estimatedFee !== null ? (string)$estimatedFee : null);

        $availableSlot->setStatus('reserved');

        $this->em->persist($booking);
        $this->em->flush();

        return $booking;
    }

    public function cancelBooking(Booking $booking, User $requester): void
    {
        if ($booking->getUser()->getId() !== $requester->getId()) {
            throw new ParkingException('Unauthorized to cancel this booking', ParkingException::UNAUTHORIZED, 403);
        }

        if (!in_array($booking->getStatus(), [Booking::STATUS_PENDING, Booking::STATUS_CONFIRMED])) {
            throw new ParkingException('Booking cannot be cancelled in current status', ParkingException::INVALID_STATUS);
        }

        $booking->setStatus(Booking::STATUS_CANCELLED);

        if ($slot = $booking->getSlot()) {
            $slot->setStatus('available');
        }

        $this->em->flush();
    }

    public function handleExpiredBookings(): int
    {
        $expired = $this->bookingRepository->findExpiredConfirmed();
        $count = 0;
        foreach ($expired as $booking) {
            $booking->setStatus(Booking::STATUS_EXPIRED);
            if ($slot = $booking->getSlot()) {
                $slot->setStatus('available');
            }
            $count++;
        }
        $this->em->flush();
        return $count;
    }
}


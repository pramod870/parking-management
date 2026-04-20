<?php
namespace App\Service;

use App\Entity\ParkingLot;
use App\Entity\ParkingSession;
use App\Entity\ParkingSlot;
use App\Entity\Payment;
use App\Entity\Vehicle;
use App\Exception\ParkingException;
use App\Repository\ParkingSessionRepository;
use App\Repository\ParkingSlotRepository;
use App\Repository\PricingRuleRepository;
use App\Repository\VehicleRepository;
use Doctrine\ORM\EntityManagerInterface;
use Psr\Log\LoggerInterface;

/**
 * Core parking service: manages entry, exit, fee calculation.
 * Follows SRP - only handles parking session lifecycle.
 */
class ParkingService
{
    public function __construct(
        private readonly EntityManagerInterface  $em,
        private readonly ParkingSlotRepository   $slotRepository,
        private readonly ParkingSessionRepository $sessionRepository,
        private readonly PricingRuleRepository   $pricingRepository,
        private readonly VehicleRepository       $vehicleRepository,
        private readonly LoggerInterface         $logger,
    ) {}

    /**
     * Register vehicle entry: find nearest slot, create session.
     */
    public function registerEntry(
        ParkingLot $lot,
        string $vehicleNumber,
        string $vehicleType,
        ?int $userId = null
    ): ParkingSession {
        $slot = $this->slotRepository->findNearestAvailable($lot->getId(), $vehicleType);

        if (!$slot) {
            throw new ParkingException(
                "No available {$vehicleType} slots in {$lot->getName()}",
                ParkingException::NO_SLOT_AVAILABLE
            );
        }

        $existing = $this->sessionRepository->findActiveByVehicleNumber($vehicleNumber);
        if ($existing) {
            throw new ParkingException(
                "Vehicle {$vehicleNumber} already has an active session",
                ParkingException::VEHICLE_ALREADY_PARKED
            );
        }

        $vehicle = $this->vehicleRepository->findOneBy(['vehicleNumber' => strtoupper($vehicleNumber)]);
        if (!$vehicle) {
            $vehicle = new Vehicle();
            $vehicle->setVehicleNumber($vehicleNumber);
            $vehicle->setVehicleType($vehicleType);
        }

        $session = new ParkingSession();
        $session->setParkingLot($lot);
        $session->setSlot($slot);
        $session->setVehicle($vehicle);
        $session->setEntryTime(new \DateTimeImmutable());
        $session->setStatus(ParkingSession::STATUS_ACTIVE);

        $slot->setStatus(ParkingSlot::STATUS_OCCUPIED);
        $lot->setAvailableSlots(max(0, $lot->getAvailableSlots() - 1));

        $this->em->persist($vehicle);
        $this->em->persist($session);
        $this->em->flush();

        $this->logger->info('Vehicle entered parking', [
            'vehicle'    => $vehicleNumber,
            'slot'       => $slot->getSlotNumber(),
            'lot'        => $lot->getName(),
            'session_id' => $session->getId(),
        ]);

        return $session;
    }

    /**
     * Process exit: compute duration + fee, create payment record.
     */
    public function processExit(ParkingSession $session, string $paymentMethod = Payment::METHOD_CASH): Payment
    {
        if ($session->getStatus() !== ParkingSession::STATUS_ACTIVE) {
            throw new ParkingException('Session is not active', ParkingException::SESSION_NOT_ACTIVE);
        }

        $exitTime = new \DateTimeImmutable();
        $duration = max(1, (int) round(
            ($exitTime->getTimestamp() - $session->getEntryTime()->getTimestamp()) / 60
        ));

        $rule = $this->pricingRepository->findActiveRule(
            $session->getParkingLot()->getId(),
            $session->getVehicle()->getVehicleType()
        );
        $fee = $rule ? $rule->calculateFee($duration) : 0.0;

        $session->setExitTime($exitTime);
        $session->setDurationMinutes($duration);
        $session->setTotalFee((string) $fee);
        $session->setStatus(ParkingSession::STATUS_COMPLETED);

        $payment = new Payment();
        $payment->setSession($session);
        $payment->setAmount((string) $fee);
        $payment->setStatus(Payment::STATUS_PENDING);
        $payment->setPaymentMethod($paymentMethod);

        $slot = $session->getSlot();
        $slot->setStatus(ParkingSlot::STATUS_AVAILABLE);
        $lot = $session->getParkingLot();
        $lot->setAvailableSlots($lot->getAvailableSlots() + 1);

        $this->em->persist($payment);
        $this->em->flush();

        $this->logger->info('Vehicle exited parking', [
            'session_id' => $session->getId(),
            'duration'   => $duration . ' min',
            'fee'        => 'Rs.' . $fee,
        ]);

        return $payment;
    }

    public function confirmPayment(Payment $payment, string $transactionId): void
    {
        $payment->setStatus(Payment::STATUS_PAID);
        $payment->setTransactionId($transactionId);
        $payment->setPaidAt(new \DateTimeImmutable());
        $this->em->flush();
    }
}


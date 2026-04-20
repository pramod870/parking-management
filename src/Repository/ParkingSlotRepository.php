<?php
namespace App\Repository;

use App\Entity\ParkingSlot;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingSlotRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingSlot::class);
    }

    /** Find nearest available slot (lowest floor + slot number) */
    public function findNearestAvailable(int $lotId, string $vehicleType): ?ParkingSlot
    {
        return $this->createQueryBuilder('s')
            ->where('s.parkingLot = :lotId')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status = :status')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('status', ParkingSlot::STATUS_AVAILABLE)
            ->orderBy('s.floor', 'ASC')
            ->addOrderBy('s.slotNumber', 'ASC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }

    /** Find available slot for a booking time range (no conflicting bookings) */
    public function findAvailableForBooking(
        int $lotId,
        string $vehicleType,
        \DateTimeImmutable $start,
        \DateTimeImmutable $end
    ): ?ParkingSlot {
        return $this->createQueryBuilder('s')
            ->where('s.parkingLot = :lotId')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status IN (:statuses)')
            ->andWhere('s.id NOT IN (
                SELECT IDENTITY(b.slot) FROM App\Entity\Booking b
                WHERE b.status IN (:activeBookingStatuses)
                AND b.startTime < :end AND b.endTime > :start
                AND b.slot IS NOT NULL
            )')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('statuses', [ParkingSlot::STATUS_AVAILABLE])
            ->setParameter('activeBookingStatuses', ['confirmed', 'active'])
            ->setParameter('start', $start)
            ->setParameter('end', $end)
            ->orderBy('s.floor', 'ASC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }

    public function getUtilizationStats(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('s')
            ->select('s.vehicleType, s.status, COUNT(s.id) as count');

        if ($lotId) {
            $qb->where('s.parkingLot = :lotId')->setParameter('lotId', $lotId);
        }

        return $qb->groupBy('s.vehicleType, s.status')->getQuery()->getArrayResult();
    }
}


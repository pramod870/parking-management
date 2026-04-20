<?php
namespace App\Repository;

use App\Entity\ParkingSession;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingSessionRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingSession::class);
    }

    public function findActiveByVehicleNumber(string $vehicleNumber): ?ParkingSession
    {
        return $this->createQueryBuilder('ps')
            ->join('ps.vehicle', 'v')
            ->where('v.vehicleNumber = :num')
            ->andWhere('ps.status = :status')
            ->setParameter('num', strtoupper($vehicleNumber))
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->getQuery()
            ->getOneOrNullResult();
    }

    public function countActive(?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE);
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function countByDate(\DateTimeImmutable $date, ?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.entryTime >= :start')
            ->andWhere('ps.entryTime < :end')
            ->setParameter('start', $date->setTime(0, 0))
            ->setParameter('end', $date->setTime(23, 59, 59));
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function countForPeriod(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.entryTime >= :from')
            ->andWhere('ps.entryTime <= :to')
            ->setParameter('from', $from)
            ->setParameter('to', $to);
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function getVehicleTypeBreakdown(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('v.vehicleType, COUNT(ps.id) as total')
            ->join('ps.vehicle', 'v')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->groupBy('v.vehicleType');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getArrayResult();
    }

    public function findActiveSessions(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('ps')
            ->join('ps.vehicle', 'v')
            ->join('ps.slot', 's')
            ->join('ps.parkingLot', 'pl')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->orderBy('ps.entryTime', 'DESC');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getResult();
    }
}


<?php
namespace App\Repository;

use App\Entity\Payment;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class PaymentRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Payment::class);
    }

    public function getTotalRevenue(?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->setParameter('status', Payment::STATUS_PAID);
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getRevenueByDate(\DateTimeImmutable $date, ?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :start')
            ->andWhere('p.paidAt < :end')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('start', $date->setTime(0, 0))
            ->setParameter('end', $date->setTime(23, 59, 59));
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getRevenueForPeriod(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to);
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getDailyBreakdown(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('p')
            ->select("DATE(p.paidAt) as date, COALESCE(SUM(p.amount), 0) as revenue, COUNT(p.id) as count")
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->groupBy('date')
            ->orderBy('date', 'ASC');
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return $qb->getQuery()->getArrayResult();
    }

    public function getRevenueByVehicleType(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('p')
            ->select('v.vehicleType, COALESCE(SUM(p.amount), 0) as revenue, COUNT(p.id) as count')
            ->join('p.session', 'ps')
            ->join('ps.vehicle', 'v')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->groupBy('v.vehicleType');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getArrayResult();
    }
}


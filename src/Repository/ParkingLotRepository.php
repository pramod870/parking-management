<?php
namespace App\Repository;

use App\Entity\ParkingLot;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingLotRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingLot::class);
    }

    public function findAllActive(): array
    {
        return $this->createQueryBuilder('pl')
            ->where('pl.isActive = true')
            ->orderBy('pl.name', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function findWithAvailableSlots(string $vehicleType): array
    {
        return $this->createQueryBuilder('pl')
            ->join('pl.slots', 's')
            ->where('pl.isActive = true')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status = :status')
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('status', 'available')
            ->groupBy('pl.id')
            ->getQuery()
            ->getResult();
    }
}


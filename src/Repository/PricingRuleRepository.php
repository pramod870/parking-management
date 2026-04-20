<?php
namespace App\Repository;

use App\Entity\PricingRule;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class PricingRuleRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, PricingRule::class);
    }

    public function findActiveRule(int $lotId, string $vehicleType): ?PricingRule
    {
        return $this->createQueryBuilder('pr')
            ->where('pr.parkingLot = :lotId')
            ->andWhere('pr.vehicleType = :vehicleType')
            ->andWhere('pr.isActive = true')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }
}


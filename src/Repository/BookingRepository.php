<?php
namespace App\Repository;

use App\Entity\Booking;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class BookingRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Booking::class);
    }

    public function findExpiredConfirmed(): array
    {
        return $this->createQueryBuilder('b')
            ->where('b.status = :status')
            ->andWhere('b.expiresAt < :now')
            ->setParameter('status', Booking::STATUS_CONFIRMED)
            ->setParameter('now', new \DateTimeImmutable())
            ->getQuery()
            ->getResult();
    }

    public function findByUserPaginated(int $userId, int $page = 1, int $limit = 10): array
    {
        $offset = ($page - 1) * $limit;
        return $this->createQueryBuilder('b')
            ->where('b.user = :userId')
            ->setParameter('userId', $userId)
            ->orderBy('b.createdAt', 'DESC')
            ->setFirstResult($offset)
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }
}


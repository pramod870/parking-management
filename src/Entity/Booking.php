<?php
namespace App\Entity;

use App\Repository\BookingRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: BookingRepository::class)]
#[ORM\Table(name: 'bookings')]
#[ORM\Index(columns: ['status'], name: 'idx_booking_status')]
#[ORM\Index(columns: ['start_time', 'end_time'], name: 'idx_booking_time')]
#[ORM\HasLifecycleCallbacks]
class Booking
{
    const STATUS_PENDING   = 'pending';
    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_ACTIVE    = 'active';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_EXPIRED   = 'expired';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'bookings')]
    #[ORM\JoinColumn(nullable: false)]
    private User $user;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingLot $parkingLot;

    #[ORM\ManyToOne(targetEntity: ParkingSlot::class, inversedBy: 'bookings')]
    #[ORM\JoinColumn(nullable: true)]
    private ?ParkingSlot $slot = null;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 30, nullable: true)]
    private ?string $vehicleNumber = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $startTime;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $endTime;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $expiresAt = null;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'pending'])]
    private string $status = self::STATUS_PENDING;

    #[ORM\Column(type: 'string', length: 50, unique: true)]
    private string $bookingReference;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $estimatedFee = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->bookingReference = 'BK' . strtoupper(substr(md5(uniqid()), 0, 8));
    }

    public function isExpired(): bool
    {
        return $this->expiresAt !== null && $this->expiresAt < new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getUser(): User { return $this->user; }
    public function setUser(User $u): static { $this->user = $u; return $this; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $l): static { $this->parkingLot = $l; return $this; }
    public function getSlot(): ?ParkingSlot { return $this->slot; }
    public function setSlot(?ParkingSlot $s): static { $this->slot = $s; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getVehicleNumber(): ?string { return $this->vehicleNumber; }
    public function setVehicleNumber(?string $n): static { $this->vehicleNumber = $n; return $this; }
    public function getStartTime(): \DateTimeImmutable { return $this->startTime; }
    public function setStartTime(\DateTimeImmutable $t): static { $this->startTime = $t; return $this; }
    public function getEndTime(): \DateTimeImmutable { return $this->endTime; }
    public function setEndTime(\DateTimeImmutable $t): static { $this->endTime = $t; return $this; }
    public function getExpiresAt(): ?\DateTimeImmutable { return $this->expiresAt; }
    public function setExpiresAt(?\DateTimeImmutable $t): static { $this->expiresAt = $t; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getBookingReference(): string { return $this->bookingReference; }
    public function getEstimatedFee(): ?string { return $this->estimatedFee; }
    public function setEstimatedFee(?string $f): static { $this->estimatedFee = $f; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}


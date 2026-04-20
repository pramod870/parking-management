<?php
namespace App\Entity;

use App\Repository\ParkingSessionRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: ParkingSessionRepository::class)]
#[ORM\Table(name: 'parking_sessions')]
#[ORM\Index(columns: ['status'], name: 'idx_session_status')]
#[ORM\Index(columns: ['entry_time'], name: 'idx_session_entry')]
#[ORM\Index(columns: ['parking_lot_id', 'status'], name: 'idx_session_lot_status')]
#[ORM\HasLifecycleCallbacks]
class ParkingSession
{
    const STATUS_ACTIVE    = 'active';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingLot $parkingLot;

    #[ORM\ManyToOne(targetEntity: ParkingSlot::class, inversedBy: 'sessions')]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingSlot $slot;

    #[ORM\ManyToOne(targetEntity: Vehicle::class, inversedBy: 'sessions')]
    #[ORM\JoinColumn(nullable: false)]
    private Vehicle $vehicle;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'parkingSessions')]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $user = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $entryTime;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $exitTime = null;

    #[ORM\Column(type: 'integer', nullable: true)]
    private ?int $durationMinutes = null;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $totalFee = null;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'active'])]
    private string $status = self::STATUS_ACTIVE;

    #[ORM\OneToOne(mappedBy: 'session', targetEntity: Payment::class, cascade: ['persist'])]
    private ?Payment $payment = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->entryTime = new \DateTimeImmutable();
    }

    public function calculateDuration(): int
    {
        $exit = $this->exitTime ?? new \DateTimeImmutable();
        return (int) round(($exit->getTimestamp() - $this->entryTime->getTimestamp()) / 60);
    }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $lot): static { $this->parkingLot = $lot; return $this; }
    public function getSlot(): ParkingSlot { return $this->slot; }
    public function setSlot(ParkingSlot $slot): static { $this->slot = $slot; return $this; }
    public function getVehicle(): Vehicle { return $this->vehicle; }
    public function setVehicle(Vehicle $v): static { $this->vehicle = $v; return $this; }
    public function getUser(): ?User { return $this->user; }
    public function setUser(?User $u): static { $this->user = $u; return $this; }
    public function getEntryTime(): \DateTimeImmutable { return $this->entryTime; }
    public function setEntryTime(\DateTimeImmutable $t): static { $this->entryTime = $t; return $this; }
    public function getExitTime(): ?\DateTimeImmutable { return $this->exitTime; }
    public function setExitTime(?\DateTimeImmutable $t): static { $this->exitTime = $t; return $this; }
    public function getDurationMinutes(): ?int { return $this->durationMinutes; }
    public function setDurationMinutes(?int $d): static { $this->durationMinutes = $d; return $this; }
    public function getTotalFee(): ?string { return $this->totalFee; }
    public function setTotalFee(?string $f): static { $this->totalFee = $f; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getPayment(): ?Payment { return $this->payment; }
    public function setPayment(?Payment $p): static { $this->payment = $p; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}


<?php
namespace App\Entity;

use App\Repository\ParkingSlotRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ParkingSlotRepository::class)]
#[ORM\Table(name: 'parking_slots')]
#[ORM\Index(columns: ['status'], name: 'idx_slot_status')]
#[ORM\Index(columns: ['vehicle_type'], name: 'idx_slot_vehicle_type')]
#[ORM\Index(columns: ['parking_lot_id', 'status'], name: 'idx_slot_lot_status')]
#[ORM\HasLifecycleCallbacks]
class ParkingSlot
{
    const STATUS_AVAILABLE = 'available';
    const STATUS_OCCUPIED  = 'occupied';
    const STATUS_RESERVED  = 'reserved';
    const STATUS_MAINTENANCE = 'maintenance';

    const VEHICLE_CAR   = 'car';
    const VEHICLE_BIKE  = 'bike';
    const VEHICLE_TRUCK = 'truck';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class, inversedBy: 'slots')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ParkingLot $parkingLot;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\NotBlank]
    private string $slotNumber;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: [self::VEHICLE_CAR, self::VEHICLE_BIKE, self::VEHICLE_TRUCK])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'available'])]
    #[Assert\Choice(choices: [self::STATUS_AVAILABLE, self::STATUS_OCCUPIED, self::STATUS_RESERVED, self::STATUS_MAINTENANCE])]
    private string $status = self::STATUS_AVAILABLE;

    #[ORM\Column(type: 'integer', options: ['default' => 1])]
    private int $floor = 1;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    #[ORM\OneToMany(mappedBy: 'slot', targetEntity: ParkingSession::class)]
    private Collection $sessions;

    #[ORM\OneToMany(mappedBy: 'slot', targetEntity: Booking::class)]
    private Collection $bookings;

    public function __construct()
    {
        $this->sessions = new ArrayCollection();
        $this->bookings = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
    }

    #[ORM\PreUpdate]
    public function preUpdate(): void { $this->updatedAt = new \DateTimeImmutable(); }

    public function isAvailable(): bool { return $this->status === self::STATUS_AVAILABLE; }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $lot): static { $this->parkingLot = $lot; return $this; }
    public function getSlotNumber(): string { return $this->slotNumber; }
    public function setSlotNumber(string $n): static { $this->slotNumber = $n; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getFloor(): int { return $this->floor; }
    public function setFloor(int $f): static { $this->floor = $f; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): \DateTimeImmutable { return $this->updatedAt; }
    public function getSessions(): Collection { return $this->sessions; }
    public function getBookings(): Collection { return $this->bookings; }
}


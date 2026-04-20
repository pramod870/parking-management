<?php
namespace App\Entity;

use App\Repository\ParkingLotRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ParkingLotRepository::class)]
#[ORM\Table(name: 'parking_lots')]
#[ORM\Index(columns: ['is_active'], name: 'idx_lot_active')]
#[ORM\HasLifecycleCallbacks]
class ParkingLot
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 150)]
    #[Assert\NotBlank]
    private string $name;

    #[ORM\Column(type: 'text')]
    #[Assert\NotBlank]
    private string $location;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 8, nullable: true)]
    private ?string $latitude = null;

    #[ORM\Column(type: 'decimal', precision: 11, scale: 8, nullable: true)]
    private ?string $longitude = null;

    #[ORM\Column(type: 'integer')]
    #[Assert\Positive]
    private int $totalSlots;

    #[ORM\Column(type: 'integer')]
    private int $availableSlots;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $isActive = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    #[ORM\OneToMany(mappedBy: 'parkingLot', targetEntity: ParkingSlot::class, cascade: ['persist', 'remove'])]
    private Collection $slots;

    #[ORM\OneToMany(mappedBy: 'parkingLot', targetEntity: PricingRule::class, cascade: ['persist', 'remove'])]
    private Collection $pricingRules;

    public function __construct()
    {
        $this->slots = new ArrayCollection();
        $this->pricingRules = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
        $this->availableSlots = 0;
    }

    #[ORM\PreUpdate]
    public function preUpdate(): void { $this->updatedAt = new \DateTimeImmutable(); }

    public function getId(): ?int { return $this->id; }
    public function getName(): string { return $this->name; }
    public function setName(string $name): static { $this->name = $name; return $this; }
    public function getLocation(): string { return $this->location; }
    public function setLocation(string $location): static { $this->location = $location; return $this; }
    public function getLatitude(): ?string { return $this->latitude; }
    public function setLatitude(?string $lat): static { $this->latitude = $lat; return $this; }
    public function getLongitude(): ?string { return $this->longitude; }
    public function setLongitude(?string $lng): static { $this->longitude = $lng; return $this; }
    public function getTotalSlots(): int { return $this->totalSlots; }
    public function setTotalSlots(int $total): static { $this->totalSlots = $total; return $this; }
    public function getAvailableSlots(): int { return $this->availableSlots; }
    public function setAvailableSlots(int $available): static { $this->availableSlots = $available; return $this; }
    public function isActive(): bool { return $this->isActive; }
    public function setIsActive(bool $isActive): static { $this->isActive = $isActive; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): \DateTimeImmutable { return $this->updatedAt; }
    public function getSlots(): Collection { return $this->slots; }
    public function getPricingRules(): Collection { return $this->pricingRules; }
}


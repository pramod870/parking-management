<?php
namespace App\Entity;

use App\Repository\VehicleRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: VehicleRepository::class)]
#[ORM\Table(name: 'vehicles')]
#[ORM\Index(columns: ['vehicle_number'], name: 'idx_vehicle_number')]
#[ORM\HasLifecycleCallbacks]
class Vehicle
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $owner = null;

    #[ORM\Column(type: 'string', length: 30, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Regex(pattern: '/^[A-Z0-9\-]+$/')]
    private string $vehicleNumber;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $make = null;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $model = null;

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    private ?string $color = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\OneToMany(mappedBy: 'vehicle', targetEntity: ParkingSession::class)]
    private Collection $sessions;

    public function __construct()
    {
        $this->sessions = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getOwner(): ?User { return $this->owner; }
    public function setOwner(?User $owner): static { $this->owner = $owner; return $this; }
    public function getVehicleNumber(): string { return $this->vehicleNumber; }
    public function setVehicleNumber(string $n): static { $this->vehicleNumber = strtoupper(trim($n)); return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getMake(): ?string { return $this->make; }
    public function setMake(?string $m): static { $this->make = $m; return $this; }
    public function getModel(): ?string { return $this->model; }
    public function setModel(?string $m): static { $this->model = $m; return $this; }
    public function getColor(): ?string { return $this->color; }
    public function setColor(?string $c): static { $this->color = $c; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getSessions(): Collection { return $this->sessions; }
}


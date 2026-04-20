<?php
namespace App\Entity;

use App\Repository\PricingRuleRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: PricingRuleRepository::class)]
#[ORM\Table(name: 'pricing_rules')]
#[ORM\HasLifecycleCallbacks]
class PricingRule
{
    const TYPE_HOURLY = 'hourly';
    const TYPE_MINUTE = 'per_minute';
    const TYPE_FLAT   = 'flat';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class, inversedBy: 'pricingRules')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ParkingLot $parkingLot;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: [self::TYPE_HOURLY, self::TYPE_MINUTE, self::TYPE_FLAT])]
    private string $rateType = self::TYPE_HOURLY;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    #[Assert\Positive]
    private string $rate;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $minimumCharge = null;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $maximumCharge = null;

    #[ORM\Column(type: 'integer', nullable: true)]
    private ?int $freeMinutes = null;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $isActive = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function calculateFee(int $durationMinutes): float
    {
        $billableMinutes = max(0, $durationMinutes - ($this->freeMinutes ?? 0));

        $fee = match ($this->rateType) {
            self::TYPE_HOURLY => ceil($billableMinutes / 60) * (float)$this->rate,
            self::TYPE_MINUTE => $billableMinutes * (float)$this->rate,
            self::TYPE_FLAT   => (float)$this->rate,
            default           => 0.0,
        };

        if ($this->minimumCharge !== null) {
            $fee = max($fee, (float)$this->minimumCharge);
        }
        if ($this->maximumCharge !== null) {
            $fee = min($fee, (float)$this->maximumCharge);
        }

        return round($fee, 2);
    }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $l): static { $this->parkingLot = $l; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getRateType(): string { return $this->rateType; }
    public function setRateType(string $t): static { $this->rateType = $t; return $this; }
    public function getRate(): string { return $this->rate; }
    public function setRate(string $r): static { $this->rate = $r; return $this; }
    public function getMinimumCharge(): ?string { return $this->minimumCharge; }
    public function setMinimumCharge(?string $m): static { $this->minimumCharge = $m; return $this; }
    public function getMaximumCharge(): ?string { return $this->maximumCharge; }
    public function setMaximumCharge(?string $m): static { $this->maximumCharge = $m; return $this; }
    public function getFreeMinutes(): ?int { return $this->freeMinutes; }
    public function setFreeMinutes(?int $f): static { $this->freeMinutes = $f; return $this; }
    public function isActive(): bool { return $this->isActive; }
    public function setIsActive(bool $a): static { $this->isActive = $a; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}


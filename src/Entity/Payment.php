<?php
namespace App\Entity;

use App\Repository\PaymentRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: PaymentRepository::class)]
#[ORM\Table(name: 'payments')]
#[ORM\Index(columns: ['status'], name: 'idx_payment_status')]
#[ORM\HasLifecycleCallbacks]
class Payment
{
    const STATUS_PENDING = 'pending';
    const STATUS_PAID    = 'paid';
    const STATUS_FAILED  = 'failed';
    const STATUS_REFUNDED = 'refunded';

    const METHOD_CASH   = 'cash';
    const METHOD_CARD   = 'card';
    const METHOD_UPI    = 'upi';
    const METHOD_ONLINE = 'online';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\OneToOne(inversedBy: 'payment', targetEntity: ParkingSession::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingSession $session;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    private string $amount;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'pending'])]
    private string $status = self::STATUS_PENDING;

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    private ?string $paymentMethod = null;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $transactionId = null;

    #[ORM\Column(type: 'json', nullable: true)]
    private ?array $metadata = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $paidAt = null;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getSession(): ParkingSession { return $this->session; }
    public function setSession(ParkingSession $s): static { $this->session = $s; return $this; }
    public function getAmount(): string { return $this->amount; }
    public function setAmount(string $a): static { $this->amount = $a; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getPaymentMethod(): ?string { return $this->paymentMethod; }
    public function setPaymentMethod(?string $m): static { $this->paymentMethod = $m; return $this; }
    public function getTransactionId(): ?string { return $this->transactionId; }
    public function setTransactionId(?string $t): static { $this->transactionId = $t; return $this; }
    public function getMetadata(): ?array { return $this->metadata; }
    public function setMetadata(?array $m): static { $this->metadata = $m; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getPaidAt(): ?\DateTimeImmutable { return $this->paidAt; }
    public function setPaidAt(?\DateTimeImmutable $p): static { $this->paidAt = $p; return $this; }
}


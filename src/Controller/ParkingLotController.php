<?php
namespace App\Controller;

use App\Entity\ParkingLot;
use App\Entity\ParkingSlot;
use App\Entity\PricingRule;
use App\Repository\ParkingLotRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/lots', name: 'parking_lot_')]
class ParkingLotController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly ParkingLotRepository   $lotRepository,
    ) {}

    /**
     * GET /api/lots
     * List all active parking lots with availability.
     */
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $lots = $this->lotRepository->findAllActive();
        return $this->json(['data' => array_map([$this, 'serializeLot'], $lots)]);
    }

    /**
     * GET /api/lots/{id}
     * Get single parking lot details with slots.
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(ParkingLot $lot): JsonResponse
    {
        return $this->json(['data' => $this->serializeLotFull($lot)]);
    }

    /**
     * POST /api/lots
     * Create a new parking lot. [ADMIN only]
     */
    #[Route('', name: 'create', methods: ['POST'])]
    #[IsGranted('ROLE_ADMIN')]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (empty($data['name']) || empty($data['location']) || empty($data['total_slots'])) {
            return $this->json(['error' => 'name, location, total_slots are required'], Response::HTTP_BAD_REQUEST);
        }

        $lot = new ParkingLot();
        $lot->setName($data['name']);
        $lot->setLocation($data['location']);
        $lot->setTotalSlots((int)$data['total_slots']);
        $lot->setAvailableSlots((int)$data['total_slots']);
        $lot->setLatitude($data['latitude'] ?? null);
        $lot->setLongitude($data['longitude'] ?? null);

        $this->em->persist($lot);

        // Auto-generate slots if vehicle_types provided
        if (!empty($data['slot_config'])) {
            $slotNum = 1;
            foreach ($data['slot_config'] as $config) {
                $type  = $config['vehicle_type'] ?? 'car';
                $count = (int)($config['count'] ?? 0);
                for ($i = 0; $i < $count; $i++) {
                    $slot = new ParkingSlot();
                    $slot->setParkingLot($lot);
                    $slot->setSlotNumber(strtoupper(substr($type, 0, 1)) . str_pad($slotNum, 3, '0', STR_PAD_LEFT));
                    $slot->setVehicleType($type);
                    $slot->setFloor((int)($config['floor'] ?? 1));
                    $this->em->persist($slot);
                    $slotNum++;
                }
            }
        }

        // Auto-create pricing rules if provided
        if (!empty($data['pricing'])) {
            foreach ($data['pricing'] as $p) {
                $rule = new PricingRule();
                $rule->setParkingLot($lot);
                $rule->setVehicleType($p['vehicle_type']);
                $rule->setRateType($p['rate_type'] ?? PricingRule::TYPE_HOURLY);
                $rule->setRate((string)$p['rate']);
                $rule->setMinimumCharge(isset($p['minimum_charge']) ? (string)$p['minimum_charge'] : null);
                $rule->setFreeMinutes($p['free_minutes'] ?? null);
                $this->em->persist($rule);
            }
        }

        $this->em->flush();

        return $this->json(['message' => 'Parking lot created', 'data' => $this->serializeLot($lot)], Response::HTTP_CREATED);
    }

    /**
     * PUT /api/lots/{id}
     * Update parking lot. [ADMIN only]
     */
    #[Route('/{id}', name: 'update', methods: ['PUT'])]
    #[IsGranted('ROLE_ADMIN')]
    public function update(ParkingLot $lot, Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (isset($data['name']))      $lot->setName($data['name']);
        if (isset($data['location']))  $lot->setLocation($data['location']);
        if (isset($data['latitude']))  $lot->setLatitude($data['latitude']);
        if (isset($data['longitude'])) $lot->setLongitude($data['longitude']);
        if (isset($data['is_active'])) $lot->setIsActive((bool)$data['is_active']);

        $this->em->flush();

        return $this->json(['message' => 'Parking lot updated', 'data' => $this->serializeLot($lot)]);
    }

    /**
     * DELETE /api/lots/{id}
     * Delete parking lot. [ADMIN only]
     */
    #[Route('/{id}', name: 'delete', methods: ['DELETE'])]
    #[IsGranted('ROLE_ADMIN')]
    public function delete(ParkingLot $lot): JsonResponse
    {
        $this->em->remove($lot);
        $this->em->flush();
        return $this->json(['message' => 'Parking lot deleted']);
    }

    /**
     * GET /api/lots/{id}/slots
     * Get all slots of a parking lot with status.
     */
    #[Route('/{id}/slots', name: 'slots', methods: ['GET'])]
    public function slots(ParkingLot $lot, Request $request): JsonResponse
    {
        $vehicleType = $request->query->get('vehicle_type');
        $status      = $request->query->get('status');

        $slots = $lot->getSlots()->filter(function(ParkingSlot $slot) use ($vehicleType, $status) {
            if ($vehicleType && $slot->getVehicleType() !== $vehicleType) return false;
            if ($status && $slot->getStatus() !== $status) return false;
            return true;
        });

        return $this->json([
            'data' => array_map([$this, 'serializeSlot'], $slots->toArray()),
            'summary' => [
                'total'     => $lot->getTotalSlots(),
                'available' => $lot->getAvailableSlots(),
                'occupied'  => $lot->getTotalSlots() - $lot->getAvailableSlots(),
            ],
        ]);
    }

    // ── Serializers ──────────────────────────────────────────────────────────

    private function serializeLot(ParkingLot $lot): array
    {
        return [
            'id'               => $lot->getId(),
            'name'             => $lot->getName(),
            'location'         => $lot->getLocation(),
            'latitude'         => $lot->getLatitude(),
            'longitude'        => $lot->getLongitude(),
            'total_slots'      => $lot->getTotalSlots(),
            'available_slots'  => $lot->getAvailableSlots(),
            'occupied_slots'   => $lot->getTotalSlots() - $lot->getAvailableSlots(),
            'is_active'        => $lot->isActive(),
            'created_at'       => $lot->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }

    private function serializeLotFull(ParkingLot $lot): array
    {
        $data = $this->serializeLot($lot);
        $data['pricing_rules'] = array_map(function (PricingRule $r) {
            return [
                'vehicle_type'   => $r->getVehicleType(),
                'rate_type'      => $r->getRateType(),
                'rate'           => $r->getRate(),
                'minimum_charge' => $r->getMinimumCharge(),
                'free_minutes'   => $r->getFreeMinutes(),
            ];
        }, $lot->getPricingRules()->toArray());
        return $data;
    }

    private function serializeSlot(ParkingSlot $slot): array
    {
        return [
            'id'           => $slot->getId(),
            'slot_number'  => $slot->getSlotNumber(),
            'vehicle_type' => $slot->getVehicleType(),
            'status'       => $slot->getStatus(),
            'floor'        => $slot->getFloor(),
        ];
    }
}


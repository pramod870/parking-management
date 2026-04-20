<?php
namespace App\DataFixtures;

use App\Entity\Booking;
use App\Entity\ParkingLot;
use App\Entity\ParkingSession;
use App\Entity\ParkingSlot;
use App\Entity\Payment;
use App\Entity\PricingRule;
use App\Entity\User;
use App\Entity\Vehicle;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Faker\Factory;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

/**
 * Seeds the database with realistic demo data.
 * Run: php bin/console doctrine:fixtures:load
 */
class AppFixtures extends Fixture
{
    public function __construct(
        private readonly UserPasswordHasherInterface $hasher
    ) {}

    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create('en_IN');
        echo "\n🌱 Seeding database...\n";

        // ── 1. Users ─────────────────────────────────────────────
        $users = $this->seedUsers($manager, $faker);
        echo "   ✓ Users seeded\n";

        // ── 2. Parking Lots ───────────────────────────────────────
        $lots = $this->seedParkingLots($manager, $faker);
        echo "   ✓ Parking lots seeded\n";

        // ── 3. Flush lots first (FK deps)
        $manager->flush();

        // ── 4. Slots + Pricing ────────────────────────────────────
        $allSlots = $this->seedSlotsAndPricing($manager, $lots);
        echo "   ✓ Slots & pricing seeded\n";

        $manager->flush();

        // ── 5. Vehicles ───────────────────────────────────────────
        $vehicles = $this->seedVehicles($manager, $faker, $users);
        echo "   ✓ Vehicles seeded\n";

        $manager->flush();

        // ── 6. Completed Sessions + Payments ─────────────────────
        $this->seedCompletedSessions($manager, $faker, $lots, $allSlots, $vehicles, $users);
        echo "   ✓ Historical sessions & payments seeded\n";

        // ── 7. Active Sessions ────────────────────────────────────
        $this->seedActiveSessions($manager, $lots, $allSlots, $vehicles);
        echo "   ✓ Active sessions seeded\n";

        $manager->flush();

        // ── 8. Bookings ───────────────────────────────────────────
        $this->seedBookings($manager, $faker, $lots, $users);
        echo "   ✓ Bookings seeded\n";

        $manager->flush();
        echo "\n✅ Database seeded successfully!\n\n";
        $this->printCredentials();
    }

    // ── Seed Methods ─────────────────────────────────────────────────────────

    private function seedUsers(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $users = [];

        // Fixed accounts
        $accounts = [
            ['admin@parking.com',    'Admin User',     'Admin@123',   ['ROLE_ADMIN']],
            ['operator@parking.com', 'Gate Operator',  'Operator@123',['ROLE_OPERATOR']],
            ['user@parking.com',     'Regular User',   'User@123',    ['ROLE_USER']],
        ];

        foreach ($accounts as [$email, $name, $pass, $roles]) {
            $user = new User();
            $user->setEmail($email)
                 ->setName($name)
                 ->setRoles($roles)
                 ->setPassword($this->hasher->hashPassword($user, $pass))
                 ->setPhone($faker->phoneNumber());
            $manager->persist($user);
            $users[] = $user;
        }

        // Random users
        for ($i = 0; $i < 20; $i++) {
            $user = new User();
            $user->setEmail($faker->unique()->safeEmail())
                 ->setName($faker->name())
                 ->setRoles(['ROLE_USER'])
                 ->setPassword($this->hasher->hashPassword($user, 'password'))
                 ->setPhone($faker->phoneNumber());
            $manager->persist($user);
            $users[] = $user;
        }

        return $users;
    }

    private function seedParkingLots(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $lots = [];
        $lotData = [
            ['Connaught Place Parking',    'Connaught Place, New Delhi',     28.6315, 77.2167],
            ['Saket District Centre',      'Saket, New Delhi',               28.5274, 77.2159],
            ['Cyber Hub Parking',          'DLF Cyber Hub, Gurugram',        28.4950, 77.0877],
            ['Mumbai Central Parking',     'Mumbai Central, Mumbai',         18.9692, 72.8192],
            ['Bengaluru Tech Park',        'Whitefield, Bengaluru',          12.9698, 77.7499],
        ];

        foreach ($lotData as [$name, $location, $lat, $lng]) {
            $total = $faker->numberBetween(50, 200);
            $lot   = new ParkingLot();
            $lot->setName($name)
                ->setLocation($location)
                ->setLatitude((string)$lat)
                ->setLongitude((string)$lng)
                ->setTotalSlots($total)
                ->setAvailableSlots($total);
            $manager->persist($lot);
            $lots[] = $lot;
        }

        return $lots;
    }

    private function seedSlotsAndPricing(ObjectManager $manager, array $lots): array
    {
        $allSlots = [];

        // Pricing config per vehicle type
        $pricingConfig = [
            'car'   => ['rate' => '50.00',  'min' => '50.00',  'free' => 15],
            'bike'  => ['rate' => '20.00',  'min' => '20.00',  'free' => 30],
            'truck' => ['rate' => '100.00', 'min' => '100.00', 'free' => 0],
        ];

        // Slot distribution per lot
        $slotConfig = [
            ['vehicle_type' => 'car',   'count' => 30, 'floors' => 3],
            ['vehicle_type' => 'bike',  'count' => 15, 'floors' => 1],
            ['vehicle_type' => 'truck', 'count' => 5,  'floors' => 1],
        ];

        foreach ($lots as $lot) {
            $slotNum = 1;
            $lotSlots = [];

            foreach ($slotConfig as $config) {
                $type   = $config['vehicle_type'];
                $count  = $config['count'];
                $floors = $config['floors'];
                $prefix = strtoupper($type[0]);

                for ($i = 0; $i < $count; $i++) {
                    $floor = (int)ceil(($i + 1) / ceil($count / $floors));
                    $slot  = new ParkingSlot();
                    $slot->setParkingLot($lot)
                         ->setSlotNumber($prefix . str_pad($slotNum, 3, '0', STR_PAD_LEFT))
                         ->setVehicleType($type)
                         ->setFloor($floor)
                         ->setStatus(ParkingSlot::STATUS_AVAILABLE);
                    $manager->persist($slot);
                    $lotSlots[$type][] = $slot;
                    $allSlots[]        = $slot;
                    $slotNum++;
                }

                // Create pricing rule
                $pc   = $pricingConfig[$type];
                $rule = new PricingRule();
                $rule->setParkingLot($lot)
                     ->setVehicleType($type)
                     ->setRateType(PricingRule::TYPE_HOURLY)
                     ->setRate($pc['rate'])
                     ->setMinimumCharge($pc['min'])
                     ->setFreeMinutes($pc['free']);
                $manager->persist($rule);
            }
        }

        return $allSlots;
    }

    private function seedVehicles(ObjectManager $manager, \Faker\Generator $faker, array $users): array
    {
        $vehicles = [];
        $types    = ['car', 'car', 'car', 'bike', 'bike', 'truck'];
        $makes    = ['Maruti', 'Hyundai', 'Tata', 'Honda', 'Toyota', 'Mahindra', 'Bajaj', 'TVS'];
        $models   = ['Swift', 'i20', 'Nexon', 'City', 'Fortuner', 'Bolero', 'Pulsar', 'Apache'];
        $colors   = ['White', 'Black', 'Silver', 'Red', 'Blue', 'Grey', 'Brown'];

        $statePrefixes = ['DL', 'MH', 'KA', 'HR', 'UP', 'TN'];

        for ($i = 0; $i < 60; $i++) {
            $type   = $types[array_rand($types)];
            $prefix = $statePrefixes[array_rand($statePrefixes)];
            $num    = $prefix . sprintf('%02d', rand(1, 99)) . strtoupper(substr(md5(uniqid()), 0, 2)) . sprintf('%04d', rand(1000, 9999));

            $vehicle = new Vehicle();
            $vehicle->setVehicleNumber($num)
                    ->setVehicleType($type)
                    ->setMake($makes[array_rand($makes)])
                    ->setModel($models[array_rand($models)])
                    ->setColor($colors[array_rand($colors)]);

            if ($i < count($users) && $i % 2 === 0) {
                $vehicle->setOwner($users[$i]);
            }

            $manager->persist($vehicle);
            $vehicles[] = $vehicle;
        }

        return $vehicles;
    }

    private function seedCompletedSessions(
        ObjectManager $manager,
        \Faker\Generator $faker,
        array $lots,
        array $allSlots,
        array $vehicles,
        array $users
    ): void {
        // Seed 90 days of historical data
        for ($day = 90; $day >= 1; $day--) {
            $sessionsPerDay = $faker->numberBetween(5, 25);

            for ($s = 0; $s < $sessionsPerDay; $s++) {
                $lot     = $lots[array_rand($lots)];
                $vehicle = $vehicles[array_rand($vehicles)];

                // Find a slot of matching vehicle type
                $matchingSlots = array_filter($allSlots, fn($sl) =>
                    $sl->getParkingLot()->getId() === $lot->getId() &&
                    $sl->getVehicleType() === $vehicle->getVehicleType()
                );
                if (empty($matchingSlots)) continue;

                $slot = array_values($matchingSlots)[array_rand($matchingSlots)];

                $entryHour     = $faker->numberBetween(6, 20);
                $durationMins  = $faker->numberBetween(30, 480);
                $entryTime     = new \DateTimeImmutable("-{$day} days {$entryHour}:00:00");
                $exitTime      = $entryTime->modify("+{$durationMins} minutes");

                $session = new ParkingSession();
                $session->setParkingLot($lot)
                        ->setSlot($slot)
                        ->setVehicle($vehicle)
                        ->setUser($users[array_rand($users)])
                        ->setEntryTime($entryTime)
                        ->setExitTime($exitTime)
                        ->setDurationMinutes($durationMins)
                        ->setStatus(ParkingSession::STATUS_COMPLETED);

                // Calculate fee (hourly)
                $hours = ceil($durationMins / 60);
                $rate  = match ($vehicle->getVehicleType()) {
                    'car'   => 50,
                    'bike'  => 20,
                    'truck' => 100,
                    default => 50,
                };
                $fee = max($rate, $hours * $rate);
                $session->setTotalFee((string)$fee);

                $manager->persist($session);

                // Payment
                $payment = new Payment();
                $payment->setSession($session)
                        ->setAmount((string)$fee)
                        ->setStatus(Payment::STATUS_PAID)
                        ->setPaymentMethod($faker->randomElement(['cash', 'card', 'upi']))
                        ->setTransactionId('TXN' . strtoupper(substr(md5(uniqid()), 0, 10)))
                        ->setPaidAt($exitTime->modify('+2 minutes'));

                $manager->persist($payment);
            }
        }
    }

    private function seedActiveSessions(
        ObjectManager $manager,
        array $lots,
        array $allSlots,
        array $vehicles
    ): void {
        $usedSlotIds = [];

        for ($i = 0; $i < 15; $i++) {
            $lot     = $lots[array_rand($lots)];
            $vehicle = $vehicles[array_rand($vehicles)];

            $matchingSlots = array_filter($allSlots, fn($sl) =>
                $sl->getParkingLot()->getId() === $lot->getId() &&
                $sl->getVehicleType() === $vehicle->getVehicleType() &&
                !in_array($sl->getId(), $usedSlotIds)
            );
            if (empty($matchingSlots)) continue;

            $slot = array_values($matchingSlots)[0];
            $usedSlotIds[] = spl_object_id($slot);

            $entryMinsAgo = random_int(10, 240);
            $entryTime    = new \DateTimeImmutable("-{$entryMinsAgo} minutes");

            $session = new ParkingSession();
            $session->setParkingLot($lot)
                    ->setSlot($slot)
                    ->setVehicle($vehicle)
                    ->setEntryTime($entryTime)
                    ->setStatus(ParkingSession::STATUS_ACTIVE);

            $slot->setStatus(ParkingSlot::STATUS_OCCUPIED);
            $lot->setAvailableSlots(max(0, $lot->getAvailableSlots() - 1));

            $manager->persist($session);
        }
    }

    private function seedBookings(
        ObjectManager $manager,
        \Faker\Generator $faker,
        array $lots,
        array $users
    ): void {
        $types = ['car', 'bike', 'truck'];

        for ($i = 0; $i < 10; $i++) {
            $lot       = $lots[array_rand($lots)];
            $user      = $users[array_rand($users)];
            $type      = $types[array_rand($types)];
            $hoursAhead = random_int(1, 48);

            $start = new \DateTimeImmutable("+{$hoursAhead} hours");
            $end   = $start->modify('+2 hours');

            $booking = new Booking();
            $booking->setUser($user)
                    ->setParkingLot($lot)
                    ->setVehicleType($type)
                    ->setVehicleNumber('DL01AB' . str_pad((string)($i + 1000), 4, '0', STR_PAD_LEFT))
                    ->setStartTime($start)
                    ->setEndTime($end)
                    ->setExpiresAt($start->modify('+15 minutes'))
                    ->setStatus(Booking::STATUS_CONFIRMED)
                    ->setEstimatedFee((string)(2 * match($type) { 'car' => 50, 'bike' => 20, 'truck' => 100, default => 50 }));

            $manager->persist($booking);
        }
    }

    private function printCredentials(): void
    {
        echo "┌─────────────────────────────────────────────┐\n";
        echo "│           TEST CREDENTIALS                  │\n";
        echo "├─────────────────────────────────────────────┤\n";
        echo "│ ADMIN    admin@parking.com    Admin@123      │\n";
        echo "│ OPERATOR operator@parking.com Operator@123   │\n";
        echo "│ USER     user@parking.com     User@123       │\n";
        echo "└─────────────────────────────────────────────┘\n";
    }
}


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

class AppFixtures extends Fixture
{
    public function __construct(
        private readonly UserPasswordHasherInterface $hasher
    ) {}

    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create('en_IN');
        echo "\n🌱 Seeding database...\n";

        $users = $this->seedUsers($manager, $faker);
        echo "   ✓ Users seeded\n";

        $lots = $this->seedParkingLots($manager, $faker);
        echo "   ✓ Parking lots seeded\n";

        $manager->flush();

        $slotsByLot = $this->seedSlotsAndPricing($manager, $lots);
        echo "   ✓ Slots & pricing seeded\n";

        $manager->flush();

        $vehicles = $this->seedVehicles($manager, $faker, $users);
        echo "   ✓ Vehicles seeded\n";

        $manager->flush();

        $this->seedCompletedSessions($manager, $faker, $lots, $slotsByLot, $vehicles, $users);
        echo "   ✓ Historical sessions & payments seeded\n";

        $this->seedActiveSessions($manager, $lots, $slotsByLot, $vehicles);
        echo "   ✓ Active sessions seeded\n";

        $manager->flush();

        $this->seedBookings($manager, $faker, $lots, $users);
        echo "   ✓ Bookings seeded\n";

        $manager->flush();
        echo "\n✅ Database seeded successfully!\n\n";
        $this->printCredentials();
    }

    private function seedUsers(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $users = [];

        $accounts = [
            ['admin@parking.com',    'Admin User',    'Admin@123',    ['ROLE_ADMIN']],
            ['operator@parking.com', 'Gate Operator', 'Operator@123', ['ROLE_OPERATOR']],
            ['user@parking.com',     'Regular User',  'User@123',     ['ROLE_USER']],
        ];

        foreach ($accounts as [$email, $name, $pass, $roles]) {
            $user = new User();
            $user->setEmail($email)
                 ->setName($name)
                 ->setRoles($roles)
                 ->setPassword($this->hasher->hashPassword($user, $pass))
                 ->setPhone('98765' . rand(10000, 99999));
            $manager->persist($user);
            $users[] = $user;
        }

        for ($i = 0; $i < 10; $i++) {
            $user = new User();
            $user->setEmail($faker->unique()->safeEmail())
                 ->setName($faker->name())
                 ->setRoles(['ROLE_USER'])
                 ->setPassword($this->hasher->hashPassword($user, 'password'))
                 ->setPhone('98765' . rand(10000, 99999));
            $manager->persist($user);
            $users[] = $user;
        }

        return $users;
    }

    private function seedParkingLots(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $lots = [];
        $lotData = [
            ['Connaught Place Parking',  'Connaught Place, New Delhi',  28.6315, 77.2167],
            ['Saket District Centre',    'Saket, New Delhi',            28.5274, 77.2159],
            ['Cyber Hub Parking',        'DLF Cyber Hub, Gurugram',     28.4950, 77.0877],
            ['Mumbai Central Parking',   'Mumbai Central, Mumbai',      18.9692, 72.8192],
            ['Bengaluru Tech Park',      'Whitefield, Bengaluru',       12.9698, 77.7499],
        ];

        foreach ($lotData as [$name, $location, $lat, $lng]) {
            $total = 50;
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

    // Returns ['lotIndex' => ['car' => [...slots], 'bike' => [...], 'truck' => [...]]]
    private function seedSlotsAndPricing(ObjectManager $manager, array $lots): array
    {
        $slotsByLot = [];

        $pricingConfig = [
            'car'   => ['rate' => '50.00',  'min' => '50.00',  'free' => 15],
            'bike'  => ['rate' => '20.00',  'min' => '20.00',  'free' => 30],
            'truck' => ['rate' => '100.00', 'min' => '100.00', 'free' => 0],
        ];

        $slotConfig = [
            ['vehicle_type' => 'car',   'count' => 20, 'floor' => 1],
            ['vehicle_type' => 'bike',  'count' => 20, 'floor' => 2],
            ['vehicle_type' => 'truck', 'count' => 10, 'floor' => 3],
        ];

        foreach ($lots as $lotIdx => $lot) {
            $slotsByLot[$lotIdx] = ['car' => [], 'bike' => [], 'truck' => []];
            $slotNum = 1;

            foreach ($slotConfig as $config) {
                $type   = $config['vehicle_type'];
                $count  = $config['count'];
                $floor  = $config['floor'];
                $prefix = strtoupper($type[0]);

                for ($i = 0; $i < $count; $i++) {
                    $slot = new ParkingSlot();
                    $slot->setParkingLot($lot)
                         ->setSlotNumber($prefix . str_pad($slotNum, 3, '0', STR_PAD_LEFT))
                         ->setVehicleType($type)
                         ->setFloor($floor)
                         ->setStatus(ParkingSlot::STATUS_AVAILABLE);
                    $manager->persist($slot);
                    $slotsByLot[$lotIdx][$type][] = $slot;
                    $slotNum++;
                }

                // Pricing rule
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

        return $slotsByLot;
    }

    private function seedVehicles(ObjectManager $manager, \Faker\Generator $faker, array $users): array
    {
        $vehicles = [];
        $types    = ['car', 'car', 'car', 'bike', 'bike', 'truck'];
        $makes    = ['Maruti', 'Hyundai', 'Tata', 'Honda', 'Toyota', 'Mahindra'];
        $models   = ['Swift', 'i20', 'Nexon', 'City', 'Fortuner', 'Bolero'];
        $colors   = ['White', 'Black', 'Silver', 'Red', 'Blue', 'Grey'];
        $states   = ['DL', 'MH', 'KA', 'HR', 'UP', 'TN'];

        for ($i = 0; $i < 30; $i++) {
            $type  = $types[array_rand($types)];
            $state = $states[array_rand($states)];
            $num   = $state . sprintf('%02d', rand(1, 99)) . chr(rand(65, 90)) . chr(rand(65, 90)) . sprintf('%04d', rand(1000, 9999));

            $vehicle = new Vehicle();
            $vehicle->setVehicleNumber($num)
                    ->setVehicleType($type)
                    ->setMake($makes[array_rand($makes)])
                    ->setModel($models[array_rand($models)])
                    ->setColor($colors[array_rand($colors)]);

            if ($i < count($users)) {
                $vehicle->setOwner($users[$i]);
            }

            $manager->persist($vehicle);
            $vehicles[$type][] = $vehicle;
        }

        return $vehicles;
    }

    private function seedCompletedSessions(
        ObjectManager $manager,
        \Faker\Generator $faker,
        array $lots,
        array $slotsByLot,
        array $vehicles,
        array $users
    ): void {
        $rates = ['car' => 50, 'bike' => 20, 'truck' => 100];

        // 30 days of history, ~5 sessions per day
        for ($day = 30; $day >= 1; $day--) {
            for ($s = 0; $s < 5; $s++) {
                $lotIdx = array_rand($lots);
                $lot    = $lots[$lotIdx];

                // Pick a random vehicle type that has both vehicles and slots
                $availableTypes = array_keys(array_filter(
                    $slotsByLot[$lotIdx],
                    fn($slots) => !empty($slots)
                ));

                // Intersect with vehicle types we have
                $vehicleTypes = array_intersect($availableTypes, array_keys($vehicles));
                if (empty($vehicleTypes)) continue;

                $vehicleTypes = array_values($vehicleTypes);
                $type         = $vehicleTypes[array_rand($vehicleTypes)];

                $typeVehicles = $vehicles[$type];
                $vehicle      = $typeVehicles[array_rand($typeVehicles)];
                $slot         = $slotsByLot[$lotIdx][$type][array_rand($slotsByLot[$lotIdx][$type])];

                $entryHour    = $faker->numberBetween(6, 20);
                $durationMins = $faker->numberBetween(30, 300);
                $entryTime    = new \DateTimeImmutable("-{$day} days {$entryHour}:00:00");
                $exitTime     = $entryTime->modify("+{$durationMins} minutes");

                $hours = (int)ceil($durationMins / 60);
                $fee   = max($rates[$type], $hours * $rates[$type]);

                $session = new ParkingSession();
                $session->setParkingLot($lot)
                        ->setSlot($slot)
                        ->setVehicle($vehicle)
                        ->setUser($users[array_rand($users)])
                        ->setEntryTime($entryTime)
                        ->setExitTime($exitTime)
                        ->setDurationMinutes($durationMins)
                        ->setTotalFee((string)$fee)
                        ->setStatus(ParkingSession::STATUS_COMPLETED);

                $manager->persist($session);

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
        array $slotsByLot,
        array $vehicles
    ): void {
        $usedSlots = [];

        for ($i = 0; $i < 8; $i++) {
            $lotIdx = $i % count($lots);
            $lot    = $lots[$lotIdx];

            $types = array_keys(array_filter($slotsByLot[$lotIdx], fn($s) => !empty($s)));
            $types = array_intersect($types, array_keys($vehicles));
            $types = array_values($types);
            if (empty($types)) continue;

            $type = $types[$i % count($types)];
            if (empty($vehicles[$type]) || empty($slotsByLot[$lotIdx][$type])) continue;

            // Find a slot not already used
            $slot = null;
            foreach ($slotsByLot[$lotIdx][$type] as $s) {
                $key = spl_object_id($s);
                if (!in_array($key, $usedSlots)) {
                    $slot = $s;
                    $usedSlots[] = $key;
                    break;
                }
            }
            if (!$slot) continue;

            $typeVehicles = $vehicles[$type];
            $vehicle      = $typeVehicles[$i % count($typeVehicles)];
            $minsAgo      = rand(10, 200);
            $entryTime    = new \DateTimeImmutable("-{$minsAgo} minutes");

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

    private function seedBookings(ObjectManager $manager, \Faker\Generator $faker, array $lots, array $users): void
    {
        $types = ['car', 'bike'];

        for ($i = 0; $i < 5; $i++) {
            $lot        = $lots[$i % count($lots)];
            $user       = $users[$i % count($users)];
            $type       = $types[$i % count($types)];
            $hoursAhead = ($i + 1) * 3;
            $start      = new \DateTimeImmutable("+{$hoursAhead} hours");
            $end        = $start->modify('+2 hours');
            $rate       = $type === 'car' ? 50 : 20;

            $booking = new Booking();
            $booking->setUser($user)
                    ->setParkingLot($lot)
                    ->setVehicleType($type)
                    ->setVehicleNumber('DL01' . chr(65 + $i) . 'B' . str_pad((string)($i + 1000), 4, '0', STR_PAD_LEFT))
                    ->setStartTime($start)
                    ->setEndTime($end)
                    ->setExpiresAt($start->modify('+15 minutes'))
                    ->setStatus(Booking::STATUS_CONFIRMED)
                    ->setEstimatedFee((string)(2 * $rate));

            $manager->persist($booking);
        }
    }

    private function printCredentials(): void
    {
        echo "┌──────────────────────────────────────────────┐\n";
        echo "│             TEST CREDENTIALS                 │\n";
        echo "├──────────────────────────────────────────────┤\n";
        echo "│ ADMIN    admin@parking.com    Admin@123       │\n";
        echo "│ OPERATOR operator@parking.com Operator@123   │\n";
        echo "│ USER     user@parking.com     User@123       │\n";
        echo "└──────────────────────────────────────────────┘\n";
    }
}
<?php
namespace App\Command;

use App\Service\BookingService;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:handle-expired-bookings',
    description: 'Cancel expired bookings and free their reserved slots.',
)]
class HandleExpiredBookingsCommand extends Command
{
    public function __construct(private readonly BookingService $bookingService)
    {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $io->title('Processing expired bookings...');

        $count = $this->bookingService->handleExpiredBookings();

        if ($count === 0) {
            $io->success('No expired bookings found.');
        } else {
            $io->success("Expired and released {$count} booking(s).");
        }

        return Command::SUCCESS;
    }
}


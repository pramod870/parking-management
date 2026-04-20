<?php
namespace App\Service;

use App\Repository\PaymentRepository;
use App\Repository\ParkingSessionRepository;
use App\Repository\ParkingSlotRepository;

class ReportService
{
    public function __construct(
        private readonly PaymentRepository $paymentRepository,
        private readonly ParkingSessionRepository $sessionRepository,
        private readonly ParkingSlotRepository $slotRepository,
    ) {}

    public function getDashboardStats(?int $lotId = null): array
    {
        return [
            'total_revenue'         => $this->paymentRepository->getTotalRevenue($lotId),
            'today_revenue'         => $this->paymentRepository->getRevenueByDate(new \DateTimeImmutable('today'), $lotId),
            'active_sessions'       => $this->sessionRepository->countActive($lotId),
            'total_sessions_today'  => $this->sessionRepository->countByDate(new \DateTimeImmutable('today'), $lotId),
            'slot_utilization'      => $this->slotRepository->getUtilizationStats($lotId),
            'vehicle_type_breakdown'=> $this->sessionRepository->getVehicleTypeBreakdown($lotId),
        ];
    }

    public function getRevenueReport(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): array
    {
        return [
            'period'          => ['from' => $from->format('Y-m-d'), 'to' => $to->format('Y-m-d')],
            'total_revenue'   => $this->paymentRepository->getRevenueForPeriod($from, $to, $lotId),
            'daily_breakdown' => $this->paymentRepository->getDailyBreakdown($from, $to, $lotId),
            'by_vehicle_type' => $this->paymentRepository->getRevenueByVehicleType($from, $to, $lotId),
            'total_sessions'  => $this->sessionRepository->countForPeriod($from, $to, $lotId),
        ];
    }
}


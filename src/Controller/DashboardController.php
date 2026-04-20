<?php
namespace App\Controller;

use App\Service\ReportService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/dashboard', name: 'dashboard_')]
#[IsGranted('ROLE_ADMIN')]
class DashboardController extends AbstractController
{
    public function __construct(
        private readonly ReportService $reportService,
    ) {}

    /**
     * GET /api/dashboard/stats
     * Overview stats: revenue, active sessions, utilization.
     */
    #[Route('/stats', name: 'stats', methods: ['GET'])]
    public function stats(Request $request): JsonResponse
    {
        $lotId = $request->query->get('lot_id') ? (int)$request->query->get('lot_id') : null;
        return $this->json(['data' => $this->reportService->getDashboardStats($lotId)]);
    }

    /**
     * GET /api/dashboard/revenue
     * Revenue report for a date range.
     * Query: from=2025-01-01&to=2025-01-31&lot_id=1
     */
    #[Route('/revenue', name: 'revenue', methods: ['GET'])]
    public function revenue(Request $request): JsonResponse
    {
        $from  = new \DateTimeImmutable($request->query->get('from', 'first day of this month'));
        $to    = new \DateTimeImmutable($request->query->get('to', 'last day of this month'));
        $lotId = $request->query->get('lot_id') ? (int)$request->query->get('lot_id') : null;

        return $this->json([
            'data' => $this->reportService->getRevenueReport($from, $to, $lotId),
        ]);
    }
}


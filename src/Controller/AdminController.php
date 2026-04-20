<?php
namespace App\Controller;

use App\Entity\User;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/admin', name: 'admin_')]
#[IsGranted('ROLE_ADMIN')]
class AdminController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface      $em,
        private readonly UserRepository              $userRepository,
        private readonly UserPasswordHasherInterface $hasher,
    ) {}

    /**
     * GET /api/admin/users
     * List all users.
     */
    #[Route('/users', name: 'users_list', methods: ['GET'])]
    public function listUsers(): JsonResponse
    {
        $users = $this->userRepository->findAll();
        return $this->json(['data' => array_map([$this, 'serializeUser'], $users)]);
    }

    /**
     * POST /api/admin/users
     * Create operator or admin user.
     */
    #[Route('/users', name: 'users_create', methods: ['POST'])]
    public function createUser(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (empty($data['email']) || empty($data['password']) || empty($data['name'])) {
            return $this->json(['error' => 'email, password, name required'], Response::HTTP_BAD_REQUEST);
        }

        if ($this->userRepository->findOneBy(['email' => $data['email']])) {
            return $this->json(['error' => 'Email already exists'], Response::HTTP_CONFLICT);
        }

        $user = new User();
        $user->setEmail($data['email']);
        $user->setName($data['name']);
        $user->setPhone($data['phone'] ?? null);

        $role  = $data['role'] ?? 'ROLE_USER';
        $allowedRoles = ['ROLE_USER', 'ROLE_OPERATOR', 'ROLE_ADMIN'];
        $user->setRoles(in_array($role, $allowedRoles) ? [$role] : ['ROLE_USER']);
        $user->setPassword($this->hasher->hashPassword($user, $data['password']));

        $this->em->persist($user);
        $this->em->flush();

        return $this->json(['message' => 'User created', 'data' => $this->serializeUser($user)], Response::HTTP_CREATED);
    }

    /**
     * PUT /api/admin/users/{id}
     * Update user role or status.
     */
    #[Route('/users/{id}', name: 'users_update', methods: ['PUT'])]
    public function updateUser(User $user, Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (isset($data['role'])) {
            $allowedRoles = ['ROLE_USER', 'ROLE_OPERATOR', 'ROLE_ADMIN'];
            if (in_array($data['role'], $allowedRoles)) {
                $user->setRoles([$data['role']]);
            }
        }
        if (isset($data['is_active'])) $user->setIsActive((bool)$data['is_active']);
        if (isset($data['name']))      $user->setName($data['name']);

        $this->em->flush();
        return $this->json(['message' => 'User updated', 'data' => $this->serializeUser($user)]);
    }

    /**
     * DELETE /api/admin/users/{id}
     * Deactivate a user.
     */
    #[Route('/users/{id}', name: 'users_delete', methods: ['DELETE'])]
    public function deleteUser(User $user): JsonResponse
    {
        $user->setIsActive(false);
        $this->em->flush();
        return $this->json(['message' => 'User deactivated']);
    }

    private function serializeUser(User $u): array
    {
        return [
            'id'         => $u->getId(),
            'email'      => $u->getEmail(),
            'name'       => $u->getName(),
            'phone'      => $u->getPhone(),
            'roles'      => $u->getRoles(),
            'is_active'  => $u->isActive(),
            'created_at' => $u->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }
}


<?php
namespace App\Controller;

use App\Entity\User;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api/auth', name: 'auth_')]
class AuthController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface      $em,
        private readonly UserPasswordHasherInterface $hasher,
        private readonly ValidatorInterface          $validator,
        private readonly JWTTokenManagerInterface    $jwtManager,
        private readonly UserRepository              $userRepository,
    ) {}

    #[Route('/register', name: 'register', methods: ['POST'])]
    public function register(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        foreach (['email', 'password', 'name'] as $field) {
            if (empty($data[$field])) {
                return $this->json(['error' => "Field '{$field}' is required"], 400);
            }
        }

        if ($this->userRepository->findOneBy(['email' => $data['email']])) {
            return $this->json(['error' => 'Email already registered'], 409);
        }

        if (strlen($data['password']) < 6) {
            return $this->json(['error' => 'Password must be at least 6 characters'], 400);
        }

        $user = new User();
        $user->setEmail($data['email'])
             ->setName($data['name'])
             ->setPhone($data['phone'] ?? null)
             ->setRoles(['ROLE_USER'])
             ->setPassword($this->hasher->hashPassword($user, $data['password']));

        $errors = $this->validator->validate($user);
        if (count($errors) > 0) {
            $msgs = [];
            foreach ($errors as $e) {
                $msgs[$e->getPropertyPath()] = $e->getMessage();
            }
            return $this->json(['error' => 'Validation failed', 'details' => $msgs], 422);
        }

        $this->em->persist($user);
        $this->em->flush();

        $token = $this->jwtManager->create($user);

        return $this->json([
            'message' => 'Registration successful',
            'token'   => $token,
            'user'    => $this->serializeUser($user),
        ], 201);
    }
    #[Route('/login', name: 'login', methods: ['POST'])]
    public function login(): JsonResponse
    {
        // This will NEVER execute (handled by Symfony security)
        return $this->json(['message' => 'Login handled by firewall']);
    }

    #[Route('/profile', name: 'profile', methods: ['GET'])]
    public function profile(): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();
        if (!$user) {
            return $this->json(['error' => 'Not authenticated'], 401);
        }
        return $this->json(['user' => $this->serializeUser($user)]);
    }

    #[Route('/profile', name: 'profile_update', methods: ['PUT'])]
    public function updateProfile(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();
        $data = json_decode($request->getContent(), true) ?? [];

        if (!empty($data['name']))  $user->setName($data['name']);
        if (!empty($data['phone'])) $user->setPhone($data['phone']);

        if (!empty($data['password'])) {
            if (strlen($data['password']) < 6) {
                return $this->json(['error' => 'Password must be at least 6 characters'], 400);
            }
            $user->setPassword($this->hasher->hashPassword($user, $data['password']));
        }

        $this->em->flush();
        return $this->json([
            'message' => 'Profile updated',
            'user'    => $this->serializeUser($user),
        ]);
    }

    private function serializeUser(User $user): array
    {
        return [
            'id'         => $user->getId(),
            'email'      => $user->getEmail(),
            'name'       => $user->getName(),
            'phone'      => $user->getPhone(),
            'roles'      => $user->getRoles(),
            'is_active'  => $user->isActive(),
            'created_at' => $user->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }
}
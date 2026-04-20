<?php
namespace App\Controller;

use App\Entity\User;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Core\Authentication\Token\Storage\TokenStorageInterface;
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

    /**
     * POST /api/auth/register
     * Register a new user.
     */
    #[Route('/register', name: 'register', methods: ['POST'])]
    public function register(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        $required = ['email', 'password', 'name'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return $this->error("Field '{$field}' is required", Response::HTTP_BAD_REQUEST);
            }
        }

        if ($this->userRepository->findOneBy(['email' => $data['email']])) {
            return $this->error('Email already registered', Response::HTTP_CONFLICT);
        }

        if (strlen($data['password']) < 6) {
            return $this->error('Password must be at least 6 characters', Response::HTTP_BAD_REQUEST);
        }

        $user = new User();
        $user->setEmail($data['email']);
        $user->setName($data['name']);
        $user->setPhone($data['phone'] ?? null);
        $user->setRoles(['ROLE_USER']);
        $user->setPassword($this->hasher->hashPassword($user, $data['password']));

        $errors = $this->validator->validate($user);
        if (count($errors) > 0) {
            return $this->validationError($errors);
        }

        $this->em->persist($user);
        $this->em->flush();

        $token = $this->jwtManager->create($user);

        return $this->json([
            'message' => 'Registration successful',
            'token'   => $token,
            'user'    => $this->serializeUser($user),
        ], Response::HTTP_CREATED);
    }

    /**
     * POST /api/auth/login
     * Authenticate and receive JWT token.
     * (Actual authentication handled by LexikJWT - this is for docs/fallback)
     */
    #[Route('/login', name: 'login', methods: ['POST'])]
    public function login(): JsonResponse
    {
        // Handled by lexik/jwt-authentication-bundle (security.yaml firewall)
        // This endpoint exists for documentation purposes
        return $this->json(['message' => 'Use POST with email/password JSON body']);
    }

    /**
     * GET /api/auth/profile
     * Get current authenticated user profile.
     */
    #[Route('/profile', name: 'profile', methods: ['GET'])]
    public function profile(): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();
        if (!$user) {
            return $this->error('Not authenticated', Response::HTTP_UNAUTHORIZED);
        }

        return $this->json(['user' => $this->serializeUser($user)]);
    }

    /**
     * PUT /api/auth/profile
     * Update current user profile.
     */
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
                return $this->error('Password must be at least 6 characters', Response::HTTP_BAD_REQUEST);
            }
            $user->setPassword($this->hasher->hashPassword($user, $data['password']));
        }

        $this->em->flush();

        return $this->json([
            'message' => 'Profile updated',
            'user'    => $this->serializeUser($user),
        ]);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

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

    private function error(string $message, int $code = 400): JsonResponse
    {
        return $this->json(['error' => $message], $code);
    }

    private function validationError(\Symfony\Component\Validator\ConstraintViolationListInterface $errors): JsonResponse
    {
        $messages = [];
        foreach ($errors as $error) {
            $messages[$error->getPropertyPath()] = $error->getMessage();
        }
        return $this->json(['error' => 'Validation failed', 'details' => $messages], Response::HTTP_UNPROCESSABLE_ENTITY);
    }
}


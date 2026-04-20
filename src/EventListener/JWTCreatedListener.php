<?php
namespace App\EventListener;

use App\Entity\User;
use Lexik\Bundle\JWTAuthenticationBundle\Event\JWTCreatedEvent;

/**
 * Adds extra user data to JWT payload.
 */
class JWTCreatedListener
{
    public function onJWTCreated(JWTCreatedEvent $event): void
    {
        /** @var User $user */
        $user    = $event->getUser();
        $payload = $event->getData();

        // Add extra claims to token
        $payload['id']    = $user->getId();
        $payload['name']  = $user->getName();
        $payload['roles'] = $user->getRoles();

        $event->setData($payload);
    }
}


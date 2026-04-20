<?php
namespace App\Exception;

class ParkingException extends \RuntimeException
{
    const NO_SLOT_AVAILABLE       = 'NO_SLOT_AVAILABLE';
    const VEHICLE_ALREADY_PARKED  = 'VEHICLE_ALREADY_PARKED';
    const SESSION_NOT_ACTIVE      = 'SESSION_NOT_ACTIVE';
    const SESSION_NOT_FOUND       = 'SESSION_NOT_FOUND';
    const INVALID_STATUS          = 'INVALID_STATUS';
    const UNAUTHORIZED            = 'UNAUTHORIZED';

    public function __construct(string $message, private string $errorCode = 'PARKING_ERROR', int $httpCode = 400)
    {
        parent::__construct($message, $httpCode);
    }

    public function getErrorCode(): string { return $this->errorCode; }
}


# 🅿️ Parking Management System — Symfony 7 + PostgreSQL

Production-ready REST API with JWT auth, role-based access, billing, bookings, and reporting.

---

## 📁 Project Structure

```
parking-system/
├── src/
│   ├── Controller/
│   │   ├── AuthController.php          # Register, login, profile
│   │   ├── ParkingLotController.php    # CRUD for lots + slots
│   │   ├── SessionController.php       # Entry, exit, payment
│   │   ├── BookingController.php       # Pre-booking system
│   │   ├── DashboardController.php     # Reports & analytics
│   │   └── AdminController.php         # User management
│   ├── Entity/
│   │   ├── User.php
│   │   ├── ParkingLot.php
│   │   ├── ParkingSlot.php
│   │   ├── Vehicle.php
│   │   ├── ParkingSession.php
│   │   ├── Payment.php
│   │   ├── PricingRule.php
│   │   └── Booking.php
│   ├── Repository/           # Doctrine query methods
│   ├── Service/
│   │   ├── ParkingService.php   # Entry/exit logic
│   │   ├── BookingService.php   # Booking + expiry
│   │   └── ReportService.php    # Revenue + stats
│   ├── EventListener/
│   │   ├── JWTCreatedListener.php   # Add claims to JWT
│   │   └── ExceptionListener.php    # Global error handler
│   ├── Exception/
│   │   └── ParkingException.php
│   └── DataFixtures/
│       └── AppFixtures.php          # Seeder with 90 days data
├── config/
│   ├── packages/
│   │   ├── security.yaml
│   │   ├── doctrine.yaml
│   │   ├── lexik_jwt_authentication.yaml
│   │   ├── nelmio_cors.yaml
│   │   ├── monolog.yaml
│   │   ├── framework.yaml
│   │   └── rate_limiter.yaml
│   ├── services.yaml
│   └── routes.yaml
├── migrations/
│   └── schema.sql               # Complete PostgreSQL schema
├── docker/
│   ├── Dockerfile
│   └── nginx.conf
├── docker-compose.yml
├── composer.json
└── .env
```

---

## ⚡ Quick Start (Docker — Recommended)

```bash
# 1. Clone and configure
git clone <repo> parking-system && cd parking-system
cp .env .env.local

# 2. Start all services
docker-compose up -d

# 3. Wait ~15s for DB to initialize, then:
docker-compose exec app php bin/console doctrine:fixtures:load --no-interaction

# 4. Done! API is live at:
# http://localhost:8080/api
```

---

## 🖥️ Manual Setup (Local)

### Prerequisites
- PHP 8.2+
- PostgreSQL 15+
- Composer 2.x
- OpenSSL

### Step 1 — Install dependencies
```bash
composer install
```

### Step 2 — Database
```bash
# Create DB
createdb parking_db
createuser -P parking_user    # set password: parking_pass

# Run schema
psql -U parking_user -d parking_db -f migrations/schema.sql
```

### Step 3 — Configure .env
```env
DATABASE_URL="postgresql://parking_user:parking_pass@127.0.0.1:5432/parking_db?serverVersion=16"
APP_SECRET=your_32_char_secret_here
JWT_PASSPHRASE=your_jwt_passphrase
```

### Step 4 — Generate JWT keys
```bash
mkdir -p config/jwt
openssl genrsa -out config/jwt/private.pem -aes256 4096
openssl rsa -pubout -in config/jwt/private.pem -out config/jwt/public.pem
# Enter your JWT_PASSPHRASE when prompted
```

### Step 5 — Run migrations + seed
```bash
php bin/console doctrine:migrations:migrate
php bin/console doctrine:fixtures:load
```

### Step 6 — Start dev server
```bash
symfony server:start
# OR
php -S localhost:8000 -t public/
```

---

## 🔐 Authentication

All protected endpoints require: `Authorization: Bearer <JWT_TOKEN>`

### Test Credentials (after fixtures):

| Role     | Email                  | Password     |
|----------|------------------------|--------------|
| Admin    | admin@parking.com      | Admin@123    |
| Operator | operator@parking.com   | Operator@123 |
| User     | user@parking.com       | User@123     |

---

## 📡 API Endpoints

### Auth
| Method | Endpoint            | Access  | Description          |
|--------|---------------------|---------|----------------------|
| POST   | /api/auth/register  | Public  | Register new user    |
| POST   | /api/auth/login     | Public  | Get JWT token        |
| GET    | /api/auth/profile   | User+   | Get own profile      |
| PUT    | /api/auth/profile   | User+   | Update profile       |

### Parking Lots
| Method | Endpoint              | Access   | Description           |
|--------|-----------------------|----------|-----------------------|
| GET    | /api/lots             | Public   | List all active lots  |
| GET    | /api/lots/{id}        | Public   | Lot details + pricing |
| POST   | /api/lots             | Admin    | Create lot            |
| PUT    | /api/lots/{id}        | Admin    | Update lot            |
| DELETE | /api/lots/{id}        | Admin    | Delete lot            |
| GET    | /api/lots/{id}/slots  | Auth     | Lot slots with status |

### Sessions (Entry/Exit)
| Method | Endpoint                   | Access    | Description              |
|--------|----------------------------|-----------|--------------------------|
| GET    | /api/sessions              | Operator+ | List active sessions      |
| POST   | /api/sessions/entry        | Operator+ | Register vehicle entry    |
| GET    | /api/sessions/{id}         | Operator+ | Session details           |
| POST   | /api/sessions/{id}/exit    | Operator+ | Process exit + fee        |
| POST   | /api/sessions/{id}/pay     | Operator+ | Confirm payment           |

### Bookings
| Method | Endpoint           | Access | Description        |
|--------|--------------------|--------|--------------------|
| GET    | /api/bookings      | User+  | My bookings        |
| POST   | /api/bookings      | User+  | Create booking     |
| GET    | /api/bookings/{id} | User+  | Booking details    |
| DELETE | /api/bookings/{id} | User+  | Cancel booking     |

### Dashboard (Admin only)
| Method | Endpoint                   | Access | Description        |
|--------|----------------------------|--------|--------------------|
| GET    | /api/dashboard/stats       | Admin  | Live stats         |
| GET    | /api/dashboard/revenue     | Admin  | Revenue report     |

### Admin
| Method | Endpoint              | Access | Description      |
|--------|-----------------------|--------|------------------|
| GET    | /api/admin/users      | Admin  | List users       |
| POST   | /api/admin/users      | Admin  | Create user      |
| PUT    | /api/admin/users/{id} | Admin  | Update role      |
| DELETE | /api/admin/users/{id} | Admin  | Deactivate user  |

---

## 📥 Sample Requests & Responses

### 1. Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"operator@parking.com","password":"Operator@123"}'
```
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "user": { "id": 2, "email": "operator@parking.com", "roles": ["ROLE_OPERATOR"] }
}
```

### 2. Vehicle Entry
```bash
curl -X POST http://localhost:8080/api/sessions/entry \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"lot_id": 1, "vehicle_number": "DL01AB1234", "vehicle_type": "car"}'
```
```json
{
  "message": "Vehicle entry registered successfully",
  "data": {
    "id": 42,
    "status": "active",
    "vehicle_number": "DL01AB1234",
    "vehicle_type": "car",
    "parking_lot": "Connaught Place Parking",
    "slot_number": "C001",
    "floor": 1,
    "entry_time": "2026-04-17 10:30:00",
    "total_fee": null,
    "payment_status": null
  }
}
```

### 3. Vehicle Exit
```bash
curl -X POST http://localhost:8080/api/sessions/42/exit \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"payment_method": "upi"}'
```
```json
{
  "message": "Vehicle exit processed successfully",
  "data": {
    "session_id": 42,
    "vehicle_number": "DL01AB1234",
    "entry_time": "2026-04-17 10:30:00",
    "exit_time": "2026-04-17 12:45:00",
    "duration_minutes": 135,
    "duration_readable": "2h 15m",
    "total_fee": "150.00",
    "payment_id": 38,
    "payment_status": "pending",
    "payment_method": "upi"
  }
}
```

### 4. Create Booking
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "lot_id": 1,
    "vehicle_type": "car",
    "vehicle_number": "DL01AB9999",
    "start_time": "2026-04-18 09:00:00",
    "end_time": "2026-04-18 11:00:00"
  }'
```
```json
{
  "message": "Booking confirmed",
  "data": {
    "id": 5,
    "booking_reference": "BKAF3C1E2D",
    "status": "confirmed",
    "parking_lot": "Connaught Place Parking",
    "slot_number": "C003",
    "start_time": "2026-04-18 09:00:00",
    "end_time": "2026-04-18 11:00:00",
    "estimated_fee": "100.00",
    "expires_at": "2026-04-18 09:15:00"
  }
}
```

### 5. Dashboard Stats
```bash
curl http://localhost:8080/api/dashboard/stats \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```
```json
{
  "data": {
    "total_revenue": "185450.00",
    "today_revenue": "3200.00",
    "active_sessions": 15,
    "total_sessions_today": 47,
    "slot_utilization": [
      {"vehicleType": "car",   "status": "occupied",  "count": 12},
      {"vehicleType": "car",   "status": "available", "count": 138},
      {"vehicleType": "bike",  "status": "occupied",  "count": 3},
      {"vehicleType": "truck", "status": "available", "count": 25}
    ],
    "vehicle_type_breakdown": [
      {"vehicleType": "car",  "total": 12},
      {"vehicleType": "bike", "total": 3}
    ]
  }
}
```

---

## 🏗️ Architecture

### Design Patterns
- **Repository Pattern** — All DB queries isolated from business logic
- **Service Layer** — ParkingService, BookingService handle domain logic
- **Event Listeners** — JWT enrichment, global exception handling
- **DI Container** — All dependencies injected via constructor

### SOLID Applied
- **SRP** — Each class has one clear job
- **OCP** — Add new vehicle types by extending enums only
- **DIP** — Services depend on repository interfaces, not implementations
- **ISP** — Controller methods handle exactly one concern

### Role Hierarchy
```
ROLE_ADMIN
  └── ROLE_OPERATOR
        └── ROLE_USER
```

---

## 🚀 Production Deployment

```bash
# 1. Set production env
APP_ENV=prod
APP_DEBUG=false

# 2. Optimize
composer install --no-dev --optimize-autoloader
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

# 3. Using Docker
docker-compose -f docker-compose.yml up -d --build

# 4. Run migrations
docker-compose exec app php bin/console doctrine:migrations:migrate --no-interaction
```

---

## 🔧 Useful Commands

```bash
# Clear cache
php bin/console cache:clear

# Load fixtures
php bin/console doctrine:fixtures:load --no-interaction

# Create migration from entities
php bin/console make:migration

# Run migrations
php bin/console doctrine:migrations:migrate

# Check routes
php bin/console debug:router

# Validate doctrine schema
php bin/console doctrine:schema:validate

# Handle expired bookings (run as cron)
php bin/console app:handle-expired-bookings
```

---

## 📦 Tech Stack

| Layer        | Technology                              |
|--------------|-----------------------------------------|
| Framework    | Symfony 7.1                             |
| Database     | PostgreSQL 16 (Doctrine ORM)            |
| Auth         | JWT (lexik/jwt-authentication-bundle)   |
| Serializer   | Symfony Serializer                      |
| Logging      | Monolog (structured JSON in prod)       |
| Rate Limit   | Symfony Rate Limiter                    |
| CORS         | nelmio/cors-bundle                      |
| Fixtures     | doctrine/doctrine-fixtures-bundle       |
| Containers   | Docker + Docker Compose                 |
| Web Server   | Nginx + PHP-FPM                         |
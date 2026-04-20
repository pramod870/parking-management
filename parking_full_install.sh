#!/bin/bash
# ================================================================
# PARKING SYSTEM - COMPLETE FILE INSTALLER
# Run from your project root:
#   cd ~/Documents/Pramod\ Resume/parking-system
#   bash parking_full_install.sh
# ================================================================

PROJECT="$(pwd)"
echo "Installing all files into: $PROJECT"

# Create directories
mkdir -p "$PROJECT/src/Entity"
mkdir -p "$PROJECT/src/Controller"
mkdir -p "$PROJECT/src/Repository"
mkdir -p "$PROJECT/src/Service"
mkdir -p "$PROJECT/src/EventListener"
mkdir -p "$PROJECT/src/Exception"
mkdir -p "$PROJECT/src/Command"
mkdir -p "$PROJECT/src/DataFixtures"
mkdir -p "$PROJECT/config/packages"
mkdir -p "$PROJECT/migrations"
mkdir -p "$PROJECT/public"

# --- .env ---
mkdir -p "$PROJECT/"
cat > "$PROJECT/.env" << 'FILEEOF__ENV'
###> symfony/framework-bundle ###
APP_ENV=dev
APP_SECRET=your_secret_key_change_in_production_32chars
###< symfony/framework-bundle ###

###> doctrine/doctrine-bundle ###
DATABASE_URL="postgresql://parking_user:parking_pass@127.0.0.1:5432/parking_db?serverVersion=16&charset=utf8"
###< doctrine/doctrine-bundle ###

###> lexik/jwt-authentication-bundle ###
JWT_SECRET_KEY=%kernel.project_dir%/config/jwt/private.pem
JWT_PUBLIC_KEY=%kernel.project_dir%/config/jwt/public.pem
JWT_PASSPHRASE=your_jwt_passphrase_change_in_production
JWT_TTL=3600
###< lexik/jwt-authentication-bundle ###

###> Rate Limiting ###
RATE_LIMIT_LOGIN=5
RATE_LIMIT_API=100
###< Rate Limiting ###

###> Parking Config ###
PARKING_DEFAULT_HOURLY_RATE=50
PARKING_DEFAULT_MINUTE_RATE=1
PARKING_BOOKING_EXPIRY_MINUTES=15
###< Parking Config ###

###> Redis (optional) ###
REDIS_URL=redis://localhost:6379
###< Redis ###

FILEEOF__ENV
echo "✅ .env"

# --- composer.json ---
mkdir -p "$PROJECT/"
cat > "$PROJECT/composer.json" << 'FILEEOF_COMPOSER_JSON'
{
    "name": "parking/management-system",
    "description": "Production-ready Parking Management System built with Symfony 7",
    "type": "project",
    "license": "MIT",
    "require": {
        "php": ">=8.2",
        "ext-ctype": "*",
        "ext-iconv": "*",
        "ext-pdo": "*",
        "doctrine/annotations": "^2.0",
        "doctrine/doctrine-bundle": "^2.11",
        "doctrine/doctrine-migrations-bundle": "^3.3",
        "doctrine/orm": "^3.1",
        "lexik/jwt-authentication-bundle": "^2.20",
        "nelmio/cors-bundle": "^2.4",
        "symfony/console": "7.1.*",
        "symfony/doctrine-messenger": "7.1.*",
        "symfony/dotenv": "7.1.*",
        "symfony/expression-language": "7.1.*",
        "symfony/flex": "^2",
        "symfony/framework-bundle": "7.1.*",
        "symfony/monolog-bundle": "^3.10",
        "symfony/password-hasher": "7.1.*",
        "symfony/rate-limiter": "7.1.*",
        "symfony/runtime": "7.1.*",
        "symfony/security-bundle": "7.1.*",
        "symfony/serializer": "7.1.*",
        "symfony/uid": "7.1.*",
        "symfony/validator": "7.1.*",
        "symfony/yaml": "7.1.*"
    },
    "require-dev": {
        "doctrine/doctrine-fixtures-bundle": "^3.6",
        "fakerphp/faker": "^1.23",
        "phpunit/phpunit": "^11.0",
        "symfony/browser-kit": "7.1.*",
        "symfony/css-selector": "7.1.*",
        "symfony/maker-bundle": "^1.58",
        "symfony/phpunit-bridge": "^7.1"
    },
    "config": {
        "allow-plugins": {
            "php-http/discovery": true,
            "symfony/flex": true,
            "symfony/runtime": true
        },
        "sort-packages": true
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    },
    "replace": {
        "symfony/polyfill-ctype": "*",
        "symfony/polyfill-iconv": "*",
        "symfony/polyfill-php72": "*",
        "symfony/polyfill-php73": "*",
        "symfony/polyfill-php74": "*",
        "symfony/polyfill-php80": "*",
        "symfony/polyfill-php81": "*"
    },
    "scripts": {
        "auto-scripts": {
            "cache:clear": "symfony-cmd",
            "assets:install %PUBLIC_DIR%": "symfony-cmd"
        },
        "post-install-cmd": [
            "@auto-scripts"
        ],
        "post-update-cmd": [
            "@auto-scripts"
        ]
    },
    "conflict": {
        "symfony/symfony": "*"
    },
    "extra": {
        "symfony": {
            "allow-contrib": false,
            "require": "7.1.*"
        }
    }
}

FILEEOF_COMPOSER_JSON
echo "✅ composer.json"

# --- config/packages/doctrine.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/doctrine.yaml" << 'FILEEOF_CONFIG_PACKAGES_DOCTRINE_YAML'
doctrine:
    dbal:
        url: '%env(resolve:DATABASE_URL)%'
        profiling_collect_backtrace: '%kernel.debug%'

    orm:
        auto_generate_proxy_classes: true
        enable_lazy_ghost_objects: true
        naming_strategy: doctrine.orm.naming_strategy.underscore_number_aware
        auto_mapping: true
        mappings:
            App:
                type: attribute
                is_bundle: false
                dir: '%kernel.project_dir%/src/Entity'
                prefix: 'App\Entity'
                alias: App

when@test:
    doctrine:
        dbal:
            dbname_suffix: '_test%env(default::TEST_TOKEN)%'

when@prod:
    doctrine:
        orm:
            auto_generate_proxy_classes: false
            proxy_dir: '%kernel.build_dir%/doctrine/orm/Proxies'
            query_cache_driver:
                type: pool
                pool: doctrine.system_cache_pool
            result_cache_driver:
                type: pool
                pool: doctrine.result_cache_pool

    framework:
        cache:
            pools:
                doctrine.result_cache_pool:
                    adapter: cache.app
                doctrine.system_cache_pool:
                    adapter: cache.system

FILEEOF_CONFIG_PACKAGES_DOCTRINE_YAML
echo "✅ config/packages/doctrine.yaml"

# --- config/packages/framework.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/framework.yaml" << 'FILEEOF_CONFIG_PACKAGES_FRAMEWORK_YAML'
framework:
    secret: '%env(APP_SECRET)%'
    http_method_override: true
    handle_all_throwables: true

    session:
        handler_id: null
        cookie_secure: auto
        cookie_samesite: lax
        storage_factory_id: session.storage.factory.native

    php_errors:
        log: true

    serializer:
        enabled: true
        enable_attributes: true

    validation:
        email_validation_mode: html5

    router:
        utf8: true
        strict_requirements: null

when@test:
    framework:
        test: true
        session:
            storage_factory_id: session.storage.factory.mock_file

FILEEOF_CONFIG_PACKAGES_FRAMEWORK_YAML
echo "✅ config/packages/framework.yaml"

# --- config/packages/lexik_jwt_authentication.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/lexik_jwt_authentication.yaml" << 'FILEEOF_CONFIG_PACKAGES_LEXIK_JWT_AUTHENTICATION_YAML'
lexik_jwt_authentication:
    secret_key: '%env(resolve:JWT_SECRET_KEY)%'
    public_key: '%env(resolve:JWT_PUBLIC_KEY)%'
    pass_phrase: '%env(JWT_PASSPHRASE)%'
    token_ttl: '%env(int:JWT_TTL)%'
    user_id_claim: email

FILEEOF_CONFIG_PACKAGES_LEXIK_JWT_AUTHENTICATION_YAML
echo "✅ config/packages/lexik_jwt_authentication.yaml"

# --- config/packages/monolog.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/monolog.yaml" << 'FILEEOF_CONFIG_PACKAGES_MONOLOG_YAML'
monolog:
    channels:
        - parking
        - security

when@dev:
    monolog:
        handlers:
            main:
                type: stream
                path: "%kernel.logs_dir%/%kernel.environment%.log"
                level: debug
                channels: ["!event"]
            console:
                type: console
                process_psr_3_messages: false
                channels: ["!event", "!doctrine", "!console"]

when@prod:
    monolog:
        handlers:
            main:
                type: fingers_crossed
                action_level: error
                handler: nested
                excluded_http_codes: [404, 405]
                buffer_size: 50
            nested:
                type: stream
                path: php://stderr
                level: debug
                formatter: monolog.formatter.json
            parking:
                type: stream
                path: "%kernel.logs_dir%/parking.log"
                level: info
                channels: [parking]
            security_log:
                type: stream
                path: "%kernel.logs_dir%/security.log"
                level: info
                channels: [security]

FILEEOF_CONFIG_PACKAGES_MONOLOG_YAML
echo "✅ config/packages/monolog.yaml"

# --- config/packages/nelmio_cors.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/nelmio_cors.yaml" << 'FILEEOF_CONFIG_PACKAGES_NELMIO_CORS_YAML'
nelmio_cors:
    defaults:
        origin_regex: true
        allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
        allow_methods: ['GET', 'OPTIONS', 'POST', 'PUT', 'PATCH', 'DELETE']
        allow_headers: ['Content-Type', 'Authorization']
        expose_headers: ['Link']
        max_age: 3600
    paths:
        '^/api':
            allow_origin: ['*']
            allow_headers: ['*']
            allow_methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH']
            max_age: 3600

FILEEOF_CONFIG_PACKAGES_NELMIO_CORS_YAML
echo "✅ config/packages/nelmio_cors.yaml"

# --- config/packages/rate_limiter.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/rate_limiter.yaml" << 'FILEEOF_CONFIG_PACKAGES_RATE_LIMITER_YAML'
framework:
    rate_limiter:
        login_limiter:
            policy: fixed_window
            limit: 5
            interval: '1 minute'

        api_limiter:
            policy: sliding_window
            limit: 100
            interval: '1 minute'

FILEEOF_CONFIG_PACKAGES_RATE_LIMITER_YAML
echo "✅ config/packages/rate_limiter.yaml"

# --- config/packages/security.yaml ---
mkdir -p "$PROJECT/config/packages"
cat > "$PROJECT/config/packages/security.yaml" << 'FILEEOF_CONFIG_PACKAGES_SECURITY_YAML'
security:
    password_hashers:
        App\Entity\User:
            algorithm: bcrypt
            cost: 12

    providers:
        app_user_provider:
            entity:
                class: App\Entity\User
                property: email

    role_hierarchy:
        ROLE_OPERATOR: ROLE_USER
        ROLE_ADMIN:    [ROLE_OPERATOR, ROLE_USER]

    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false

        login:
            pattern:  ^/api/auth/login
            stateless: true
            json_login:
                check_path:               /api/auth/login
                success_handler:          lexik_jwt_authentication.handler.authentication_success
                failure_handler:          lexik_jwt_authentication.handler.authentication_failure
                username_path:            email
                password_path:            password

        api:
            pattern:   ^/api
            stateless: true
            jwt: ~

    access_control:
        # Public endpoints
        - { path: ^/api/auth/register, roles: PUBLIC_ACCESS }
        - { path: ^/api/auth/login,    roles: PUBLIC_ACCESS }
        - { path: ^/api/lots$,         roles: PUBLIC_ACCESS, methods: [GET] }
        - { path: ^/api/lots/\d+$,     roles: PUBLIC_ACCESS, methods: [GET] }

        # Authenticated endpoints
        - { path: ^/api/auth/profile,  roles: ROLE_USER }
        - { path: ^/api/bookings,      roles: ROLE_USER }
        - { path: ^/api/sessions,      roles: ROLE_OPERATOR }
        - { path: ^/api/dashboard,     roles: ROLE_ADMIN }
        - { path: ^/api/admin,         roles: ROLE_ADMIN }
        - { path: ^/api,               roles: IS_AUTHENTICATED_FULLY }

when@test:
    security:
        password_hashers:
            Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface:
                algorithm: auto
                cost: 4

FILEEOF_CONFIG_PACKAGES_SECURITY_YAML
echo "✅ config/packages/security.yaml"

# --- config/routes.yaml ---
mkdir -p "$PROJECT/config"
cat > "$PROJECT/config/routes.yaml" << 'FILEEOF_CONFIG_ROUTES_YAML'
controllers:
    resource:
        path: ../src/Controller/
        namespace: App\Controller
    type: attribute

FILEEOF_CONFIG_ROUTES_YAML
echo "✅ config/routes.yaml"

# --- config/services.yaml ---
mkdir -p "$PROJECT/config"
cat > "$PROJECT/config/services.yaml" << 'FILEEOF_CONFIG_SERVICES_YAML'
parameters:
    parking.booking_expiry_minutes: '%env(int:PARKING_BOOKING_EXPIRY_MINUTES)%'
    parking.default_hourly_rate:    '%env(float:PARKING_DEFAULT_HOURLY_RATE)%'

services:
    # Default configuration for services in *this* file
    _defaults:
        autowire: true
        autoconfigure: true
        public: false

    # Makes classes in src/ available as services
    App\:
        resource: '../src/'
        exclude:
            - '../src/DependencyInjection/'
            - '../src/Entity/'
            - '../src/Kernel.php'

    # Inject booking expiry minutes into BookingService
    App\Service\BookingService:
        arguments:
            $expiryMinutes: '%parking.booking_expiry_minutes%'

    # Named logger channels
    App\Service\ParkingService:
        arguments:
            $logger: '@monolog.logger.parking'

    App\EventListener\JWTCreatedListener:
        tags:
            - { name: kernel.event_listener, event: lexik_jwt_authentication.on_jwt_created, method: onJWTCreated }

FILEEOF_CONFIG_SERVICES_YAML
echo "✅ config/services.yaml"

# --- docker-compose.yml ---
mkdir -p "$PROJECT/"
cat > "$PROJECT/docker-compose.yml" << 'FILEEOF_DOCKER_COMPOSE_YML'
version: '3.9'

services:

  # ── PHP-FPM App ──────────────────────────────────────────
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: parking_app
    restart: unless-stopped
    environment:
      APP_ENV: prod
      APP_SECRET: ${APP_SECRET}
      DATABASE_URL: postgresql://parking_user:parking_pass@postgres:5432/parking_db?serverVersion=16
      JWT_SECRET_KEY: /var/www/config/jwt/private.pem
      JWT_PUBLIC_KEY:  /var/www/config/jwt/public.pem
      JWT_PASSPHRASE:  ${JWT_PASSPHRASE}
      REDIS_URL: redis://redis:6379
    volumes:
      - .:/var/www
      - ./docker/php.ini:/usr/local/etc/php/conf.d/custom.ini
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - parking_net

  # ── Nginx ────────────────────────────────────────────────
  nginx:
    image: nginx:1.25-alpine
    container_name: parking_nginx
    restart: unless-stopped
    ports:
      - "8080:80"
      - "443:443"
    volumes:
      - .:/var/www
      - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app
    networks:
      - parking_net

  # ── PostgreSQL ───────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: parking_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB:       parking_db
      POSTGRES_USER:     parking_user
      POSTGRES_PASSWORD: parking_pass
      PGDATA:            /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations/schema.sql:/docker-entrypoint-initdb.d/01_schema.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U parking_user -d parking_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - parking_net

  # ── Redis (caching) ──────────────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: parking_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - parking_net

  # ── pgAdmin (optional dev tool) ──────────────────────────
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: parking_pgadmin
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL:    admin@parking.com
      PGADMIN_DEFAULT_PASSWORD: admin123
    ports:
      - "5050:80"
    depends_on:
      - postgres
    networks:
      - parking_net
    profiles:
      - dev

volumes:
  postgres_data:
  redis_data:

networks:
  parking_net:
    driver: bridge

FILEEOF_DOCKER_COMPOSE_YML
echo "✅ docker-compose.yml"

# --- migrations/schema.sql ---
mkdir -p "$PROJECT/migrations"
cat > "$PROJECT/migrations/schema.sql" << 'FILEEOF_MIGRATIONS_SCHEMA_SQL'
-- ============================================================
-- Parking Management System — PostgreSQL Schema
-- Run: psql -U parking_user -d parking_db -f schema.sql
-- ============================================================

-- ── Extensions ───────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- for fuzzy search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- for composite indexes

-- ── ENUMS ────────────────────────────────────────────────────
DO $$ BEGIN
    CREATE TYPE vehicle_type_enum AS ENUM ('car', 'bike', 'truck');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE slot_status_enum AS ENUM ('available', 'occupied', 'reserved', 'maintenance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE session_status_enum AS ENUM ('active', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE booking_status_enum AS ENUM ('pending', 'confirmed', 'active', 'completed', 'cancelled', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE rate_type_enum AS ENUM ('hourly', 'per_minute', 'flat');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── USERS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id         SERIAL PRIMARY KEY,
    email      VARCHAR(180) NOT NULL,
    name       VARCHAR(100) NOT NULL,
    phone      VARCHAR(20),
    roles      JSON         NOT NULL DEFAULT '["ROLE_USER"]',
    password   VARCHAR(255) NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_email UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_user_email    ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_active   ON users(is_active);

-- ── PARKING LOTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parking_lots (
    id               SERIAL PRIMARY KEY,
    name             VARCHAR(150) NOT NULL,
    location         TEXT         NOT NULL,
    latitude         DECIMAL(10,8),
    longitude        DECIMAL(11,8),
    total_slots      INT          NOT NULL CHECK (total_slots > 0),
    available_slots  INT          NOT NULL DEFAULT 0,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lot_active    ON parking_lots(is_active);
CREATE INDEX IF NOT EXISTS idx_lot_location  ON parking_lots USING GIN (location gin_trgm_ops);

-- ── PARKING SLOTS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parking_slots (
    id              SERIAL PRIMARY KEY,
    parking_lot_id  INT          NOT NULL REFERENCES parking_lots(id) ON DELETE CASCADE,
    slot_number     VARCHAR(20)  NOT NULL,
    vehicle_type    VARCHAR(20)  NOT NULL DEFAULT 'car',
    status          VARCHAR(20)  NOT NULL DEFAULT 'available',
    floor           INT          NOT NULL DEFAULT 1,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_slot_lot_number UNIQUE (parking_lot_id, slot_number)
);

CREATE INDEX IF NOT EXISTS idx_slot_status       ON parking_slots(status);
CREATE INDEX IF NOT EXISTS idx_slot_vehicle_type ON parking_slots(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_slot_lot_status   ON parking_slots(parking_lot_id, status);
CREATE INDEX IF NOT EXISTS idx_slot_lot_type_status ON parking_slots(parking_lot_id, vehicle_type, status);

-- ── VEHICLES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vehicles (
    id             SERIAL PRIMARY KEY,
    owner_id       INT REFERENCES users(id) ON DELETE SET NULL,
    vehicle_number VARCHAR(30)  NOT NULL,
    vehicle_type   VARCHAR(20)  NOT NULL DEFAULT 'car',
    make           VARCHAR(100),
    model          VARCHAR(100),
    color          VARCHAR(20),
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_vehicle_number UNIQUE (vehicle_number)
);

CREATE INDEX IF NOT EXISTS idx_vehicle_number ON vehicles(vehicle_number);
CREATE INDEX IF NOT EXISTS idx_vehicle_type   ON vehicles(vehicle_type);

-- ── PRICING RULES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pricing_rules (
    id              SERIAL PRIMARY KEY,
    parking_lot_id  INT           NOT NULL REFERENCES parking_lots(id) ON DELETE CASCADE,
    vehicle_type    VARCHAR(20)   NOT NULL,
    rate_type       VARCHAR(20)   NOT NULL DEFAULT 'hourly',
    rate            DECIMAL(10,2) NOT NULL CHECK (rate >= 0),
    minimum_charge  DECIMAL(10,2),
    maximum_charge  DECIMAL(10,2),
    free_minutes    INT DEFAULT 0,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pricing_lot_vehicle UNIQUE (parking_lot_id, vehicle_type)
);

CREATE INDEX IF NOT EXISTS idx_pricing_lot_type ON pricing_rules(parking_lot_id, vehicle_type, is_active);

-- ── PARKING SESSIONS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parking_sessions (
    id               SERIAL PRIMARY KEY,
    parking_lot_id   INT           NOT NULL REFERENCES parking_lots(id),
    slot_id          INT           NOT NULL REFERENCES parking_slots(id),
    vehicle_id       INT           NOT NULL REFERENCES vehicles(id),
    user_id          INT           REFERENCES users(id) ON DELETE SET NULL,
    entry_time       TIMESTAMP     NOT NULL DEFAULT NOW(),
    exit_time        TIMESTAMP,
    duration_minutes INT,
    total_fee        DECIMAL(10,2),
    status           VARCHAR(20)   NOT NULL DEFAULT 'active',
    created_at       TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_session_status      ON parking_sessions(status);
CREATE INDEX IF NOT EXISTS idx_session_entry       ON parking_sessions(entry_time DESC);
CREATE INDEX IF NOT EXISTS idx_session_lot_status  ON parking_sessions(parking_lot_id, status);
CREATE INDEX IF NOT EXISTS idx_session_vehicle     ON parking_sessions(vehicle_id);

-- ── PAYMENTS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
    id              SERIAL PRIMARY KEY,
    session_id      INT           NOT NULL UNIQUE REFERENCES parking_sessions(id),
    amount          DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    status          VARCHAR(20)   NOT NULL DEFAULT 'pending',
    payment_method  VARCHAR(20),
    transaction_id  VARCHAR(100),
    metadata        JSONB,
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    paid_at         TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_status  ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payment_paid_at ON payments(paid_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_method  ON payments(payment_method);

-- ── BOOKINGS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
    id                 SERIAL PRIMARY KEY,
    user_id            INT          NOT NULL REFERENCES users(id),
    parking_lot_id     INT          NOT NULL REFERENCES parking_lots(id),
    slot_id            INT          REFERENCES parking_slots(id),
    vehicle_type       VARCHAR(20)  NOT NULL,
    vehicle_number     VARCHAR(30),
    start_time         TIMESTAMP    NOT NULL,
    end_time           TIMESTAMP    NOT NULL,
    expires_at         TIMESTAMP,
    status             VARCHAR(20)  NOT NULL DEFAULT 'pending',
    booking_reference  VARCHAR(50)  NOT NULL,
    estimated_fee      DECIMAL(10,2),
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_booking_reference UNIQUE (booking_reference),
    CONSTRAINT chk_booking_times    CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_booking_status     ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_booking_time       ON bookings(start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_booking_user       ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_booking_lot        ON bookings(parking_lot_id);
CREATE INDEX IF NOT EXISTS idx_booking_expires    ON bookings(expires_at) WHERE status = 'confirmed';

-- ── AUDIT LOG (bonus) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
    id          SERIAL PRIMARY KEY,
    user_id     INT REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entity      VARCHAR(100),
    entity_id   INT,
    payload     JSONB,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_user      ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action    ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_created   ON audit_logs(created_at DESC);

-- ── TRIGGERS: auto-update updated_at ────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    CREATE TRIGGER trg_users_updated     BEFORE UPDATE ON users          FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    CREATE TRIGGER trg_lots_updated      BEFORE UPDATE ON parking_lots   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    CREATE TRIGGER trg_slots_updated     BEFORE UPDATE ON parking_slots  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── VIEWS ────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_active_sessions AS
    SELECT
        ps.id,
        pl.name                             AS lot_name,
        s.slot_number,
        s.floor,
        v.vehicle_number,
        v.vehicle_type,
        u.name                              AS user_name,
        ps.entry_time,
        EXTRACT(EPOCH FROM (NOW() - ps.entry_time))/60 AS duration_minutes,
        ps.status
    FROM parking_sessions ps
    JOIN parking_lots pl   ON pl.id = ps.parking_lot_id
    JOIN parking_slots s   ON s.id  = ps.slot_id
    JOIN vehicles v        ON v.id  = ps.vehicle_id
    LEFT JOIN users u      ON u.id  = ps.user_id
    WHERE ps.status = 'active';

CREATE OR REPLACE VIEW v_revenue_summary AS
    SELECT
        pl.name                         AS lot_name,
        DATE(p.paid_at)                 AS date,
        COUNT(p.id)                     AS transactions,
        COALESCE(SUM(p.amount), 0)      AS total_revenue,
        COALESCE(AVG(p.amount), 0)      AS avg_fee
    FROM payments p
    JOIN parking_sessions ps ON ps.id = p.session_id
    JOIN parking_lots pl     ON pl.id = ps.parking_lot_id
    WHERE p.status = 'paid'
    GROUP BY pl.name, DATE(p.paid_at)
    ORDER BY date DESC;

FILEEOF_MIGRATIONS_SCHEMA_SQL
echo "✅ migrations/schema.sql"

# --- phpunit.xml ---
mkdir -p "$PROJECT/"
cat > "$PROJECT/phpunit.xml" << 'FILEEOF_PHPUNIT_XML'
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         colors="true"
         bootstrap="vendor/autoload.php"
>
    <php>
        <ini name="display_errors" value="1" />
        <ini name="error_reporting" value="-1" />
        <server name="APP_ENV" value="test" force="true" />
        <server name="SHELL_VERBOSITY" value="-1" />
        <server name="SYMFONY_PHPUNIT_REMOVE" value="" />
        <server name="SYMFONY_PHPUNIT_VERSION" value="11.0" />
        <env name="DATABASE_URL" value="postgresql://parking_user:parking_pass@127.0.0.1:5432/parking_db_test?serverVersion=16" />
        <env name="JWT_PASSPHRASE" value="test_passphrase" />
    </php>

    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>

    <source>
        <include>
            <directory suffix=".php">src</directory>
        </include>
        <exclude>
            <directory>src/DataFixtures</directory>
        </exclude>
    </source>

    <coverage>
        <report>
            <html outputDirectory="var/coverage"/>
            <text outputFile="php://stdout" showOnlySummary="true"/>
        </report>
    </coverage>
</phpunit>

FILEEOF_PHPUNIT_XML
echo "✅ phpunit.xml"

# --- public/index.php ---
mkdir -p "$PROJECT/public"
cat > "$PROJECT/public/index.php" << 'FILEEOF_PUBLIC_INDEX_PHP'
<?php

use App\Kernel;

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context) {
    return new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);
};

FILEEOF_PUBLIC_INDEX_PHP
echo "✅ public/index.php"

# --- src/Command/HandleExpiredBookingsCommand.php ---
mkdir -p "$PROJECT/src/Command"
cat > "$PROJECT/src/Command/HandleExpiredBookingsCommand.php" << 'FILEEOF_SRC_COMMAND_HANDLEEXPIREDBOOKINGSCOMMAND_PHP'
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

FILEEOF_SRC_COMMAND_HANDLEEXPIREDBOOKINGSCOMMAND_PHP
echo "✅ src/Command/HandleExpiredBookingsCommand.php"

# --- src/Controller/AdminController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/AdminController.php" << 'FILEEOF_SRC_CONTROLLER_ADMINCONTROLLER_PHP'
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

FILEEOF_SRC_CONTROLLER_ADMINCONTROLLER_PHP
echo "✅ src/Controller/AdminController.php"

# --- src/Controller/AuthController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/AuthController.php" << 'FILEEOF_SRC_CONTROLLER_AUTHCONTROLLER_PHP'
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

FILEEOF_SRC_CONTROLLER_AUTHCONTROLLER_PHP
echo "✅ src/Controller/AuthController.php"

# --- src/Controller/BookingController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/BookingController.php" << 'FILEEOF_SRC_CONTROLLER_BOOKINGCONTROLLER_PHP'
<?php
namespace App\Controller;

use App\Entity\Booking;
use App\Entity\ParkingLot;
use App\Entity\User;
use App\Exception\ParkingException;
use App\Repository\BookingRepository;
use App\Repository\ParkingLotRepository;
use App\Service\BookingService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/bookings', name: 'booking_')]
#[IsGranted('ROLE_USER')]
class BookingController extends AbstractController
{
    public function __construct(
        private readonly BookingService      $bookingService,
        private readonly BookingRepository   $bookingRepository,
        private readonly ParkingLotRepository $lotRepository,
    ) {}

    /**
     * POST /api/bookings
     * Create a pre-booking.
     */
    #[Route('', name: 'create', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];
        /** @var User $user */
        $user = $this->getUser();

        $required = ['lot_id', 'vehicle_type', 'start_time', 'end_time'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return $this->json(['error' => "Field '{$field}' is required"], Response::HTTP_BAD_REQUEST);
            }
        }

        $lot = $this->lotRepository->find($data['lot_id']);
        if (!$lot) {
            return $this->json(['error' => 'Parking lot not found'], Response::HTTP_NOT_FOUND);
        }

        try {
            $startTime = new \DateTimeImmutable($data['start_time']);
            $endTime   = new \DateTimeImmutable($data['end_time']);
        } catch (\Exception $e) {
            return $this->json(['error' => 'Invalid date format. Use: Y-m-d H:i:s'], Response::HTTP_BAD_REQUEST);
        }

        if ($startTime >= $endTime) {
            return $this->json(['error' => 'start_time must be before end_time'], Response::HTTP_BAD_REQUEST);
        }

        if ($startTime < new \DateTimeImmutable()) {
            return $this->json(['error' => 'start_time must be in the future'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $booking = $this->bookingService->createBooking(
                $user, $lot, $data['vehicle_type'], $startTime, $endTime,
                $data['vehicle_number'] ?? null
            );

            return $this->json([
                'message' => 'Booking confirmed',
                'data'    => $this->serializeBooking($booking),
            ], Response::HTTP_CREATED);

        } catch (ParkingException $e) {
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], Response::HTTP_UNPROCESSABLE_ENTITY);
        }
    }

    /**
     * GET /api/bookings
     * List current user's bookings.
     */
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(Request $request): JsonResponse
    {
        /** @var User $user */
        $user    = $this->getUser();
        $page    = max(1, (int)$request->query->get('page', 1));
        $bookings = $this->bookingRepository->findByUserPaginated($user->getId(), $page);

        return $this->json([
            'data' => array_map([$this, 'serializeBooking'], $bookings),
            'page' => $page,
        ]);
    }

    /**
     * GET /api/bookings/{id}
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(Booking $booking): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        if ($booking->getUser()->getId() !== $user->getId() && !$this->isGranted('ROLE_ADMIN')) {
            return $this->json(['error' => 'Access denied'], Response::HTTP_FORBIDDEN);
        }

        return $this->json(['data' => $this->serializeBooking($booking)]);
    }

    /**
     * DELETE /api/bookings/{id}
     * Cancel a booking.
     */
    #[Route('/{id}', name: 'cancel', methods: ['DELETE'])]
    public function cancel(Booking $booking): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        try {
            $this->bookingService->cancelBooking($booking, $user);
            return $this->json(['message' => 'Booking cancelled successfully']);
        } catch (ParkingException $e) {
            $code = $e->getCode() === 403 ? Response::HTTP_FORBIDDEN : Response::HTTP_BAD_REQUEST;
            return $this->json(['error' => $e->getMessage()], $code);
        }
    }

    private function serializeBooking(Booking $b): array
    {
        return [
            'id'                 => $b->getId(),
            'booking_reference'  => $b->getBookingReference(),
            'status'             => $b->getStatus(),
            'parking_lot'        => $b->getParkingLot()->getName(),
            'vehicle_type'       => $b->getVehicleType(),
            'vehicle_number'     => $b->getVehicleNumber(),
            'slot_number'        => $b->getSlot()?->getSlotNumber(),
            'start_time'         => $b->getStartTime()->format('Y-m-d H:i:s'),
            'end_time'           => $b->getEndTime()->format('Y-m-d H:i:s'),
            'expires_at'         => $b->getExpiresAt()?->format('Y-m-d H:i:s'),
            'estimated_fee'      => $b->getEstimatedFee(),
            'is_expired'         => $b->isExpired(),
            'created_at'         => $b->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }
}

FILEEOF_SRC_CONTROLLER_BOOKINGCONTROLLER_PHP
echo "✅ src/Controller/BookingController.php"

# --- src/Controller/DashboardController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/DashboardController.php" << 'FILEEOF_SRC_CONTROLLER_DASHBOARDCONTROLLER_PHP'
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

FILEEOF_SRC_CONTROLLER_DASHBOARDCONTROLLER_PHP
echo "✅ src/Controller/DashboardController.php"

# --- src/Controller/ParkingLotController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/ParkingLotController.php" << 'FILEEOF_SRC_CONTROLLER_PARKINGLOTCONTROLLER_PHP'
<?php
namespace App\Controller;

use App\Entity\ParkingLot;
use App\Entity\ParkingSlot;
use App\Entity\PricingRule;
use App\Repository\ParkingLotRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/lots', name: 'parking_lot_')]
class ParkingLotController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly ParkingLotRepository   $lotRepository,
    ) {}

    /**
     * GET /api/lots
     * List all active parking lots with availability.
     */
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $lots = $this->lotRepository->findAllActive();
        return $this->json(['data' => array_map([$this, 'serializeLot'], $lots)]);
    }

    /**
     * GET /api/lots/{id}
     * Get single parking lot details with slots.
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(ParkingLot $lot): JsonResponse
    {
        return $this->json(['data' => $this->serializeLotFull($lot)]);
    }

    /**
     * POST /api/lots
     * Create a new parking lot. [ADMIN only]
     */
    #[Route('', name: 'create', methods: ['POST'])]
    #[IsGranted('ROLE_ADMIN')]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (empty($data['name']) || empty($data['location']) || empty($data['total_slots'])) {
            return $this->json(['error' => 'name, location, total_slots are required'], Response::HTTP_BAD_REQUEST);
        }

        $lot = new ParkingLot();
        $lot->setName($data['name']);
        $lot->setLocation($data['location']);
        $lot->setTotalSlots((int)$data['total_slots']);
        $lot->setAvailableSlots((int)$data['total_slots']);
        $lot->setLatitude($data['latitude'] ?? null);
        $lot->setLongitude($data['longitude'] ?? null);

        $this->em->persist($lot);

        // Auto-generate slots if vehicle_types provided
        if (!empty($data['slot_config'])) {
            $slotNum = 1;
            foreach ($data['slot_config'] as $config) {
                $type  = $config['vehicle_type'] ?? 'car';
                $count = (int)($config['count'] ?? 0);
                for ($i = 0; $i < $count; $i++) {
                    $slot = new ParkingSlot();
                    $slot->setParkingLot($lot);
                    $slot->setSlotNumber(strtoupper(substr($type, 0, 1)) . str_pad($slotNum, 3, '0', STR_PAD_LEFT));
                    $slot->setVehicleType($type);
                    $slot->setFloor((int)($config['floor'] ?? 1));
                    $this->em->persist($slot);
                    $slotNum++;
                }
            }
        }

        // Auto-create pricing rules if provided
        if (!empty($data['pricing'])) {
            foreach ($data['pricing'] as $p) {
                $rule = new PricingRule();
                $rule->setParkingLot($lot);
                $rule->setVehicleType($p['vehicle_type']);
                $rule->setRateType($p['rate_type'] ?? PricingRule::TYPE_HOURLY);
                $rule->setRate((string)$p['rate']);
                $rule->setMinimumCharge(isset($p['minimum_charge']) ? (string)$p['minimum_charge'] : null);
                $rule->setFreeMinutes($p['free_minutes'] ?? null);
                $this->em->persist($rule);
            }
        }

        $this->em->flush();

        return $this->json(['message' => 'Parking lot created', 'data' => $this->serializeLot($lot)], Response::HTTP_CREATED);
    }

    /**
     * PUT /api/lots/{id}
     * Update parking lot. [ADMIN only]
     */
    #[Route('/{id}', name: 'update', methods: ['PUT'])]
    #[IsGranted('ROLE_ADMIN')]
    public function update(ParkingLot $lot, Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        if (isset($data['name']))      $lot->setName($data['name']);
        if (isset($data['location']))  $lot->setLocation($data['location']);
        if (isset($data['latitude']))  $lot->setLatitude($data['latitude']);
        if (isset($data['longitude'])) $lot->setLongitude($data['longitude']);
        if (isset($data['is_active'])) $lot->setIsActive((bool)$data['is_active']);

        $this->em->flush();

        return $this->json(['message' => 'Parking lot updated', 'data' => $this->serializeLot($lot)]);
    }

    /**
     * DELETE /api/lots/{id}
     * Delete parking lot. [ADMIN only]
     */
    #[Route('/{id}', name: 'delete', methods: ['DELETE'])]
    #[IsGranted('ROLE_ADMIN')]
    public function delete(ParkingLot $lot): JsonResponse
    {
        $this->em->remove($lot);
        $this->em->flush();
        return $this->json(['message' => 'Parking lot deleted']);
    }

    /**
     * GET /api/lots/{id}/slots
     * Get all slots of a parking lot with status.
     */
    #[Route('/{id}/slots', name: 'slots', methods: ['GET'])]
    public function slots(ParkingLot $lot, Request $request): JsonResponse
    {
        $vehicleType = $request->query->get('vehicle_type');
        $status      = $request->query->get('status');

        $slots = $lot->getSlots()->filter(function(ParkingSlot $slot) use ($vehicleType, $status) {
            if ($vehicleType && $slot->getVehicleType() !== $vehicleType) return false;
            if ($status && $slot->getStatus() !== $status) return false;
            return true;
        });

        return $this->json([
            'data' => array_map([$this, 'serializeSlot'], $slots->toArray()),
            'summary' => [
                'total'     => $lot->getTotalSlots(),
                'available' => $lot->getAvailableSlots(),
                'occupied'  => $lot->getTotalSlots() - $lot->getAvailableSlots(),
            ],
        ]);
    }

    // ── Serializers ──────────────────────────────────────────────────────────

    private function serializeLot(ParkingLot $lot): array
    {
        return [
            'id'               => $lot->getId(),
            'name'             => $lot->getName(),
            'location'         => $lot->getLocation(),
            'latitude'         => $lot->getLatitude(),
            'longitude'        => $lot->getLongitude(),
            'total_slots'      => $lot->getTotalSlots(),
            'available_slots'  => $lot->getAvailableSlots(),
            'occupied_slots'   => $lot->getTotalSlots() - $lot->getAvailableSlots(),
            'is_active'        => $lot->isActive(),
            'created_at'       => $lot->getCreatedAt()->format('Y-m-d H:i:s'),
        ];
    }

    private function serializeLotFull(ParkingLot $lot): array
    {
        $data = $this->serializeLot($lot);
        $data['pricing_rules'] = array_map(function (PricingRule $r) {
            return [
                'vehicle_type'   => $r->getVehicleType(),
                'rate_type'      => $r->getRateType(),
                'rate'           => $r->getRate(),
                'minimum_charge' => $r->getMinimumCharge(),
                'free_minutes'   => $r->getFreeMinutes(),
            ];
        }, $lot->getPricingRules()->toArray());
        return $data;
    }

    private function serializeSlot(ParkingSlot $slot): array
    {
        return [
            'id'           => $slot->getId(),
            'slot_number'  => $slot->getSlotNumber(),
            'vehicle_type' => $slot->getVehicleType(),
            'status'       => $slot->getStatus(),
            'floor'        => $slot->getFloor(),
        ];
    }
}

FILEEOF_SRC_CONTROLLER_PARKINGLOTCONTROLLER_PHP
echo "✅ src/Controller/ParkingLotController.php"

# --- src/Controller/SessionController.php ---
mkdir -p "$PROJECT/src/Controller"
cat > "$PROJECT/src/Controller/SessionController.php" << 'FILEEOF_SRC_CONTROLLER_SESSIONCONTROLLER_PHP'
<?php
namespace App\Controller;

use App\Entity\Payment;
use App\Entity\ParkingLot;
use App\Entity\ParkingSession;
use App\Exception\ParkingException;
use App\Repository\ParkingLotRepository;
use App\Repository\ParkingSessionRepository;
use App\Service\ParkingService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

#[Route('/api/sessions', name: 'session_')]
class SessionController extends AbstractController
{
    public function __construct(
        private readonly ParkingService           $parkingService,
        private readonly ParkingLotRepository     $lotRepository,
        private readonly ParkingSessionRepository $sessionRepository,
    ) {}

    /**
     * POST /api/sessions/entry
     * Register vehicle entry.
     * Body: { lot_id, vehicle_number, vehicle_type, payment_method? }
     */
    #[Route('/entry', name: 'entry', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function entry(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true) ?? [];

        $required = ['lot_id', 'vehicle_number', 'vehicle_type'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return $this->json(['error' => "Field '{$field}' is required"], Response::HTTP_BAD_REQUEST);
            }
        }

        $lot = $this->lotRepository->find($data['lot_id']);
        if (!$lot || !$lot->isActive()) {
            return $this->json(['error' => 'Parking lot not found or inactive'], Response::HTTP_NOT_FOUND);
        }

        $validTypes = ['car', 'bike', 'truck'];
        if (!in_array($data['vehicle_type'], $validTypes)) {
            return $this->json(['error' => 'vehicle_type must be: car, bike, or truck'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $session = $this->parkingService->registerEntry(
                $lot,
                $data['vehicle_number'],
                $data['vehicle_type']
            );

            return $this->json([
                'message' => 'Vehicle entry registered successfully',
                'data'    => $this->serializeSession($session),
            ], Response::HTTP_CREATED);

        } catch (ParkingException $e) {
            $code = $e->getErrorCode() === ParkingException::NO_SLOT_AVAILABLE
                ? Response::HTTP_UNPROCESSABLE_ENTITY
                : Response::HTTP_CONFLICT;
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], $code);
        }
    }

    /**
     * POST /api/sessions/{id}/exit
     * Process vehicle exit and generate invoice.
     * Body: { payment_method? }
     */
    #[Route('/{id}/exit', name: 'exit', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function exit(ParkingSession $session, Request $request): JsonResponse
    {
        $data   = json_decode($request->getContent(), true) ?? [];
        $method = $data['payment_method'] ?? Payment::METHOD_CASH;

        try {
            $payment = $this->parkingService->processExit($session, $method);

            return $this->json([
                'message' => 'Vehicle exit processed successfully',
                'data'    => $this->serializeExitResponse($session, $payment),
            ]);

        } catch (ParkingException $e) {
            return $this->json(['error' => $e->getMessage(), 'code' => $e->getErrorCode()], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * POST /api/sessions/{id}/pay
     * Confirm payment for a session (after gateway callback).
     */
    #[Route('/{id}/pay', name: 'pay', methods: ['POST'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function confirmPayment(ParkingSession $session, Request $request): JsonResponse
    {
        $data          = json_decode($request->getContent(), true) ?? [];
        $transactionId = $data['transaction_id'] ?? ('TXN' . strtoupper(substr(md5(uniqid()), 0, 10)));

        $payment = $session->getPayment();
        if (!$payment) {
            return $this->json(['error' => 'No payment record found for this session'], Response::HTTP_NOT_FOUND);
        }

        if ($payment->getStatus() === Payment::STATUS_PAID) {
            return $this->json(['error' => 'Payment already confirmed'], Response::HTTP_CONFLICT);
        }

        $this->parkingService->confirmPayment($payment, $transactionId);

        return $this->json([
            'message' => 'Payment confirmed',
            'invoice' => $this->serializeInvoice($session, $payment),
        ]);
    }

    /**
     * GET /api/sessions
     * List active sessions (with optional lot_id filter).
     */
    #[Route('', name: 'list', methods: ['GET'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function list(Request $request): JsonResponse
    {
        $lotId    = $request->query->get('lot_id');
        $sessions = $this->sessionRepository->findActiveSessions($lotId ? (int)$lotId : null);

        return $this->json([
            'data'  => array_map([$this, 'serializeSession'], $sessions),
            'total' => count($sessions),
        ]);
    }

    /**
     * GET /api/sessions/{id}
     * Get session details.
     */
    #[Route('/{id}', name: 'show', methods: ['GET'])]
    #[IsGranted('ROLE_OPERATOR')]
    public function show(ParkingSession $session): JsonResponse
    {
        return $this->json(['data' => $this->serializeSession($session)]);
    }

    // ── Serializers ──────────────────────────────────────────────────────────

    private function serializeSession(ParkingSession $s): array
    {
        $now      = new \DateTimeImmutable();
        $duration = (int) round(
            ($s->getExitTime() ?? $now)->getTimestamp() - $s->getEntryTime()->getTimestamp()
        ) / 60;

        return [
            'id'               => $s->getId(),
            'status'           => $s->getStatus(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'vehicle_type'     => $s->getVehicle()->getVehicleType(),
            'parking_lot'      => $s->getParkingLot()->getName(),
            'slot_number'      => $s->getSlot()->getSlotNumber(),
            'floor'            => $s->getSlot()->getFloor(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()?->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes() ?? (int)$duration,
            'total_fee'        => $s->getTotalFee(),
            'payment_status'   => $s->getPayment()?->getStatus(),
        ];
    }

    private function serializeExitResponse(ParkingSession $s, Payment $p): array
    {
        return [
            'session_id'       => $s->getId(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes(),
            'duration_readable'=> floor($s->getDurationMinutes() / 60) . 'h ' . ($s->getDurationMinutes() % 60) . 'm',
            'total_fee'        => $s->getTotalFee(),
            'payment_id'       => $p->getId(),
            'payment_status'   => $p->getStatus(),
            'payment_method'   => $p->getPaymentMethod(),
        ];
    }

    private function serializeInvoice(ParkingSession $s, Payment $p): array
    {
        return [
            'invoice_no'       => 'INV-' . str_pad((string)$p->getId(), 8, '0', STR_PAD_LEFT),
            'session_id'       => $s->getId(),
            'vehicle_number'   => $s->getVehicle()->getVehicleNumber(),
            'vehicle_type'     => $s->getVehicle()->getVehicleType(),
            'parking_lot'      => $s->getParkingLot()->getName(),
            'slot_number'      => $s->getSlot()->getSlotNumber(),
            'entry_time'       => $s->getEntryTime()->format('Y-m-d H:i:s'),
            'exit_time'        => $s->getExitTime()?->format('Y-m-d H:i:s'),
            'duration_minutes' => $s->getDurationMinutes(),
            'total_fee'        => $p->getAmount(),
            'payment_method'   => $p->getPaymentMethod(),
            'transaction_id'   => $p->getTransactionId(),
            'paid_at'          => $p->getPaidAt()?->format('Y-m-d H:i:s'),
            'generated_at'     => (new \DateTimeImmutable())->format('Y-m-d H:i:s'),
        ];
    }
}

FILEEOF_SRC_CONTROLLER_SESSIONCONTROLLER_PHP
echo "✅ src/Controller/SessionController.php"

# --- src/DataFixtures/AppFixtures.php ---
mkdir -p "$PROJECT/src/DataFixtures"
cat > "$PROJECT/src/DataFixtures/AppFixtures.php" << 'FILEEOF_SRC_DATAFIXTURES_APPFIXTURES_PHP'
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

/**
 * Seeds the database with realistic demo data.
 * Run: php bin/console doctrine:fixtures:load
 */
class AppFixtures extends Fixture
{
    public function __construct(
        private readonly UserPasswordHasherInterface $hasher
    ) {}

    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create('en_IN');
        echo "\n🌱 Seeding database...\n";

        // ── 1. Users ─────────────────────────────────────────────
        $users = $this->seedUsers($manager, $faker);
        echo "   ✓ Users seeded\n";

        // ── 2. Parking Lots ───────────────────────────────────────
        $lots = $this->seedParkingLots($manager, $faker);
        echo "   ✓ Parking lots seeded\n";

        // ── 3. Flush lots first (FK deps)
        $manager->flush();

        // ── 4. Slots + Pricing ────────────────────────────────────
        $allSlots = $this->seedSlotsAndPricing($manager, $lots);
        echo "   ✓ Slots & pricing seeded\n";

        $manager->flush();

        // ── 5. Vehicles ───────────────────────────────────────────
        $vehicles = $this->seedVehicles($manager, $faker, $users);
        echo "   ✓ Vehicles seeded\n";

        $manager->flush();

        // ── 6. Completed Sessions + Payments ─────────────────────
        $this->seedCompletedSessions($manager, $faker, $lots, $allSlots, $vehicles, $users);
        echo "   ✓ Historical sessions & payments seeded\n";

        // ── 7. Active Sessions ────────────────────────────────────
        $this->seedActiveSessions($manager, $lots, $allSlots, $vehicles);
        echo "   ✓ Active sessions seeded\n";

        $manager->flush();

        // ── 8. Bookings ───────────────────────────────────────────
        $this->seedBookings($manager, $faker, $lots, $users);
        echo "   ✓ Bookings seeded\n";

        $manager->flush();
        echo "\n✅ Database seeded successfully!\n\n";
        $this->printCredentials();
    }

    // ── Seed Methods ─────────────────────────────────────────────────────────

    private function seedUsers(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $users = [];

        // Fixed accounts
        $accounts = [
            ['admin@parking.com',    'Admin User',     'Admin@123',   ['ROLE_ADMIN']],
            ['operator@parking.com', 'Gate Operator',  'Operator@123',['ROLE_OPERATOR']],
            ['user@parking.com',     'Regular User',   'User@123',    ['ROLE_USER']],
        ];

        foreach ($accounts as [$email, $name, $pass, $roles]) {
            $user = new User();
            $user->setEmail($email)
                 ->setName($name)
                 ->setRoles($roles)
                 ->setPassword($this->hasher->hashPassword($user, $pass))
                 ->setPhone($faker->phoneNumber());
            $manager->persist($user);
            $users[] = $user;
        }

        // Random users
        for ($i = 0; $i < 20; $i++) {
            $user = new User();
            $user->setEmail($faker->unique()->safeEmail())
                 ->setName($faker->name())
                 ->setRoles(['ROLE_USER'])
                 ->setPassword($this->hasher->hashPassword($user, 'password'))
                 ->setPhone($faker->phoneNumber());
            $manager->persist($user);
            $users[] = $user;
        }

        return $users;
    }

    private function seedParkingLots(ObjectManager $manager, \Faker\Generator $faker): array
    {
        $lots = [];
        $lotData = [
            ['Connaught Place Parking',    'Connaught Place, New Delhi',     28.6315, 77.2167],
            ['Saket District Centre',      'Saket, New Delhi',               28.5274, 77.2159],
            ['Cyber Hub Parking',          'DLF Cyber Hub, Gurugram',        28.4950, 77.0877],
            ['Mumbai Central Parking',     'Mumbai Central, Mumbai',         18.9692, 72.8192],
            ['Bengaluru Tech Park',        'Whitefield, Bengaluru',          12.9698, 77.7499],
        ];

        foreach ($lotData as [$name, $location, $lat, $lng]) {
            $total = $faker->numberBetween(50, 200);
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

    private function seedSlotsAndPricing(ObjectManager $manager, array $lots): array
    {
        $allSlots = [];

        // Pricing config per vehicle type
        $pricingConfig = [
            'car'   => ['rate' => '50.00',  'min' => '50.00',  'free' => 15],
            'bike'  => ['rate' => '20.00',  'min' => '20.00',  'free' => 30],
            'truck' => ['rate' => '100.00', 'min' => '100.00', 'free' => 0],
        ];

        // Slot distribution per lot
        $slotConfig = [
            ['vehicle_type' => 'car',   'count' => 30, 'floors' => 3],
            ['vehicle_type' => 'bike',  'count' => 15, 'floors' => 1],
            ['vehicle_type' => 'truck', 'count' => 5,  'floors' => 1],
        ];

        foreach ($lots as $lot) {
            $slotNum = 1;
            $lotSlots = [];

            foreach ($slotConfig as $config) {
                $type   = $config['vehicle_type'];
                $count  = $config['count'];
                $floors = $config['floors'];
                $prefix = strtoupper($type[0]);

                for ($i = 0; $i < $count; $i++) {
                    $floor = (int)ceil(($i + 1) / ceil($count / $floors));
                    $slot  = new ParkingSlot();
                    $slot->setParkingLot($lot)
                         ->setSlotNumber($prefix . str_pad($slotNum, 3, '0', STR_PAD_LEFT))
                         ->setVehicleType($type)
                         ->setFloor($floor)
                         ->setStatus(ParkingSlot::STATUS_AVAILABLE);
                    $manager->persist($slot);
                    $lotSlots[$type][] = $slot;
                    $allSlots[]        = $slot;
                    $slotNum++;
                }

                // Create pricing rule
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

        return $allSlots;
    }

    private function seedVehicles(ObjectManager $manager, \Faker\Generator $faker, array $users): array
    {
        $vehicles = [];
        $types    = ['car', 'car', 'car', 'bike', 'bike', 'truck'];
        $makes    = ['Maruti', 'Hyundai', 'Tata', 'Honda', 'Toyota', 'Mahindra', 'Bajaj', 'TVS'];
        $models   = ['Swift', 'i20', 'Nexon', 'City', 'Fortuner', 'Bolero', 'Pulsar', 'Apache'];
        $colors   = ['White', 'Black', 'Silver', 'Red', 'Blue', 'Grey', 'Brown'];

        $statePrefixes = ['DL', 'MH', 'KA', 'HR', 'UP', 'TN'];

        for ($i = 0; $i < 60; $i++) {
            $type   = $types[array_rand($types)];
            $prefix = $statePrefixes[array_rand($statePrefixes)];
            $num    = $prefix . sprintf('%02d', rand(1, 99)) . strtoupper(substr(md5(uniqid()), 0, 2)) . sprintf('%04d', rand(1000, 9999));

            $vehicle = new Vehicle();
            $vehicle->setVehicleNumber($num)
                    ->setVehicleType($type)
                    ->setMake($makes[array_rand($makes)])
                    ->setModel($models[array_rand($models)])
                    ->setColor($colors[array_rand($colors)]);

            if ($i < count($users) && $i % 2 === 0) {
                $vehicle->setOwner($users[$i]);
            }

            $manager->persist($vehicle);
            $vehicles[] = $vehicle;
        }

        return $vehicles;
    }

    private function seedCompletedSessions(
        ObjectManager $manager,
        \Faker\Generator $faker,
        array $lots,
        array $allSlots,
        array $vehicles,
        array $users
    ): void {
        // Seed 90 days of historical data
        for ($day = 90; $day >= 1; $day--) {
            $sessionsPerDay = $faker->numberBetween(5, 25);

            for ($s = 0; $s < $sessionsPerDay; $s++) {
                $lot     = $lots[array_rand($lots)];
                $vehicle = $vehicles[array_rand($vehicles)];

                // Find a slot of matching vehicle type
                $matchingSlots = array_filter($allSlots, fn($sl) =>
                    $sl->getParkingLot()->getId() === $lot->getId() &&
                    $sl->getVehicleType() === $vehicle->getVehicleType()
                );
                if (empty($matchingSlots)) continue;

                $slot = array_values($matchingSlots)[array_rand($matchingSlots)];

                $entryHour     = $faker->numberBetween(6, 20);
                $durationMins  = $faker->numberBetween(30, 480);
                $entryTime     = new \DateTimeImmutable("-{$day} days {$entryHour}:00:00");
                $exitTime      = $entryTime->modify("+{$durationMins} minutes");

                $session = new ParkingSession();
                $session->setParkingLot($lot)
                        ->setSlot($slot)
                        ->setVehicle($vehicle)
                        ->setUser($users[array_rand($users)])
                        ->setEntryTime($entryTime)
                        ->setExitTime($exitTime)
                        ->setDurationMinutes($durationMins)
                        ->setStatus(ParkingSession::STATUS_COMPLETED);

                // Calculate fee (hourly)
                $hours = ceil($durationMins / 60);
                $rate  = match ($vehicle->getVehicleType()) {
                    'car'   => 50,
                    'bike'  => 20,
                    'truck' => 100,
                    default => 50,
                };
                $fee = max($rate, $hours * $rate);
                $session->setTotalFee((string)$fee);

                $manager->persist($session);

                // Payment
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
        array $allSlots,
        array $vehicles
    ): void {
        $usedSlotIds = [];

        for ($i = 0; $i < 15; $i++) {
            $lot     = $lots[array_rand($lots)];
            $vehicle = $vehicles[array_rand($vehicles)];

            $matchingSlots = array_filter($allSlots, fn($sl) =>
                $sl->getParkingLot()->getId() === $lot->getId() &&
                $sl->getVehicleType() === $vehicle->getVehicleType() &&
                !in_array($sl->getId(), $usedSlotIds)
            );
            if (empty($matchingSlots)) continue;

            $slot = array_values($matchingSlots)[0];
            $usedSlotIds[] = spl_object_id($slot);

            $entryMinsAgo = random_int(10, 240);
            $entryTime    = new \DateTimeImmutable("-{$entryMinsAgo} minutes");

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

    private function seedBookings(
        ObjectManager $manager,
        \Faker\Generator $faker,
        array $lots,
        array $users
    ): void {
        $types = ['car', 'bike', 'truck'];

        for ($i = 0; $i < 10; $i++) {
            $lot       = $lots[array_rand($lots)];
            $user      = $users[array_rand($users)];
            $type      = $types[array_rand($types)];
            $hoursAhead = random_int(1, 48);

            $start = new \DateTimeImmutable("+{$hoursAhead} hours");
            $end   = $start->modify('+2 hours');

            $booking = new Booking();
            $booking->setUser($user)
                    ->setParkingLot($lot)
                    ->setVehicleType($type)
                    ->setVehicleNumber('DL01AB' . str_pad((string)($i + 1000), 4, '0', STR_PAD_LEFT))
                    ->setStartTime($start)
                    ->setEndTime($end)
                    ->setExpiresAt($start->modify('+15 minutes'))
                    ->setStatus(Booking::STATUS_CONFIRMED)
                    ->setEstimatedFee((string)(2 * match($type) { 'car' => 50, 'bike' => 20, 'truck' => 100, default => 50 }));

            $manager->persist($booking);
        }
    }

    private function printCredentials(): void
    {
        echo "┌─────────────────────────────────────────────┐\n";
        echo "│           TEST CREDENTIALS                  │\n";
        echo "├─────────────────────────────────────────────┤\n";
        echo "│ ADMIN    admin@parking.com    Admin@123      │\n";
        echo "│ OPERATOR operator@parking.com Operator@123   │\n";
        echo "│ USER     user@parking.com     User@123       │\n";
        echo "└─────────────────────────────────────────────┘\n";
    }
}

FILEEOF_SRC_DATAFIXTURES_APPFIXTURES_PHP
echo "✅ src/DataFixtures/AppFixtures.php"

# --- src/Entity/Booking.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/Booking.php" << 'FILEEOF_SRC_ENTITY_BOOKING_PHP'
<?php
namespace App\Entity;

use App\Repository\BookingRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: BookingRepository::class)]
#[ORM\Table(name: 'bookings')]
#[ORM\Index(columns: ['status'], name: 'idx_booking_status')]
#[ORM\Index(columns: ['start_time', 'end_time'], name: 'idx_booking_time')]
#[ORM\HasLifecycleCallbacks]
class Booking
{
    const STATUS_PENDING   = 'pending';
    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_ACTIVE    = 'active';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_EXPIRED   = 'expired';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'bookings')]
    #[ORM\JoinColumn(nullable: false)]
    private User $user;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingLot $parkingLot;

    #[ORM\ManyToOne(targetEntity: ParkingSlot::class, inversedBy: 'bookings')]
    #[ORM\JoinColumn(nullable: true)]
    private ?ParkingSlot $slot = null;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 30, nullable: true)]
    private ?string $vehicleNumber = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $startTime;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $endTime;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $expiresAt = null;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'pending'])]
    private string $status = self::STATUS_PENDING;

    #[ORM\Column(type: 'string', length: 50, unique: true)]
    private string $bookingReference;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $estimatedFee = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->bookingReference = 'BK' . strtoupper(substr(md5(uniqid()), 0, 8));
    }

    public function isExpired(): bool
    {
        return $this->expiresAt !== null && $this->expiresAt < new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getUser(): User { return $this->user; }
    public function setUser(User $u): static { $this->user = $u; return $this; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $l): static { $this->parkingLot = $l; return $this; }
    public function getSlot(): ?ParkingSlot { return $this->slot; }
    public function setSlot(?ParkingSlot $s): static { $this->slot = $s; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getVehicleNumber(): ?string { return $this->vehicleNumber; }
    public function setVehicleNumber(?string $n): static { $this->vehicleNumber = $n; return $this; }
    public function getStartTime(): \DateTimeImmutable { return $this->startTime; }
    public function setStartTime(\DateTimeImmutable $t): static { $this->startTime = $t; return $this; }
    public function getEndTime(): \DateTimeImmutable { return $this->endTime; }
    public function setEndTime(\DateTimeImmutable $t): static { $this->endTime = $t; return $this; }
    public function getExpiresAt(): ?\DateTimeImmutable { return $this->expiresAt; }
    public function setExpiresAt(?\DateTimeImmutable $t): static { $this->expiresAt = $t; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getBookingReference(): string { return $this->bookingReference; }
    public function getEstimatedFee(): ?string { return $this->estimatedFee; }
    public function setEstimatedFee(?string $f): static { $this->estimatedFee = $f; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}

FILEEOF_SRC_ENTITY_BOOKING_PHP
echo "✅ src/Entity/Booking.php"

# --- src/Entity/ParkingLot.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/ParkingLot.php" << 'FILEEOF_SRC_ENTITY_PARKINGLOT_PHP'
<?php
namespace App\Entity;

use App\Repository\ParkingLotRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ParkingLotRepository::class)]
#[ORM\Table(name: 'parking_lots')]
#[ORM\Index(columns: ['is_active'], name: 'idx_lot_active')]
#[ORM\HasLifecycleCallbacks]
class ParkingLot
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 150)]
    #[Assert\NotBlank]
    private string $name;

    #[ORM\Column(type: 'text')]
    #[Assert\NotBlank]
    private string $location;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 8, nullable: true)]
    private ?string $latitude = null;

    #[ORM\Column(type: 'decimal', precision: 11, scale: 8, nullable: true)]
    private ?string $longitude = null;

    #[ORM\Column(type: 'integer')]
    #[Assert\Positive]
    private int $totalSlots;

    #[ORM\Column(type: 'integer')]
    private int $availableSlots;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $isActive = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    #[ORM\OneToMany(mappedBy: 'parkingLot', targetEntity: ParkingSlot::class, cascade: ['persist', 'remove'])]
    private Collection $slots;

    #[ORM\OneToMany(mappedBy: 'parkingLot', targetEntity: PricingRule::class, cascade: ['persist', 'remove'])]
    private Collection $pricingRules;

    public function __construct()
    {
        $this->slots = new ArrayCollection();
        $this->pricingRules = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
        $this->availableSlots = 0;
    }

    #[ORM\PreUpdate]
    public function preUpdate(): void { $this->updatedAt = new \DateTimeImmutable(); }

    public function getId(): ?int { return $this->id; }
    public function getName(): string { return $this->name; }
    public function setName(string $name): static { $this->name = $name; return $this; }
    public function getLocation(): string { return $this->location; }
    public function setLocation(string $location): static { $this->location = $location; return $this; }
    public function getLatitude(): ?string { return $this->latitude; }
    public function setLatitude(?string $lat): static { $this->latitude = $lat; return $this; }
    public function getLongitude(): ?string { return $this->longitude; }
    public function setLongitude(?string $lng): static { $this->longitude = $lng; return $this; }
    public function getTotalSlots(): int { return $this->totalSlots; }
    public function setTotalSlots(int $total): static { $this->totalSlots = $total; return $this; }
    public function getAvailableSlots(): int { return $this->availableSlots; }
    public function setAvailableSlots(int $available): static { $this->availableSlots = $available; return $this; }
    public function isActive(): bool { return $this->isActive; }
    public function setIsActive(bool $isActive): static { $this->isActive = $isActive; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): \DateTimeImmutable { return $this->updatedAt; }
    public function getSlots(): Collection { return $this->slots; }
    public function getPricingRules(): Collection { return $this->pricingRules; }
}

FILEEOF_SRC_ENTITY_PARKINGLOT_PHP
echo "✅ src/Entity/ParkingLot.php"

# --- src/Entity/ParkingSession.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/ParkingSession.php" << 'FILEEOF_SRC_ENTITY_PARKINGSESSION_PHP'
<?php
namespace App\Entity;

use App\Repository\ParkingSessionRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: ParkingSessionRepository::class)]
#[ORM\Table(name: 'parking_sessions')]
#[ORM\Index(columns: ['status'], name: 'idx_session_status')]
#[ORM\Index(columns: ['entry_time'], name: 'idx_session_entry')]
#[ORM\Index(columns: ['parking_lot_id', 'status'], name: 'idx_session_lot_status')]
#[ORM\HasLifecycleCallbacks]
class ParkingSession
{
    const STATUS_ACTIVE    = 'active';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingLot $parkingLot;

    #[ORM\ManyToOne(targetEntity: ParkingSlot::class, inversedBy: 'sessions')]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingSlot $slot;

    #[ORM\ManyToOne(targetEntity: Vehicle::class, inversedBy: 'sessions')]
    #[ORM\JoinColumn(nullable: false)]
    private Vehicle $vehicle;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'parkingSessions')]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $user = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $entryTime;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $exitTime = null;

    #[ORM\Column(type: 'integer', nullable: true)]
    private ?int $durationMinutes = null;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $totalFee = null;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'active'])]
    private string $status = self::STATUS_ACTIVE;

    #[ORM\OneToOne(mappedBy: 'session', targetEntity: Payment::class, cascade: ['persist'])]
    private ?Payment $payment = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->entryTime = new \DateTimeImmutable();
    }

    public function calculateDuration(): int
    {
        $exit = $this->exitTime ?? new \DateTimeImmutable();
        return (int) round(($exit->getTimestamp() - $this->entryTime->getTimestamp()) / 60);
    }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $lot): static { $this->parkingLot = $lot; return $this; }
    public function getSlot(): ParkingSlot { return $this->slot; }
    public function setSlot(ParkingSlot $slot): static { $this->slot = $slot; return $this; }
    public function getVehicle(): Vehicle { return $this->vehicle; }
    public function setVehicle(Vehicle $v): static { $this->vehicle = $v; return $this; }
    public function getUser(): ?User { return $this->user; }
    public function setUser(?User $u): static { $this->user = $u; return $this; }
    public function getEntryTime(): \DateTimeImmutable { return $this->entryTime; }
    public function setEntryTime(\DateTimeImmutable $t): static { $this->entryTime = $t; return $this; }
    public function getExitTime(): ?\DateTimeImmutable { return $this->exitTime; }
    public function setExitTime(?\DateTimeImmutable $t): static { $this->exitTime = $t; return $this; }
    public function getDurationMinutes(): ?int { return $this->durationMinutes; }
    public function setDurationMinutes(?int $d): static { $this->durationMinutes = $d; return $this; }
    public function getTotalFee(): ?string { return $this->totalFee; }
    public function setTotalFee(?string $f): static { $this->totalFee = $f; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getPayment(): ?Payment { return $this->payment; }
    public function setPayment(?Payment $p): static { $this->payment = $p; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}

FILEEOF_SRC_ENTITY_PARKINGSESSION_PHP
echo "✅ src/Entity/ParkingSession.php"

# --- src/Entity/ParkingSlot.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/ParkingSlot.php" << 'FILEEOF_SRC_ENTITY_PARKINGSLOT_PHP'
<?php
namespace App\Entity;

use App\Repository\ParkingSlotRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ParkingSlotRepository::class)]
#[ORM\Table(name: 'parking_slots')]
#[ORM\Index(columns: ['status'], name: 'idx_slot_status')]
#[ORM\Index(columns: ['vehicle_type'], name: 'idx_slot_vehicle_type')]
#[ORM\Index(columns: ['parking_lot_id', 'status'], name: 'idx_slot_lot_status')]
#[ORM\HasLifecycleCallbacks]
class ParkingSlot
{
    const STATUS_AVAILABLE = 'available';
    const STATUS_OCCUPIED  = 'occupied';
    const STATUS_RESERVED  = 'reserved';
    const STATUS_MAINTENANCE = 'maintenance';

    const VEHICLE_CAR   = 'car';
    const VEHICLE_BIKE  = 'bike';
    const VEHICLE_TRUCK = 'truck';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class, inversedBy: 'slots')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ParkingLot $parkingLot;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\NotBlank]
    private string $slotNumber;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: [self::VEHICLE_CAR, self::VEHICLE_BIKE, self::VEHICLE_TRUCK])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'available'])]
    #[Assert\Choice(choices: [self::STATUS_AVAILABLE, self::STATUS_OCCUPIED, self::STATUS_RESERVED, self::STATUS_MAINTENANCE])]
    private string $status = self::STATUS_AVAILABLE;

    #[ORM\Column(type: 'integer', options: ['default' => 1])]
    private int $floor = 1;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    #[ORM\OneToMany(mappedBy: 'slot', targetEntity: ParkingSession::class)]
    private Collection $sessions;

    #[ORM\OneToMany(mappedBy: 'slot', targetEntity: Booking::class)]
    private Collection $bookings;

    public function __construct()
    {
        $this->sessions = new ArrayCollection();
        $this->bookings = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
    }

    #[ORM\PreUpdate]
    public function preUpdate(): void { $this->updatedAt = new \DateTimeImmutable(); }

    public function isAvailable(): bool { return $this->status === self::STATUS_AVAILABLE; }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $lot): static { $this->parkingLot = $lot; return $this; }
    public function getSlotNumber(): string { return $this->slotNumber; }
    public function setSlotNumber(string $n): static { $this->slotNumber = $n; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getFloor(): int { return $this->floor; }
    public function setFloor(int $f): static { $this->floor = $f; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): \DateTimeImmutable { return $this->updatedAt; }
    public function getSessions(): Collection { return $this->sessions; }
    public function getBookings(): Collection { return $this->bookings; }
}

FILEEOF_SRC_ENTITY_PARKINGSLOT_PHP
echo "✅ src/Entity/ParkingSlot.php"

# --- src/Entity/Payment.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/Payment.php" << 'FILEEOF_SRC_ENTITY_PAYMENT_PHP'
<?php
namespace App\Entity;

use App\Repository\PaymentRepository;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: PaymentRepository::class)]
#[ORM\Table(name: 'payments')]
#[ORM\Index(columns: ['status'], name: 'idx_payment_status')]
#[ORM\HasLifecycleCallbacks]
class Payment
{
    const STATUS_PENDING = 'pending';
    const STATUS_PAID    = 'paid';
    const STATUS_FAILED  = 'failed';
    const STATUS_REFUNDED = 'refunded';

    const METHOD_CASH   = 'cash';
    const METHOD_CARD   = 'card';
    const METHOD_UPI    = 'upi';
    const METHOD_ONLINE = 'online';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\OneToOne(inversedBy: 'payment', targetEntity: ParkingSession::class)]
    #[ORM\JoinColumn(nullable: false)]
    private ParkingSession $session;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    private string $amount;

    #[ORM\Column(type: 'string', length: 20, options: ['default' => 'pending'])]
    private string $status = self::STATUS_PENDING;

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    private ?string $paymentMethod = null;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $transactionId = null;

    #[ORM\Column(type: 'json', nullable: true)]
    private ?array $metadata = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable', nullable: true)]
    private ?\DateTimeImmutable $paidAt = null;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getSession(): ParkingSession { return $this->session; }
    public function setSession(ParkingSession $s): static { $this->session = $s; return $this; }
    public function getAmount(): string { return $this->amount; }
    public function setAmount(string $a): static { $this->amount = $a; return $this; }
    public function getStatus(): string { return $this->status; }
    public function setStatus(string $s): static { $this->status = $s; return $this; }
    public function getPaymentMethod(): ?string { return $this->paymentMethod; }
    public function setPaymentMethod(?string $m): static { $this->paymentMethod = $m; return $this; }
    public function getTransactionId(): ?string { return $this->transactionId; }
    public function setTransactionId(?string $t): static { $this->transactionId = $t; return $this; }
    public function getMetadata(): ?array { return $this->metadata; }
    public function setMetadata(?array $m): static { $this->metadata = $m; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getPaidAt(): ?\DateTimeImmutable { return $this->paidAt; }
    public function setPaidAt(?\DateTimeImmutable $p): static { $this->paidAt = $p; return $this; }
}

FILEEOF_SRC_ENTITY_PAYMENT_PHP
echo "✅ src/Entity/Payment.php"

# --- src/Entity/PricingRule.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/PricingRule.php" << 'FILEEOF_SRC_ENTITY_PRICINGRULE_PHP'
<?php
namespace App\Entity;

use App\Repository\PricingRuleRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: PricingRuleRepository::class)]
#[ORM\Table(name: 'pricing_rules')]
#[ORM\HasLifecycleCallbacks]
class PricingRule
{
    const TYPE_HOURLY = 'hourly';
    const TYPE_MINUTE = 'per_minute';
    const TYPE_FLAT   = 'flat';

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: ParkingLot::class, inversedBy: 'pricingRules')]
    #[ORM\JoinColumn(nullable: false, onDelete: 'CASCADE')]
    private ParkingLot $parkingLot;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: [self::TYPE_HOURLY, self::TYPE_MINUTE, self::TYPE_FLAT])]
    private string $rateType = self::TYPE_HOURLY;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2)]
    #[Assert\Positive]
    private string $rate;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $minimumCharge = null;

    #[ORM\Column(type: 'decimal', precision: 10, scale: 2, nullable: true)]
    private ?string $maximumCharge = null;

    #[ORM\Column(type: 'integer', nullable: true)]
    private ?int $freeMinutes = null;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $isActive = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function calculateFee(int $durationMinutes): float
    {
        $billableMinutes = max(0, $durationMinutes - ($this->freeMinutes ?? 0));

        $fee = match ($this->rateType) {
            self::TYPE_HOURLY => ceil($billableMinutes / 60) * (float)$this->rate,
            self::TYPE_MINUTE => $billableMinutes * (float)$this->rate,
            self::TYPE_FLAT   => (float)$this->rate,
            default           => 0.0,
        };

        if ($this->minimumCharge !== null) {
            $fee = max($fee, (float)$this->minimumCharge);
        }
        if ($this->maximumCharge !== null) {
            $fee = min($fee, (float)$this->maximumCharge);
        }

        return round($fee, 2);
    }

    public function getId(): ?int { return $this->id; }
    public function getParkingLot(): ParkingLot { return $this->parkingLot; }
    public function setParkingLot(ParkingLot $l): static { $this->parkingLot = $l; return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getRateType(): string { return $this->rateType; }
    public function setRateType(string $t): static { $this->rateType = $t; return $this; }
    public function getRate(): string { return $this->rate; }
    public function setRate(string $r): static { $this->rate = $r; return $this; }
    public function getMinimumCharge(): ?string { return $this->minimumCharge; }
    public function setMinimumCharge(?string $m): static { $this->minimumCharge = $m; return $this; }
    public function getMaximumCharge(): ?string { return $this->maximumCharge; }
    public function setMaximumCharge(?string $m): static { $this->maximumCharge = $m; return $this; }
    public function getFreeMinutes(): ?int { return $this->freeMinutes; }
    public function setFreeMinutes(?int $f): static { $this->freeMinutes = $f; return $this; }
    public function isActive(): bool { return $this->isActive; }
    public function setIsActive(bool $a): static { $this->isActive = $a; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
}

FILEEOF_SRC_ENTITY_PRICINGRULE_PHP
echo "✅ src/Entity/PricingRule.php"

# --- src/Entity/User.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/User.php" << 'FILEEOF_SRC_ENTITY_USER_PHP'
<?php
// ============================================================
// src/Entity/User.php
// ============================================================
namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
#[ORM\Index(columns: ['email'], name: 'idx_user_email')]
#[ORM\HasLifecycleCallbacks]
class User implements UserInterface, PasswordAuthenticatedUserInterface
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 180, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Email]
    private string $email;

    #[ORM\Column(type: 'string', length: 100)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 2, max: 100)]
    private string $name;

    #[ORM\Column(type: 'string', nullable: true)]
    private ?string $phone = null;

    /** @var list<string> */
    #[ORM\Column(type: 'json')]
    private array $roles = [];

    #[ORM\Column(type: 'string')]
    private string $password;

    #[ORM\Column(type: 'boolean', options: ['default' => true])]
    private bool $isActive = true;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $updatedAt;

    #[ORM\OneToMany(mappedBy: 'user', targetEntity: ParkingSession::class)]
    private Collection $parkingSessions;

    #[ORM\OneToMany(mappedBy: 'user', targetEntity: Booking::class)]
    private Collection $bookings;

    public function __construct()
    {
        $this->parkingSessions = new ArrayCollection();
        $this->bookings = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
    }

    #[ORM\PreUpdate]
    public function preUpdate(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getEmail(): string { return $this->email; }
    public function setEmail(string $email): static { $this->email = $email; return $this; }
    public function getName(): string { return $this->name; }
    public function setName(string $name): static { $this->name = $name; return $this; }
    public function getPhone(): ?string { return $this->phone; }
    public function setPhone(?string $phone): static { $this->phone = $phone; return $this; }
    public function getUserIdentifier(): string { return $this->email; }
    public function getRoles(): array { $roles = $this->roles; $roles[] = 'ROLE_USER'; return array_unique($roles); }
    public function setRoles(array $roles): static { $this->roles = $roles; return $this; }
    public function getPassword(): string { return $this->password; }
    public function setPassword(string $password): static { $this->password = $password; return $this; }
    public function isActive(): bool { return $this->isActive; }
    public function setIsActive(bool $isActive): static { $this->isActive = $isActive; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): \DateTimeImmutable { return $this->updatedAt; }
    public function eraseCredentials(): void {}
}

FILEEOF_SRC_ENTITY_USER_PHP
echo "✅ src/Entity/User.php"

# --- src/Entity/Vehicle.php ---
mkdir -p "$PROJECT/src/Entity"
cat > "$PROJECT/src/Entity/Vehicle.php" << 'FILEEOF_SRC_ENTITY_VEHICLE_PHP'
<?php
namespace App\Entity;

use App\Repository\VehicleRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: VehicleRepository::class)]
#[ORM\Table(name: 'vehicles')]
#[ORM\Index(columns: ['vehicle_number'], name: 'idx_vehicle_number')]
#[ORM\HasLifecycleCallbacks]
class Vehicle
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\ManyToOne(targetEntity: User::class)]
    #[ORM\JoinColumn(nullable: true)]
    private ?User $owner = null;

    #[ORM\Column(type: 'string', length: 30, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Regex(pattern: '/^[A-Z0-9\-]+$/')]
    private string $vehicleNumber;

    #[ORM\Column(type: 'string', length: 20)]
    #[Assert\Choice(choices: ['car', 'bike', 'truck'])]
    private string $vehicleType;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $make = null;

    #[ORM\Column(type: 'string', length: 100, nullable: true)]
    private ?string $model = null;

    #[ORM\Column(type: 'string', length: 20, nullable: true)]
    private ?string $color = null;

    #[ORM\Column(type: 'datetime_immutable')]
    private \DateTimeImmutable $createdAt;

    #[ORM\OneToMany(mappedBy: 'vehicle', targetEntity: ParkingSession::class)]
    private Collection $sessions;

    public function __construct()
    {
        $this->sessions = new ArrayCollection();
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }
    public function getOwner(): ?User { return $this->owner; }
    public function setOwner(?User $owner): static { $this->owner = $owner; return $this; }
    public function getVehicleNumber(): string { return $this->vehicleNumber; }
    public function setVehicleNumber(string $n): static { $this->vehicleNumber = strtoupper(trim($n)); return $this; }
    public function getVehicleType(): string { return $this->vehicleType; }
    public function setVehicleType(string $t): static { $this->vehicleType = $t; return $this; }
    public function getMake(): ?string { return $this->make; }
    public function setMake(?string $m): static { $this->make = $m; return $this; }
    public function getModel(): ?string { return $this->model; }
    public function setModel(?string $m): static { $this->model = $m; return $this; }
    public function getColor(): ?string { return $this->color; }
    public function setColor(?string $c): static { $this->color = $c; return $this; }
    public function getCreatedAt(): \DateTimeImmutable { return $this->createdAt; }
    public function getSessions(): Collection { return $this->sessions; }
}

FILEEOF_SRC_ENTITY_VEHICLE_PHP
echo "✅ src/Entity/Vehicle.php"

# --- src/EventListener/ExceptionListener.php ---
mkdir -p "$PROJECT/src/EventListener"
cat > "$PROJECT/src/EventListener/ExceptionListener.php" << 'FILEEOF_SRC_EVENTLISTENER_EXCEPTIONLISTENER_PHP'
<?php
namespace App\EventListener;

use App\Exception\ParkingException;
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * Converts all exceptions to consistent JSON responses for API routes.
 */
class ExceptionListener
{
    public function __construct(private readonly LoggerInterface $logger) {}

    public function onKernelException(ExceptionEvent $event): void
    {
        $request = $event->getRequest();

        // Only handle API routes
        if (!str_starts_with($request->getPathInfo(), '/api')) {
            return;
        }

        $exception = $event->getThrowable();

        [$statusCode, $message, $extra] = match (true) {
            $exception instanceof ParkingException => [
                max(400, $exception->getCode()),
                $exception->getMessage(),
                ['error_code' => $exception->getErrorCode()],
            ],
            $exception instanceof NotFoundHttpException => [
                Response::HTTP_NOT_FOUND,
                'Resource not found',
                [],
            ],
            $exception instanceof AccessDeniedHttpException => [
                Response::HTTP_FORBIDDEN,
                'Access denied. Insufficient permissions.',
                [],
            ],
            $exception instanceof HttpExceptionInterface => [
                $exception->getStatusCode(),
                $exception->getMessage(),
                [],
            ],
            default => [
                Response::HTTP_INTERNAL_SERVER_ERROR,
                'An unexpected error occurred',
                [],
            ],
        };

        // Log server errors
        if ($statusCode >= 500) {
            $this->logger->error('API Exception', [
                'message'   => $exception->getMessage(),
                'trace'     => $exception->getTraceAsString(),
                'path'      => $request->getPathInfo(),
            ]);
        }

        $response = new JsonResponse(array_merge([
            'error'   => $message,
            'status'  => $statusCode,
            'path'    => $request->getPathInfo(),
        ], $extra), $statusCode);

        $event->setResponse($response);
    }
}

FILEEOF_SRC_EVENTLISTENER_EXCEPTIONLISTENER_PHP
echo "✅ src/EventListener/ExceptionListener.php"

# --- src/EventListener/JWTCreatedListener.php ---
mkdir -p "$PROJECT/src/EventListener"
cat > "$PROJECT/src/EventListener/JWTCreatedListener.php" << 'FILEEOF_SRC_EVENTLISTENER_JWTCREATEDLISTENER_PHP'
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

FILEEOF_SRC_EVENTLISTENER_JWTCREATEDLISTENER_PHP
echo "✅ src/EventListener/JWTCreatedListener.php"

# --- src/Exception/ParkingException.php ---
mkdir -p "$PROJECT/src/Exception"
cat > "$PROJECT/src/Exception/ParkingException.php" << 'FILEEOF_SRC_EXCEPTION_PARKINGEXCEPTION_PHP'
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

FILEEOF_SRC_EXCEPTION_PARKINGEXCEPTION_PHP
echo "✅ src/Exception/ParkingException.php"

# --- src/Kernel.php ---
mkdir -p "$PROJECT/src"
cat > "$PROJECT/src/Kernel.php" << 'FILEEOF_SRC_KERNEL_PHP'
<?php
namespace App;

use Symfony\Bundle\FrameworkBundle\Kernel\MicroKernelTrait;
use Symfony\Component\HttpKernel\Kernel as BaseKernel;

class Kernel extends BaseKernel
{
    use MicroKernelTrait;
}

FILEEOF_SRC_KERNEL_PHP
echo "✅ src/Kernel.php"

# --- src/Repository/BookingRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/BookingRepository.php" << 'FILEEOF_SRC_REPOSITORY_BOOKINGREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\Booking;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class BookingRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Booking::class);
    }

    public function findExpiredConfirmed(): array
    {
        return $this->createQueryBuilder('b')
            ->where('b.status = :status')
            ->andWhere('b.expiresAt < :now')
            ->setParameter('status', Booking::STATUS_CONFIRMED)
            ->setParameter('now', new \DateTimeImmutable())
            ->getQuery()
            ->getResult();
    }

    public function findByUserPaginated(int $userId, int $page = 1, int $limit = 10): array
    {
        $offset = ($page - 1) * $limit;
        return $this->createQueryBuilder('b')
            ->where('b.user = :userId')
            ->setParameter('userId', $userId)
            ->orderBy('b.createdAt', 'DESC')
            ->setFirstResult($offset)
            ->setMaxResults($limit)
            ->getQuery()
            ->getResult();
    }
}

FILEEOF_SRC_REPOSITORY_BOOKINGREPOSITORY_PHP
echo "✅ src/Repository/BookingRepository.php"

# --- src/Repository/ParkingLotRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/ParkingLotRepository.php" << 'FILEEOF_SRC_REPOSITORY_PARKINGLOTREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\ParkingLot;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingLotRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingLot::class);
    }

    public function findAllActive(): array
    {
        return $this->createQueryBuilder('pl')
            ->where('pl.isActive = true')
            ->orderBy('pl.name', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function findWithAvailableSlots(string $vehicleType): array
    {
        return $this->createQueryBuilder('pl')
            ->join('pl.slots', 's')
            ->where('pl.isActive = true')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status = :status')
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('status', 'available')
            ->groupBy('pl.id')
            ->getQuery()
            ->getResult();
    }
}

FILEEOF_SRC_REPOSITORY_PARKINGLOTREPOSITORY_PHP
echo "✅ src/Repository/ParkingLotRepository.php"

# --- src/Repository/ParkingSessionRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/ParkingSessionRepository.php" << 'FILEEOF_SRC_REPOSITORY_PARKINGSESSIONREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\ParkingSession;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingSessionRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingSession::class);
    }

    public function findActiveByVehicleNumber(string $vehicleNumber): ?ParkingSession
    {
        return $this->createQueryBuilder('ps')
            ->join('ps.vehicle', 'v')
            ->where('v.vehicleNumber = :num')
            ->andWhere('ps.status = :status')
            ->setParameter('num', strtoupper($vehicleNumber))
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->getQuery()
            ->getOneOrNullResult();
    }

    public function countActive(?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE);
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function countByDate(\DateTimeImmutable $date, ?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.entryTime >= :start')
            ->andWhere('ps.entryTime < :end')
            ->setParameter('start', $date->setTime(0, 0))
            ->setParameter('end', $date->setTime(23, 59, 59));
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function countForPeriod(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): int
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('COUNT(ps.id)')
            ->where('ps.entryTime >= :from')
            ->andWhere('ps.entryTime <= :to')
            ->setParameter('from', $from)
            ->setParameter('to', $to);
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return (int) $qb->getQuery()->getSingleScalarResult();
    }

    public function getVehicleTypeBreakdown(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('ps')
            ->select('v.vehicleType, COUNT(ps.id) as total')
            ->join('ps.vehicle', 'v')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->groupBy('v.vehicleType');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getArrayResult();
    }

    public function findActiveSessions(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('ps')
            ->join('ps.vehicle', 'v')
            ->join('ps.slot', 's')
            ->join('ps.parkingLot', 'pl')
            ->where('ps.status = :status')
            ->setParameter('status', ParkingSession::STATUS_ACTIVE)
            ->orderBy('ps.entryTime', 'DESC');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getResult();
    }
}

FILEEOF_SRC_REPOSITORY_PARKINGSESSIONREPOSITORY_PHP
echo "✅ src/Repository/ParkingSessionRepository.php"

# --- src/Repository/ParkingSlotRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/ParkingSlotRepository.php" << 'FILEEOF_SRC_REPOSITORY_PARKINGSLOTREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\ParkingSlot;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class ParkingSlotRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, ParkingSlot::class);
    }

    /** Find nearest available slot (lowest floor + slot number) */
    public function findNearestAvailable(int $lotId, string $vehicleType): ?ParkingSlot
    {
        return $this->createQueryBuilder('s')
            ->where('s.parkingLot = :lotId')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status = :status')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('status', ParkingSlot::STATUS_AVAILABLE)
            ->orderBy('s.floor', 'ASC')
            ->addOrderBy('s.slotNumber', 'ASC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }

    /** Find available slot for a booking time range (no conflicting bookings) */
    public function findAvailableForBooking(
        int $lotId,
        string $vehicleType,
        \DateTimeImmutable $start,
        \DateTimeImmutable $end
    ): ?ParkingSlot {
        return $this->createQueryBuilder('s')
            ->where('s.parkingLot = :lotId')
            ->andWhere('s.vehicleType = :vehicleType')
            ->andWhere('s.status IN (:statuses)')
            ->andWhere('s.id NOT IN (
                SELECT IDENTITY(b.slot) FROM App\Entity\Booking b
                WHERE b.status IN (:activeBookingStatuses)
                AND b.startTime < :end AND b.endTime > :start
                AND b.slot IS NOT NULL
            )')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setParameter('statuses', [ParkingSlot::STATUS_AVAILABLE])
            ->setParameter('activeBookingStatuses', ['confirmed', 'active'])
            ->setParameter('start', $start)
            ->setParameter('end', $end)
            ->orderBy('s.floor', 'ASC')
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }

    public function getUtilizationStats(?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('s')
            ->select('s.vehicleType, s.status, COUNT(s.id) as count');

        if ($lotId) {
            $qb->where('s.parkingLot = :lotId')->setParameter('lotId', $lotId);
        }

        return $qb->groupBy('s.vehicleType, s.status')->getQuery()->getArrayResult();
    }
}

FILEEOF_SRC_REPOSITORY_PARKINGSLOTREPOSITORY_PHP
echo "✅ src/Repository/ParkingSlotRepository.php"

# --- src/Repository/PaymentRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/PaymentRepository.php" << 'FILEEOF_SRC_REPOSITORY_PAYMENTREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\Payment;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class PaymentRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Payment::class);
    }

    public function getTotalRevenue(?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->setParameter('status', Payment::STATUS_PAID);
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getRevenueByDate(\DateTimeImmutable $date, ?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :start')
            ->andWhere('p.paidAt < :end')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('start', $date->setTime(0, 0))
            ->setParameter('end', $date->setTime(23, 59, 59));
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getRevenueForPeriod(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): string
    {
        $qb = $this->createQueryBuilder('p')
            ->select('COALESCE(SUM(p.amount), 0)')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to);
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return (string) $qb->getQuery()->getSingleScalarResult();
    }

    public function getDailyBreakdown(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('p')
            ->select("DATE(p.paidAt) as date, COALESCE(SUM(p.amount), 0) as revenue, COUNT(p.id) as count")
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->groupBy('date')
            ->orderBy('date', 'ASC');
        if ($lotId) {
            $qb->join('p.session', 'ps')
               ->andWhere('ps.parkingLot = :lotId')
               ->setParameter('lotId', $lotId);
        }
        return $qb->getQuery()->getArrayResult();
    }

    public function getRevenueByVehicleType(\DateTimeImmutable $from, \DateTimeImmutable $to, ?int $lotId = null): array
    {
        $qb = $this->createQueryBuilder('p')
            ->select('v.vehicleType, COALESCE(SUM(p.amount), 0) as revenue, COUNT(p.id) as count')
            ->join('p.session', 'ps')
            ->join('ps.vehicle', 'v')
            ->where('p.status = :status')
            ->andWhere('p.paidAt >= :from')
            ->andWhere('p.paidAt <= :to')
            ->setParameter('status', Payment::STATUS_PAID)
            ->setParameter('from', $from)
            ->setParameter('to', $to)
            ->groupBy('v.vehicleType');
        if ($lotId) $qb->andWhere('ps.parkingLot = :lotId')->setParameter('lotId', $lotId);
        return $qb->getQuery()->getArrayResult();
    }
}

FILEEOF_SRC_REPOSITORY_PAYMENTREPOSITORY_PHP
echo "✅ src/Repository/PaymentRepository.php"

# --- src/Repository/PricingRuleRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/PricingRuleRepository.php" << 'FILEEOF_SRC_REPOSITORY_PRICINGRULEREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\PricingRule;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class PricingRuleRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, PricingRule::class);
    }

    public function findActiveRule(int $lotId, string $vehicleType): ?PricingRule
    {
        return $this->createQueryBuilder('pr')
            ->where('pr.parkingLot = :lotId')
            ->andWhere('pr.vehicleType = :vehicleType')
            ->andWhere('pr.isActive = true')
            ->setParameter('lotId', $lotId)
            ->setParameter('vehicleType', $vehicleType)
            ->setMaxResults(1)
            ->getQuery()
            ->getOneOrNullResult();
    }
}

FILEEOF_SRC_REPOSITORY_PRICINGRULEREPOSITORY_PHP
echo "✅ src/Repository/PricingRuleRepository.php"

# --- src/Repository/UserRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/UserRepository.php" << 'FILEEOF_SRC_REPOSITORY_USERREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\User;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;
use Symfony\Component\Security\Core\Exception\UnsupportedUserException;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\PasswordUpgraderInterface;

class UserRepository extends ServiceEntityRepository implements PasswordUpgraderInterface
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, User::class);
    }

    public function upgradePassword(PasswordAuthenticatedUserInterface $user, string $newHashedPassword): void
    {
        if (!$user instanceof User) {
            throw new UnsupportedUserException(sprintf('Instances of "%s" are not supported.', $user::class));
        }
        $user->setPassword($newHashedPassword);
        $this->getEntityManager()->persist($user);
        $this->getEntityManager()->flush();
    }
}

FILEEOF_SRC_REPOSITORY_USERREPOSITORY_PHP
echo "✅ src/Repository/UserRepository.php"

# --- src/Repository/VehicleRepository.php ---
mkdir -p "$PROJECT/src/Repository"
cat > "$PROJECT/src/Repository/VehicleRepository.php" << 'FILEEOF_SRC_REPOSITORY_VEHICLEREPOSITORY_PHP'
<?php
namespace App\Repository;

use App\Entity\Vehicle;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\Persistence\ManagerRegistry;

class VehicleRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Vehicle::class);
    }
}

FILEEOF_SRC_REPOSITORY_VEHICLEREPOSITORY_PHP
echo "✅ src/Repository/VehicleRepository.php"

# --- src/Service/BookingService.php ---
mkdir -p "$PROJECT/src/Service"
cat > "$PROJECT/src/Service/BookingService.php" << 'FILEEOF_SRC_SERVICE_BOOKINGSERVICE_PHP'
<?php
namespace App\Service;

use App\Entity\Booking;
use App\Entity\ParkingLot;
use App\Entity\User;
use App\Exception\ParkingException;
use App\Repository\BookingRepository;
use App\Repository\ParkingSlotRepository;
use App\Repository\PricingRuleRepository;
use Doctrine\ORM\EntityManagerInterface;

class BookingService
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly BookingRepository $bookingRepository,
        private readonly ParkingSlotRepository $slotRepository,
        private readonly PricingRuleRepository $pricingRepository,
        private readonly int $expiryMinutes = 15,
    ) {}

    public function createBooking(
        User $user,
        ParkingLot $lot,
        string $vehicleType,
        \DateTimeImmutable $startTime,
        \DateTimeImmutable $endTime,
        ?string $vehicleNumber = null
    ): Booking {
        $availableSlot = $this->slotRepository->findAvailableForBooking(
            $lot->getId(), $vehicleType, $startTime, $endTime
        );

        if (!$availableSlot) {
            throw new ParkingException(
                "No {$vehicleType} slots available for selected time",
                ParkingException::NO_SLOT_AVAILABLE
            );
        }

        $durationMinutes = (int) round(($endTime->getTimestamp() - $startTime->getTimestamp()) / 60);
        $rule = $this->pricingRepository->findActiveRule($lot->getId(), $vehicleType);
        $estimatedFee = $rule ? $rule->calculateFee($durationMinutes) : null;

        $booking = new Booking();
        $booking->setUser($user);
        $booking->setParkingLot($lot);
        $booking->setSlot($availableSlot);
        $booking->setVehicleType($vehicleType);
        $booking->setVehicleNumber($vehicleNumber);
        $booking->setStartTime($startTime);
        $booking->setEndTime($endTime);
        $booking->setExpiresAt($startTime->modify("+{$this->expiryMinutes} minutes"));
        $booking->setStatus(Booking::STATUS_CONFIRMED);
        $booking->setEstimatedFee($estimatedFee !== null ? (string)$estimatedFee : null);

        $availableSlot->setStatus('reserved');

        $this->em->persist($booking);
        $this->em->flush();

        return $booking;
    }

    public function cancelBooking(Booking $booking, User $requester): void
    {
        if ($booking->getUser()->getId() !== $requester->getId()) {
            throw new ParkingException('Unauthorized to cancel this booking', ParkingException::UNAUTHORIZED, 403);
        }

        if (!in_array($booking->getStatus(), [Booking::STATUS_PENDING, Booking::STATUS_CONFIRMED])) {
            throw new ParkingException('Booking cannot be cancelled in current status', ParkingException::INVALID_STATUS);
        }

        $booking->setStatus(Booking::STATUS_CANCELLED);

        if ($slot = $booking->getSlot()) {
            $slot->setStatus('available');
        }

        $this->em->flush();
    }

    public function handleExpiredBookings(): int
    {
        $expired = $this->bookingRepository->findExpiredConfirmed();
        $count = 0;
        foreach ($expired as $booking) {
            $booking->setStatus(Booking::STATUS_EXPIRED);
            if ($slot = $booking->getSlot()) {
                $slot->setStatus('available');
            }
            $count++;
        }
        $this->em->flush();
        return $count;
    }
}

FILEEOF_SRC_SERVICE_BOOKINGSERVICE_PHP
echo "✅ src/Service/BookingService.php"

# --- src/Service/ParkingService.php ---
mkdir -p "$PROJECT/src/Service"
cat > "$PROJECT/src/Service/ParkingService.php" << 'FILEEOF_SRC_SERVICE_PARKINGSERVICE_PHP'
<?php
namespace App\Service;

use App\Entity\ParkingLot;
use App\Entity\ParkingSession;
use App\Entity\ParkingSlot;
use App\Entity\Payment;
use App\Entity\Vehicle;
use App\Exception\ParkingException;
use App\Repository\ParkingSessionRepository;
use App\Repository\ParkingSlotRepository;
use App\Repository\PricingRuleRepository;
use App\Repository\VehicleRepository;
use Doctrine\ORM\EntityManagerInterface;
use Psr\Log\LoggerInterface;

/**
 * Core parking service: manages entry, exit, fee calculation.
 * Follows SRP - only handles parking session lifecycle.
 */
class ParkingService
{
    public function __construct(
        private readonly EntityManagerInterface  $em,
        private readonly ParkingSlotRepository   $slotRepository,
        private readonly ParkingSessionRepository $sessionRepository,
        private readonly PricingRuleRepository   $pricingRepository,
        private readonly VehicleRepository       $vehicleRepository,
        private readonly LoggerInterface         $logger,
    ) {}

    /**
     * Register vehicle entry: find nearest slot, create session.
     */
    public function registerEntry(
        ParkingLot $lot,
        string $vehicleNumber,
        string $vehicleType,
        ?int $userId = null
    ): ParkingSession {
        $slot = $this->slotRepository->findNearestAvailable($lot->getId(), $vehicleType);

        if (!$slot) {
            throw new ParkingException(
                "No available {$vehicleType} slots in {$lot->getName()}",
                ParkingException::NO_SLOT_AVAILABLE
            );
        }

        $existing = $this->sessionRepository->findActiveByVehicleNumber($vehicleNumber);
        if ($existing) {
            throw new ParkingException(
                "Vehicle {$vehicleNumber} already has an active session",
                ParkingException::VEHICLE_ALREADY_PARKED
            );
        }

        $vehicle = $this->vehicleRepository->findOneBy(['vehicleNumber' => strtoupper($vehicleNumber)]);
        if (!$vehicle) {
            $vehicle = new Vehicle();
            $vehicle->setVehicleNumber($vehicleNumber);
            $vehicle->setVehicleType($vehicleType);
        }

        $session = new ParkingSession();
        $session->setParkingLot($lot);
        $session->setSlot($slot);
        $session->setVehicle($vehicle);
        $session->setEntryTime(new \DateTimeImmutable());
        $session->setStatus(ParkingSession::STATUS_ACTIVE);

        $slot->setStatus(ParkingSlot::STATUS_OCCUPIED);
        $lot->setAvailableSlots(max(0, $lot->getAvailableSlots() - 1));

        $this->em->persist($vehicle);
        $this->em->persist($session);
        $this->em->flush();

        $this->logger->info('Vehicle entered parking', [
            'vehicle'    => $vehicleNumber,
            'slot'       => $slot->getSlotNumber(),
            'lot'        => $lot->getName(),
            'session_id' => $session->getId(),
        ]);

        return $session;
    }

    /**
     * Process exit: compute duration + fee, create payment record.
     */
    public function processExit(ParkingSession $session, string $paymentMethod = Payment::METHOD_CASH): Payment
    {
        if ($session->getStatus() !== ParkingSession::STATUS_ACTIVE) {
            throw new ParkingException('Session is not active', ParkingException::SESSION_NOT_ACTIVE);
        }

        $exitTime = new \DateTimeImmutable();
        $duration = max(1, (int) round(
            ($exitTime->getTimestamp() - $session->getEntryTime()->getTimestamp()) / 60
        ));

        $rule = $this->pricingRepository->findActiveRule(
            $session->getParkingLot()->getId(),
            $session->getVehicle()->getVehicleType()
        );
        $fee = $rule ? $rule->calculateFee($duration) : 0.0;

        $session->setExitTime($exitTime);
        $session->setDurationMinutes($duration);
        $session->setTotalFee((string) $fee);
        $session->setStatus(ParkingSession::STATUS_COMPLETED);

        $payment = new Payment();
        $payment->setSession($session);
        $payment->setAmount((string) $fee);
        $payment->setStatus(Payment::STATUS_PENDING);
        $payment->setPaymentMethod($paymentMethod);

        $slot = $session->getSlot();
        $slot->setStatus(ParkingSlot::STATUS_AVAILABLE);
        $lot = $session->getParkingLot();
        $lot->setAvailableSlots($lot->getAvailableSlots() + 1);

        $this->em->persist($payment);
        $this->em->flush();

        $this->logger->info('Vehicle exited parking', [
            'session_id' => $session->getId(),
            'duration'   => $duration . ' min',
            'fee'        => 'Rs.' . $fee,
        ]);

        return $payment;
    }

    public function confirmPayment(Payment $payment, string $transactionId): void
    {
        $payment->setStatus(Payment::STATUS_PAID);
        $payment->setTransactionId($transactionId);
        $payment->setPaidAt(new \DateTimeImmutable());
        $this->em->flush();
    }
}

FILEEOF_SRC_SERVICE_PARKINGSERVICE_PHP
echo "✅ src/Service/ParkingService.php"

# --- src/Service/ReportService.php ---
mkdir -p "$PROJECT/src/Service"
cat > "$PROJECT/src/Service/ReportService.php" << 'FILEEOF_SRC_SERVICE_REPORTSERVICE_PHP'
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

FILEEOF_SRC_SERVICE_REPORTSERVICE_PHP
echo "✅ src/Service/ReportService.php"

echo ""
echo "=== Checking PHP syntax ==="
errors=0
for f in "$PROJECT"/src/Entity/*.php "$PROJECT"/src/Controller/*.php; do
    result=$(php -l "$f" 2>&1)
    if echo "$result" | grep -q "Parse error\|Fatal error"; then
        echo "❌ $f"
        errors=$((errors+1))
    fi
done
echo ""
if [ $errors -eq 0 ]; then
    echo "✅ All files OK!"
    echo ""
    echo "Next steps:"
    echo "  php bin/console cache:clear"
    echo "  php bin/console doctrine:database:create --if-not-exists"
    echo "  php bin/console doctrine:migrations:migrate"
    echo "  php bin/console doctrine:fixtures:load"
    echo "  php -S localhost:8000 -t public/"
else
    echo "❌ $errors file(s) have errors"
fi
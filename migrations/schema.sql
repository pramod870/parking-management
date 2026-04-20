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


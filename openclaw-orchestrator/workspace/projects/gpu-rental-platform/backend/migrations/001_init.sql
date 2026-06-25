-- GPU Cloud Platform - Initial Migration
-- 001_init.sql

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Wallets table
CREATE TABLE IF NOT EXISTS wallets (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    balance DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'CNY',
    updated_at TIMESTAMP DEFAULT NOW()
);

-- GPU models catalog
CREATE TABLE IF NOT EXISTS gpu_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    vram_gb INT NOT NULL,
    cuda_cores INT,
    mem_bandwidth_gb VARCHAR(20),
    fp32_tflops DECIMAL(6,1),
    price_per_hour DECIMAL(6,2) NOT NULL,
    monthly_price DECIMAL(8,2),
    total_count INT DEFAULT 0,
    available_count INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'available',
    created_at TIMESTAMP DEFAULT NOW()
);

-- GPU instances
CREATE TABLE IF NOT EXISTS gpu_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    gpu_model_id INT NOT NULL REFERENCES gpu_models(id),
    status VARCHAR(20) DEFAULT 'pending',
    image VARCHAR(100) DEFAULT 'ubuntu-22.04-pytorch',
    ssh_key TEXT,
    ip_address INET,
    container_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    stopped_at TIMESTAMP,
    released_at TIMESTAMP
);

-- Billing records
CREATE TABLE IF NOT EXISTS billing_records (
    id BIGSERIAL PRIMARY KEY,
    instance_id UUID REFERENCES gpu_instances(id),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(20) DEFAULT 'usage',
    amount DECIMAL(8,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Recharge records
CREATE TABLE IF NOT EXISTS recharge_records (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(8,2) NOT NULL,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT NOW()
);

-- SSH keys
CREATE TABLE IF NOT EXISTS ssh_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    public_key TEXT NOT NULL,
    fingerprint VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- API tokens
CREATE TABLE IF NOT EXISTS api_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(100),
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_gpu_instances_user_id ON gpu_instances(user_id);
CREATE INDEX idx_gpu_instances_status ON gpu_instances(status);
CREATE INDEX idx_billing_records_user_id ON billing_records(user_id);
CREATE INDEX idx_billing_records_created_at ON billing_records(created_at);
CREATE INDEX idx_recharge_records_user_id ON recharge_records(user_id);
CREATE INDEX idx_ssh_keys_user_id ON ssh_keys(user_id);
CREATE INDEX idx_api_tokens_user_id ON api_tokens(user_id);

-- Seed GPU models
INSERT INTO gpu_models (name, vram_gb, cuda_cores, mem_bandwidth_gb, fp32_tflops, price_per_hour, monthly_price, total_count, available_count) VALUES
('RTX 4080', 16, 9728, '717 GB/s', 48.7, 1.50, 756, 100, 100),
('RTX 4090', 24, 16384, '1008 GB/s', 82.6, 2.50, 1260, 200, 200),
('V100 32G', 32, 5120, '900 GB/s', 15.7, 2.00, 1008, 50, 48),
('A100 40G', 40, 6912, '1555 GB/s', 19.5, 5.00, 2520, 150, 150),
('A100 80G', 80, 6912, '2039 GB/s', 19.5, 8.00, 4032, 100, 100),
('H100 80G', 80, 16896, '3350 GB/s', 67.0, 18.00, 9072, 30, 28)
ON CONFLICT (name) DO NOTHING;

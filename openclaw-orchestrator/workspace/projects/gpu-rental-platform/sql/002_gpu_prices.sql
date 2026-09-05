-- GPU 价格配置表
CREATE TABLE IF NOT EXISTS gpu_price_configs (
    id BIGSERIAL PRIMARY KEY,
    gpu_type VARCHAR(32) UNIQUE NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,
    memory_gb INT NOT NULL,
    vcpus INT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 插入初始价格配置
INSERT INTO gpu_price_configs (gpu_type, hourly_rate, memory_gb, vcpus) VALUES
    ('rtx4090', 1.50, 24, 8),
    ('v100', 3.00, 32, 8),
    ('a100_40', 8.00, 40, 8),
    ('a100_80', 15.00, 80, 16),
    ('h100', 25.00, 80, 16)
ON CONFLICT (gpu_type) DO NOTHING;

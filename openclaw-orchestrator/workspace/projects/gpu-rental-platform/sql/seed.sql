-- Seed data for development/testing

-- GPU price reference (for documentation)
-- rtx4090: ¥1.50/h
-- v100: ¥3.00/h
-- a100_40: ¥8.00/h
-- a100_80: ¥15.00/h
-- h100: ¥25.00/h

-- Test user (password: test123)
INSERT INTO users (username, email, password_hash, balance, status)
VALUES ('testuser', 'test@example.com', '7465737431323300000000000000000000000000000000000000000000000000', 100.00, 'active')
ON CONFLICT (username) DO NOTHING;

-- Test GPU instance
INSERT INTO gpu_instances (user_id, name, gpu_type, memory_gb, vcpus, status, public_ip, ssh_port, hourly_rate)
VALUES (1, 'dev-gpu-01', 'rtx4090', 24, 8, 'running', '10.0.1.100', 22001, 1.50)
ON CONFLICT DO NOTHING;

-- Sample notification
INSERT INTO notifications (user_id, title, content, type)
VALUES (1, 'Welcome!', 'Welcome to GPU Rental Platform. Your account has been credited with ¥100.', 'system')
ON CONFLICT DO NOTHING;

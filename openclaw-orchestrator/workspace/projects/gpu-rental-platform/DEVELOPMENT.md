# GPU Rental Platform - Development Environment

## Prerequisites
- Go 1.21+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose (optional)

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start all services (PostgreSQL, Redis, API)
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f api
```

### Option 2: Local Development

```bash
# 1. Start dependencies
docker-compose up -d postgres redis

# 2. Set up environment
cp .env.example .env

# 3. Download dependencies
go mod download

# 4. Run server
go run ./cmd/server
```

## API Usage

### Register
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123"}'
```

### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'
```

### Create GPU Instance
```bash
curl -X POST http://localhost:8080/api/v1/instances \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-gpu","gpu_type":"rtx4090"}'
```

### List Instances
```bash
curl http://localhost:8080/api/v1/instances \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Database Schema

Run migrations manually:
```bash
psql -U gpu_user -d gpu_platform -f sql/schema.sql
psql -U gpu_user -d gpu_platform -f sql/seed.sql
```

## GPU Types & Pricing

| Type | Memory | vCPUs | Price/hr |
|------|--------|-------|----------|
| rtx4090 | 24GB | 8 | ¥1.50 |
| v100 | 32GB | 8 | ¥3.00 |
| a100_40 | 40GB | 8 | ¥8.00 |
| a100_80 | 80GB | 16 | ¥15.00 |
| h100 | 80GB | 16 | ¥25.00 |

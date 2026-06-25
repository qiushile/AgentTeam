package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port        int
	DatabaseURL string
	RedisURL    string
	JWTSecret   string
	JWTExpiry   int // hours
}

func Load() (*Config, error) {
	port := 8080
	if p := os.Getenv("SERVER_PORT"); p != "" {
		if v, err := strconv.Atoi(p); err == nil {
			port = v
		}
	}

	jwtExpiry := 24
	if e := os.Getenv("JWT_EXPIRY_HOURS"); e != "" {
		if v, err := strconv.Atoi(e); err == nil {
			jwtExpiry = v
		}
	}

	return &Config{
		Port:        port,
		DatabaseURL: getEnv("DATABASE_URL", "postgres://gpucloud:gpucloud@localhost:5432/gpucloud?sslmode=disable"),
		RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379/0"),
		JWTSecret:   getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
		JWTExpiry:   jwtExpiry,
	}, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

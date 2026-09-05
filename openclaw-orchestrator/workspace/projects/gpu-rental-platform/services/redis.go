package services

import (
	"context"
	"log"

	"github.com/redis/go-redis/v9"
)

// InitRedis initializes Redis connection
func InitRedis(url string) (*redis.Client, error) {
	// Parse redis:// URL to host:port
	addr := "localhost:6379"
	if url != "" {
		// Simple parsing for redis://host:port format
		addr = url
		if len(url) > 7 && url[:7] == "redis://" {
			addr = url[7:]
		}
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: "",
		DB:       0,
	})

	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, err
	}

	log.Println("✅ Redis connected successfully")
	return rdb, nil
}

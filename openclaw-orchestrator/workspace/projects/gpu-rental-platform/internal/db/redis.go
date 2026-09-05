package db

import (
	"context"
	"log"

	"github.com/redis/go-redis/v9"
)

// NewRedis creates a new Redis client
func NewRedis(addr string) (*redis.Client, error) {
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

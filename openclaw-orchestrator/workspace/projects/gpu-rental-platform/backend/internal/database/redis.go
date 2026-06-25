package database

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()

type Redis struct {
	Client *redis.Client
}

func NewRedis(url string) (*Redis, error) {
	opts, err := redis.ParseURL(url)
	if err != nil {
		return nil, fmt.Errorf("parse redis url: %w", err)
	}

	client := redis.NewClient(opts)

	if _, err := client.Ping(ctx).Result(); err != nil {
		return nil, fmt.Errorf("ping redis: %w", err)
	}

	return &Redis{Client: client}, nil
}

func (r *Redis) Close() error {
	return r.Client.Close()
}

// Cache helpers
func (r *Redis) Set(key string, value interface{}, ttl time.Duration) error {
	return r.Client.Set(ctx, key, value, ttl).Err()
}

func (r *Redis) Get(key string) (string, error) {
	return r.Client.Get(ctx, key).Result()
}

func (r *Redis) Del(key string) error {
	return r.Client.Del(ctx, key).Err()
}

func (r *Redis) Exists(key string) (bool, error) {
	n, err := r.Client.Exists(ctx, key).Result()
	return n > 0, err
}

// Instance metrics cache
func (r *Redis) SetInstanceMetrics(instanceID string, metrics map[string]interface{}) error {
	return r.Client.HSet(ctx, "metrics:"+instanceID, metrics).Err()
}

func (r *Redis) GetInstanceMetrics(instanceID string) (map[string]string, error) {
	return r.Client.HGetAll(ctx, "metrics:"+instanceID).Result()
}

// Rate limiting
func (r *Redis) IncrementCounter(key string, ttl time.Duration) (int64, error) {
	pipe := r.Client.TxPipeline()
	counter := pipe.Incr(ctx, key)
	pipe.Expire(ctx, key, ttl)
	_, err := pipe.Exec(ctx)
	if err != nil {
		return 0, err
	}
	return counter.Val(), nil
}

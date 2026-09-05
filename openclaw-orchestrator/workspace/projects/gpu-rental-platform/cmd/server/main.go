package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"gpu-rental-platform/config"
	"gpu-rental-platform/internal/middleware"
	"gpu-rental-platform/internal/router"
	"gpu-rental-platform/services"
	"gpu-rental-platform/worker"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	_ = godotenv.Load()

	cfg := config.LoadConfig()

	// Initialize database
	db, err := services.InitDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize Redis
	rdb, err := services.InitRedis(cfg.RedisURL)
	if err != nil {
		log.Fatalf("Failed to initialize Redis: %v", err)
	}
	defer rdb.Close()

	// Run migrations
	if err := services.RunMigrations(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Set Gin mode
	gin.SetMode(cfg.GinMode)

	// Setup router with all routes
	r := router.Setup(db, rdb)

	// Apply global middleware
	r.Use(middleware.CORS())
	r.Use(middleware.RequestID())
	r.Use(middleware.Recovery())

	// Start billing worker in background
	billingWorker := worker.NewBillingWorker(db, rdb)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go billingWorker.Start(ctx)

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan
		log.Println("🛑 Shutting down...")
		cancel()
	}()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 GPU Rental Platform starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

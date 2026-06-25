package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gpucloud/internal/config"
	"gpucloud/internal/database"
	"gpucloud/internal/handler"
	"gpucloud/internal/middleware"
	"gpucloud/internal/service"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func main() {
	// Initialize logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Load config
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Connect to PostgreSQL
	db, err := database.NewPostgres(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run migrations
	if err := db.Migrate(); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}
	logger.Info("Database migrations completed")

	// Connect to Redis
	rdb, err := database.NewRedis(cfg.RedisURL)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer rdb.Close()

	// Seed GPU models
	gpuSvc := service.NewGPUService(db)
	if err := gpuSvc.SeedModels(context.Background()); err != nil {
		logger.Warn("Failed to seed GPU models", zap.Error(err))
	}

	// Initialize services
	userService := service.NewUserService(db, rdb)
	instanceService := service.NewInstanceService(db, rdb, gpuSvc)
	billingService := service.NewBillingService(db, rdb)
	monitorService := service.NewMonitorService(rdb)

	// Setup Gin router
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Logger(logger))
	r.Use(middleware.CORS())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "ok",
			"timestamp": time.Now().Format(time.RFC3339),
			"version":   "1.0.0",
		})
	})

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Auth (public)
		auth := v1.Group("/auth")
		authHandler := handler.NewAuthHandler(userService, cfg.JWTSecret)
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.RefreshToken)

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(cfg.JWTSecret, userService))
		{
			// User
			userHandler := handler.NewUserHandler(userService)
			protected.GET("/users/me", userHandler.GetProfile)
			protected.PUT("/users/me", userHandler.UpdateProfile)

			// GPU models
			gpuHandler := handler.NewGPUHandler(gpuSvc)
			protected.GET("/gpu/models", gpuHandler.ListModels)
			protected.GET("/gpu/models/:id", gpuHandler.GetModel)

			// Instances
			instanceHandler := handler.NewInstanceHandler(instanceService)
			protected.GET("/instances", instanceHandler.ListInstances)
			protected.POST("/instances", instanceHandler.CreateInstance)
			protected.GET("/instances/:id", instanceHandler.GetInstance)
			protected.POST("/instances/:id/start", instanceHandler.StartInstance)
			protected.POST("/instances/:id/stop", instanceHandler.StopInstance)
			protected.DELETE("/instances/:id", instanceHandler.ReleaseInstance)
			protected.GET("/instances/:id/ssh", instanceHandler.GetSSHInfo)

			// Billing
			billingHandler := handler.NewBillingHandler(billingService)
			protected.GET("/billing/balance", billingHandler.GetBalance)
			protected.GET("/billing/records", billingHandler.ListRecords)
			protected.POST("/billing/recharge", billingHandler.Recharge)

			// Monitor
			monitorHandler := handler.NewMonitorHandler(monitorService)
			protected.GET("/instances/:id/metrics", monitorHandler.GetMetrics)
		}
	}

	// Start server
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%d", cfg.Port),
		Handler: r,
	}

	go func() {
		logger.Info("Server starting", zap.Int("port", cfg.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Server failed", zap.Error(err))
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}
	logger.Info("Server exited")
}

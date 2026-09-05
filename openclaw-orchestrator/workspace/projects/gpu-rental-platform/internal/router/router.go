package router

import (
	"database/sql"
	"net/http"

	"gpu-rental-platform/internal/handler"
	"gpu-rental-platform/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// Setup initializes all routes
func Setup(db *sql.DB, rdb *redis.Client) *gin.Engine {
	r := gin.New()

	// Initialize handlers
	authHandler := handler.NewAuthHandler(db)
	instanceHandler := handler.NewInstanceHandler(db)
	orderHandler := handler.NewOrderHandler(db)
	apikeyHandler := handler.NewAPIKeyHandler(db)

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "gpu-rental-platform"})
	})

	// Public routes
	api := r.Group("/api/v1")
	{
		// Auth
		api.POST("/auth/register", authHandler.Register)
		api.POST("/auth/login", authHandler.Login)

		// GPU prices (public)
		api.GET("/gpu/prices", instanceHandler.GetGPUPrices)
	}

	// Protected routes
	protected := api.Group("")
	protected.Use(middleware.JWTAuth())
	{
		// User
		protected.GET("/user/me", authHandler.GetMe)

		// Instances
		protected.POST("/instances", instanceHandler.CreateInstance)
		protected.GET("/instances", instanceHandler.ListInstances)
		protected.POST("/instances/:id/stop", instanceHandler.StopInstance)
		protected.DELETE("/instances/:id", instanceHandler.DeleteInstance)

		// Orders & Billing
		protected.POST("/orders", orderHandler.CreateOrder)
		protected.GET("/orders", orderHandler.ListOrders)
		protected.GET("/usage", orderHandler.GetUsage)

		// API Keys
		protected.POST("/api-keys", apikeyHandler.CreateKey)
		protected.GET("/api-keys", apikeyHandler.ListKeys)
		protected.DELETE("/api-keys/:id", apikeyHandler.RevokeKey)
	}

	// Admin routes (no auth middleware for now, add admin auth later)
	admin := api.Group("/admin")
	{
		admin.GET("/instances", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "admin: list all instances"})
		})
		admin.GET("/users", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "admin: list all users"})
		})
		admin.POST("/billing/run", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "admin: trigger billing cycle"})
		})
	}

	return r
}

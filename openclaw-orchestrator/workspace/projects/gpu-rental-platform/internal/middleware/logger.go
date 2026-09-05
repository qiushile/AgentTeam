package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
)

// RequestID adds a unique request ID to each request
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := fmt.Sprintf("req-%d", time.Now().UnixNano())
		c.Set("request_id", requestID)
		c.Writer.Header().Set("X-Request-ID", requestID)
		c.Next()
	}
}

// Recovery is a custom recovery middleware
func Recovery() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		c.JSON(500, gin.H{
			"error": "internal server error",
		})
	})
}

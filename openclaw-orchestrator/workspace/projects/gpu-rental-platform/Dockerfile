FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files first for caching
COPY go.mod go.sum* ./
RUN go mod download || true

# Copy source code
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/gpu-platform ./cmd/server

# Final image
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /app/gpu-platform .

EXPOSE 8080

CMD ["./gpu-platform"]

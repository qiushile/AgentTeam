package services

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
)

// InitDB initializes PostgreSQL connection
func InitDB(dsn string) (*sql.DB, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		return nil, err
	}

	log.Println("✅ PostgreSQL connected successfully")
	return db, nil
}

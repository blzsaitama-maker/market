package main

import (
	"log"
	"market/internal/server"
)

func main() {
	srv := server.New()
	log.Println("Starting server on :8080")
	if err := srv.Start(":8080"); err != nil {
		log.Fatalf("could not start server: %v", err)
	}
}

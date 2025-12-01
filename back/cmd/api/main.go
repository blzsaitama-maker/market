package main

import (
	"log"
	"os"
	"github.com/daniel/market/back/internal/database"
	"github.com/daniel/market/back/internal/server"
)

func main() {
	// 1. Configurar o arquivo de log
	// Abre o arquivo 'backend.log'. Cria se não existir e anexa novos logs ao final.
	logFile, err := os.OpenFile("backend.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatalf("Erro ao abrir o arquivo de log: %v", err)
	}
	defer logFile.Close()

	// Direciona a saída do log para o arquivo que abrimos.
	log.SetOutput(logFile)
	// Define o formato do prefixo do log para incluir data, hora e arquivo/linha.
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	log.Println("Aplicação iniciada. Logs serão gravados em backend.log")

	// 2. Conectar ao banco de dados
	db, err := database.Connect()
	if err != nil {
		log.Fatalf("Não foi possível conectar ao banco de dados: %v", err)
	}
	defer db.Close()

	// 3. Iniciar o servidor
	srv := server.New(db)
	log.Println("Servidor escutando na porta :8080")
	if err := srv.Start(":8080"); err != nil {
		log.Fatalf("Não foi possível iniciar o servidor: %v", err)
	}
}

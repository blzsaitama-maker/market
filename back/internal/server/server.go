package server

import (
	"database/sql"
	"net/http"

	"github.com/daniel/market/back/internal/product" // Importa o pacote product
	"github.com/gorilla/mux"
)

// Server holds the router and database connection.
type Server struct {
	router         *mux.Router
	db             *sql.DB
	productHandler *product.Handler // Adiciona o handler de produto
}

// New creates a new Server instance.
func New(db *sql.DB) *Server {
	productHandler := product.NewHandler(db) // Cria uma nova instância do handler de produto
	s := &Server{
		router:         mux.NewRouter(),
		db:             db,
		productHandler: productHandler, // Atribui ao servidor
	}
	s.router.Use(s.loggingMiddleware) // Aplica o middleware de logging a todas as rotas
	s.routes()
	return s
}

// Start starts the HTTP server.
func (s *Server) Start(addr string) error {
	return http.ListenAndServe(addr, s.router)
}

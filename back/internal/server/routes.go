package server

import (
	"net/http"
)

func (s *Server) routes() {
	s.router.HandleFunc("/", s.handleRoot()).Methods(http.MethodGet)

	s.router.HandleFunc("/products", s.productHandler.ListProducts).Methods(http.MethodGet)
	s.router.HandleFunc("/products", s.productHandler.CreateProduct).Methods(http.MethodPost)
	s.router.HandleFunc("/products/{id}", s.productHandler.GetProduct).Methods(http.MethodGet)
	s.router.HandleFunc("/products/{id}", s.productHandler.UpdateProduct).Methods(http.MethodPut)
	s.router.HandleFunc("/products/{id}", s.productHandler.DeleteProduct).Methods(http.MethodDelete)
}

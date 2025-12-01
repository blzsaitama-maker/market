package server

import (
	"log"
	"net/http"
	"time"
)

// loggingMiddleware registra cada requisição recebida.
func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// O `next.ServeHTTP` passa a requisição para o próximo handler na cadeia.
		next.ServeHTTP(w, r)

		// Após o handler ter processado, registramos os detalhes.
		log.Printf(
			"%s %s %s %s",
			r.Method, r.RequestURI, r.Proto, time.Since(start),
		)
	})
}

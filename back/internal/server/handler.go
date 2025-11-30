package server

import (
	"fmt"
	"net/http"
)

func (s *Server) handleRoot() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "API online!")
	}
}

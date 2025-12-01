package product

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux" // Will be used for parsing path variables
)

// Handler provides product related API endpoints.
type Handler struct {
	DB *sql.DB
}

// NewHandler creates a new product handler.
func NewHandler(db *sql.DB) *Handler {
	return &Handler{DB: db}
}

// ListProducts handles GET requests to /products
func (h *Handler) ListProducts(w http.ResponseWriter, r *http.Request) {
	rows, err := h.DB.Query("SELECT product_id, name, description, category_id, supplier_id, sale_price, purchase_price, barcode FROM Products")
	if err != nil {
		log.Printf("ListProducts: Error querying products: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	products := []Product{}
	for rows.Next() {
		var p Product
		if err := rows.Scan(&p.ProductID, &p.Name, &p.Description, &p.CategoryID, &p.SupplierID, &p.SalePrice, &p.PurchasePrice, &p.Barcode); err != nil {
			log.Printf("ListProducts: Error scanning product row: %v", err)
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			return
		}
		products = append(products, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

// GetProduct handles GET requests to /products/{id}
func (h *Handler) GetProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	row := h.DB.QueryRow("SELECT product_id, name, description, category_id, supplier_id, sale_price, purchase_price, barcode FROM Products WHERE product_id = ?", id)

	var p Product
	err = row.Scan(&p.ProductID, &p.Name, &p.Description, &p.CategoryID, &p.SupplierID, &p.SalePrice, &p.PurchasePrice, &p.Barcode)
	if err == sql.ErrNoRows {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	} else if err != nil {
		log.Printf("GetProduct: Error scanning product: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p)
}

// CreateProduct handles POST requests to /products
func (h *Handler) CreateProduct(w http.ResponseWriter, r *http.Request) {
	var p Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation (more comprehensive validation might be needed)
	if p.Name == "" || p.SalePrice <= 0 || p.PurchasePrice < 0 {
		http.Error(w, "Name and SalePrice are required, SalePrice must be positive and PurchasePrice must be non-negative", http.StatusBadRequest)
		return
	}

	result, err := h.DB.Exec(
		"INSERT INTO Products (name, description, category_id, supplier_id, sale_price, purchase_price, barcode) VALUES (?, ?, ?, ?, ?, ?, ?)",
		p.Name, p.Description, p.CategoryID, p.SupplierID, p.SalePrice, p.PurchasePrice, p.Barcode,
	)
	if err != nil {
		log.Printf("CreateProduct: Error inserting product: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	id, err := result.LastInsertId()
	if err != nil {
		log.Printf("CreateProduct: Error getting last insert ID: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	p.ProductID = int(id) // Assign the newly generated ID

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(p)
}

// UpdateProduct handles PUT requests to /products/{id}
func (h *Handler) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	var p Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation
	if p.Name == "" || p.SalePrice <= 0 || p.PurchasePrice < 0 {
		http.Error(w, "Name and SalePrice are required, SalePrice must be positive and PurchasePrice must be non-negative", http.StatusBadRequest)
		return
	}

	// Ensure the ID from the URL path is used for the update, not potentially from the body
	p.ProductID = id

	_, err = h.DB.Exec(
		"UPDATE Products SET name = ?, description = ?, category_id = ?, supplier_id = ?, sale_price = ?, purchase_price = ?, barcode = ? WHERE product_id = ?",
		p.Name, p.Description, p.CategoryID, p.SupplierID, p.SalePrice, p.PurchasePrice, p.Barcode, p.ProductID,
	)
	if err != nil {
		log.Printf("UpdateProduct: Error updating product: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(p) // Return the updated product
}

// DeleteProduct handles DELETE requests to /products/{id}
func (h *Handler) DeleteProduct(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid product ID", http.StatusBadRequest)
		return
	}

	result, err := h.DB.Exec("DELETE FROM Products WHERE product_id = ?", id)
	if err != nil {
		log.Printf("DeleteProduct: Error deleting product: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("DeleteProduct: Error getting rows affected: %v", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent) // 204 No Content for successful deletion
}

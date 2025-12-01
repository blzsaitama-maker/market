package product

import (
	"database/sql"
	"time" // Though not in schema, good to have for future fields like CreatedAt/UpdatedAt
)

// Product represents a product in the market.db database.
type Product struct {
	ProductID   int            `json:"product_id"`
	Name        string         `json:"name"`
	Description sql.NullString `json:"description"`
	CategoryID  sql.NullInt64  `json:"category_id"`
	SupplierID  sql.NullInt64  `json:"supplier_id"`
	SalePrice   float64        `json:"sale_price"`
	PurchasePrice float64      `json:"purchase_price"` // Added purchase_price
	Barcode     sql.NullString `json:"barcode"` // Barcode is UNIQUE, but can be NULL in case of manual product creation.
	// Add other fields from setup_db.go if necessary, e.g., created_at, updated_at
}

// Category represents a product category.
type Category struct {
	CategoryID int    `json:"category_id"`
	Name       string `json:"name"`
}

// Supplier represents a product supplier.
type Supplier struct {
	SupplierID int    `json:"supplier_id"`
	Name       string `json:"name"`
}

// Inventory represents product inventory details.
// Based on the 'Inventory' table in setup_db.go
type Inventory struct {
	InventoryID int       `json:"inventory_id"`
	ProductID   int       `json:"product_id"`
	Quantity    int       `json:"quantity"`
	Location    string    `json:"location"`
	LastUpdated time.Time `json:"last_updated"`
}
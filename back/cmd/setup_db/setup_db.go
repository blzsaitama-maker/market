
package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	db, err := sql.Open("sqlite3", "./market.db")
	if err != nil {
		log.Fatal("failed to open database: ", err)
	}
	defer db.Close()

	sqlScript := `
-- #######################################################################
-- # 1. TABELAS DE ESTRUTURA E RELACIONAMENTO BÁSICO
-- #######################################################################

-- 1.1 Tabela de Categorias
CREATE TABLE IF NOT EXISTS Categories (
    category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name VARCHAR(50) UNIQUE NOT NULL
);

-- 1.2 Tabela de Fornecedores
CREATE TABLE IF NOT EXISTS Suppliers (
    supplier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    company_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone_number VARCHAR(20)
);

-- 1.3 Tabela de Produtos
CREATE TABLE IF NOT EXISTS Products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES Categories(category_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    supplier_id INTEGER REFERENCES Suppliers(supplier_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    sale_price NUMERIC(10, 2) NOT NULL CHECK (sale_price > 0),
    purchase_price NUMERIC(10, 2) NOT NULL CHECK (purchase_price >= 0), -- Allow 0 for initial entry or if cost is unknown
    barcode VARCHAR(50) UNIQUE
);

-- #######################################################################
-- # 2. TABELAS DE PESSOAS E ACESSO
-- #######################################################################

-- 2.1 Tabela de Clientes
CREATE TABLE IF NOT EXISTS Customers (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    address TEXT
);

-- 2.2 Tabela de Funcionários (Dados Pessoais)
CREATE TABLE IF NOT EXISTS Employees (
    employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(50),
    hire_date DATE NOT NULL,
    salary NUMERIC(10, 2)
);

-- 2.3 Tabela de Papéis/Permissões
CREATE TABLE IF NOT EXISTS Roles (
    role_id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- 2.4 Tabela de Usuários do Sistema (Login)
CREATE TABLE IF NOT EXISTS System_Users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER UNIQUE REFERENCES Employees(employee_id) ON UPDATE CASCADE ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role_id INTEGER REFERENCES Roles(role_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE
);

-- #######################################################################
-- # 3. TABELAS DE ESTOQUE E LOGÍSTICA (Lotes, Validade, Localização)
-- #######################################################################

-- 3.1 Tabela de Lotes (para controle de validade e custo)
CREATE TABLE IF NOT EXISTS Batches (
    batch_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER REFERENCES Products(product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    batch_code VARCHAR(50),
    expiration_date DATE NOT NULL,
    quantity_received INTEGER NOT NULL,
    purchase_price NUMERIC(10, 2),
    date_received TIMESTAMP NOT NULL,
    UNIQUE (product_id, batch_code)
);

-- 3.2 Tabela de Inventário (Estoque por Localização)
CREATE TABLE IF NOT EXISTS Inventory (
    inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id INTEGER REFERENCES Batches(batch_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    location VARCHAR(50) NOT NULL, 
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0),
    last_moved TIMESTAMP WITH TIME ZONE,
    UNIQUE (batch_id, location)
);

-- #######################################################################
-- # 4. TABELAS DE TRANSAÇÕES DE VENDA
-- #######################################################################

-- 4.1 Tabela de Vendas (Cabeçalho da Transação)
CREATE TABLE IF NOT EXISTS Sales (
    sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER REFERENCES Customers(customer_id) ON UPDATE CASCADE ON DELETE SET NULL,
    employee_id INTEGER REFERENCES Employees(employee_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    sale_datetime TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(50)
);

-- 4.2 Tabela de Itens de Venda (Detalhes da Transação)
CREATE TABLE IF NOT EXISTS Sale_Items (
    sale_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id INTEGER REFERENCES Sales(sale_id) ON UPDATE CASCADE ON DELETE CASCADE,
    product_id INTEGER REFERENCES Products(product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_sold NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL,
    discount_amount NUMERIC(10, 2) DEFAULT 0,
    UNIQUE (sale_id, product_id)
);
	`
	_, err = db.Exec(sqlScript)
	if err != nil {
		log.Fatalf("failed to execute schema script: %v", err)
	}

	log.Println("Database schema created successfully.")

	// --- Insert Admin User ---

	// 1. Insert Role
	var roleID int64
	err = db.QueryRow("INSERT INTO Roles (role_name) VALUES ('Admin') ON CONFLICT(role_name) DO UPDATE SET role_name = excluded.role_name RETURNING role_id;").Scan(&roleID)
    if err != nil {
        // If it already exists, query it
        if err.Error() == "Scan error on column index 0, name \"role_id\": converting NULL to int64 is unsupported" || err.Error() == "sql: no rows in return" {
             err = db.QueryRow("SELECT role_id FROM Roles WHERE role_name = 'Admin'").Scan(&roleID)
             if err != nil {
                log.Fatalf("failed to get admin role id: %v", err)
             }
        } else {
		    log.Fatalf("failed to insert or get admin role: %v", err)
        }
	}


	// 2. Insert Employee
	var employeeID int64
	res, err := db.Exec("INSERT INTO Employees (first_name, last_name, job_title, hire_date) VALUES ('Admin', 'User', 'Administrator', CURRENT_DATE);")
	if err != nil {
		log.Fatalf("failed to insert admin employee: %v", err)
	}
	employeeID, err = res.LastInsertId()
	if err != nil {
		log.Fatalf("failed to get last insert id for employee: %v", err)
	}

	// 3. Insert System User
	// WARNING: Storing password in plain text. This is insecure.
	password := "84573651"
	_, err = db.Exec("INSERT INTO System_Users (employee_id, username, password_hash, role_id) VALUES (?, ?, ?, ?)", employeeID, "admin", password, roleID)
	if err != nil {
		log.Fatalf("failed to insert admin user: %v", err)
	}

	log.Println("Admin user created successfully with username 'admin' and the provided password.")
	log.Println("SECURITY WARNING: The password is NOT hashed. This is insecure and should be fixed.")
}

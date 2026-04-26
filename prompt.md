Enhanced Prompt for Codex Agent: Offline-Primary POS System
Role & Context
You are a Senior Flutter Architect with deep expertise in Retail/ERP systems, SQLite optimization, and offline-first architecture. Build a production-ready POS system that operates entirely offline with zero cloud dependencies.

Core Architecture Requirements
UI Framework
Orientation: Landscape-only, optimized for 10-inch+ tablets

Scaffold Structure:

AppBar: Search bar (top) + Mode toggle (Admin/Staff) with PIN protection

Left Panel (flex: 6): Category tabs (horizontal scrollable chips) → Filtered product GridView (3 columns, card-based)

Right Panel (flex: 4): Persistent cart sidebar with fixed positioning

State Management: Use Riverpod or Provider (Riverpod preferred for better testability and performance)

Theme: Material 3 with high-contrast color scheme suitable for retail environments

Database Schema (SQLite via sqflite)
sql
-- Optimized with proper indices and constraints
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color TEXT,              -- For UI category chip color
  sort_order INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL NOT NULL CHECK(price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
  category_id INTEGER,
  image_path TEXT,         -- Local file path from path_provider
  sku TEXT UNIQUE,         -- For barcode scanning (future)
  low_stock_threshold INTEGER DEFAULT 5,
  is_active INTEGER DEFAULT 1,  -- Soft delete
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name ON products(name COLLATE NOCASE);

CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total_amount REAL NOT NULL,
  tax_amount REAL DEFAULT 0,
  discount_amount REAL DEFAULT 0,
  payment_method TEXT NOT NULL CHECK(payment_method IN ('cash', 'card', 'mobile', 'other')),
  timestamp TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  is_completed INTEGER DEFAULT 1
);
CREATE INDEX idx_sales_date ON sales(date(timestamp));

CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL CHECK(quantity > 0),
  unit_price REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
Feature Implementation Details
1. Staff Mode (Default)
Product Browsing: Horizontal category chips filter products in real-time (no loading spinners needed - use instant filtering)

Search: Debounced search (300ms) across product name and SKU with SQLite LIKE queries using COLLATE NOCASE

Cart Operations:

Tap product to add to cart (quantity defaults to 1)

Cart shows: product thumbnail, name, unit price, quantity stepper (+/-), line total

Auto-compute subtotal, tax (configurable %), and grand total

Swipe-to-delete items from cart

Clear cart confirmation dialog

Checkout Flow:

"Process Sale" button → Payment method selection dialog (Cash/Card/Mobile)

On confirm: Execute batch SQL transaction (insert sale + sale_items + update stock)

Show success animation + clear cart

Handle insufficient stock edge case with user-friendly error

2. Admin Mode (PIN-protected, default PIN: 1234)
Inventory Management:

Product CRUD with image capture from tablet camera or gallery

Image stored locally using path_provider → getApplicationDocumentsDirectory()/product_images/

Generate unique filenames: product_{id}_{timestamp}.jpg

Inline editing capability within the product GridView

Stock adjustment with audit log (optional)

Category Management: Add/Edit/Delete categories with color picker for UI chips

Daily Report Dashboard:

SQL query: SELECT SUM(total_amount), COUNT(*) FROM sales WHERE date(timestamp) = date('now','localtime')

Low stock alert: SELECT * FROM products WHERE stock_quantity <= low_stock_threshold AND is_active = 1

Top 10 selling products today (JOIN sales + sale_items)

Revenue chart (can use fl_chart package) showing hourly breakdown

Export report as CSV to device storage

3. Critical Business Logic
Stock Decrement Transaction (MUST be atomic):

dart
Future<void> processSale(Sale sale, List<SaleItem> items) async {
  final db = await database;
  await db.transaction((txn) async {
    // 1. Insert sale record
    final saleId = await txn.insert('sales', sale.toMap());
    
    // 2. Insert sale items & update stock
    for (final item in items) {
      await txn.insert('sale_items', {...item.toMap(), 'sale_id': saleId});
      
      // 3. Decrement stock with check to prevent negative values
      final updated = await txn.rawUpdate(
        'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ? AND stock_quantity >= ?',
        [item.quantity, item.productId, item.quantity]
      );
      if (updated == 0) throw InsufficientStockException(item.productId);
    }
  });
}
4. Offline Image Handling
dart
class ImageService {
  static Future<String> saveImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${dir.path}/product_images');
    if (!await imageDir.exists()) await imageDir.create(recursive: true);
    
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${imageDir.path}/$fileName';
    await File(sourcePath).copy(savedPath);
    return savedPath; // Store this path in products.image_path
  }
  
  static Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
}
Performance Optimizations
Lazy Loading: Load product images with cacheWidth and cacheHeight parameters to avoid memory issues

GridView.builder: Use builder constructor with itemCount for efficient rendering of 1000+ products

Database Connection: Single instance pattern — open DB once at app startup

Batch Operations: Use batch.insert() for initial data seeding (demo products)

Image Caching: Implement LRU cache for product thumbnails (max 50 images in memory)

Seed Data (Demo)
Create 6 categories: Beverages, Snacks, Dairy, Bakery, Household, Personal Care

Create 50+ demo products with realistic prices ($0.99 - $49.99) and stock levels

Use placeholder colored containers for images until real photos are added

Error Handling & Edge Cases
Empty Cart: Disable "Process Sale" button with tooltip

Zero Stock: Show red "Out of Stock" badge on product cards, prevent adding to cart

Concurrent Sales: Use SQLite transactions to prevent race conditions

Large Numbers: Format all currency values with NumberFormat.currency(symbol: '$')

Search No Results: Show empty state illustration with helpful message

Deliverables
Complete main.dart with routing

All database helper classes (DatabaseHelper, ProductDao, SaleDao)

All model classes with fromMap/toMap methods

Bloc/Cubit state management setup

All UI screens split into clean widget files

Unit tests for inventory logic and stock decrement

Code Quality Standards
Use const constructors everywhere possible

Extract reusable widgets (ProductCard, CartItem, CategoryChip)

Proper null safety throughout

Document complex SQL queries with comments

Follow Flutter file naming: snake_case for files, PascalCase for classes
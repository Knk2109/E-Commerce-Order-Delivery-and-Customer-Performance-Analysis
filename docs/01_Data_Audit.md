# Data Audit Report

## Project

Olist E-Commerce Data Warehouse & Business Intelligence Analysis

---

## Audit Objective

The purpose of this audit was to assess data quality, validate record integrity, identify missing values and duplicates, and ensure that the datasets were suitable for dimensional modeling, SQL analytics, and Power BI reporting.

---

## Source Datasets

| Dataset                |    Records |
| ---------------------- | ---------: |
| Customers              |     99,441 |
| Orders                 |     99,441 |
| Order Items            |    112,650 |
| Payments               |    103,886 |
| Reviews                |     99,224 |
| Products               |     32,951 |
| Sellers                |      3,095 |
| Geolocation (Original) | ~1,000,000 |

---

## Data Quality Checks Performed

### 1. Record Count Validation

* Verified successful loading of all source datasets into PostgreSQL.
* Confirmed row counts between source files and database tables.

### 2. Duplicate Record Analysis

* Conducted duplicate checks across all datasets.
* Identified approximately 268,000 duplicate records in the Geolocation dataset.
* Removed duplicate records based on identical zip code, city, and state combinations.
* Final Geolocation table contained 738,332 unique records.

### 3. Primary Key Validation

Validated uniqueness of primary keys across all major datasets:

| Table     | Primary Key |
| --------- | ----------- |
| Customers | customer_id |
| Orders    | order_id    |
| Products  | product_id  |
| Sellers   | seller_id   |
| Reviews   | review_id   |

No duplicate primary key violations were detected.

### 4. Null Value Assessment

Key findings:

| Column                        | Null Records |
| ----------------------------- | -----------: |
| order_approved_at             |          160 |
| order_delivered_carrier_date  |        1,783 |
| order_delivered_customer_date |        2,965 |

Observation:

* Missing delivery-related dates were primarily associated with cancelled, unavailable, invoiced, processing, and shipped orders.
* Null values were retained where they represented valid business scenarios.

### 5. Data Type Validation

Verified and standardized:

* Date fields → TIMESTAMP / DATE
* Monetary fields → NUMERIC
* IDs → VARCHAR
* Review Scores → INTEGER

### 6. Product Category Standardization

* Mapped Portuguese product category names to English using the category translation dataset.
* Addressed blank and missing category values where applicable.

### 7. Referential Integrity Checks

Validated relationships between:

* Orders ↔ Customers
* Order Items ↔ Orders
* Order Items ↔ Products
* Order Items ↔ Sellers
* Payments ↔ Orders
* Reviews ↔ Orders

No significant referential integrity issues were identified.

---

## Audit Conclusion

The datasets successfully passed data quality validation and were approved for downstream transformation into a dimensional data warehouse.

Key outcomes:

* Duplicate geolocation records removed.
* Primary key uniqueness confirmed.
* Data types standardized.
* Product categories translated and cleaned.
* Referential integrity verified.
* Data prepared for Star Schema modeling, SQL analytics, and Power BI dashboard development.

Status: PASSED

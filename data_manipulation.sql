/* Customer dataset */
SELECT * 
FROM `cogent-sweep-446018-f5.Customers.customers`
LIMIT 10;

SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Customers.customers` ;

/* have to repeat for other datasets as well */
/* Geolocation */
SELECT * 
FROM `cogent-sweep-446018-f5.Geolocation.geolocation`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Geolocation.geolocation`;

/* Order Items*/
SELECT * 
FROM `cogent-sweep-446018-f5.Order_Items.order_items`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Order_Items.order_items`;

/*Orders */
SELECT * 
FROM `cogent-sweep-446018-f5.Orders.orders`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Orders.orders`;


/*Payments*/
SELECT * 
FROM `cogent-sweep-446018-f5.Payments.payments`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Payments.payments`;

/* Products */
SELECT * 
FROM `cogent-sweep-446018-f5.Products.products`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Products.products`;


/*Sellers */
SELECT * 
FROM `cogent-sweep-446018-f5.Sellers.sellers`
LIMIT 10;
SELECT COUNT(*) 
FROM `cogent-sweep-446018-f5.Sellers.sellers`;


------ #Transform --------

-- #Customers (NA Removal)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Customers.cleaned_customers` AS
SELECT DISTINCT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    COALESCE(customer_city, 'Unknown') AS customer_city,
    UPPER(customer_state) AS customer_state
FROM `cogent-sweep-446018-f5.Customers.customers`;

-- #Geolocation (NA Removal and Standardization)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Geolocation.cleaned_geolocation` AS
SELECT DISTINCT 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    COALESCE(geolocation_city, 'Unknown') AS geolocation_city,
    UPPER(geolocation_state) AS geolocation_state
FROM `cogent-sweep-446018-f5.Geolocation.geolocation`;

-- #Order Items (NA Removal and Calculated Total Cost)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Order_Items.cleaned_order_items` AS
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    COALESCE(price, 0) AS price,
    COALESCE(freight_value, 0) AS freight_value,
    (COALESCE(price, 0) + COALESCE(freight_value, 0)) AS total_cost
FROM `cogent-sweep-446018-f5.Order_Items.order_items`;

-- #Orders (Standardizing Status)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Orders.cleaned_orders` AS
SELECT 
    order_id,
    customer_id,
    UPPER(order_status) AS order_status
FROM `cogent-sweep-446018-f5.Orders.orders`;


-- #Payments (NA Removal and Standardization)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Payments.cleaned_payments` AS
SELECT 
    order_id,
    payment_sequential,
    UPPER(payment_type) AS payment_type,
    COALESCE(payment_installments, 0) AS payment_installments,
    COALESCE(payment_value, 0) AS payment_value
FROM `cogent-sweep-446018-f5.Payments.payments`;


-- #Sellers (NA Removal and Standardization)
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Sellers.cleaned_sellers` AS
SELECT DISTINCT 
    seller_id,
    seller_zip_code_prefix,
    COALESCE(seller_city, 'Unknown') AS seller_city,
    UPPER(seller_state) AS seller_state
FROM `cogent-sweep-446018-f5.Sellers.sellers`;


-- Join all tables to get comprehensive order details
CREATE OR REPLACE TABLE `cogent-sweep-446018-f5.Joined_Data.Final_Dataset` AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_id,
    o.order_status,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    oi.total_cost,
    p.product_category,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    s.seller_city AS seller_city,
    s.seller_state AS seller_state,
    pay.payment_type,
    pay.payment_value,
    g.geolocation_lat,
    g.geolocation_lng,
    g.geolocation_city AS geo_city,
    g.geolocation_state AS geo_state
FROM 
    `cogent-sweep-446018-f5.Orders.cleaned_orders` o
JOIN 
    `cogent-sweep-446018-f5.Customers.cleaned_customers` c
    ON o.customer_id = c.customer_id
JOIN 
    `cogent-sweep-446018-f5.Order_Items.cleaned_order_items` oi
    ON o.order_id = oi.order_id
JOIN 
    `cogent-sweep-446018-f5.Products.products` p
    ON oi.product_id = p.product_id
JOIN 
    `cogent-sweep-446018-f5.Sellers.cleaned_sellers` s
    ON oi.seller_id = s.seller_id
JOIN 
    `cogent-sweep-446018-f5.Payments.cleaned_payments` pay
    ON o.order_id = pay.order_id
JOIN 
    `cogent-sweep-446018-f5.Geolocation.cleaned_geolocation` g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;


SELECT COUNT(*)
FROM `cogent-sweep-446018-f5.Joined_Data.Final_Dataset` ;



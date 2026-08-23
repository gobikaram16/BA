-- ============================================================
-- BA TASK 3 - WEEK 3
-- Multi-Echelon Supply Chain Network Design
-- Mixed-Integer Linear Programming (MILP)
-- ============================================================

-- 1. CREATE FACTORIES TABLE

CREATE TABLE factories (
    factory_id INT PRIMARY KEY,
    factory_name VARCHAR(100),
    production_capacity INT,
    production_cost DECIMAL(10,2)
);


-- 2. CREATE WAREHOUSES TABLE

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(100),
    storage_capacity INT,
    fixed_cost DECIMAL(10,2)
);


-- 3. CREATE CUSTOMER ZONES TABLE

CREATE TABLE customer_zones (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    demand INT,
    minimum_service_level DECIMAL(5,2)
);


-- 4. FACTORY DATA

INSERT INTO factories VALUES
(1, 'Factory A', 1000, 12.00),
(2, 'Factory B', 1200, 10.00),
(3, 'Factory C', 800, 14.00);


-- 5. WAREHOUSE DATA

INSERT INTO warehouses VALUES
(1, 'Warehouse A', 900, 5000.00),
(2, 'Warehouse B', 1000, 6000.00),
(3, 'Warehouse C', 700, 4500.00);


-- 6. CUSTOMER ZONE DATA

INSERT INTO customer_zones VALUES
(1, 'Customer Zone A', 500, 0.90),
(2, 'Customer Zone B', 600, 0.85),
(3, 'Customer Zone C', 400, 0.90),
(4, 'Customer Zone D', 300, 0.80);


-- ============================================================
-- 7. FACTORY TO WAREHOUSE TRANSPORTATION COST
-- ============================================================

CREATE TABLE factory_warehouse_cost (
    factory_id INT,
    warehouse_id INT,
    transport_cost DECIMAL(10,2),
    max_transport_capacity INT
);


INSERT INTO factory_warehouse_cost VALUES
(1, 1, 4.00, 700),
(1, 2, 6.00, 600),
(1, 3, 8.00, 500),

(2, 1, 5.00, 700),
(2, 2, 4.00, 800),
(2, 3, 7.00, 600),

(3, 1, 6.00, 500),
(3, 2, 5.00, 600),
(3, 3, 4.00, 500);


-- ============================================================
-- 8. WAREHOUSE TO CUSTOMER TRANSPORTATION COST
-- ============================================================

CREATE TABLE warehouse_customer_cost (
    warehouse_id INT,
    customer_id INT,
    transport_cost DECIMAL(10,2),
    max_transport_capacity INT
);


INSERT INTO warehouse_customer_cost VALUES
(1, 1, 3.00, 500),
(1, 2, 5.00, 500),
(1, 3, 6.00, 400),
(1, 4, 7.00, 300),

(2, 1, 4.00, 500),
(2, 2, 3.00, 600),
(2, 3, 5.00, 400),
(2, 4, 6.00, 300),

(3, 1, 6.00, 500),
(3, 2, 5.00, 500),
(3, 3, 3.00, 400),
(3, 4, 4.00, 300);


-- ============================================================
-- 9. DISPLAY FACTORY CAPACITY
-- ============================================================

SELECT
    factory_id,
    factory_name,
    production_capacity,
    production_cost
FROM factories
ORDER BY factory_id;


-- ============================================================
-- 10. DISPLAY WAREHOUSE CAPACITY
-- ============================================================

SELECT
    warehouse_id,
    warehouse_name,
    storage_capacity,
    fixed_cost
FROM warehouses
ORDER BY warehouse_id;


-- ============================================================
-- 11. DISPLAY CUSTOMER DEMAND
-- ============================================================

SELECT
    customer_id,
    customer_name,
    demand,
    minimum_service_level
FROM customer_zones
ORDER BY customer_id;


-- ============================================================
-- 12. FACTORY -> WAREHOUSE CAPACITY CONSTRAINT
-- ============================================================

SELECT
    f.factory_name,
    w.warehouse_name,
    c.transport_cost,
    c.max_transport_capacity
FROM factory_warehouse_cost c
JOIN factories f
    ON c.factory_id = f.factory_id
JOIN warehouses w
    ON c.warehouse_id = w.warehouse_id
ORDER BY f.factory_id, w.warehouse_id;


-- ============================================================
-- 13. WAREHOUSE -> CUSTOMER CAPACITY CONSTRAINT
-- ============================================================

SELECT
    w.warehouse_name,
    c.customer_name,
    t.transport_cost,
    t.max_transport_capacity
FROM warehouse_customer_cost t
JOIN warehouses w
    ON t.warehouse_id = w.warehouse_id
JOIN customer_zones c
    ON t.customer_id = c.customer_id
ORDER BY w.warehouse_id, c.customer_id;


-- ============================================================
-- 14. TOTAL CUSTOMER DEMAND
-- ============================================================

SELECT
    SUM(demand) AS total_customer_demand
FROM customer_zones;


-- ============================================================
-- 15. TOTAL FACTORY PRODUCTION CAPACITY
-- ============================================================

SELECT
    SUM(production_capacity) AS total_factory_capacity
FROM factories;


-- ============================================================
-- 16. CHECK SUPPLY VS DEMAND
-- ============================================================

SELECT
    (SELECT SUM(production_capacity)
     FROM factories) AS total_supply,

    (SELECT SUM(demand)
     FROM customer_zones) AS total_demand,

    (SELECT SUM(production_capacity)
     FROM factories)
    -
    (SELECT SUM(demand)
     FROM customer_zones) AS supply_surplus;


-- ============================================================
-- 17. FACTORY PRODUCTION COST
-- ============================================================

SELECT
    factory_name,
    production_capacity,
    production_cost,
    production_capacity * production_cost AS maximum_production_cost
FROM factories;


-- ============================================================
-- 18. WAREHOUSE FIXED COST
-- ============================================================

SELECT
    warehouse_name,
    storage_capacity,
    fixed_cost
FROM warehouses
ORDER BY fixed_cost;


-- ============================================================
-- 19. CHEAPEST FACTORY -> WAREHOUSE ROUTES
-- ============================================================

SELECT
    factory_id,
    warehouse_id,
    transport_cost,
    max_transport_capacity
FROM factory_warehouse_cost
WHERE transport_cost = (
    SELECT MIN(transport_cost)
    FROM factory_warehouse_cost
)
ORDER BY transport_cost;


-- ============================================================
-- 20. CHEAPEST WAREHOUSE -> CUSTOMER ROUTES
-- ============================================================

SELECT
    warehouse_id,
    customer_id,
    transport_cost,
    max_transport_capacity
FROM warehouse_customer_cost
WHERE transport_cost = (
    SELECT MIN(transport_cost)
    FROM warehouse_customer_cost
)
ORDER BY transport_cost;


-- ============================================================
-- 21. MINIMUM SERVICE LEVEL REQUIREMENT
-- ============================================================

SELECT
    customer_name,
    demand,
    minimum_service_level,

    CEILING(
        demand * minimum_service_level
    ) AS minimum_required_supply

FROM customer_zones
ORDER BY customer_id;


-- ============================================================
-- 22. WAREHOUSE CAPACITY UTILIZATION
-- ============================================================

SELECT
    warehouse_id,
    warehouse_name,
    storage_capacity,

    ROUND(
        storage_capacity * 100.0 /
        (SELECT SUM(storage_capacity)
         FROM warehouses),
        2
    ) AS capacity_percentage

FROM warehouses
ORDER BY warehouse_id;


-- ============================================================
-- 23. TOTAL POTENTIAL TRANSPORTATION COST
-- ============================================================

SELECT
    SUM(
        transport_cost * max_transport_capacity
    ) AS total_factory_warehouse_transport_cost
FROM factory_warehouse_cost;


SELECT
    SUM(
        transport_cost * max_transport_capacity
    ) AS total_warehouse_customer_transport_cost
FROM warehouse_customer_cost;


-- ============================================================
-- 24. COMPLETE NETWORK COST ANALYSIS
-- ============================================================

SELECT
    (
        SELECT SUM(production_capacity * production_cost)
        FROM factories
    ) AS production_cost,

    (
        SELECT SUM(fixed_cost)
        FROM warehouses
    ) AS warehouse_fixed_cost,

    (
        SELECT SUM(transport_cost * max_transport_capacity)
        FROM factory_warehouse_cost
    ) AS factory_warehouse_cost,

    (
        SELECT SUM(transport_cost * max_transport_capacity)
        FROM warehouse_customer_cost
    ) AS warehouse_customer_cost;


-- ============================================================
-- 25. TOTAL SUPPLY CHAIN OPERATING COST
-- ============================================================

SELECT
    (
        SELECT SUM(production_capacity * production_cost)
        FROM factories
    )
    +
    (
        SELECT SUM(fixed_cost)
        FROM warehouses
    )
    +
    (
        SELECT SUM(transport_cost * max_transport_capacity)
        FROM factory_warehouse_cost
    )
    +
    (
        SELECT SUM(transport_cost * max_transport_capacity)
        FROM warehouse_customer_cost
    )
    AS total_supply_chain_cost;


-- ============================================================
-- 26. MILP DECISION VARIABLES
-- ============================================================

CREATE TABLE supply_chain_decisions (
    factory_id INT,
    warehouse_id INT,
    customer_id INT,
    factory_to_warehouse_quantity INT DEFAULT 0,
    warehouse_to_customer_quantity INT DEFAULT 0,
    warehouse_open INT DEFAULT 0
);


-- ============================================================
-- 27. SAMPLE FEASIBLE NETWORK DECISION
-- ============================================================

INSERT INTO supply_chain_decisions
VALUES
(1, 1, 1, 500, 500, 1),
(1, 2, 2, 400, 400, 1),
(2, 2, 3, 400, 400, 1),
(2, 3, 4, 300, 300, 1);


-- ============================================================
-- 28. CHECK FACTORY CAPACITY CONSTRAINT
-- ============================================================

SELECT
    f.factory_name,
    f.production_capacity,
    SUM(s.factory_to_warehouse_quantity) AS allocated_quantity,

    f.production_capacity -
    SUM(s.factory_to_warehouse_quantity) AS remaining_capacity

FROM factories f
JOIN supply_chain_decisions s
    ON f.factory_id = s.factory_id

GROUP BY
    f.factory_id,
    f.factory_name,
    f.production_capacity;


-- ============================================================
-- 29. CHECK WAREHOUSE STORAGE CAPACITY
-- ============================================================

SELECT
    w.warehouse_name,
    w.storage_capacity,
    SUM(s.warehouse_to_customer_quantity) AS allocated_quantity,

    w.storage_capacity -
    SUM(s.warehouse_to_customer_quantity) AS remaining_capacity

FROM warehouses w
JOIN supply_chain_decisions s
    ON w.warehouse_id = s.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    w.storage_capacity;


-- ============================================================
-- 30. CHECK CUSTOMER SERVICE LEVEL
-- ============================================================

SELECT
    c.customer_name,
    c.demand,
    c.minimum_service_level,

    SUM(s.warehouse_to_customer_quantity)
        AS supplied_quantity,

    CEILING(
        c.demand * c.minimum_service_level
    ) AS minimum_required_quantity

FROM customer_zones c
JOIN supply_chain_decisions s
    ON c.customer_id = s.customer_id

GROUP BY
    c.customer_id,
    c.customer_name,
    c.demand,
    c.minimum_service_level;


-- ============================================================
-- 31. FINAL SUPPLY CHAIN COST
-- ============================================================

SELECT
    SUM(
        s.factory_to_warehouse_quantity * fw.transport_cost
    ) AS factory_warehouse_transport_cost,

    SUM(
        s.warehouse_to_customer_quantity * wc.transport_cost
    ) AS warehouse_customer_transport_cost

FROM supply_chain_decisions s

JOIN factory_warehouse_cost fw
    ON s.factory_id = fw.factory_id
    AND s.warehouse_id = fw.warehouse_id

JOIN warehouse_customer_cost wc
    ON s.warehouse_id = wc.warehouse_id
    AND s.customer_id = wc.customer_id;


-- ============================================================
-- END OF WEEK-3 BA TASK
-- ============================================================

-- ============================================
-- BA TASK 4 - WEEK 4
-- High-Performance Market Basket Analytics
-- Compressed FP-Trees from Scratch
-- ============================================

-- 1. CREATE TABLE

CREATE TABLE transactions (
    transaction_id INT,
    item_id INT,
    item_name VARCHAR(100)
);


-- 2. INSERT SAMPLE TRANSACTION DATA

INSERT INTO transactions (transaction_id, item_id, item_name) VALUES
(1, 101, 'Milk'),
(1, 102, 'Bread'),
(1, 103, 'Butter'),

(2, 101, 'Milk'),
(2, 102, 'Bread'),

(3, 101, 'Milk'),
(3, 103, 'Butter'),

(4, 102, 'Bread'),
(4, 103, 'Butter'),

(5, 101, 'Milk'),
(5, 102, 'Bread'),
(5, 103, 'Butter'),

(6, 101, 'Milk'),
(6, 102, 'Bread'),

(7, 101, 'Milk'),
(7, 103, 'Butter'),

(8, 102, 'Bread'),
(8, 103, 'Butter');


-- 3. CHECK TRANSACTION DATA

SELECT *
FROM transactions
ORDER BY transaction_id, item_id;


-- 4. FIND TOTAL NUMBER OF TRANSACTIONS

SELECT COUNT(DISTINCT transaction_id) AS total_transactions
FROM transactions;


-- 5. FIND ITEM FREQUENCY

SELECT
    item_id,
    item_name,
    COUNT(DISTINCT transaction_id) AS support_count,
    ROUND(
        COUNT(DISTINCT transaction_id) * 100.0 /
        (SELECT COUNT(DISTINCT transaction_id)
         FROM transactions),
        2
    ) AS support_percentage
FROM transactions
GROUP BY item_id, item_name
ORDER BY support_count DESC;


-- 6. FIND FREQUENT 2-ITEMSETS

SELECT
    a.item_name AS item1,
    b.item_name AS item2,
    COUNT(DISTINCT a.transaction_id) AS support_count,
    ROUND(
        COUNT(DISTINCT a.transaction_id) * 100.0 /
        (SELECT COUNT(DISTINCT transaction_id)
         FROM transactions),
        2
    ) AS support_percentage
FROM transactions a
JOIN transactions b
    ON a.transaction_id = b.transaction_id
    AND a.item_id < b.item_id
GROUP BY a.item_name, b.item_name
ORDER BY support_count DESC;


-- 7. FIND FREQUENT 3-ITEMSETS

SELECT
    a.item_name AS item1,
    b.item_name AS item2,
    c.item_name AS item3,
    COUNT(DISTINCT a.transaction_id) AS support_count
FROM transactions a
JOIN transactions b
    ON a.transaction_id = b.transaction_id
    AND a.item_id < b.item_id
JOIN transactions c
    ON a.transaction_id = c.transaction_id
    AND b.item_id < c.item_id
GROUP BY
    a.item_name,
    b.item_name,
    c.item_name
ORDER BY support_count DESC;


-- 8. FIND ITEMS WITH MINIMUM SUPPORT OF 40%

SELECT
    item_id,
    item_name,
    COUNT(DISTINCT transaction_id) AS support_count
FROM transactions
GROUP BY item_id, item_name
HAVING COUNT(DISTINCT transaction_id) >=
       0.40 *
       (SELECT COUNT(DISTINCT transaction_id)
        FROM transactions)
ORDER BY support_count DESC;


-- 9. MILK -> BREAD ASSOCIATION RULE

WITH total_transactions AS (
    SELECT COUNT(DISTINCT transaction_id) AS total
    FROM transactions
),
milk_count AS (
    SELECT COUNT(DISTINCT transaction_id) AS total
    FROM transactions
    WHERE item_name = 'Milk'
),
bread_count AS (
    SELECT COUNT(DISTINCT transaction_id) AS total
    FROM transactions
    WHERE item_name = 'Bread'
),
milk_bread_count AS (
    SELECT COUNT(DISTINCT a.transaction_id) AS total
    FROM transactions a
    JOIN transactions b
        ON a.transaction_id = b.transaction_id
    WHERE a.item_name = 'Milk'
      AND b.item_name = 'Bread'
)

SELECT
    'Milk -> Bread' AS association_rule,

    milk_bread_count.total AS support_count,

    ROUND(
        milk_bread_count.total * 100.0 /
        total_transactions.total,
        2
    ) AS support_percentage,

    ROUND(
        milk_bread_count.total * 100.0 /
        milk_count.total,
        2
    ) AS confidence_percentage,

    ROUND(
        (
            milk_bread_count.total * 1.0 /
            milk_count.total
        )
        /
        (
            bread_count.total * 1.0 /
            total_transactions.total
        ),
        2
    ) AS lift

FROM total_transactions,
     milk_count,
     bread_count,
     milk_bread_count;


-- 10. TOP FREQUENT ITEMSETS

SELECT
    item_name,
    COUNT(DISTINCT transaction_id) AS frequency
FROM transactions
GROUP BY item_name
ORDER BY frequency DESC;

select * from film f;
select*from country c2;
select*from city;

--Melihat Pendapatan Per Negara
SELECT
    c2.country AS Negara,
    SUM(p.amount) AS total_revenue
FROM country c2
JOIN city c 
    ON c2.country_id = c.country_id
JOIN address a 
    ON c.city_id = a.city_id
JOIN customer cu 
    ON a.address_id = cu.address_id
JOIN payment p 
    ON cu.customer_id = p.customer_id
GROUP BY c2.country
ORDER BY total_revenue DESC;

--Melihat Jumlah Pendapatan filem
SELECT
    f.title AS film_title,
    SUM(p.amount) AS total_revenue
FROM film f
JOIN inventory i 
    ON f.film_id = i.film_id
JOIN rental r 
    ON i.inventory_id = r.inventory_id
JOIN payment p 
    ON r.rental_id = p.rental_id
GROUP BY f.title
ORDER BY total_revenue DESC;

--Melihat Jumlah Sewa
SELECT
    f.title AS film_title,
    COUNT(r.rental_id) AS jumlah_sewa
FROM film f
JOIN inventory i 
    ON f.film_id = i.film_id
JOIN rental r 
    ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY jumlah_sewa DESC;

--Understanding data
select*from customer c;
select* from payment p;
select*from inventory i;
select*from rental r;

--Melihat Frequensi dan Monetery
WITH rfm_base AS (
    SELECT
        c.customer_id,
        MAX(r.rental_date) AS last_rental_date,
        COUNT(r.rental_id) AS frequency,
        SUM(p.amount) AS monetary
    FROM customer c
    JOIN rental r 
        ON c.customer_id = r.customer_id
    JOIN payment p 
        ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
)
SELECT * FROM rfm_base;

--Melihat Recency , Frequensy dan Monetery
WITH rfm_cacl AS (
    SELECT
        c.customer_id,
        MAX(r.rental_date) AS last_rental_date,
        COUNT(r.rental_id) AS frequency,
        SUM(p.amount) AS monetary
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
)
SELECT
    customer_id,
    (DATE '2006-03-15' - last_rental_date::date) AS recency,
    frequency,
    monetary
FROM rfm_cacl;

--Melihat Score RFM dan score
WITH rfm_base AS (
    SELECT
        c.customer_id,
        MAX(r.rental_date) AS last_rental_date,
        COUNT(r.rental_id) AS frequency,
        SUM(p.amount) AS monetary
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
),
rfm_calc AS (
    SELECT
        customer_id,
        (DATE '2006-03-15' - last_rental_date::date) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(3) OVER (ORDER BY frequency) AS f_score,
        NTILE(3) OVER (ORDER BY monetary) AS m_score
    FROM rfm_calc
)
SELECT * FROM rfm;

-- Segmentasi
WITH rfm_base AS (
    SELECT
        c.customer_id,
        MAX(r.rental_date) AS last_rental_date,
        COUNT(r.rental_id) AS frequency,
        SUM(p.amount) AS monetary
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
),
rfm_calc AS (
    SELECT
        customer_id,
        (DATE '2006-03-15' - last_rental_date::date) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(3) OVER (ORDER BY frequency) AS f_score,
        NTILE(3) OVER (ORDER BY monetary) AS m_score
    FROM rfm_calc
)
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
        WHEN r_score = 5 AND f_score = 3 AND m_score = 3 THEN 'Champion'
        WHEN r_score >= 4 AND f_score >= 2 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score = 1 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 2 AND m_score >= 2 THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Hibernating'
        WHEN r_score = 2 THEN 'Need Attention'
        when r_score = 3 and f_score <=3 and m_score <=3 then 'Potential loyal'
        ELSE 'Others'
    END AS segment
FROM rfm;
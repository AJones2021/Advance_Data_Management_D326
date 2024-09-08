CREATE OR REPLACE FUNCTION time_of_month (payment_date TIMESTAMP)
	RETURNS VARCHAR(9)
	LANGUAGE plpgsql
	AS
	$$
	DECLARE month_of_payment VARCHAR(9);
	BEGIN
		SELECT EXTRACT (MONTH FROM payment_date) INTO month_of_payment;
		RETURN month_of_payment;
	END;
	$$

CREATE TABLE film_category_details (
name VARCHAR (25), 
category_id INT, 
title VARCHAR (255),
film_id INT, 
inventory_film_id INT,
inventory_id INT, 
customer_id INT, 
amount numeric(5,2), 
payment_date VARCHAR(25) 
);

CREATE TABLE category_summary (
	name VARCHAR (25),
	month VARCHAR (9),
	payment_total INT
);

INSERT INTO film_category_details
SELECT c.name, fc.category_id, f.title, f.film_id, i.film_id, r.inventory_id, p.customer_id, p.amount, time_of_month(p.payment_date)
FROM category AS c
INNER JOIN film_category AS fc
ON c.category_id = fc.category_id
INNER JOIN film AS f
ON fc.film_id = f.film_id
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
INNER JOIN payment AS p
ON r.customer_id = p.customer_id
WHERE p.payment_date BETWEEN '2007-02-15 00:00:00.000000' AND '2007-05-14 23:59:59.999999'
GROUP BY p.payment_date, c.name, p.customer_id, fc.category_id, f.title, i.film_id, f.film_id, p.amount, r.inventory_id
ORDER BY p.payment_date  DESC;

CREATE OR REPLACE FUNCTION trigger_update()
RETURNS TRIGGER
LANGUAGE plpggsql
AS 
$$
BEGIN
	DELETE FROM category_summary;
	INSERT INTO category_summary
	SELECT name, payment_date, SUM(amount)
	FROM film_category_details
	GROUP BY payment_date, name
	ORDER BY payment_date, name;
	RETURN NEW;
END;
$$

CREATE TRIGGER update_summary
AFTER INSERT
ON film_category_details
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_update();

CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE plpgsql
AS 
$$
BEGIN
	DELETE FROM film_category_details;
	INSERT INTO film_category_details
SELECT c.name, fc.category_id, f.title, f.film_id, i.film_id, r.inventory_id, p.customer_id, p.amount, time_of_month(p.payment_date)
FROM category AS c
INNER JOIN film_category AS fc
ON c.category_id = fc.category_id
INNER JOIN film AS f
ON fc.film_id = f.film_id
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
INNER JOIN payment AS p
ON r.customer_id = p.customer_id
WHERE p.payment_date BETWEEN '2007-02-15 00:00:00.000000' AND '2007-05-14 23:59:59.999999'
GROUP BY p.payment_date, c.name, p.customer_id, fc.category_id, f.title, i.film_id, f.film_id, p.amount, r.inventory_id
ORDER BY p.payment_date  DESC;
RETURN;
END;
$$

CALL refresh_tables();
SELECT * FROM film_category_details;
SELECT * FROM category_summary;



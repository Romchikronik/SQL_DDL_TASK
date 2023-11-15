-- VIEW  , Well, actually we don't have payment with current quarter, but if we add that, everything will be displayed in the table.
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category_name,
    SUM(p.amount) AS total_sales_revenue
FROM
    CATEGORY c
JOIN
    FILM_CATEGORY fc ON c.category_id = fc.category_id
JOIN
    INVENTORY i ON fc.film_id = i.film_id
JOIN
    RENTAL r ON i.inventory_id = r.inventory_id
JOIN
    PAYMENT p ON r.rental_id = p.rental_id
WHERE
    EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
AND
    EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    c.name
HAVING
    SUM(p.amount) > 0;


-- query language function
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(quarter INTEGER)
RETURNS TABLE(category_name VARCHAR, total_sales_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CAST(c.name AS VARCHAR) AS category_name,  -- Cast to VARCHAR
        SUM(p.amount) AS total_sales_revenue
    FROM
        CATEGORY c
    JOIN
        FILM_CATEGORY fc ON c.category_id = fc.category_id
    JOIN
        INVENTORY i ON fc.film_id = i.film_id
    JOIN
        RENTAL r ON i.inventory_id = r.inventory_id
    JOIN
        PAYMENT p ON r.rental_id = p.rental_id
    WHERE
        EXTRACT(QUARTER FROM p.payment_date) = quarter
    AND
        EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;


-- procedure language function

-- First create a PROCEDURE. By default we do not have lang 'Klingon' in our table, so exception will be thrown
CREATE OR REPLACE PROCEDURE new_movie(movie_title VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    lang_id INTEGER;
BEGIN
    -- Check if Klingon language exists
    SELECT INTO lang_id language_id FROM LANGUAGE WHERE name = 'Klingon';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language not found: Klingon';
    END IF;

    -- Insert the new movie
    INSERT INTO FILM (film_id, title, release_year, language_id, rental_duration, rental_rate, replacement_cost, last_update)
    VALUES (
        (SELECT COALESCE(MAX(film_id), 0) + 1 FROM FILM),  -- Generate a new unique film ID
        movie_title,
        EXTRACT(YEAR FROM CURRENT_DATE),  -- Current year
        lang_id,  -- Language ID for Klingon
        3,  -- Rental duration
        4.99,  -- Rental rate
        19.99,  -- Replacement cost
        CURRENT_TIMESTAMP  -- Last update timestamp
    );
END;
$$;

-- but if we add 'Klingon' in our lang table:
INSERT INTO language (name) VALUES ('Klingon');

-- Now when we are calling our PROCEDURE the film is added to the table
-- CALL new_movie('Example Movie Title');
/***** 05. SQL: Question Set 1 *****/

/* Question 1: Which countries have the most Invoices?*/

SELECT billing_country,COUNT(billing_country) AS Invoice_Number
FROM invoice
GROUP BY billing_country
ORDER BY Invoice_Number DESC;


/* Question 2: Which city has the best customers? 
We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns the 1 city that has the highest sum of invoice totals. 
Return both the city name and the sum of all invoice totals.*/

SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1;

/*Question 3: Who is the best customer?
The customer who has spent the most money will be declared the best customer. 
Build a query that returns the person who has spent the most money. 
Invoice, InvoiceLine, and Customer tables to retrieve this information*/

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY (customer.customer_id)
ORDER BY total_spending DESC
LIMIT 1;

/***** 06. SQL: Question Set 2 *****/

/*Question 1:
Use your query to return the email, first name, last name, and Genre of all Rock Music listeners.
Return your list ordered alphabetically by email address starting with A.*/

/*Sol 1:*/
SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoiceline ON invoice.invoice_id = invoiceline.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

/*Sol2:*/
SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoiceline ON invoiceline.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoiceline.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;


/*Question 2: Who is writing the rock music?
Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands.*/

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;


/*Question 3
First, find which artist has earned the most according to the InvoiceLines?
Now use this artist to find which customer spent the most on this artist.
For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables.
Notice, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, 
and then multiply this by the price for each artist.*/

WITH tbl_best_selling_artist AS(
	SELECT artist.artist_id AS artist_id,artist.name AS artist_name,SUM(invoiceline.unit_price*invoiceline.quantity) AS total_sales
	FROM invoiceline
	JOIN track ON track.track_id = invoiceline.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)

SELECT bsa.artist_name,SUM(il.unit_price*il.quantity) AS amount_spent,c.customer_id,c.first_name,c.last_name
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoiceline il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN tbl_best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,3,4,5
ORDER BY 2 DESC;



/**** 07. (Advanced) SQL: Question Set 3 *****/

/*Question 1:
We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres.*/

/*sales for each country*/
SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
FROM invoiceline
JOIN invoice ON invoice.invoice_id = invoiceline.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN track ON track.track_id = invoiceline.track_id
JOIN genre ON genre.genre_id = track.genre_id
GROUP BY 2,3,4
ORDER BY 2;

/*max genre for each country */
SELECT MAX(purchases_per_genre) AS max_genre_number, country
FROM tbl_sales_per_country
GROUP BY 2
ORDER BY 2;

/*** Final ***/
WITH RECURSIVE
	tbl_sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoiceline
		JOIN invoice ON invoice.invoice_id = invoiceline.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoiceline.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	)
	,tbl_max_genre_per_country AS(SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM tbl_sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT tbl_sales_per_country.* 
FROM tbl_sales_per_country
JOIN tbl_max_genre_per_country ON tbl_sales_per_country.country = tbl_max_genre_per_country.country
WHERE tbl_sales_per_country.purchases_per_genre = tbl_max_genre_per_country.max_genre_number;


/*Question 2:
Return all the track names that have a song length longer than the average song length. 
Though you could perform this with two queries. 
Imagine you wanted your query to update based on when new data is put in the database. 
Therefore, you do not want to hard code the average into your query. You only need the Track table to complete this query.
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.*/

SELECT name,miliseconds
FROM track
WHERE miliseconds > (
	SELECT AVG(miliseconds) AS avg_track_length
	FROM track)
ORDER BY miliseconds DESC;


/*Question 3:
Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.
You should only need to use the Customer and Invoice tables.*/

WITH RECURSIVE 
	tbl_customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	tbl_country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM tbl_customter_with_country
		GROUP BY billing_country)

SELECT tbl_cc.billing_country, tbl_cc.total_spending,tbl_cc.first_name,tbl_cc.last_name,tbl_cc.customer_id
FROM tbl_customter_with_country tbl_cc
JOIN tbl_country_max_spending tbl_ms
ON tbl_cc.billing_country = tbl_ms.billing_country
WHERE tbl_cc.total_spending = tbl_ms.max_spending
ORDER BY 1;


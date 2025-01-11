		-- 		FEATURE ANALYSIS OF FACTORS AFFECTING ORDER PLACEMENT
        
-- This analysis focuses on assessing factors affecting the ordering of the products(books) of a book store. 
-- It seeks to find patterns in the ordering and sale of books in order to help the business make data driven decisions
-- regarding purchase orders and inventory management and ultimately improve business outcome.
	
-- Note: Q:/ indicates question or problem while 
-- R:/ indicates response/answer


						-- DATA EXPLORATION

-- Q:/ Total number of distinct books currently in stock
SELECT COUNT(DISTINCT book_id) AS num_bks FROM books;
-- R:/  10,058

-- Total number of distinct books that have been ordered so far
SELECT COUNT(DISTINCT book_id) AS num_ordered_bks FROM order_line2;
-- R:/  7,589

-- Q:/ What is the total number of books that have not been ordered at all
SELECT COUNT(book_id) FROM books WHERE book_id NOT IN (
	SELECT DISTINCT book_id FROM order_line2);
-- R:/  2,469

-- Q:/ Displaying the total number of distinct books in stock, number of distinct books ever ordered
-- and the percentage of distinct books ordered

WITH all_bks AS (
	SELECT count(DISTINCT book_id) AS num_bks FROM books),
ordered_bks AS (
	SELECT count(DISTINCT book_id) AS num_ordered_bks FROM order_line2)
SELECT num_ordered_bks, num_bks, round((num_ordered_bks/num_bks) * 100,2) AS percentage_of_book_types_ordered
FROM all_bks JOIN ordered_bks;
-- R:/  Percentage of distinct book types ordered is 75.45%

-- Q:/ Total number of orders
SELECT COUNT(order_id) order_count FROM customer_orders;
-- R:/ Total number of orders placed so far is 7,322 orders.

-- Q:/ Number of order items so far
SELECT COUNT( order_id) FROM order_line2;
-- R:/ Total number of order items is 13,933.

-- Q:/ Total quantity sold so far
SELECT SUM(quantity) FROM order_line2;
-- R:/ Total quantity sold is 92,915 copies of books.

-- Q:/ What is the Total order value (Total revenue)
SELECT SUM(price * quantity) Total_Revenue FROM order_line2;
-- R:/ Total order value(Total revenue) is 926,934.16

-- Q:/ What is the Average Order value (AOV)
SELECT ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id),2) AOV FROM order_line2;
-- R:/ Average order value is 126.60

-- Q:/ What is the Average product revenue (APR) 
SELECT SUM(price * quantity)/sum(quantity) FROM order_line2;
-- R:/ Average product revenue is 9.97

-- NB: AOV that is significantly higher than APR could indicate that customers buy more items per order,
-- a good reason to try to boost orders. It could also be because they purchase higher priced items. 

-- Exploring to see if the same book has been sold for the same price or for varying prices over time
WITH same_price_check AS (
SELECT o.book_id, price, 
CASE 
	WHEN LEAD(price) OVER (ORDER BY book_id) = price AND 
		LEAD(o.book_id) OVER (ORDER BY book_id) = o.book_id THEN 'same'
	WHEN LAG(price) OVER (ORDER BY book_id) = price AND
		LAG(o.book_id) OVER (ORDER BY book_id) = o.book_id THEN 'same' ELSE ""
    END AS check_price
FROM books b
JOIN order_line2 o
ON b.book_id = o.book_id)
SELECT * FROM same_price_check WHERE check_price = 'same'
ORDER BY book_id;
-- R:/ Quite strangely, most of the same books sold have not been sold at the same price... just 4 have!

-- Q:/ What is the Average Selling Price of books
SELECT round(avg(price),2) FROM order_line2;
-- R:/  Average selling price is 10.01
 
-- Q:/ Exploring how often the ordered books have actually been ordered
WITH order_freq AS (
	SELECT book_id, count(book_id) num_of_times_ordered FROM order_line2
	GROUP BY book_id
    )
SELECT count(num_of_times_ordered) num_of_books, num_of_times_ordered
	FROM order_freq
	GROUP BY num_of_times_ordered
	ORDER BY num_of_books;
    
-- R:/ The highest number of orders for a given book is 8 orders. Relatively few books have been ordered up to 5 times. 
-- Majority have been ordered for even less number of times, once or twice



			-- DEEP DIVE INTO FACTORS INFLUENCING ORDERS AND FEATURE ANALYSIS OF ORDERS.

-- Q:/ List of books that have not been ordered, including their authors,
-- finding out how books by such authors have fared

WITH unordered_bks AS (
	SELECT book_id FROM books WHERE book_id NOT IN (
	SELECT DISTINCT book_id FROM order_line2)),
author_not_ordered AS (
	SELECT a.author_id, count(*) AS num_not_ordered 
	FROM unordered_bks
	JOIN book_authors a
	ON unordered_bks.book_id = a.book_id
    GROUP BY a.author_id),
ordered_bks AS (SELECT book_id FROM books WHERE book_id IN 
	(SELECT DISTINCT book_id FROM order_line2)),
author_ordered AS (SELECT a.author_id, count(*) AS num_ordered 
	FROM ordered_bks
	JOIN book_author a
	ON ordered_bks.book_id = a.book_id
    GROUP BY a.author_id)        
SELECT author_not_ordered.author_id, author_not_ordered.num_not_ordered, author_ordered.num_ordered, 
	round(author_not_ordered.num_not_ordered/
    (author_ordered.num_ordered + author_not_ordered.num_not_ordered) * 100,1) 
    AS percentage_of_authors_books_not_ordered
	FROM author_not_ordered
    LEFT JOIN author_ordered ON author_not_ordered.author_id = author_ordered.author_id
    WHERE author_not_ordered.num_not_ordered >=3
    ORDER BY percentage_of_authors_books_not_ordered DESC;

-- R:/ 16 authors with as much as 3 unordered books have over 50 percent of their books not ordered yet.
-- The author with id 6539 has 5 of his books in our store and only one has ever been ordered. 

-- Q:/ List of books that have not been ordered with their years of publication, 
-- finding out if there is something about books published in specific years, sales-wise.

WITH pub_year_unordered as (
	SELECT YEAR(publication_date) year_of_publication, count(book_id) num_unordered_bks
	FROM books where book_id NOT IN 
		(SELECT DISTINCT book_id FROM order_line2)
	GROUP BY YEAR(publication_date)),
pub_year_ordered AS (
	SELECT YEAR(publication_date) year_of_publication, count(book_id) num_ordered_bks
	FROM books WHERE book_id IN 
		(SELECT distinct book_id FROM order_line2)
	GROUP BY YEAR(publication_date))
SELECT pu.year_of_publication, pu.num_unordered_bks, COALESCE(p.num_ordered_bks,0) num_ordered_bks,
	round(pu.num_unordered_bks/(pu.num_unordered_bks + COALESCE(p.num_ordered_bks,0)),2) 
	percentage_of_unordered_published
	FROM pub_year_unordered pu
    LEFT JOIN pub_year_ordered p
	ON pu.year_of_publication = p.year_of_publication
	WHERE pu.num_unordered_bks >=3 AND (pu.num_unordered_bks - p.num_ordered_bks) >=3
	ORDER BY percentage_of_unordered_published DESC;
    
-- R:/ There is nothing much to the year of publication. Only books pubished in 1968 and 2015 
-- so far give us a rather insignificant reason to be concerned about the viability of books 
-- published in specific years. 

-- Q:/ Books in what language sell more
SELECT b.language_id, l.language_name, COUNT(b.language_id) AS ordered_per_lang
FROM order_line2 o
LEFT JOIN books b
ON o.book_id = b.book_id
LEFT JOIN book_language l
ON b.language_id = l.language_id
GROUP BY b.language_id, l.language_name
ORDER BY ordered_per_lang DESC;

-- Alternative solution to the question, 'Books in what language sell more?'
WITH book_lang AS (
	SELECT o.book_id, b.language_id
	FROM order_line2 o
	LEFT JOIN books b
	ON o.book_id = b.book_id)
SELECT book_lang.language_id, l.language_name, count(book_lang.language_id) as ordered_per_lang
	FROM book_lang
	JOIN book_language l
	ON book_lang.language_id = l.language_id
	GROUP BY book_lang.language_id, l.language_name
	ORDER BY ordered_per_lang DESC;
    
-- R:/ Generally, books in English language sell more, then Spanish, French and German books.

-- Q:/ What percentage of the number of books of various languages in stock have been ordered.
WITH all_books AS (
	SELECT b.language_id, l.language_name, count(b.language_id) num_per_lang
	FROM books b LEFT JOIN book_language l
    ON b.language_id=l.language_id
    GROUP BY b.language_id, l.language_name
    ),
ordered_books AS (
	SELECT b.language_id, l.language_name, count(b.language_id) AS ordered_per_lang
	FROM order_line2 o
	LEFT JOIN books b
	ON o.book_id = b.book_id
    LEFT JOIN book_language l
    ON b.language_id = l.language_id
	GROUP BY b.language_id, l.language_name)
SELECT all_books.language_id, all_books.language_name, all_books.num_per_lang, ordered_books.ordered_per_lang,
	round((ordered_books.ordered_per_lang/all_books.num_per_lang) * 100,2) percent_ordered
	FROM all_books JOIN ordered_books
	ON all_books.language_id = ordered_books.language_id
	ORDER BY ordered_per_lang DESC;
    
-- R:/ This has only been explored out of curiosity. Output shows that these highly demanded languages 
-- also have a high demand relative to the number of books in that language available in stock.

-- Q:/ Does the volume of books have an effect on sales
-- Getting an idea of the size of books in stock

SELECT MAX(num_pages), MIN(num_pages), AVG(num_pages), STD(num_pages) FROM books;
SELECT book_id, num_pages FROM books
ORDER BY num_pages DESC;

-- R:/ The maximum and average number of pages of books in stock is 6,576 and 332 pages respectively.

-- Q:/ Does the volume of books have an effect on order/sales
WITH book_sizes AS (SELECT book_id, num_pages,
	CASE WHEN num_pages <=100 THEN "small"
		WHEN num_pages BETWEEN 100 AND 500 THEN "medium"
		WHEN num_pages BETWEEN 501 AND 2000 THEN "large"
		WHEN num_pages > 2000 THEN "extra large"
		END AS book_size FROM books),
ordered_bks_sizes AS (
	SELECT o.book_id, bs.num_pages, bs.book_size
	FROM order_line2 o
    JOIN book_sizes bs
    ON o.book_id = bs.book_id),
size_count AS (SELECT book_size, count(book_size) book_count FROM ordered_bks_sizes
    GROUP BY book_size)
SELECT book_size, book_count, round(book_count * 100/(SELECT sum(book_count) FROM size_count),2) as percentage_of_books
	FROM size_count
	ORDER BY book_count DESC;

-- R:/ From the result, the volume of books has an effect on order/sales. 
-- 76% of all ordered books are medium sized (btw 100 to 500 pages). This is quite a large numnber. 
-- Next best size of ordered books are large books making up 15% of all orders, small books 9% and extra large books less than 1%

-- Q:/ Assess the percentage of book sizes ordered relative to the number of such books in stock.
WITH booksandsizes AS (
	SELECT book_id, num_pages,
	CASE WHEN num_pages <=100 THEN "small"
		WHEN num_pages BETWEEN 100 AND 500 THEN "medium"
		WHEN num_pages BETWEEN 501 AND 2000 THEN "large"
		WHEN num_pages > 2000 THEN "extra large"
		END AS book_size,
	count(book_id) OVER(PARTITION BY CASE WHEN num_pages <=100 THEN "small"
		WHEN num_pages BETWEEN 100 AND 500 THEN "medium"
		WHEN num_pages BETWEEN 501 AND 2000 THEN "large"
		WHEN num_pages > 2000 THEN "extra large" END) AS num_size
	FROM books),
ordered_bks_sizes AS (
	SELECT o.book_id, bs.num_pages, bs.book_size, bs.num_size
	FROM order_line2 o
    JOIN booksandsizes bs
    ON o.book_id = bs.book_id)
SELECT book_size, COUNT(book_size) num_ordered_per_size, ROUND(AVG(num_size),0) AS num_bks,
	ROUND((COUNT(book_size) / AVG(num_size))*100,1) AS relative_percentage_ordered
	FROM ordered_bks_sizes
	GROUP BY book_size
	ORDER BY COUNT(book_size) DESC;

-- R:/ A larger number of books in stock is truly medium sized.
-- The percentage shows that relative to the number of each book size in stock, 
-- medium sized books also have the highest percentage of ordered books.


			-- INFLUENCE OF TIME/PERIOD ON ORDER AND REVENUE
            
-- Q:/ How did we fare in terms of sales and revenue generation in various years.

WITH year_order AS (
	SELECT YEAR(co.order_date) years, COUNT(DISTINCT o.order_id) num_of_orders, SUM(o.price * o.quantity) revenue
	FROM customer_orders co
	JOIN order_line2 o
	ON co.order_id = o.order_id
	GROUP BY YEAR(co.order_date)
	)
SELECT *,
DENSE_RANK() OVER (ORDER BY num_of_orders DESC) rank_by_qty_ordered,
DENSE_RANK() OVER (ORDER BY revenue DESC) rank_by_revenue
FROM year_order
ORDER BY rank_by_qty_ordered;

-- R:/ Both sales and revenue generation were best in 2023, then 2022, 2024. 
-- "Market" looks like it was bad in 2021, our first year, but, we would need to explore this further
-- More concerning is the low sale and revenue in 2024. Lets look further into 2021 and 2024 below

-- Q:/ Exploring the start_month and end_month for our first business year and last business year for which we have records.

SELECT 2021 AS year, MIN(MONTH(order_date)) start_month, MAX(MONTH(order_date)) end_month
FROM customer_orders co
WHERE YEAR(order_date) =2021
UNION ALL
SELECT 2024 AS year, MIN(MONTH(order_date)), MAX(MONTH(order_date))
FROM customer_orders co
WHERE YEAR(order_date) =2024;

-- R:/ Data show that we only have records from October till December for 2021 (our first year)
-- and from January till October for 2024 so far.
-- This could explain the relatively low order/revenue record for both years.
-- An exclusion of the last two months still showed 2024 ranking slightly above 2022 but still below 2033, 
-- but the gap in sales and revenue was clearly reduced.

-- Q:/ How did we fare in terms of order and revenue generation in various months of various years.
WITH month_yr_order AS (
	SELECT DATE_FORMAT(co.order_date, '%M-%Y') months, COUNT(DISTINCT o.order_id) num_of_orders, SUM(o.price * o.quantity) revenue
	FROM customer_orders co
	JOIN order_line2 o
	ON co.order_id = o.order_id
	GROUP BY months)
SELECT *,
DENSE_RANK() OVER (ORDER BY num_of_orders DESC) rank_by_qty_ordered,
DENSE_RANK() OVER (ORDER BY revenue DESC) rank_by_revenue
FROM month_yr_order
ORDER BY rank_by_qty_ordered;

-- R:/ The top numbers of orders were distributed across months in the 3 later years with April, 2023 topping the chart
-- April 2023 however ranked second in revenue generation as highest revenue was recorded in August, 2022.

-- Q:/ How were order placements and revenue generation in various months.
WITH month_order AS (
	SELECT MONTHNAME(co.order_date) months, COUNT(DISTINCT o.order_id) num_of_orders, SUM(o.price * o.quantity) revenue
	FROM customer_orders co
	JOIN order_line2 o
	ON co.order_id = o.order_id
	GROUP BY MONTHNAME(co.order_date)
	)
SELECT *,
DENSE_RANK() OVER (ORDER BY num_of_orders DESC) rank_by_qty_ordered,
DENSE_RANK() OVER (ORDER BY revenue DESC) rank_by_revenue
FROM month_order
ORDER BY rank_by_qty_ordered;

-- R:/ The highest revenue and quantity ordered were recorded in April, August was also a good month in both respects. 
-- This was despite the fact that there were no records for these months in 2021.
-- Order placement and revenue generation were low in September. November. February and October were also poor.

-- Q:/ Checking the percentage contribution from the days of the week

WITH day_contr AS (
	SELECT DAYNAME(c.order_date) AS day_of_week, COUNT(DISTINCT o.order_id) AS order_count, SUM(o.price * o.quantity) AS revenue
	FROM customer_orders c
    JOIN order_line2 o
    ON o.order_id = c.order_id
	GROUP BY DAYNAME(c.order_date))
SELECT day_of_week, order_count, revenue,
ROUND(order_count * 100/(SELECT SUM(order_count) FROM day_contr),2) AS percent_order_count_contr, 
ROUND(revenue * 100/(SELECT SUM(revenue) FROM day_contr),2) AS percentage_rev_contr FROM day_contr
ORDER BY order_count desc;

-- R:/ The percentage contribution from the days of the week is very slightly different. 
-- They each contribute between 13 to 15% or orders placed and revenue accrued, 
-- with Monday and Sunday having the highest number of orders placed and highest revenue respectively.
-- Tuesday is at the bottom for both metrics 


-- LET'S NOW LOOK AT THE BEST SELLERS AND CONFIRM THE FEATURES WE HAVE FOUND TO HAVE SIGNIFICANT IMPACT
-- FROM OUR FEATURE ANALYSIS SO FAR.

-- Q:/ What books have been most ordered

SELECT o.book_id, b.title, COUNT(o.book_id) num_ordered
FROM order_line2 o
JOIN books b
ON o.book_id = b.book_id
GROUP BY o.book_id, b.title
ORDER BY COUNT(o.book_id) DESC;
-- R:/ The book titled 'All New People' has been ordered 8 different times so far, 4 books have been ordered 7 times,
-- 20 books 6 times and so on. This summary was shown in an earlier query while the dataset was explored.

-- Q:/ What books have had the highest sales

SELECT o.book_id, b.title, COUNT(o.book_id) num_ordered, sum(quantity) sales
FROM order_line2 o
JOIN books b
ON o.book_id = b.book_id
GROUP BY o.book_id, b.title
ORDER BY sales DESC;

-- R:/ The book 'All New People' with the highest number of orders has had the highest copies sold (77 copies),
-- Death in Kashmir with 5 orders and highest revenue as seen earlier has the second highest sales (68 copies).

-- Q:/ What books have brought in the most revenue

SELECT o.book_id, b.title, SUM(o.price * o.quantity) revenue, COUNT(o.book_id) num_of_orders
FROM order_line2 o
JOIN books b
ON o.book_id = b.book_id
GROUP BY o.book_id, b.title
ORDER BY revenue DESC, num_of_orders DESC;

-- R:/ 'Death in Kashmir', with 5 orders so far, has reeled in the highest revenue of over a thousand dollars.
-- 'All New People' with the highest number of orders(8), brought in the seventh highest revenue of over 700 dollars .    
    
-- Are there books that are usually co_ordered     
    SELECT ol1.book_id AS book1, ol2.book_id AS book2, COUNT(*) AS times_ordered_together
FROM order_line2 ol1
JOIN order_line2 ol2 ON ol1.order_id = ol2.order_id AND ol1.book_id > ol2.book_id
GROUP BY ol1.book_id, ol2.book_id
ORDER BY times_ordered_together DESC;

-- Book co_ordering is nearly non-existent in the bookstore. There has been only two instances , involving only two books.     

-- NB:/ So far, from our analysis, we saw strong indications that books in English language and
-- books of medium or large size significantly sell more. Now that we have listed our  best sellers,
-- Q:/ Let's confirm how many of the best sellers (most ordered books) are in English language and of medium or large size.

WITH best_sellers AS (
	SELECT o.book_id, b.title, COUNT(o.order_id) times_ordered
	FROM order_line2 o
	JOIN books b
	ON o.book_id = b.book_id
	GROUP BY o.book_id, b.title
	HAVING COUNT(o.book_id) >= 5), -- order_count in the top 25% would be >=6. We use 5 to accommodate more samples
book_features AS (
    SELECT b.book_id, b.title, b.times_ordered,
	CASE WHEN l.language_name LIKE "%English%" AND bk.num_pages BETWEEN  100 AND 2000 THEN 1 ELSE 0 END AS eng_and_medium_large_bks
	FROM best_sellers b
	JOIN books bk ON b.book_id = bk.book_id
	JOIN book_language l ON bk.language_id = l.language_id)
SELECT sum(eng_and_medium_large_bks) 'eng_and_medium/large_bks', count(eng_and_medium_large_bks) total_bestsellers,
	round((AVG(eng_and_medium_large_bks))*100,2) 'percentage_of_eng_and_medium/large_sized_bestsellers'
	FROM book_features;

-- R:/ 83% of our bestsellers are books in English language and either medium or large sized.

-- Q:/ Let's confirm how many of our best sellers(most sold) books are either in English lanuage and of medium or large size or both.

WITH best_seller_rank AS (
	SELECT o.book_id, b.title, SUM(o.quantity) qty_ordered,
	RANK() OVER(ORDER BY SUM(o.quantity) DESC) qty_rank
	FROM order_line2 o
	JOIN books b
	ON o.book_id = b.book_id
	GROUP BY o.book_id, b.title),
best_sellers AS (
	SELECT * FROM best_seller_rank where qty_rank <=100), -- best sellers here are our top ~100 selling books.
book_features as (
    SELECT b.book_id, b.title, b.qty_ordered,
	CASE WHEN l.language_name LIKE "%English%" AND bk.num_pages between  100 AND 2000 then 1 else 0 end as eng_and_medium_large_bks
	FROM best_sellers b
	JOIN books bk ON b.book_id = bk.book_id
	JOIN book_language l ON bk.language_id = l.language_id)
SELECT sum(eng_and_medium_large_bks) 'eng_and_medium/large_bks', count(eng_and_medium_large_bks) total_bestsellers,
	round((AVG(eng_and_medium_large_bks))*100,2) 'percentage_of_eng_and_medium/large_sized_bestsellers'
	FROM book_features;

-- R:/ 85% of our bestsellers(top ~100 selling books) are books in English language and medium/large size.

    
					-- SUMMARY
-- /: This feature analysis, looked into the features of ordered books in a bookstore. 
-- /: Features considered include authors of books, year of publication, book language, book size, period of order etc.
-- /: It established that most of the product that have been ordered so far are books in a specific language(English)
-- /: Books of medium or large size were also found to make up a large number of ordered books.
-- /: Having established these features of all ordered books. We selected the bestsellers.
-- /: We tested the bestsellers to determine what percentage have these features we discovered
-- /: We established that 83% of our bestsellers(based on orders) are books written in English language and are books of medium/large size
-- /: We also established that 85% of bestsellers (based on sales) are both written in English and are medium/large size books.

				-- CONCLUSION/RECOMMENDATION
-- /: We therefore conclude from our feature analysis that features particulary language and size influence order
-- and books with such features should be considered more in our order purchase to boost order and revenue 
-- and reduce unnecessary inventory pile up.
-- /: We could closely monitor books by authors with relatively less number of books ordered and consider
-- reducing the quantity of these authors books in future purchase orders to avoid unnecessary product pile up.
-- /: Sales and revenue were higher in certain months, though the margins were not so high. This could be further investigated to find out if there were 
-- specific strategies employed in those periods that need to be encouraged.


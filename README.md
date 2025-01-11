# Bookstore-Order-Analysis
## A feature analysis of factors influencing order placement in a bookstore

This is an analysis conducted to understand the factors affecting order placements in a bookstore, aiming to help the bookstore make 
data-driven decisions regarding purchase orders and inventory management. 

By identifying key trends and patterns, this analysis can contribute to improved order placements, increased sales, and ultimately higher revenue.

Features considered include authors of books, year of publication, book language, book size, period of order etc.<br>
It employed MySQL and showcased the use of simple to complex queries to retrieve relevant information from data.<br>
Outputs were structured in such a way as to serve the end users of the data, displaying most values in percentages and ranks for ease of comparison.<br>

### Findings

1. The analysis established that very many of the books that have been ordered so far are books in a specific language(English)<br>
2. Books of medium or large size were found to make up a large percentage (about 90%) of ordered books.<br>
3. Years of publication and authors of books were found to have very minute and insignificant influence on book orders<br>
4. Orders were higher in certain months and days of the week but the margin was not quite eye catching<br> 
5. Having established the features which significantly influence book orders, we selected the bestsellers for testing these features.<br>
6. We tested the bestsellers to determine what percentage have these features we discovered.<br>
7. We established that 83% of bestsellers (based on orders) are both written in English and medium/large sized.<br> 
8. We also established that 85% of bestsellers (based on sales) are both written in English and medium/large sized.


### Conclusion/Recommendation

1. We conclude from our feature analysis that features particulary language and size significantly influence order placement,<br>
sales and revenue in the bookstore and books with such features should be considered more in our order purchase to boost order <br>
and revenue and reduce unnecessary inventory pile up.
2. We could, for now, closely monitor books by authors with relatively less number of books ordered and consider<br>
reducing the quantity of these authors books in future purchase orders to avoid unnecessary product pile up.
3. Sales and revenue were higher in certain months such as April and August, though the margins were not so high.<br>
This could be further investigated to find out if there were specific strategies employed in those periods that need to be encouraged.

### Suggestions for data collection/future analysis

1. Data on other book features such as genre, format(hardcover, paperback, e-book) and medium of order placement, if applicable,<br>
could help to reveal more about features influencing book orders if made available.<br>
3. Future analysis and queries for onward use should be made more dynamic in areas where specific values were coded for simplicity.


# Final-Project-Transforming-and-Analyzing-Data-with-SQL

## Project/Goals
The project consists of a database containing five tables. The main goal is to process the tables in the database for comprehensive data analyses. This can be done through the processes of removing faulty data, formatting columns (such as changing data types) where applicable, quality assurance to check for additional errors and addressing them as best as possible (such as QA processes to find missing data and running queries to fill in gaps), and lastly establishinng relations between the tables.

## Process
### 1. Import CSV into SQL, starting with varchar type for all data
### 2. QA column names and revise to avoid query language conflicts
### 3. Query each column to determine proper data types and character limitations
### 4. Revise data types accordingly
### 5. Query each table for more information and quality control
### 6. Revise tables based on information gathered from previous queries
### 7. Perform analyses on newly cleaned and formatted database for answers

## Results
By scanning through the data, the database appears to be that of a Google merchandise website where users can buy all sorts of products. The data ranges from 2016-08-01 to 2017-08-01, with one table in particular (analytics) containing far more entries from 2017-05-01 to 2017-08-01. There is one table (sales_report) that appears to be a subset of the main products table, with only one additional columnn (ratio) that is derived from simply dividing two already existing columns, and can agruably be removed from the database (for the purpose of this project the table was kept). The overlap of two tables (analytics and all_sessions) made it more possible to fill out certain missing entries and thus more accurate analyses that involved the data affected (mainly the revenue data) can be performed.

## Challenges 
The largest challenge was being unable to reliably link the analytics and all_sessions table as there are no unique values in either table. At best, joins using several common fields were possible. The next challenge was the vast amount of missing revenue data in both of the aforementioned tables. While results were achieved, a more full dataset would provide far more accurate results. The next biggest challenge was the name and category field formatting as several entries are context sensitive and require manual intervention in addition to queries.

## Future Goals
Future goals would involve:
- Figuring out a proper way to link the analytics and all_sessions tables together as currently the database has the analytics table not connected to any of the other tables. A many-to-many relationship between these two should be possible given the amounts of columns they have in common
- Create thorough product name queries to fix naming issues (via regular expressions)
- Create queries to help modify product categories so that there would be less categories in the database, making it easier to categorize products

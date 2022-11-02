--SQL Retail data analysis



create database Retail_data_analysis
use Retail_data_analysis


--DATA PREPARATION AND UNDERSTANDING 
--1.what is the total number of rows in each of the 3 tables in the database?
--Q1--BEGIN 
SELECT * FROM (
SELECT 'Customer' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Customer UNION ALL
SELECT 'Transactions' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Transactions UNION ALL
SELECT 'prod_cat_info' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM prod_cat_info
) TB
--Q1--END


--2.what is the total number of transactions that have a return?
--Q2--BEGIN
SELECT COUNT(transaction_id)[No of return] from Transactions
where Qty < 0
--Q2--END



--3. As you would have noticed, the dates provided across the datasets are not in a correct format. as first steps, pls convert the data variables into valid date formats befor proceeding ahead
--Q3--BEGIN 
alter table customer
alter column DOB datetime
--Q3--END



--4. what is the time range of the transaction data available for analysis? show the output in number of days, months and years simultaneously in different columns. 
--Q4--BEGIN
Select datediff(day,min(tran_date),max(tran_date))[no of days],
datediff(month,min(tran_date),max(tran_date))[no of months],
datediff(year,min(tran_date),max(tran_date))[no of years]
from Transactions
--Q4--END



--5.which product category does the sub category "DIY" belong to?
--Q5--BEGIN
select distinct(prod_cat) from prod_cat_info
where prod_subcat = 'DIY'
--Q5--END




--DATA ANALYSIS

--1. which channel is most frequently used for transactions?
--Q1--BEGIN
select top 1 * from (select DISTINCT(STORE_TYPE),count(store_type)[Count] from Transactions
group by Store_type) t1
order by [Count] desc
--Q1--END



--2.what is the count of male and female customers and how many?
--Q2--BEGIN
select count(case when Gender = 'M' then 1 end)as male_count,
count(case when Gender = 'F' then 1 end)as female_count
from Customer
--Q2--END


--3.from which city do we have the maximum number of customers and how many?
--Q3--BEGIN  
select top 1 * from (select city_code, count(customer_id)[count] from Customer
group by city_code) t2
order by [count] desc
--Q3--END	


--4.how many sub categories are there under the book category?
--Q4--BEGIN
select count(Distinct(prod_subcat))[no of sub categories in books category] from prod_cat_info
where prod_cat = 'Books'
--Q4--END


--5. what is the maximum quantity of products ever ordered?
--Q5--BEGIN
select max(abs(Qty))[Max Qty of products ordered] from Transactions
--Q5--END


--6. what is the net total revenue generated in categories Electronics and books?
--Q6--BEGIN
select sum(qty*rate)[total revenue generated without tax from electronics and books] from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
and prod_cat in ('Electronics','Books') and Qty > 0
--Q6--END


--7. how many customers have > 10 transactions with us, excluding returns? 
--Q7--BEGIN
select cust_id, count(transaction_id)[count] from Transactions
where Qty > 0
group by cust_id
having count(transaction_id) > 10
--Q7--END


--8. what is the combined revenue earned from the "Electronics" and "clothing" category, from "flagship stores"? 
--Q8--BEGIN
select sum(total_amt)[combined revenue earned from flagship electronics and clothing stores] from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
and prod_cat in ('Electronics','Clothing') and Store_type = 'Flagship store'
--Q8--END


--9. what is the total revenue generated "male" customers in "electronics" category? output should display total revenue by prod sub-cat.
--Q9--BEGIN
select prod_subcat, sum((Qty*Rate)+Tax) [total revenue generated from males ] from Transactions	inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code inner join Customer on Transactions.cust_id = Customer.customer_Id
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
and Gender = 'M' and Qty  >0 and prod_cat = 'Electronics'
group by prod_subcat
--Q9--END


--10. what is the percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
--Q10--BEGIN
select top 5 prod_subcat,
round((sum(case when total_amt > 0 then total_amt end)/( select sum(case when total_amt > 0 then total_amt end) as total_returns from Transactions)) * 100, 2)[percentage of sales], 
round((sum(case when total_amt < 0 then total_amt end)/ ( select sum(case when total_amt < 0 then total_amt end) as total_returns from Transactions)) * 100, 2)[percentage of returns]
from transactions inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code 
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
group by prod_subcat
order by [percentage of sales] desc
--Q10--END


--11. for all custemors ages btw 25 to 35 years find what is the net total revenue generated bye these customers in last 30 days of trans for max transaction data vailable in the data?
--Q11--BEGIN
select sum(Qty*Rate)[Net total revenue] from 
(select * from Transactions inner join Customer on Transactions.cust_id = Customer.customer_Id
where (DATEDIFF(year, DOB, GETDATE()) between 25 and 30) 
and (DATEDIFF(day, tran_date, (select MAX(tran_date) from Transactions))) < 31 ) t4
where Qty > 0
--Q11--END



--12. which product category has seen the max value of returns in the last 3 months of transactions?
--Q12--BEGIN
select top 1 prod_cat, sum(total_amt)[total returns] from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.total_amt  < 0 
and Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
and ((DATEDIFF(month, tran_date, (select MAX(tran_date) from Transactions))) < 4) 
GROUP BY prod_cat
order by prod_cat desc
--Q12--END


--13. which store-stype sells the maximum products; by value of sales amount and by quantity sold?	
--Q13--BEGIN
select Store_type from (select t2.[Store_type], sum(t2.[total_amt]) [ttl_sales], sum(t2.[Qty]) [ttl_qty] 
				from [dbo].[prod_cat_info] t1 , [dbo].[Transactions] t2 
				where t1.[prod_cat_code] = t2.[prod_cat_code] 
				and t1.[prod_sub_cat_code] = t2.[prod_subcat_code] 
				and t2.[total_amt] > 0 and t2.[Qty] > 0
				group by t2.[Store_type]) y , (select max(x.ttl_amt) TAmt, max(x.ttl_qty) TQty
 										from (select t2.[Store_type], sum(t2.[total_amt]) ttl_amt, sum(t2.[Qty]) [ttl_qty] 
											from [dbo].[prod_cat_info] t1 , [dbo].[Transactions] t2 
											where t1.[prod_cat_code] = t2.[prod_cat_code] 
											and t1.[prod_sub_cat_code] = t2.[prod_subcat_code] 
											and t2.[total_amt] > 0 and t2.[Qty] > 0
											group by t2.[Store_type]) x)z
where y.ttl_sales =  z.TAmt and y.ttl_qty = z.TQty


--Q13--END


--14. what are the categories for which average reveneuw is above the overall average?
--Q14--BEGIN
select prod_cat, avg(total_amt)[avg_revenue] from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
group by prod_cat
having avg(total_amt) > (select avg(total_amt) from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code ) 
--Q14--END


--15. Find the average and total revenue by each subcategory for the categories which are amoung top 5 in terms of quantity sold.	
--Q15--BEGIN
select prod_subcat, round(avg(total_amt),2)[avg_revenue],round(sum(total_amt),2)[total_revenue] from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
and prod_cat in 
(select top 5 prod_cat from Transactions left join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
where Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code 
group by prod_cat
order by sum(Qty) desc)
group by prod_subcat

--Q15--END
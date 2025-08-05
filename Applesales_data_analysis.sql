--1.Find each country and number of stores
select country,count(store_id) as total_stores from stores
group by 1 order by 2 desc
--2. What is the total number of units sold by each store?
select s.store_id,store_name,sum(quantity) from sales as s
join stores as st
on s.store_id=st.store_id
group by 1,2
order by 3 desc
--3.How many sales occurred in December 2023?
select count(*) as sales_in_DEC2023 from sales
where  to_char(sale_date::date,'mm-yy')='12-23'
--4. How many stores have never had a warranty claim filed against any of their products?
select count(store_id) from(select store_id,count(claim_id) as total_claims from warranty as w
right join sales as s
on w.sale_id=s.sale_id
group by 1) as claim_data
where total_claims=0
--5. What percentage of warranty claims are marked as "Warranty Void"?
select round((count(*)::numeric/(select count(*) from warranty))*100,2) as Percent_Warranty_Voids from warranty
where repair_status='Warranty Void'
--6. Which store had the highest total units sold in the 2 last years?
SELECT s.store_id,store_name,count(quantity) as units_sold from sales as s
join stores as st
on s.store_id=st.store_id
where sale_date::date>=current_date-interval '2 year'
group by 1,2 order by 3 desc limit 1
--7.Count the number of unique products sold in the last 2 years.
select count(distinct product_name) as unique_products_sold from products as p
join sales as s
on s.product_id=p.product_id
where sale_date::date>=current_date-interval '2 year';
--8. What is the average price of products in each category?
select category_id,round(avg(price)::numeric,2) as average_price from products
group by 1 order by 1
--9. How many warranty claims were filed in 2020?
select count(*) from warranty where extract(year from claim_date::date)=2020
--10. Identify each store and best selling day based on highest qty sold
with cte as(select store_id,to_char(sale_date::date,'Day') as days,sum(quantity)as qty_sold,
dense_rank() over(partition by store_id order by sum(quantity)) as ranks from sales
group by 1,2)
select * from cte where ranks=1 order by 3 desc
--11. Identify least selling product of each country for each year based on total unit sold
with cte as(select extract(year from sale_date::date) as Years,country,product_name,sum(quantity) as units_sold, 
dense_rank() over(partition by extract(year from sale_date::date),country order by sum(quantity)) as ranks from sales as s
join stores as st
on s.store_id=st.store_id
join products as p
on p.product_id=s.product_id
group by 1,2,3 order by 1)
select * from cte where ranks=1 order by 1
--12. How many warranty claims were filed within 180 days of a product sale?
select count(*) from sales as s
join warranty as w
on s.sale_id=w.sale_id
where sale_date::date>=claim_date::date-interval '180 days'
--13. How many warranty claims have been filed for products launched in the last two years?
select count(*) from warranty as w
join sales as s
on s.sale_id=w.sale_id
join products as p
on s.product_id=p.product_id
where launch_date::date>=current_date-interval '2 years'
--14. List the months in the last 3 years where sales exceeded 5000 units from usa.
with cte as (select to_char(sale_date::date,'Month') as Months,sum(quantity) as units_sold from sales as s
join stores as st
on s.store_id=st.store_id
where country='USA' and sale_date::date>=current_date-interval '3 years'
group by 1)
select * from cte where units_sold>5000
--15. Which product category had the most warranty claims filed in the last 2 years?
select category_id,count(*) as total_claims from warranty as w
join sales as s
on w.sale_id=s.sale_id
join products as p
on p.product_id=s.product_id
where claim_date:: date>=current_date-interval '2 years'
group by 1 order by 2 desc limit 1
--16. Determine the percentage chance of receiving claims after each purchase for each country.
select country,round(count(claim_id)::numeric/count(s.sale_id)*100,2) as chance_of_claims from stores as st
join sales as s
on st.store_id=s.store_id
left join warranty as w
on w.sale_id=s.sale_id
group by 1 order by 2 desc
--17. Analyze each stores year by year growth ratio
with cte as(select *,lag(current_year_revenue) over(partition by store_id,store_name order by Years) as previous_year_revenue from(
select s.store_id,store_name,extract(year from sale_date::date) as Years,sum(quantity*price) as current_year_revenue from sales as s
join products as p
on s.product_id=p.product_id
join stores as st
on s.store_id=st.store_id
group by 1,2,3 order by 1) as yearly_data)
select *,(current_year_revenue-previous_year_revenue)/previous_year_revenue*100 as growth_percentage from cte 
where (current_year_revenue-previous_year_revenue)/previous_year_revenue*100  is not NULL order by 6 desc
--18. What is the correlation between product price and warranty claims for products sold in the
--last five years? (Segment based on diff price)
select case when price<500 then 'Less Expensive'
when price between 500 and 1000 then 'Moderately Expensive'
else 'Highly Expensive' end as price_group,count(claim_id) as total_claims from warranty as w
left join sales as s
on w.sale_id=s.sale_id
join products as p
on s.product_id=p.product_id
where sale_date::date>=current_date-interval '5 years'
group by 1
--19. Identify the store with the highest percentage of "Paid Repaired" claims in 
--relation to total claims filed.
select s.store_id,store_name,round(count(case when repair_status='Paid Repaired'then 1 end)::numeric/count(*)*100,2) as percent_repaired from warranty as w
join sales as s
on s.sale_id=w.sale_id
join stores as st
on s.store_id=st.store_id
group by 1,2 order by 3 desc limit 1
--20.Write SQL query to calculate the monthly running total of sales for each store over the past
--four years and compare the trends across this period?
with cte as(select *,sum(current_month_revenue) over(partition by store_id,store_name,Years order by Month_num) as Running_total from(
select s.store_id,store_name,extract(year from sale_date::date) as Years ,extract(Month from sale_date::date) as Month_num,to_char(sale_date::date,'Month') as Months,sum(quantity*price) as current_month_revenue from sales as s
join products as p
on s.product_id=p.product_id
join stores as st
on s.store_id=st.store_id
where sale_date::date>=current_date-interval '4 years'
group by 1,2,3,4,5 order by 1,4 ) as yearly_data)
select * from cte 
--21.Analyze sales trends of product over time, segmented into key time periods: from launch to 6
--months, 6-12 months, 12-18 months, and beyond 18 months?
select distinct p.product_id,product_name,launch_date,
sum(case when launch_date::date>=sale_date::date-interval '6 months' then (quantity) else 0 end) as "6 months",
sum(case when launch_date::date between sale_date::date-interval '12 months' and sale_date::date-interval '6 months' then (quantity) else 0 end) as "6-12 months",
sum(case when launch_date::date<=sale_date::date-interval '18 months' then (quantity) else 0 end) as "18-months" from products as p
join sales as s
on p.product_id=s.product_id

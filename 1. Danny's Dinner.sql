---1.What is the total amount each customer spent at the restaurant?
select 
customer_id, sum(price) as 'total spent'
from dbo.menu m join dbo.sales s
on m.product_id = s.product_id
group by customer_id;

---2. How many days has each customer visited the restaurant?
select  
customer_id, count(customer_id) as days_spent 
from dbo.sales
group by customer_id;


---3. What was the first item from the menu purchased by each customer?
select 
	s.customer_id, 
	s.order_date,
	m.product_name
from dbo.sales s join dbo.menu m
on s.product_id=m.product_id
where 
s.order_date=(
select min(order_date) from dbo.sales where
product_id=s.product_id)
order by s.customer_id, m.product_name;


---using window function
with rp as(
select 
	s.customer_id, m.product_name, s.order_date,
	row_number() over(partition by s.customer_id order by s.order_date) as rn
from dbo.sales s join dbo.menu m 
on s.product_id=m.product_id)
select customer_id, order_date, product_name
	from rp 
	where rn=1
	order by customer_id;

select * 
	from sales s join menu m on s.product_id=m.product_id
	where
	s.order_date = (select min(order_date) from sales where customer_id=s.customer_id);


---4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1
	m.product_name, s.product_id, count(s.product_id) as products
	from sales s join menu m 
	on s.product_id=m.product_id
	group by m.product_name, s.product_id
	order by products desc

---how many from the most bought, are bought by each customers ?
with cte as(
	select top 1
		m.product_name, s.product_id, count(s.product_id) as products
		from sales s join menu m 
		on s.product_id=m.product_id
		group by m.product_name, s.product_id
		order by products desc
		)
		select 
			s.customer_id, count(s.product_id) as count_by_customer
			from sales s join cte c on s.product_id=c.product_id
			group by s.customer_id;


---5. Which item was the most popular for each customer?
with cnr as(
		select s.customer_id,  m.product_name, count(s.product_id) as ordered_number,
		rank() over(partition by s.customer_id order by count(s.product_id) desc) as most_ordered
		from sales s join menu m on s.product_id=m.product_id
		group by s.customer_id, m.product_name
	)
	select customer_id,product_name, ordered_number from cnr where most_ordered=1
;


---6. Which item was purchased first by the customer after they became a member?
with cte as(
select 
	s.customer_id, m.product_name, order_date, join_date,
	row_number() over(partition by s.customer_id order by order_date) as rn
	from sales s join members mem on s.customer_id=mem.customer_id join menu m on s.product_id=m.product_id
	where order_date>=join_date)
	select customer_id,product_name  from cte where rn =1;


---7.Which item was purchased just before the customer became a member?
with cte as(
select 
	s.customer_id, m.product_name, order_date, join_date,
	row_number() over(partition by s.customer_id order by order_date desc) as rn
	from sales s join members mem on s.customer_id=mem.customer_id join menu m on s.product_id=m.product_id
	where order_date<join_date)
		select customer_id,product_name  from cte where rn =1;


---8. What is the total items and amount spent for each member before they became a member?
select 
	s.customer_id, count(s.product_id) as total_items, sum(price) as total_cost
	from sales s join members mem on s.customer_id=mem.customer_id join menu m on s.product_id=m.product_id
	where order_date<join_date
	group by s.customer_id;


---9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	s.customer_id, 
	sum(case	
		when m.product_name = 'sushi' then price*2*10
		else price*10
	 END) as points
	from sales s  join menu m on 
	s.product_id=m.product_id
	group by s.customer_id;


---10.In the first week after a customer joins the program (including their join date) 
---they earn 2x points on all items, not just sushi - how many points do customer
---A and B have at the end of January?
select 
	s.customer_id, 
	sum(case	
		when order_date between join_date and DATEADD(day,6,join_date) then price*2*10
		else price*10
	 END) as points
	from sales s  join menu m on 
	s.product_id=m.product_id
	join members mem on s.customer_id=mem.customer_id
	where order_date <= cast('2021-01-31' as date)
	group by s.customer_id;

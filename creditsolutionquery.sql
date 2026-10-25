
select * from credit;

/* 1 write a query to print top 5 cities with highest spends 
and their percentage contribution of total credit card spends*/

with cte1 as(
select city,sum(amount) as total_spend
from credit
group by city)
,total_spent as (
select sum(cast(amount as bigint)) as total_amount from credit
)
select top 5 cte1.*,round(total_spend*1.0/total_amount *100,2) as percentage
from cte1,total_spent
order by total_spend desc

/* 2 write a query to print highest spend month and amount spent in that month for each card type*/

with cte as(
select card_type,sum(amount) as total_spend,datepart(year,transaction_date) as yt,datepart(month,transaction_date) as mt
from credit 
group by card_type,datepart(year,transaction_date),datepart(month,transaction_date)
--order by card_type,total_spend desc
)
select * from (select *,
rank() over(partition by card_type order by total_spend desc) as rn
from cte) a
where rn=1

/* 3  write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of  1,000,000 total spends */

with cte as(
select *,sum(amount) over (partition by card_type order by transaction_date) as total_spend
from credit
) select * from (select *,rank() over (partition by card_type order by transaction_date) as rn
from cte where total_spend>1000000) a
where rn=1

/* 4 write a query to find city which had lowest percentage spend for gold card type */

with cte as (
select city,card_type,sum(amount) as total,
sum( case when card_type='gold' then amount end) as gold_amount
from credit
group by city,card_type
)
select top 5 city,sum(gold_amount)*1.0/sum(total) as gold_ratio
from cte 
group by city
having sum(gold_amount) is not null
order by gold_ratio

/* 5 write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel) */

with cte as (
select city,exp_type,sum(amount) as total_amount
from credit
group by city,exp_type
)
select city,
min(case when rn_desc=1 then exp_type end) as highest_expense,
max(case when rn_asc=1 then exp_type end) as lowest_expense
from (select *,
rank() over (partition by city order by total_amount desc) as rn_desc,
rank() over (partition by city order by total_amount asc) as rn_asc
from cte) a
group by city


/* 6. write a query to find percentage contribution of spends by females for each expense type */

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_ratio
from credit
group by exp_type
order by percentage_ratio desc


/*7. which card and expense type combination saw highest month over month growth in Jan-2014 */

with cte as (
select card_type,exp_type,datepart(year,transaction_date) as yr,
datepart(month,transaction_date) as month,
sum(amount) as total
from credit
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select *, (total-pre_month_spend)*1.0/pre_month_spend as mom_spend
from (select *,
lag(total,1) over (partition by card_type,exp_type order by yr,month) as pre_month_spend
from cte) a
where pre_month_spend is not null 
and month=1 and yr=2014

/*8. during weekends which city has highest total spend to total no of transcations ratio */

select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit
where datepart(weekday,transaction_date) in (1,7)
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

/*9. which city took least number of days to reach its 500th transaction after the first transaction in that city */

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 


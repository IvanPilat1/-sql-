select   *
from qvi_transaction_data qtd;

select *
from qvi_purchase_behaviour qpb;


--1. Агрегація та групування
--Які продукти є найбільш популярними?

select "PROD_NAME" , count("PROD_NAME") as number_of_operating_PROD
from  qvi_transaction_data qtd 
group by "PROD_NAME" 
order by number_of_operating_PROD desc 


--Який продукт генерує найбільший дохід?

select "PROD_NAME" , SUM("TOT_SALES") as total_sales
from  qvi_transaction_data qtd 
group by "PROD_NAME" 
order by total_sales desc 
 

-- Які магазини мають найбільший обсяг продажів?

select "STORE_NBR" , COUNT("DATE")
from qvi_transaction_data qtd 
group by "STORE_NBR" 
order by COUNT("DATE") desc;


--2.Робота з датами
--Які дні тижня є найбільш активними з точки зору продажів?

select to_char(DATE '1899-12-30' + interval '1 day' * "DATE" , 'Day') as Day_for_week,
	   sum("TOT_SALES") 
from qvi_transaction_data
group by to_char(DATE '1899-12-30' + interval '1 day' * "DATE" , 'Day') 
order by sum("TOT_SALES") desc 


--Як змінюються продажі від місяця до місяця?

select  to_char(DATE '1899-12-30' + interval '1 day' * "DATE" , 'Month') as month,
        sum("TOT_SALES")
from qvi_transaction_data qtd 
group by to_char(DATE '1899-12-30' + interval '1 day' * "DATE", 'Month')
order by sum("TOT_SALES") desc


--3. Підзапити
--Які клієнти витратили більше за середній чек по всіх транзакціях?

select sum("TOT_SALES")
from qvi_transaction_data qtd 
group by "LYLTY_CARD_NBR" 
having sum("TOT_SALES") >(

	select avg("TOT_SALES")
	from qvi_transaction_data qtd 
)


--Які продукти мають більший середній продаж, ніж середній продаж всіх продуктів?

select "PROD_NAME"
        ,avg("PROD_QTY")
from qvi_transaction_data qtd 
group by "PROD_NAME"
having avg("PROD_QTY") > (
	select avg("PROD_QTY")
	from qvi_transaction_data qtd2 
)


--Які клієнти здійснили транзакції на конкретний продукт, що мають найвищий середній чек?

select distinct "LYLTY_CARD_NBR"
from qvi_transaction_data qtd 
where "PROD_NBR" = (
	select "PROD_NBR"
	from qvi_transaction_data qtd2 
	group by "PROD_NBR" 
	order by avg("TOT_SALES") desc
	limit 1
)


 -- 4. Об’єднання таблиць (JOIN)
-- Яка частка загальних продажів припадає на преміум-клієнтів?

with premium_sales as (
	select  sum(qtd."TOT_SALES") as total_premium_sales
	from qvi_transaction_data qtd 
	inner join qvi_purchase_behaviour qpb on qtd."LYLTY_CARD_NBR" = qpb."LYLTY_CARD_NBR"
	where qpb."PREMIUM_CUSTOMER" = 'Premium'
	group by qpb."PREMIUM_CUSTOMER" 
),
total_sales as (
	select  sum(qtd."TOT_SALES") as total_sales
	from qvi_transaction_data qtd 
	inner join qvi_purchase_behaviour qpb on qtd."LYLTY_CARD_NBR" = qpb."LYLTY_CARD_NBR"
 )
 select ((ps.total_premium_sales/ts.total_sales) * 100) AS premium_sales_percentage
 from premium_sales ps , total_sales ts
 
 
 --Які категорії клієнтів здійснюють найбільше покупок?
 
 select  qpb."LIFESTAGE" 
         , sum(qtd."TOT_SALES")
	from qvi_transaction_data qtd 
	inner join qvi_purchase_behaviour qpb on qtd."LYLTY_CARD_NBR" = qpb."LYLTY_CARD_NBR"
group by qpb."LIFESTAGE" 
order by sum(qtd."TOT_SALES") desc 


 --5. Умовна логіка (CASE)
--Категоризація витрат клієнтів на основі життєвих етапів:
select   qpb."LIFESTAGE"
         ,case 
         	when avg(qtd."TOT_SALES") < 10 then  'Low'
         	when avg(qtd."TOT_SALES") between 10 and 20 then 'Medium'
         	else 'high'
         end
	from qvi_transaction_data qtd 
	inner join qvi_purchase_behaviour qpb on qtd."LYLTY_CARD_NBR" = qpb."LYLTY_CARD_NBR"
group by qpb."LIFESTAGE"


--6. Розширені запити та аналітичні функції
 --Які топ 3 продукти за обсягом продажів для кожної категорії клієнтів?
with RankedProducts as (
	select   qpb."LIFESTAGE" 
	         ,qtd."PROD_NAME" 
	         ,sum(qtd."TOT_SALES") as TotalSales
	         ,rank() over(partition by qpb."LIFESTAGE" order by sum(qtd."TOT_SALES") desc) as SalesRank
	from qvi_transaction_data qtd 
	inner join qvi_purchase_behaviour qpb on qtd."LYLTY_CARD_NBR" = qpb."LYLTY_CARD_NBR"
	group by qpb."LIFESTAGE", qtd."PROD_NAME" 
)
select "LIFESTAGE"
       ,"PROD_NAME"
       ,TotalSales
       ,SalesRank
from RankedProducts
where SalesRank < 4 


 
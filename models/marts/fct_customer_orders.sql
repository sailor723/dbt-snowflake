with
-- import CTEs
customers as (
    select 
        *
    from {{ ref('stg_jaffle_shop__customers') }}
),

paid_orders as (
    select 
        *
    from {{ ref('inter_orders') }}
),  -- <-- Added comma here

-- logical CTEs


-- final CTEs

-- simple select

-- final CTEs
final as (
    select
        paid_orders.order_id,
        paid_orders.customer_id,
        paid_orders.order_placed_at,
        paid_orders.order_status,
        paid_orders.total_amount_paid,
        paid_orders.payment_finalized_date,
        customers.customer_first_name,
        customers.customer_last_name,

        -- sales transaction sequence
        row_number() over (order by paid_orders.order_id) as transaction_seq,

        -- customer transaction sequence
        row_number() over (partition by paid_orders.customer_id order by paid_orders.order_id) as customer_sales_seq,

        -- new vs returning customer 
        case 
            when (
                rank() over (
                    partition by paid_orders.customer_id
                    order by paid_orders.order_placed_at, paid_orders.order_id
                ) = 1
            ) then 'new'
            else 'return' 
        end as nvsr,

        -- customer_lifetime_value
        sum(total_amount_paid) over (
            partition by customer_id	         
            order by order_placed_at	            
        ) as customer_lifetime_value,	             

        -- first day of sales
        first_value(paid_orders.order_placed_at) over (
            partition by paid_orders.customer_id
            order by paid_orders.order_placed_at
        ) as fdos
    from paid_orders
    left join customers on paid_orders.customer_id = customers.customer_id
)

select * from final;
DELETE
FROM mart.f_customer_retention
WHERE period_id=(SELECT week_of_year_iso FROM mart.d_calendar WHERE date_actual = '{{ds}}'::DATE);

WITH weekly_orders AS (
    SELECT
        dc.week_of_year_iso AS period_id,
        s.customer_id,
        s.item_id,
        COUNT(*) AS order_count,
        SUM(s.payment_amount) FILTER (WHERE status = 'shipped') AS total_payment_shipped,
        COUNT(*) FILTER (WHERE status = 'refunded') AS refund_count
    FROM
        mart.f_sales s JOIN mart.d_calendar dc ON dc.date_id = s.date_id
    WHERE dc.date_actual = '{{ds}}'::DATE
    GROUP BY
        dc.week_of_year_iso,
        customer_id,
        item_id
),
customer_types AS (
    SELECT
        period_id,
        customer_id,
        COUNT(DISTINCT item_id) AS item_count,
        SUM(order_count) AS total_orders,
        SUM(total_payment_shipped) AS total_payment_shipped,
        SUM(refund_count) AS total_refund_count,
        CASE
            WHEN SUM(order_count) = 1 THEN 'new'
            ELSE 'returning'
        END AS customer_type,
        CASE
            WHEN SUM(refund_count) > 1 THEN 'refunded'
            ELSE 'non_refunded'
        END AS refund_status
    FROM
        weekly_orders
    GROUP BY
        period_id,
        customer_id
),
summary AS (
    SELECT
        wo.period_id AS period_id,
        'weekly' AS period_name,
        item_id,
        COUNT(DISTINCT CASE WHEN ct.customer_type = 'new' THEN wo.customer_id END) AS new_customers_count,
        COUNT(DISTINCT CASE WHEN ct.customer_type = 'returning' THEN wo.customer_id END) AS returning_customers_count,
        COUNT(DISTINCT CASE WHEN ct.refund_status = 'refunded' THEN wo.customer_id END) AS refunded_customer_count,
        SUM(CASE WHEN ct.customer_type = 'new' THEN wo.total_payment_shipped ELSE 0 END) AS new_customers_revenue,
        SUM(CASE WHEN ct.customer_type = 'returning' THEN wo.total_payment_shipped ELSE 0 END) AS returning_customers_revenue,
        SUM(wo.refund_count) AS customers_refunded
    FROM
        weekly_orders wo
    JOIN
        customer_types ct
    ON
        wo.period_id = ct.period_id AND wo.customer_id = ct.customer_id
    GROUP BY
        wo.period_id,
        item_id
)
INSERT INTO mart.f_customer_retention
SELECT
    period_name,
    period_id,
    item_id,
    new_customers_count,
    returning_customers_count,
    refunded_customer_count,
    new_customers_revenue,
    returning_customers_revenue,
    customers_refunded
FROM
    summary
ORDER BY
    period_id,
    item_id;
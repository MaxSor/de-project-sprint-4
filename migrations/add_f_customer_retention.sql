CREATE TABLE mart.f_customer_retention (
	period_name varchar(15) NOT NULL,
	period_id varchar(15) NOT NULL,
	item_id int4 NOT NULL,
	new_customers_count int8 NOT NULL,
	returning_customers_count int8 NOT NULL,
	refunded_customer_count int8 NOT NULL,
	new_customers_revenue int8 NOT NULL,
	returning_customers_revenue int8 NOT NULL,
	customers_refunded int8 NOT NULL,
	CONSTRAINT f_customer_retention_item_id_fkey FOREIGN KEY (item_id) REFERENCES mart.d_item(item_id)
);
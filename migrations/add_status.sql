ALTER TABLE mart.f_sales ADD COLUMN status varchar(15) NOT NULL Default 'shipped';
ALTER TABLE staging.user_order_log  ADD COLUMN status varchar(15) NOT NULL Default 'shipped';
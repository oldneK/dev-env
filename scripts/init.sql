-- Create Schemas
CREATE DATABASE IF NOT EXISTS monolith_db;
CREATE DATABASE IF NOT EXISTS user_service_db;
CREATE DATABASE IF NOT EXISTS order_service_db;

-- Create Users
-- User for monolith
CREATE USER IF NOT EXISTS 'monolith_user'@'%' IDENTIFIED BY 'monolith_pass';
GRANT ALL PRIVILEGES ON monolith_db.* TO 'monolith_user'@'%';

-- User for user-service
CREATE USER IF NOT EXISTS 'user_service_user'@'%' IDENTIFIED BY 'user_pass';
GRANT ALL PRIVILEGES ON user_service_db.* TO 'user_service_user'@'%';

-- User for order-service
CREATE USER IF NOT EXISTS 'order_service_user'@'%' IDENTIFIED BY 'order_pass';
GRANT ALL PRIVILEGES ON order_service_db.* TO 'order_service_user'@'%';


FLUSH PRIVILEGES;


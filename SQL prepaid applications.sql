CREATE DATABASE prepaid_db;
USE prepaid_db;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    mobile VARCHAR(15),
    password VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recharge plans table
CREATE TABLE recharge_plans (
    id VARCHAR(50) PRIMARY KEY,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    validity VARCHAR(50) NOT NULL,
    operator VARCHAR(50) NOT NULL,
    circle VARCHAR(50) NOT NULL,
    data VARCHAR(50),
    talktime VARCHAR(50)
);

-- Transactions table
CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    transaction_id VARCHAR(50) NOT NULL,
    mobile_number VARCHAR(15) NOT NULL,
    operator VARCHAR(50) NOT NULL,
    circle VARCHAR(50) NOT NULL,
    plan_id VARCHAR(50),
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    payment_id VARCHAR(100),
    payment_date TIMESTAMP NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (plan_id) REFERENCES recharge_plans(id)
);

-- Auto recharge table
CREATE TABLE auto_recharge (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    mobile_number VARCHAR(15) NOT NULL,
    operator VARCHAR(50) NOT NULL,
    plan_id VARCHAR(50) NOT NULL,
    frequency ENUM('DAY', 'WEEK', 'MONTH') NOT NULL,
    next_recharge_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (plan_id) REFERENCES recharge_plans(id),
    UNIQUE KEY (user_id, mobile_number)
);

-- Insert sample admin user
INSERT INTO users (name, email, mobile, password, is_admin) 
VALUES ('Admin User', 'admin@example.com', '9876543210', SHA2('admin123', 256), TRUE);

-- Insert sample recharge plans
INSERT INTO recharge_plans (id, description, amount, validity, operator, circle, data, talktime) VALUES
('airtel_199', 'Airtel 1.5GB/Day + Unlimited Calls', 199.00, '28 Days', 'airtel', 'delhi', '1.5GB/Day', 'Unlimited'),
('jio_299', 'Jio 2GB/Day + Jio Apps', 299.00, '28 Days', 'jio', 'delhi', '2GB/Day', 'Unlimited'),
('vi_149', 'Vi 1GB/Day + Unlimited Calls', 149.00, '28 Days', 'vi', 'delhi', '1GB/Day', 'Unlimited'),
('bsnl_109', 'BSNL 1GB + 100mins/day', 109.00, '28 Days', 'bsnl', 'delhi', '1GB/Day', '100mins/day');
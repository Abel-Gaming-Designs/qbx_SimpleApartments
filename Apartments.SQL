CREATE TABLE IF NOT EXISTS apartments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(60) NOT NULL,
    apartment_id VARCHAR(50) NOT NULL,
    bucket INT NOT NULL
);
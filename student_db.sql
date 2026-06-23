CREATE SCHEMA IF NOT EXISTS student_db;

USE student_db;

CREATE TABLE students (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_name VARCHAR(100) NOT NULL,
    course VARCHAR(100),
    email VARCHAR(100),
    age INT,
    PRIMARY KEY (id)
);

INSERT INTO students (student_name, course, email, age) VALUES
('Rahul Sharma', 'Computer Science', 'rahul@gmail.com', 21),
('Priya Verma', 'Mechanical Engineering', 'priya@gmail.com', 22),
('Amit Kumar', 'Electronics', 'amit@gmail.com', 20),
('Sneha Gupta', 'Information Technology', 'sneha@gmail.com', 23),
('Vikas Singh', 'Civil Engineering', 'vikas@gmail.com', 21);
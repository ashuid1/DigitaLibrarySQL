-- Create the LibraryManagementSystem database
CREATE DATABASE LibraryManagementSystem;

-- Switch to the newly created database
USE LibraryManagementSystem;

-- Create the Books table
CREATE TABLE Books (
    BookID INT PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(50),
    Genre VARCHAR(30),
    AvailableCopies INT
);

-- Create the Patrons table
CREATE TABLE Patrons (
    PatronID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(20)
);

-- Create the Transactions table
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY,
    BookID INT,
    PatronID INT,
    CheckoutDate DATE,
    DueDate DATE,
    ReturnDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (PatronID) REFERENCES Patrons(PatronID)
);

-- Insert sample data into the Books table
INSERT INTO Books (BookID, Title, Author, Genre, AvailableCopies)
VALUES
    (1, 'The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', 5),
    (2, 'To Kill a Mockingbird', 'Harper Lee', 'Fiction', 3),
    (3, '1984', 'George Orwell', 'Science Fiction', 7),
    (4, 'Pride and Prejudice', 'Jane Austen', 'Romance', 4);

-- Insert sample data into the Patrons table
INSERT INTO Patrons (PatronID, FirstName, LastName, Email, Phone)
VALUES
    (1, 'John', 'Doe', 'john.doe@example.com', '555-1234'),
    (2, 'Jane', 'Smith', 'jane.smith@example.com', '555-5678'),
    (3, 'Michael', 'Johnson', 'michael.johnson@example.com', '555-9876');

-- Insert sample data into the Transactions table
INSERT INTO Transactions (TransactionID, BookID, PatronID, CheckoutDate, DueDate, ReturnDate)
VALUES
    (1, 1, 1, '2023-08-10', '2023-08-20', NULL),
    (2, 2, 2, '2023-08-12', '2023-08-22', NULL),
    (3, 3, 3, '2023-08-15', '2023-08-25', NULL),
    (4, 4, 1, '2023-08-18', '2023-08-28', NULL);

-- Add a new book to Book table

INSERT INTO Books (BookID, Title, Author, Genre, AvailableCopies)
VALUES (5, 'The Catcher in the Rye', 'J.D. Salinger', 'Classic', 2);

-- Register the new Patron to Patron Table

INSERT INTO Patrons (PatronID, FirstName, LastName, Email, Phone)
VALUES (4, 'Emily', 'Brown', 'emily.brown@example.com', '555-4321');

-- Record a New Transaction When a Patron Checks Out a Book

INSERT INTO Transactions (TransactionID, BookID, PatronID, CheckoutDate, DueDate, ReturnDate)
VALUES (5, 2, 4, '2023-08-20', '2023-08-30', NULL);

--  Update the AvailableCopies Column When a Book Is Checked Out or Returned

UPDATE Books
SET AvailableCopies = AvailableCopies - 1
WHERE BookID = 2;

-- BookID 2 was returned
UPDATE Books
SET AvailableCopies = AvailableCopies + 1
WHERE BookID = 2;

-- Mark a Transaction as Returned When a Book Is Returned by a Patron
UPDATE Transactions
SET ReturnDate = CURDATE()  -- Assuming today is the return date
WHERE TransactionID = 5;

-- Report of Checked-Out Books with Patron Information
SELECT
    t.TransactionID,
    b.Title AS BookTitle,
    p.FirstName AS PatronFirstName,
    p.LastName AS PatronLastName,
    t.CheckoutDate,
    t.DueDate
FROM Transactions t
JOIN Books b ON t.BookID = b.BookID
JOIN Patrons p ON t.PatronID = p.PatronID
WHERE t.ReturnDate IS NULL;

-- Total Number of Books Checked Out by Each Patron
SELECT
    p.PatronID,
    p.FirstName,
    p.LastName,
    COUNT(t.TransactionID) AS TotalCheckedOut
FROM Patrons p
LEFT JOIN Transactions t ON p.PatronID = t.PatronID
GROUP BY p.PatronID, p.FirstName, p.LastName;

-- Most Popular Genres Based on Number of Books
SELECT
    Genre,
    COUNT(BookID) AS NumBooks
FROM Books
GROUP BY Genre
ORDER BY NumBooks DESC;

-- Late Transactions Along with Associated Fines
SELECT
    t.TransactionID,
    p.FirstName AS PatronFirstName,
    p.LastName AS PatronLastName,
    b.Title AS BookTitle,
    t.DueDate,
    t.ReturnDate,
    DATEDIFF(t.ReturnDate, t.DueDate) AS DaysLate,
    DATEDIFF(t.ReturnDate, t.DueDate) * 1 AS FineAmount  -- Assuming $1 fine per day
FROM Transactions t
JOIN Patrons p ON t.PatronID = p.PatronID
JOIN Books b ON t.BookID = b.BookID
WHERE t.ReturnDate > t.DueDate;

-- Patron Who Has Checked Out the Most Books
SELECT
    p.PatronID,
    p.FirstName,
    p.LastName,
    COUNT(t.TransactionID) AS TotalCheckouts
FROM Patrons p
LEFT JOIN Transactions t ON p.PatronID = t.PatronID
GROUP BY p.PatronID, p.FirstName, p.LastName
ORDER BY TotalCheckouts DESC
LIMIT 1;

-- Books That Have Never Been Checked Out
SELECT
    b.BookID,
    b.Title
FROM Books b
LEFT JOIN Transactions t ON b.BookID = t.BookID
WHERE t.TransactionID IS NULL;

-- Average Checkout Duration for Books
SELECT
    b.BookID,
    b.Title,
    AVG(DATEDIFF(t.ReturnDate, t.CheckoutDate)) AS AvgCheckoutDuration
FROM Books b
JOIN Transactions t ON b.BookID = t.BookID
WHERE t.ReturnDate IS NOT NULL
GROUP BY b.BookID, b.Title;

-- Most Popular Author Based on Number of Checkouts
SELECT
    b.Author,
    COUNT(t.TransactionID) AS TotalCheckouts
FROM Books b
LEFT JOIN Transactions t ON b.BookID = t.BookID
GROUP BY b.Author
ORDER BY TotalCheckouts DESC
LIMIT 1;


-- Add foreign key constraint to Transactions table
ALTER TABLE Transactions
ADD CONSTRAINT FK_Book FOREIGN KEY (BookID) REFERENCES Books(BookID),
ADD CONSTRAINT FK_Patron FOREIGN KEY (PatronID) REFERENCES Patrons(PatronID);

-- Handling Scenarios of Overbooked Books
DELIMITER //

CREATE TRIGGER CheckAvailableCopies
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE available INT;

    SELECT AvailableCopies INTO available
    FROM Books
    WHERE BookID = NEW.BookID;

    IF available < 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This book is not available for checkout';
    END IF;
END;
//

DELIMITER ;

--  Fine Calculation System in SQL
DELIMITER //

CREATE TRIGGER CalculateFine
BEFORE UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.ReturnDate > NEW.DueDate THEN
        SET NEW.FineAmount = DATEDIFF(NEW.ReturnDate, NEW.DueDate) * 1; -- Assuming $1 fine per day
    ELSE
        SET NEW.FineAmount = 0;
    END IF;
END;
//

DELIMITER ;
show tables;






CREATE DATABASE QuanLyQuanCafe
GO

USE QuanLyQuanCafe
GO

-- Food
-- Table
-- FoodCategory
-- Account
-- Bill
-- BillInfo

CREATE TABLE TableFood
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'B�n ch?a c� t�n',
	status NVARCHAR(100) NOT NULL DEFAULT N'Tr?ng'	-- Tr?ng || C� ng??i
)
GO

CREATE TABLE Account
(
	UserName NVARCHAR(100) PRIMARY KEY,	
	DisplayName NVARCHAR(100) NOT NULL DEFAULT N'Kter',
	PassWord NVARCHAR(1000) NOT NULL DEFAULT 0,
	Type INT NOT NULL  DEFAULT 0 -- 1: admin && 0: staff
)
GO

CREATE TABLE FoodCategory
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Ch?a ??t t�n'
)
GO

CREATE TABLE Food
(
	id INT IDENTITY PRIMARY KEY,
	name NVARCHAR(100) NOT NULL DEFAULT N'Ch?a ??t t�n',
	idCategory INT NOT NULL,
	price FLOAT NOT NULL DEFAULT 0
	
	FOREIGN KEY (idCategory) REFERENCES FoodCategory(id)
)
GO

CREATE TABLE Bill
(
	id INT IDENTITY PRIMARY KEY,
	DateCheckIn DATE NOT NULL DEFAULT GETDATE(),
	DateCheckOut DATE,
	idTable INT NOT NULL,
	status INT NOT NULL DEFAULT 0, -- 1: ?� thanh to�n && 0: ch?a thanh to�n
	discount int ,
	totalPrice float
	FOREIGN KEY (idTable) REFERENCES TableFood(id)
)
GO


CREATE TABLE BillInfo
(
	id INT IDENTITY PRIMARY KEY,
	idBill INT NOT NULL,
	idFood INT NOT NULL,
	count INT NOT NULL DEFAULT 0
	
	FOREIGN KEY (idBill) REFERENCES dbo.Bill(id),
	FOREIGN KEY (idFood) REFERENCES dbo.Food(id)
)
GO
--------------------------
--t?o trigger
CREATE TRIGGER UTG_UpdateBillInfo
ON dbo.BillInfo FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @idBill INT
	
	SELECT @idBill = idBill FROM Inserted
	
	DECLARE @idTable INT
	
	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill AND status = 0	
	
	DECLARE @count INT
	SELECT @count = COUNT(*) FROM dbo.BillInfo WHERE idBill = @idBill
	
	IF (@count > 0)
	BEGIN
	
		
		UPDATE dbo.TableFood SET status = N'C� ng??i' WHERE id = @idTable		
		
	END		
	ELSE
	BEGIN

	UPDATE dbo.TableFood SET status = N'Tr?ng' WHERE id = @idTable	
	end
	
END
GO


CREATE TRIGGER UTG_UpdateBill
ON dbo.Bill FOR UPDATE
AS
BEGIN
	DECLARE @idBill INT
	
	SELECT @idBill = id FROM Inserted	
	
	DECLARE @idTable INT
	
	SELECT @idTable = idTable FROM dbo.Bill WHERE id = @idBill
	
	DECLARE @count int = 0
	
	SELECT @count = COUNT(*) FROM dbo.Bill WHERE idTable = @idTable AND status = 0
	
	IF (@count = 0)
		UPDATE dbo.TableFood SET status = N'Tr?ng' WHERE id = @idTable
END
GO
CREATE TRIGGER UTG_DeleteBillInfo
ON BillInfo FOR DELETE
AS 
BEGIN
	DECLARE @idBillInfo INT
	DECLARE @idBill INT
	SELECT @idBillInfo = id, @idBill = Deleted.idBill FROM Deleted
	
	DECLARE @idTable INT
	SELECT @idTable = idTable FROM Bill WHERE id = @idBill
	
	DECLARE @count INT = 0
	
	SELECT @count = COUNT(*) FROM BillInfo AS bi, Bill AS b WHERE b.id = bi.idBill AND b.id = @idBill AND b.status = 0
	
	IF (@count = 0)
		UPDATE dbo.TableFood SET status = N'Tr?ng' WHERE id = @idTable
END
GO
--- T?o procedure 
CREATE PROC USP_GetAccountByUserName
@userName nvarchar(100)
AS 
BEGIN
	SELECT * FROM dbo.Account WHERE UserName = @userName
END
GO

CREATE PROC USP_Login
@userName nvarchar(100), @passWord nvarchar(100)
AS
BEGIN
	SELECT * FROM dbo.Account WHERE UserName = @userName AND PassWord = @passWord
END
GO

-- th�m b�n
DECLARE @i INT = 0

WHILE @i <= 10
BEGIN
	INSERT dbo.TableFood ( name)VALUES  ( N'B�n ' + CAST(@i AS nvarchar(100)))
	SET @i = @i + 1
END
GO

CREATE PROC USP_GetTableList
AS SELECT * FROM dbo.TableFood
GO



CREATE PROC USP_InsertBill
@idTable INT
AS
BEGIN
	INSERT dbo.Bill 
	        ( DateCheckIn ,
	          DateCheckOut ,
	          idTable ,
	          status,
	          discount
	        )
	VALUES  ( GETDATE() , -- DateCheckIn - date
	          NULL , -- DateCheckOut - date
	          @idTable , -- idTable - int
	          0,  -- status - int
	          0
	        )
END
GO

CREATE PROC USP_InsertBillInfo
@idBill INT, @idFood INT, @count INT
AS
BEGIN

	DECLARE @isExitsBillInfo INT
	DECLARE @foodCount INT = 1
	
	SELECT @isExitsBillInfo = id, @foodCount = b.count 
	FROM dbo.BillInfo AS b 
	WHERE idBill = @idBill AND idFood = @idFood

	IF (@isExitsBillInfo > 0)
	BEGIN
		DECLARE @newCount INT = @foodCount + @count
		IF (@newCount > 0)
			UPDATE dbo.BillInfo	SET count = @foodCount + @count WHERE idFood = @idFood
		ELSE
			DELETE dbo.BillInfo WHERE idBill = @idBill AND idFood = @idFood
	END
	ELSE
	BEGIN
		INSERT	dbo.BillInfo
        ( idBill, idFood, count )
		VALUES  ( @idBill, -- idBill - int
          @idFood, -- idFood - int
          @count  -- count - int
          )
	END
END
GO



CREATE PROC USP_SwitchTable
@idTable1 INT, @idTable2 int
AS BEGIN

	DECLARE @idFirstBill int
	DECLARE @idSeconrdBill INT
	
	DECLARE @isFirstTablEmty INT = 1
	DECLARE @isSecondTablEmty INT = 1
	
	
	SELECT @idSeconrdBill = id FROM dbo.Bill WHERE idTable = @idTable2 AND status = 0
	SELECT @idFirstBill = id FROM dbo.Bill WHERE idTable = @idTable1 AND status = 0

	
	IF (@idFirstBill IS NULL)
	BEGIN
		INSERT dbo.Bill
		        ( DateCheckIn ,
		          DateCheckOut ,
		          idTable ,
		          status
		        )
		VALUES  ( GETDATE() , -- DateCheckIn - date
		          NULL , -- DateCheckOut - date
		          @idTable1 , -- idTable - int
		          0  -- status - int
		        )
		        
		SELECT @idFirstBill = MAX(id) FROM dbo.Bill WHERE idTable = @idTable1 AND status = 0
		
	END
	
	SELECT @isFirstTablEmty = COUNT(*) FROM dbo.BillInfo WHERE idBill = @idFirstBill

	
	IF (@idSeconrdBill IS NULL)
	BEGIN
		INSERT dbo.Bill
		        ( DateCheckIn ,
		          DateCheckOut ,
		          idTable ,
		          status
		        )
		VALUES  ( GETDATE() , -- DateCheckIn - date
		          NULL , -- DateCheckOut - date
		          @idTable2 , -- idTable - int
		          0  -- status - int
		        )
		SELECT @idSeconrdBill = MAX(id) FROM dbo.Bill WHERE idTable = @idTable2 AND status = 0
		
	END
	
	SELECT @isSecondTablEmty = COUNT(*) FROM dbo.BillInfo WHERE idBill = @idSeconrdBill
	
	SELECT id INTO IDBillInfoTable FROM dbo.BillInfo WHERE idBill = @idSeconrdBill
	
	UPDATE dbo.BillInfo SET idBill = @idSeconrdBill WHERE idBill = @idFirstBill
	
	UPDATE dbo.BillInfo SET idBill = @idFirstBill WHERE id IN (SELECT * FROM IDBillInfoTable)
	
	DROP TABLE IDBillInfoTable
	
	IF (@isFirstTablEmty = 0)
		UPDATE dbo.TableFood SET status = N'Tr?ng' WHERE id = @idTable2
		
	IF (@isSecondTablEmty= 0)
		UPDATE dbo.TableFood SET status = N'Tr?ng' WHERE id = @idTable1
END
GO



Create PROC USP_GetListBillByDate
@checkIn date, @checkOut date
AS 
BEGIN
	SELECT t.name AS [T�n b�n],  DateCheckIn AS [T? ng�y], DateCheckOut AS [T?i ng�y], discount AS [Gi?m gi�],b.totalPrice AS [T?ng ti?n (000 VND)]
	FROM dbo.Bill AS b,dbo.TableFood AS t
	WHERE DateCheckIn >= @checkIn AND DateCheckOut <= @checkOut AND b.status = 1
	AND t.id = b.idTable
END
GO

CREATE PROC USP_UpdateAccount
@userName NVARCHAR(100), @displayName NVARCHAR(100), @password NVARCHAR(100), @newPassword NVARCHAR(100)
AS
BEGIN
	DECLARE @isRightPass INT = 0
	
	SELECT @isRightPass = COUNT(*) FROM dbo.Account WHERE USERName = @userName AND PassWord = @password
	
	IF (@isRightPass = 1)
	BEGIN
		IF (@newPassword = NULL OR @newPassword = '')
		BEGIN
			UPDATE dbo.Account SET DisplayName = @displayName WHERE UserName = @userName
		END		
		ELSE
			UPDATE dbo.Account SET DisplayName = @displayName, PassWord = @newPassword WHERE UserName = @userName
	end
END
GO



Create PROC USP_GetListBillByDateAndPage
@checkIn date, @checkOut date, @page int
AS 
BEGIN
	DECLARE @pageRows INT = 10
	DECLARE @selectRows INT = @pageRows
	DECLARE @exceptRows INT = (@page - 1) * @pageRows
	
	;WITH BillShow AS( SELECT b.ID, t.name AS [T�n b�n], b.totalPrice AS [T?ng ti?n], DateCheckIn AS [T? ng�y], DateCheckOut AS [T?i ng�y], discount AS [Gi?m gi�]
	FROM dbo.Bill AS b,dbo.TableFood AS t
	WHERE DateCheckIn >= @checkIn AND DateCheckOut <= @checkOut AND b.status = 1
	AND t.id = b.idTable)
	
	SELECT TOP (@selectRows) * FROM BillShow WHERE id NOT IN (SELECT TOP (@exceptRows) id FROM BillShow)
END
GO

CREATE PROC USP_GetNumBillByDate
@checkIn date, @checkOut date
AS 
BEGIN
	SELECT COUNT(*)
	FROM dbo.Bill AS b,dbo.TableFood AS t
	WHERE DateCheckIn >= @checkIn AND DateCheckOut <= @checkOut AND b.status = 1
	AND t.id = b.idTable
END
GO
--------------------------- th�m d? li?u

INSERT INTO dbo.ACCOUNT(USERNAME,DISPLAYNAME,PASSWORD,TYPE) 
VALUES (N'thanh',N'thanh',N'1',1)

INSERT INTO dbo.ACCOUNT(USERNAME,DISPLAYNAME,PASSWORD,TYPE) 
VALUES (N'staff',N'staff',N'1',0)


-- th�m b�n

set identity_insert dbo.TableFood on


insert into TABLEFOOD(ID,NAME,STATUS) values(1,N'B�n 1',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(2,N'B�n 2',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(3,N'B�n 3',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(4,N'B�n 4',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(5,N'B�n 5',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(6,N'B�n 6',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(7,N'B�n 7',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(8,N'B�n 8',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(9,N'B�n 9',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(10,N'B�n 10',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(11,N'B�n 11',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(12,N'B�n 12',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(13,N'B�n 13',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(14,N'B�n 14',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(15,N'B�n 15',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(16,N'B�n 16',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(17,N'B�n 17',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(18,N'B�n 18',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(19,N'B�n 19',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(20,N'B�n 20',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(21,N'B�n 21',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(22,N'B�n 22',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(23,N'B�n 23',N'Tr?ng')
insert into TABLEFOOD(ID,NAME,STATUS) values(24,N'B�n 24',N'Tr?ng')
set identity_insert dbo.TableFood off
SELECT * FROM TABLEFOOD



-- idcategory : 1-Tra , 2-DaXay, 3-SinhTo, 4-Cafe, 5-DoAn
set identity_insert FOODCATEGORY on


INSERT FOODCATEGORY(ID,NAME) VALUES (1,N'Tr�')
INSERT FOODCATEGORY(ID,NAME) VALUES (2,N'?� xay')
INSERT FOODCATEGORY(ID,NAME) VALUES (3,N'Sinh t?')
INSERT FOODCATEGORY(ID,NAME) VALUES (4,N'Cafe')
INSERT FOODCATEGORY(ID,NAME) VALUES (5,N'?? ?n')
set identity_insert FOODCATEGORY off
SELECT * FROM FOODCATEGORY 
--th�m n??c u?ng v� ?? ?n

set identity_insert dbo.Food on 
-- id: 1-Tra
INSERT into Food(id,Name,idCategory,price) values ('01','Oolong Milk Tea','1','45000')
insert into Food(id,Name,idCategory,price) values('02','Tra dao','1','25000')
insert into Food(id,Name,idCategory,price) values('03','Tra nhan','1','25000')
insert into Food(id,Name,idCategory,price) values('04','Tra lai','1','22000')
insert into Food(id,Name,idCategory,price) values('05','Tra vai-hat sen','1','25000')
insert into Food(id,Name,idCategory,price) values('06','Tra thao mon','1','30000')
insert into Food(id,Name,idCategory,price) values('07','Tra Cocktail','1','30000')
insert into Food(id,Name,idCategory,price) values('08','Tra Dao Sua','1','30000')
insert into Food(id,Name,idCategory,price) values('09','Tra Gung','1','25000')
insert into Food(id,Name,idCategory,price) values('10','Hong Tra Chanh','1','27000')
insert into Food(id,Name,idCategory,price) values('11','Hong Tra Vai','1','27000')
insert into Food(id,Name,idCategory,price) values('12','Tra Hoa Hong','1','35000')
insert into Food(id,Name,idCategory,price) values('13','Tra Xanh Latte','1','35000')


--id-2 da xay - 40k
insert into Food(id,Name,idCategory,price) values('14','Tra Xanh Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('15','Tra Dao Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('16','Tra Xanh Xay Cung Hanh Nhan','2','40000')
insert into Food(id,Name,idCategory,price) values('17','Capuchino Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('18','Ca Phe Bac Ha Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('19','Tra Hoa Hong','2','40000')
insert into Food(id,Name,idCategory,price) values('20','Ca Phe Xay Cung Banh Oreo','2','40000')
insert into Food(id,Name,idCategory,price) values('21','Socola Ca Phe Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('22','Caramel Da Xay','2','40000')
insert into Food(id,Name,idCategory,price) values('23','Socola Trang Da Xay','2','40000')

--- id-3   sinhto nuoc ep.
insert into Food(id,Name,idCategory,price) values('24','Nuoc Tao Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('25','Nuoc Tao Va Dau Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('26','Buoi Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('27','Sinh To Bo','3','35000')
insert into Food(id,Name,idCategory,price) values('28','Dau Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('29','Thom Va Dau Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('30','Cam Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('31','Nuoc Oi Ep','3','35000')
insert into Food(id,Name,idCategory,price) values('32','Sinh To Dau','3','35000')
insert into Food(id,Name,idCategory,price) values('33','Sinh To Trai Cay Nhiet Doi','3','35000')
insert into Food(id,Name,idCategory,price) values('34','Sinh To Chuoi-Dau','3','35000')
insert into Food(id,Name,idCategory,price) values('35','Vitamin C(Xoai,Cam,Chanh Day)','3','35000')
insert into Food(id,Name,idCategory,price) values('36','Sinh To Xoai','3','35000')
insert into Food(id,Name,idCategory,price) values('37','Sinh To Chanh','3','35000')

--id 4 -- caphe
insert into Food(id,Name,idCategory,price) values('38','Capuchino','4','35000')
insert into Food(id,Name,idCategory,price) values('39','Ca Phe Latte','4','35000')
insert into Food(id,Name,idCategory,price) values('40','Ca Phe Vanilla','4','35000')
insert into Food(id,Name,idCategory,price) values('41','Ca Phe Caramel','4','35000')
insert into Food(id,Name,idCategory,price) values('42','Ca Phe Sua','4','35000')
insert into Food(id,Name,idCategory,price) values('43','Ca Phe Den','4','30000')

--id 5 -- thuc an
INSERT into Food(id,Name,idCategory,price) values ('44','Ca vien chien','5','10000')
insert into Food(id,Name,idCategory,price) values('45','Tom vien chien','5','10000')
insert into Food(id,Name,idCategory,price) values('46','Bo vien chien','5','10000')
insert into Food(id,Name,idCategory,price) values('47','Banh mi ngot','5','7000')
insert into Food(id,Name,idCategory,price) values('48','Hoanh thanh','5','10000')
insert into Food(id,Name,idCategory,price) values('49','Ha cao','5','15000')
insert into Food(id,Name,idCategory,price) values('50','Mi trung','5','15000')
set identity_insert FOODCATEGORY off


-- database
-- Get the SQL Server data path
DECLARE @data_path nvarchar(256);
SET @data_path = (SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
                  FROM master.sys.master_files
                  WHERE database_id = 1 AND file_id = 1);
--PRINT @data_path

EXECUTE ('CREATE DATABASE riddleettest1
ON
PRIMARY  
    (NAME = riddleettest1,
    FILENAME = '''+ @data_path + 'riddleettest1.mdf'',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%)
LOG ON 
   (NAME = riddleettest1log,
    FILENAME = '''+ @data_path + 'riddleettest1log.ldf'',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%)'
);

USE riddleettest1 GO



-- tables
CREATE TABLE Player (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	UName varchar(20) NOT NULL,
	PasswordSalt varchar(50) NOT NULL,
	PasswordHash varchar(50) NOT NULL,
)
ALTER TABLE [dbo].[Player] ADD  DEFAULT ('m') FOR [PasswordSalt] GO
ALTER TABLE [dbo].[Player] ADD  DEFAULT ('m') FOR [PasswordHash] GO

CREATE TABLE TroopType (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	[Name] varchar(20) NOT NULL,
	[Level] tinyint NOT NULL,
	Damage int NOT NULL,
	AttackRate int NOT NULL,
	DamageType varchar(20) NOT NULL,
	Size tinyint NOT NULL,
	MovementType varchar(20) NOT NULL,
	MovementSpeed int NOT NULL,
	CHECK(MovementType IN ('Ground', 'Air')),
	CHECK(DamageType IN ('Single', 'Multi'))
)

CREATE TABLE BuildingType (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	[Name] varchar(20) NOT NULL,
	[Level] tinyint NOT NULL,
	BuildTime int NOT NULL,
	MaxHealth int NOT NULL,
	Size tinyint NOT NULL
)

CREATE TABLE Building (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	CreationTime datetime NOT NULL,
	PosX int NOT NULL,
	PosY int NOT NULL,
	BuildingTypeID int NOT NULL REFERENCES BuildingType(ID),
	PlayerID int NOT NULL REFERENCES Player(ID)
)

CREATE TABLE Collector (
	ID int PRIMARY KEY REFERENCES BuildingType(ID)
)

CREATE TABLE Storage (
	ID int PRIMARY KEY REFERENCES BuildingType(ID)
)

CREATE TABLE Defense (
	ID int PRIMARY KEY REFERENCES BuildingType(ID),
	Damage int NOT NULL,
	AttackRate int NOT NULL,
	DamageType varchar(20) NOT NULL,
	AttacksMovementType varchar(20) NOT NULL,
	CHECK(AttacksMovementType IN ('Ground', 'Air')),
	CHECK(DamageType IN ('Single', 'Multi'))
)

CREATE TABLE Camp (
	ID int PRIMARY KEY REFERENCES BuildingType(ID),
	Capacity int NOT NULL
)

CREATE TABLE [Resource] (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	Name varchar(20) NOT NULL
)



-- relations
CREATE TABLE BuildingUpgrades (
	FromID int REFERENCES Building(ID),
	ToID int REFERENCES Building(ID),
	PRIMARY KEY(FromID, ToID)
)

CREATE TABLE HasResource (
	PlayerID int REFERENCES Player(ID),
	ResourceID int REFERENCES [Resource](ID),
	Amount int NOT NULL,
	PRIMARY KEY(PlayerID, ResourceID)
)

CREATE TABLE HasTroop (
	PlayerID int REFERENCES Player(ID),
	TroopTypeID int REFERENCES TroopType(ID),
	Amount int NOT NULL,
	PRIMARY KEY(PlayerID, TroopTypeID)
)

CREATE TABLE TroopCosts (
	TroopID int REFERENCES TroopType(ID),
	ResourceID int REFERENCES [Resource](ID),
	Amount int NOT NULL,
	PRIMARY KEY(TroopID, ResourceID)
)

CREATE TABLE BuildingCosts (
	BuildingTypeID int REFERENCES BuildingType(ID),
	ResourceID int REFERENCES [Resource](ID),
	Amount int NOT NULL,
	PRIMARY KEY(BuildingTypeID, ResourceID)
)

CREATE TABLE CollectorCollects (
	CollectorID int REFERENCES Collector(ID),
	ResourceID int REFERENCES [Resource](ID),
	Amount int NOT NULL,
	PRIMARY KEY(CollectorID, ResourceID)
)

CREATE TABLE StorageStores (
	StorageID int REFERENCES Collector(ID),
	ResourceID int REFERENCES [Resource](ID),
	Amount int NOT NULL,
	PRIMARY KEY(StorageID, ResourceID)
)

CREATE TABLE CollectorLastCollected (
	BuildingID int REFERENCES Building(ID),
	LastCollected datetime NOT NULL
)
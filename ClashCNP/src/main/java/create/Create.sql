-- database
-- Get the SQL Server data path
DECLARE @data_path nvarchar(256);
SET @data_path = (SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
                  FROM master.sys.master_files
                  WHERE database_id = 1 AND file_id = 1);
--PRINT @data_path

EXECUTE ('CREATE DATABASE riddleettest3
ON
PRIMARY  
    (NAME = riddleettest3,
    FILENAME = '''+ @data_path + 'riddleettest3.mdf'',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%)
LOG ON 
   (NAME = riddleettest3log,
    FILENAME = '''+ @data_path + 'riddleettest3log.ldf'',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%)'
);





-- tables
CREATE TABLE Player (
	ID int IDENTITY(1, 1) PRIMARY KEY,
	UName varchar(20) NOT NULL,
	PasswordSalt varchar(50) NOT NULL,
	PasswordHash varchar(50) NOT NULL,
)
ALTER TABLE [dbo].[Player] ADD  DEFAULT ('m') FOR [PasswordSalt]
ALTER TABLE [dbo].[Player] ADD  DEFAULT ('m') FOR [PasswordHash]

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




-- sprocs
/****** Object:  StoredProcedure [dbo].[AddBuilding]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[AddBuilding] (
	@username varchar(20),
	@name varchar(20),
	@level tinyint,
	@buildTime int,
	@maxHealth int,
	@size int,
	@goldCost int,
	@elixirCost int,
	@timestamp datetime,
	@x int,
	@y int,
	@troopCapacity int,
	@collectsGold int,
	@collectsElixir int,
	@damage int,
	@attackRate int,
	@damageType varchar(20),
	@attacksMovementType varchar(20),
	@goldStorage int,
	@elixirStorage int
)
AS
BEGIN
	DECLARE @player int = (SELECT ID FROM Player WHERE UName = @username);
	DECLARE @id int;
	IF EXISTS (SELECT 1 FROM BuildingType WHERE Name = @name AND Level = @level)
	BEGIN
		SET @id = (SELECT ID FROM BuildingType WHERE Name = @name AND Level = @level);
	END ELSE BEGIN
		INSERT INTO BuildingType (Name, Level, BuildTime, MaxHealth, Size)
		VALUES (@name, @level, @buildTime, @maxHealth, @size);
		SET @id = SCOPE_IDENTITY();

		DECLARE @goldId int = (SELECT ID FROM Resource WHERE Name = 'gold');
		DECLARE @elixirId int = (SELECT ID FROM Resource WHERE Name = 'elixir');

		INSERT INTO BuildingCosts (BuildingTypeID, ResourceID, Amount)
		VALUES (@id, @goldId, @goldCost);
		INSERT INTO BuildingCosts (BuildingTypeID, ResourceID, Amount)
		VALUES (@id, @elixirId, @elixirCost);

		IF NOT @troopCapacity IS NULL
			INSERT INTO Camp (ID, Capacity)
			VALUES (@id, @troopCapacity);
		IF NOT @collectsGold IS NULL
		BEGIN
			INSERT INTO Collector (ID)
			VALUES (@id);
			INSERT INTO CollectorCollects (CollectorID, ResourceId, Amount)
			VALUES (@id, @goldId, @collectsGold);
		END
		IF NOT @collectsElixir IS NULL
		BEGIN
			INSERT INTO Collector (ID)
			VALUES (@id);
			INSERT INTO CollectorCollects (CollectorID, ResourceId, Amount)
			VALUES (@id, @elixirId, @collectsElixir);
		END
		IF NOT @damage IS NULL
			INSERT INTO Defense (ID, Damage, AttackRate, DamageType, AttacksMovementType)
			VALUES (@id, @damage, @attackRate, @damageType, @attacksMovementType)
		IF NOT @goldStorage IS NULL
		BEGIN
			INSERT INTO Storage (ID)
			VALUES (@id);
			INSERT INTO StorageStores (StorageID, ResourceID, Amount)
			VALUES (@id, @goldId, @goldStorage);
		END
		IF NOT @elixirStorage IS NULL
		BEGIN
			INSERT INTO Storage (ID)
			VALUES (@id);
			INSERT INTO StorageStores (StorageID, ResourceID, Amount)
			VALUES (@id, @elixirId, @elixirStorage);
		END

		IF @level > 1
		BEGIN
			DECLARE @prevId int = (SELECT ID FROM BuildingType WHERE Name = @name AND Level = @level - 1);
			INSERT INTO BuildingUpgrades (FromID, ToID)
			VALUES (@prevId, @id);
		END
	END
	INSERT INTO Building (CreationTime, PosX, PosY, BuildingTypeID, PlayerID)
	VALUES (@timestamp, @x, @y, @id, @player);
END
GO
/****** Object:  StoredProcedure [dbo].[AddResource]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[AddResource](
	@name varchar(20)
)
AS
INSERT INTO Resource (Name)
VALUES(@name)
GO
/****** Object:  StoredProcedure [dbo].[AddTroop]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[AddTroop] (
    @player int,
    @troop int
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;
	IF NOT EXISTS (SELECT 1 FROM TroopType WHERE ID = @troop)
		throw 50002, 'troop does not exist', 1;

	IF NOT EXISTS (SELECT 1 FROM HasTroop WHERE PlayerID = @player AND TroopTypeID = @troop)
		INSERT INTO HasTroop (PlayerID, TroopTypeID, Amount)
		VALUES (@player, @troop, 1);
	ELSE
		UPDATE HasTroop
		SET Amount = Amount + 1
		WHERE PlayerID = @player AND TroopTypeID = @troop;
END
GO
/****** Object:  StoredProcedure [dbo].[CanPlaceBuilding]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE       PROCEDURE [dbo].[CanPlaceBuilding](
	@player int,
	@x int,
	@y int,
	@type int
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50004, 'player does not exist', 1;
	IF NOT EXISTS (SELECT 1 FROM BuildingType WHERE ID = @type)
		throw 50005, 'building type does not exist', 1;

	DECLARE @level int = (SELECT [level] FROM BuildingType WHERE id = @type);
	DECLARE @name varchar(20) = (SELECT Name FROM BuildingType WHERE id = @type);
	-- Maybe could check if there's space in sql? Seems like something with enough logic that the server should validate
	IF @Level <> 1 AND (NOT EXISTS (
		SELECT 1
		FROM Building
		JOIN BuildingType ON Building.BuildingTypeID = BuildingType.ID
		WHERE Building.PlayerID = @player
			AND BuildingType.Name = @name
			AND BuildingType.[level] = @level - 1
			AND Building.PosX = @x
			AND Building.PosY = @y
	))
		throw 50003, 'Missing previous level', 1;


	DECLARE @gold int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON [Resource].id = HasResource.ResourceID
		WHERE PlayerID = @player
			AND Name = 'gold'
	);
	DECLARE @elixir int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON [Resource].id = HasResource.ResourceID
		WHERE PlayerID = @player
			AND Name = 'elixir'
	);

	IF ((
		SELECT Amount
		FROM Resource
		JOIN BuildingCosts ON Resource.id = BuildingCosts.ResourceID
		JOIN BuildingType ON BuildingType.id = BuildingCosts.BuildingTypeID
		WHERE Resource.Name = 'gold' AND BuildingType.id = @type
	) > @gold
		OR (
			SELECT Amount
			FROM Resource
			JOIN BuildingCosts ON Resource.id = BuildingCosts.ResourceID
			JOIN BuildingType on BuildingType.id = BuildingCosts.BuildingTypeID
			WHERE Resource.name = 'elixir' AND BuildingType.id = @type
		) > @elixir
	)
		throw 50002, 'Insufficient resources', 1;

	RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[CanUpgrade]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[CanUpgrade](
	@PlayerID int,
	@BuildingID int
) AS BEGIN
	-- check that things exist
	IF (NOT EXISTS (SELECT * FROM Building WHERE ID = @BuildingID))
		THROW 51000, 'Building does not exist', 1
	IF (NOT EXISTS (SELECT *
					FROM Player p
					WHERE p.ID = @PlayerID))
		THROW 51000, 'Player does not exist', 1
	IF (NOT EXISTS (SELECT *
					FROM Building b
					JOIN BuildingUpgrades bu ON bu.FromId = b.BuildingTypeID
					WHERE b.Id = @BuildingID))
		THROW 51000, 'Building cannot be upgraded', 1

	-- get player resources
	DECLARE @gold int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON [Resource].id = HasResource.ResourceID
		WHERE PlayerID = @PlayerID
			AND Name = 'gold'
	);
	DECLARE @elixir int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON [Resource].id = HasResource.ResourceID
		WHERE PlayerID = @PlayerID
			AND Name = 'elixir'
	);

	-- check for sufficient resources
	IF ((
			SELECT Amount
			FROM Building old
			JOIN BuildingUpgrades bu ON bu.FromID = old.BuildingTypeID
			JOIN BuildingCosts bc ON bc.BuildingTypeID = bu.ToID
			JOIN Resource r ON r.ID = bc.ResourceID
			WHERE old.ID = @BuildingID AND r.Name = 'gold') > @gold
		OR (
			SELECT Amount
			FROM Building old
			JOIN BuildingUpgrades bu ON bu.FromID = old.BuildingTypeID
			JOIN BuildingCosts bc ON bc.BuildingTypeID = bu.ToID
			JOIN Resource r ON r.ID = bc.ResourceID
			WHERE old.ID = @BuildingID AND r.Name = 'elixir') > @elixir)
		throw 51000, 'Insufficient resources', 1;

	-- all good
	RETURN 1
END
GO
/****** Object:  StoredProcedure [dbo].[CollectFromCollector]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[CollectFromCollector] (
	@BuildingID int
) AS BEGIN
	-- check existance
	IF (NOT EXISTS (SELECT *
					FROM Building
					WHERE ID = @BuildingID))
		THROW 51000, 'Collector does not exists', 1
	IF (NOT EXISTS (SELECT *
					FROM Building
					JOIN Collector ON Building.BuildingTypeID = Collector.ID
					WHERE Building.ID = @BuildingID))
		THROW 51000, 'Building is not a collector', 1

	-- give resources
	DECLARE @goldId int = (SELECT id FROM [Resource] WHERE [Name] = 'gold');
	DECLARE @elixirId int = (SELECT id FROM [Resource] WHERE [Name] = 'elixir');
	DECLARE @playerId int = (SELECT Building.PlayerID
							 FROM Building
							 WHERE Building.ID = @BuildingID);

	DECLARE @GoldPerSec real = (SELECT CollectorCollects.Amount
					   FROM Building
					   JOIN CollectorCollects ON CollectorCollects.CollectorID = Building.BuildingTypeID
					   WHERE Building.ID = @BuildingID
					   AND CollectorCollects.ResourceID = @goldId)

	DECLARE @ElixirPerSec real = (SELECT CollectorCollects.Amount
								  FROM Building
								  JOIN CollectorCollects ON CollectorCollects.CollectorID = Building.BuildingTypeID
								  WHERE Building.ID = @BuildingID
								  AND CollectorCollects.ResourceID = @elixirId)

	DECLARE @SecsSinceColl int = (DATEDIFF(SECOND,
										   (SELECT LastCollected
											FROM CollectorLastCollected
											WHERE CollectorLastCollected.BuildingID = @BuildingID),
											GETDATE()))

	UPDATE HasResource
	SET Amount += @GoldPerSec * @SecsSinceColl / 3600.0
	WHERE HasResource.PlayerID = @playerId
	AND HasResource.ResourceID = @goldId

	UPDATE HasResource
	SET Amount += @ElixirPerSec * @SecsSinceColl / 3600.0
	WHERE HasResource.PlayerID = @playerId
	AND HasResource.ResourceID = @elixirId

	-- reset timer
	UPDATE CollectorLastCollected
	SET LastCollected = GETDATE()
	WHERE BuildingID = @BuildingID
END
GO
/****** Object:  StoredProcedure [dbo].[DeleteBuilding]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DeleteBuilding] (
	@ID int
) AS BEGIN
	DELETE FROM Building
	WHERE ID = @ID
END
GO
/****** Object:  StoredProcedure [dbo].[GetBuildings]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE         PROCEDURE [dbo].[GetBuildings] (
	@player int
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50004, 'player does not exist', 1;

SELECT Building.ID, [name], [level], maxHealth, size, posx, posy, CreationTime
FROM Building
JOIN BuildingType ON Building.buildingTypeId = BuildingType.id
WHERE Building.PlayerID = @player
END
GO
/****** Object:  StoredProcedure [dbo].[GetBuildingTypes]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[GetBuildingTypes] 
AS
BEGIN
SELECT ID, Name, Level, BuildTime, MaxHealth, Size, GoldCost.Amount AS GoldCost, ElixirCost.Amount as ElixirCost
FROM BuildingType
LEFT JOIN BuildingCosts AS GoldCost ON BuildingType.ID = GoldCost.BuildingTypeID AND GoldCost.ResourceID = 1
LEFT JOIN BuildingCosts AS ElixirCost ON BuildingType.ID = ElixirCost.BuildingTypeID AND ElixirCost.ResourceID = 2
END
GO
/****** Object:  StoredProcedure [dbo].[GetCamps]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetCamps] AS BEGIN
	SELECT * FROM Camp
END
GO
/****** Object:  StoredProcedure [dbo].[GetCollectors]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[GetCollectors] AS BEGIN
	SELECT ID, g.Amount AS CollectsGold, e.Amount AS CollectsElixir FROM Collector
	JOIN CollectorCollects g ON Collector.ID = g.CollectorID AND g.ResourceID = 1
	JOIN CollectorCollects e ON Collector.ID = e.CollectorID AND e.ResourceID = 2
END
GO
/****** Object:  StoredProcedure [dbo].[GetCredentials]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[GetCredentials]
@Username varchar(20)
AS
SELECT PasswordHash, PasswordSalt FROM Player WHERE UName = @Username;
GO
/****** Object:  StoredProcedure [dbo].[GetDefenses]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetDefenses] AS BEGIN
	SELECT * FROM Defense
END
GO
/****** Object:  StoredProcedure [dbo].[GetElixir]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetElixir] (
	@PlayerID int
) AS BEGIN
	SELECT Amount
	FROM HasResource
	JOIN Resource ON Resource.ID = HasResource.ResourceID
	WHERE PlayerID = @PlayerID AND Resource.Name = 'elixir'
END
GO
/****** Object:  StoredProcedure [dbo].[GetGold]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetGold] (
	@PlayerID int
) AS BEGIN
	SELECT Amount
	FROM HasResource
	JOIN Resource ON Resource.ID = HasResource.ResourceID
	WHERE PlayerID = @PlayerID AND Resource.Name = 'gold'
END
GO
/****** Object:  StoredProcedure [dbo].[GetPlayerId]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPlayerId]
@Username varchar(20)
AS
BEGIN
	IF @Username IS NULL OR @Username = ''
		throw 50001, 'Username cannot be null nor empty', 1;

	SELECT ID FROM Player WHERE UName = @Username;
END
GO
/****** Object:  StoredProcedure [dbo].[GetPlayers]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPlayers]
AS
SELECT UName FROM Player;
GO
/****** Object:  StoredProcedure [dbo].[GetResource]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetResource] (
    @player int,
	@resource varchar(20)
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;
	IF NOT EXISTS (SELECT 1 FROM Resource WHERE Name = @resource)
		throw 50002, 'resource does not exist', 1;

    DECLARE @resourceId int = (
		SELECT ID
		FROM Resource
		WHERE Name = @resource
	);

	DECLARE @capacity int = (SELECT SUM(StorageStores.Amount)
	FROM Building
	JOIN Storage ON Storage.ID = Building.BuildingTypeID
	JOIN StorageStores ON StorageStores.StorageID = Storage.ID
	WHERE Building.PlayerID = @player AND StorageStores.ResourceID = @resourceId);

	IF @capacity IS NULL
		SET @capacity = 0;

	DECLARE @amount int = (SELECT Amount
	FROM HasResource
	JOIN Resource ON Resource.ID = HasResource.ResourceID
	WHERE PlayerID = @player AND Resource.ID = @resourceId);

	IF @amount > @capacity
		SELECT (@capacity) AS AMOUNT
	ELSE
		SELECT (@amount) AS AMOUNT
END
GO
/****** Object:  StoredProcedure [dbo].[GetResourceCapacity]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetResourceCapacity] (
    @player int,
	@resource varchar(20)
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;
	IF NOT EXISTS (SELECT 1 FROM Resource WHERE Name = @resource)
		throw 50002, 'resource does not exist', 1;

    DECLARE @resourceId int = (
		SELECT ID
		FROM Resource
		WHERE Name = @resource
	);

	DECLARE @capacity int = (SELECT SUM(StorageStores.Amount)
	FROM Building
	JOIN Storage ON Storage.ID = Building.BuildingTypeID
	JOIN StorageStores ON StorageStores.StorageID = Storage.ID
	WHERE Building.PlayerID = @player AND StorageStores.ResourceID = @resourceId);

	IF @capacity IS NULL
		SET @capacity = 0;
	
	SELECT (@capacity) AS Capacity
END
GO
/****** Object:  StoredProcedure [dbo].[GetStorages]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[GetStorages] AS BEGIN
	SELECT ID, g.Amount AS StoresGold, e.Amount AS StoresElixir FROM Storage
	JOIN StorageStores g ON Storage.ID = g.StorageID AND g.ResourceID = 1
	JOIN StorageStores e ON Storage.ID = e.StorageID AND e.ResourceID = 2
END
GO
/****** Object:  StoredProcedure [dbo].[GetTroopCapacity]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[GetTroopCapacity] (
    @player int)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;

	DECLARE @capacity int = (SELECT SUM(Camp.Capacity)
	FROM Building
	JOIN Camp ON Camp.ID = Building.BuildingTypeID
	WHERE Building.PlayerID = @player);

	IF @capacity IS NULL
		SET @capacity = 0;
	
	SELECT (@capacity) AS Capacity
END
GO
/****** Object:  StoredProcedure [dbo].[GetTroops]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    PROCEDURE [dbo].[GetTroops] (
    @player int)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;

	SELECT ID, Name, Level, Damage, AttackRate, DamageType, Size, MovementType, MovementSpeed, Amount
	FROM TroopType
	LEFT JOIN HasTroop ON HasTroop.TroopTypeID = TroopType.ID AND HasTroop.PlayerID = @player
	ORDER BY Name;
END
GO
/****** Object:  StoredProcedure [dbo].[LoadResource]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoadResource] (
	@username varchar(20),
	@resource varchar(20),
	@amount int
)
AS
BEGIN
	DECLARE @player int = (SELECT ID FROM Player WHERE UName = @username);
	DECLARE @resourceId int = (SELECT ID FROM Resource WHERE Name = @resource);
	INSERT INTO HasResource (PlayerID, ResourceID, Amount)
	VALUES (@player, @resourceId, @amount);
END
GO
/****** Object:  StoredProcedure [dbo].[LoadTroop]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[LoadTroop] (
	@username varchar(20),
	@name varchar(20),
	@level tinyint,
	@damage int,
	@attackRate int,
	@damageType varchar(20),
	@size tinyint,
	@movementType varchar(20),
	@movementSpeed int,
	@goldCost int,
	@elixirCost int,
	@amount int
)
AS
BEGIN
	DECLARE @player int = (SELECT ID FROM Player WHERE UName = @username);
	DECLARE @id int;
	IF EXISTS (SELECT 1 FROM TroopType WHERE Name = @name AND Level = @level)
		SET @id = (SELECT ID FROM TroopType WHERE Name = @name AND Level = @level)
	ELSE BEGIN
		INSERT INTO TroopType (Name, Level, Damage, AttackRate, DamageType, Size, MovementType, MovementSpeed)
		VALUES (@name, @level, @damage, @attackRate, @damageType, @size, @movementType, @movementSpeed);
		SET @id = SCOPE_IDENTITY();

		DECLARE @goldId int = (SELECT ID FROM Resource WHERE Name = 'gold');
		DECLARE @elixirId int = (SELECT ID FROM Resource WHERE Name = 'elixir');

		INSERT INTO TroopCosts (TroopID, ResourceID, Amount)
		VALUES (@id, @goldId, @goldCost);
		INSERT INTO TroopCosts (TroopID, ResourceID, Amount)
		VALUES (@id, @elixirId, @elixirCost);
	END

	INSERT INTO HasTroop (PlayerId, TroopTypeID, Amount)
	VALUES (@player, @id, @amount);
END
GO
/****** Object:  StoredProcedure [dbo].[PlaceBuilding]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE     PROCEDURE [dbo].[PlaceBuilding] (
	@player int,
	@x int,
	@y int,
	@type int
)
AS
BEGIN
	EXEC CanPlaceBuilding @player, @x, @y, @type;

	DECLARE @goldId int = (SELECT id FROM [Resource] WHERE [Name] = 'gold');
	DECLARE @elixirId int = (SELECT id FROM [Resource] WHERE [Name] = 'elixir');
	DECLARE @gold int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @player
			AND [Resource].id = @goldId
	);
	DECLARE @elixir int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @player
			AND [Resource].id = @elixirId
	);
	DECLARE @goldCost int = (
		SELECT Amount
		FROM BuildingCosts
		WHERE ResourceID = @goldId AND BuildingTypeID = @type
	);
	DECLARE @elixirCost int = (
		SELECT Amount
		FROM BuildingCosts
		WHERE ResourceID = @elixirID AND BuildingTypeID = @type
	);

	UPDATE HasResource
	SET Amount = @gold - @goldCost
	WHERE HasResource.PlayerID = @player
		AND HasResource.[resourceid] = @goldId;
	UPDATE HasResource
	SET Amount = @elixir - @elixirCost
	WHERE HasResource.PlayerID = @player
		AND HasResource.[resourceid] = @elixirId;

	INSERT INTO Building (PlayerID, PosX, PosY, BuildingTypeID, CreationTime)
	VALUES (@player, @x, @y, @type, GETDATE());

	-- if collector, make it start collecting now
	IF (EXISTS (SELECT *
				FROM Collector
				WHERE ID = @type))
		INSERT INTO CollectorLastCollected(BuildingID, LastCollected)
		VALUES(SCOPE_IDENTITY(), GETDATE())
END
GO
/****** Object:  StoredProcedure [dbo].[RaiseTroopLevel]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[RaiseTroopLevel] (
    @player int,
    @troop int
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Player WHERE ID = @player)
		throw 50001, 'player does not exist', 1;
	IF NOT EXISTS (SELECT 1 FROM TroopType WHERE ID = @troop)
		throw 50002, 'troop does not exist', 1;

	DECLARE @name varchar(20) = (SELECT Name FROM TroopType WHERE ID = @troop);
	DECLARE @level tinyint = (SELECT Level FROM TroopType WHERE ID = @troop);

	IF NOT EXISTS (SELECT 1 FROM TroopType WHERE Name = @name AND Level = @level + 1)
		throw 50003, 'troop is already max level', 1;
	
	DECLARE @nextTroop int = (SELECT ID FROM TroopType WHERE Name = @name AND Level = @level + 1);

	DECLARE @goldId int = (SELECT id FROM [Resource] WHERE [Name] = 'gold');
	DECLARE @elixirId int = (SELECT id FROM [Resource] WHERE [Name] = 'elixir');
	DECLARE @gold int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @player
			AND [Resource].id = @goldId
	);
	DECLARE @elixir int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @player
			AND [Resource].id = @elixirId
	);
	DECLARE @goldCost int = (
		SELECT Amount
		FROM Resource
		JOIN TroopCosts ON Resource.id = TroopCosts.ResourceID
		JOIN TroopType ON TroopType.id = TroopCosts.TroopID
		WHERE Resource.id = @goldId AND TroopType.id = @nextTroop
	);
	DECLARE @elixirCost int = (
		SELECT Amount
		FROM Resource
		JOIN TroopCosts ON Resource.id = TroopCosts.ResourceID
		JOIN TroopType on TroopType.id = TroopCosts.TroopID
		WHERE Resource.id = @elixirId AND TroopType.id = @nextTroop
	);

	IF @goldCost > @gold OR @elixirCost > @elixir
		throw 50004, 'Insufficient resources', 1;

	UPDATE HasTroop
	SET TroopTypeID = @nextTroop
	WHERE PlayerID = @player AND TroopTypeID = @troop;
	UPDATE HasResource
	SET Amount = @gold - @goldCost
	WHERE PlayerID = @player AND ResourceID = @goldId;
	UPDATE HasResource
	SET Amount = @elixir - @elixirCost
	WHERE PlayerID = @player AND ResourceId = @elixirID;
END
GO
/****** Object:  StoredProcedure [dbo].[Register]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Register]
@Username varchar(20),
@PasswordHash varchar(50),
@PasswordSalt varchar(50)
AS
BEGIN
	IF @Username IS NULL OR @Username = ''
		throw 50001, 'Username cannot be null nor empty', 1;
	IF @PasswordHash IS NULL OR @PasswordHash = ''
		throw 50002, 'PasswordHash cannot be null nor empty', 1;
	IF @PasswordSalt IS NULL OR @PasswordSalt = ''
		throw 50003, 'PasswordSalt cannot be null nor empty', 1;
	IF EXISTS (SELECT 1 FROM Player WHERE UName = @Username)
		throw 50004, 'Username already exists', 1;

	INSERT INTO Player (Uname, PasswordHash, PasswordSalt)
	VALUES (@Username, @PasswordHash, @PasswordSalt);
END
GO
/****** Object:  StoredProcedure [dbo].[Upgrade]    Script Date: 2/19/2026 6:35:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Upgrade](
	@PlayerID int,
	@BuildingID int
) AS BEGIN
	-- check eligibility
	EXEC CanUpgrade @PlayerID, @BuildingID;

	-- find the btid to update to
	DECLARE @NewBuildingTypeID int = (SELECT newBt.ID
									  FROM Building oldB
									  JOIN BuildingType oldBt ON oldB.BuildingTypeID = oldBt.ID
									  JOIN BuildingUpgrades bu ON bu.FromID = oldBt.ID
									  JOIN BuildingType newBt ON newBt.ID = bu.ToID
									  WHERE oldB.ID = @BuildingID)

	-- determine costs
	DECLARE @goldId int = (SELECT id FROM [Resource] WHERE [Name] = 'gold');
	DECLARE @elixirId int = (SELECT id FROM [Resource] WHERE [Name] = 'elixir');
	DECLARE @gold int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @PlayerID
			AND [Resource].id = @goldId
	);
	DECLARE @elixir int = (
		SELECT Amount
		FROM HasResource
		JOIN [Resource] ON HasResource.ResourceID = Resource.id
		WHERE playerid = @PlayerID
			AND [Resource].id = @elixirId
	);
	DECLARE @goldCost int = (
		SELECT Amount
		FROM BuildingCosts
		WHERE ResourceID = @goldId AND BuildingTypeID = @NewBuildingTypeID
	);
	DECLARE @elixirCost int = (
		SELECT Amount
		FROM BuildingCosts
		WHERE ResourceID = @elixirID AND BuildingTypeID = @NewBuildingTypeID
	);

	-- subtract costs
	UPDATE HasResource
	SET Amount = @gold - @goldCost
	WHERE HasResource.PlayerID = @PlayerID
		AND HasResource.[resourceid] = @goldId;
	UPDATE HasResource
	SET Amount = @elixir - @elixirCost
	WHERE HasResource.PlayerID = @PlayerID
		AND HasResource.[resourceid] = @elixirId;

	-- upgrade the building
	UPDATE Building
	SET Building.BuildingTypeID = @NewBuildingTypeID
	WHERE Building.ID = @BuildingID

	-- update the construction time
	UPDATE Building
	SET CreationTime = GETDATE()
	WHERE Building.ID = @BuildingID
END
GO
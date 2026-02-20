package populate;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import java.security.SecureRandom;
import java.sql.ResultSet;
import java.util.Arrays;
import java.util.Base64;
import java.util.Random;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.swing.JOptionPane;

import com.github.cliftonlabs.json_simple.JsonArray;
import com.github.cliftonlabs.json_simple.JsonException;
import com.github.cliftonlabs.json_simple.JsonObject;
import com.github.cliftonlabs.json_simple.Jsoner;

public class Populate {
    private static final Random RANDOM = new SecureRandom();
    private static final Base64.Encoder enc = Base64.getEncoder();
    private static final Base64.Decoder dec = Base64.getDecoder();

    private static byte[] hashPassword(byte[] salt, String password) {
        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 65536, 128);
        SecretKeyFactory f;
        byte[] hash = null;
        try {
            f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
            hash = f.generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (InvalidKeySpecException e) {
            e.printStackTrace();
        }

        return hash;
    }

		
	private static void register(Connection conn, String username, String password) {
        byte[] salt = new byte[16];
        RANDOM.nextBytes(salt);
        byte[] hashedPass = hashPassword(salt, password);

        try {
            CallableStatement stmt = conn.prepareCall("{? = call Register(?, ?, ?)}");
            stmt.registerOutParameter(1, Types.INTEGER);
            stmt.setString(2, username);
            stmt.setString(3, enc.encodeToString(hashedPass));
            stmt.setString(4, enc.encodeToString(salt));

            stmt.execute();
        } catch (Exception e) {
        	e.printStackTrace();
        }
	}
	
	private static void addResource(Connection conn, String resource) throws SQLException {
		CallableStatement stmt = conn.prepareCall("{? = call AddResource(?)}");
		stmt.registerOutParameter(1, Types.INTEGER);
		stmt.setString(2, resource);
		stmt.execute();
	}

	private static void loadResource(Connection conn, String username, String resource, int amount)
			throws SQLException {
		CallableStatement stmt = conn.prepareCall("{? = call LoadResource(?, ?, ?)}");
		stmt.registerOutParameter(1, Types.INTEGER);
		stmt.setString(2, username);
		stmt.setString(3, resource);
		stmt.setInt(4, amount);
		stmt.execute();
	}

	private static void addBuilding(Connection conn, String username, String name, int level, int buildTime,
			int maxHealth, int size, int goldCost, int elixirCost, Timestamp timestamp, int x, int y, int troopCapacity,
			int collectsGold, int collectsElixir, int damage, int attackRate, String damageType,
			String attacksMovementType, int goldStorage, int elixirStorage) throws SQLException {
		CallableStatement stmt = conn
				.prepareCall("{? = call AddBuilding(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}");
		stmt.registerOutParameter(1, Types.INTEGER);
		stmt.setString(2, username);
		stmt.setString(3, name);
		stmt.setInt(4, level);
		stmt.setInt(5, buildTime);
		stmt.setInt(6, maxHealth);
		stmt.setInt(7, size);
		stmt.setInt(8, goldCost);
		stmt.setInt(9, elixirCost);
		stmt.setTimestamp(10, timestamp);
		stmt.setInt(11, x);
		stmt.setInt(12, y);
		if (troopCapacity != -1) {
			stmt.setInt(13, troopCapacity);
		} else {
			stmt.setNull(13, Types.INTEGER);
		}
		if (collectsGold != -1) {
			stmt.setInt(14, collectsGold);
		} else {
			stmt.setNull(14, Types.INTEGER);
		}
		if (collectsElixir != -1) {
			stmt.setInt(15, collectsElixir);
		} else {
			stmt.setNull(15, Types.INTEGER);
		}
		if (damageType != null) {
			stmt.setInt(16, damage);
			stmt.setInt(17, attackRate);
			stmt.setString(18, damageType);
			stmt.setString(19, attacksMovementType);
		} else {
			stmt.setNull(16, Types.INTEGER);
			stmt.setNull(17, Types.INTEGER);
			stmt.setNull(18, Types.VARCHAR);
			stmt.setNull(19, Types.VARCHAR);
		}
		if (goldStorage != -1) {
			stmt.setInt(20, goldStorage);
		} else {
			stmt.setNull(20, Types.INTEGER);
		}
		if (elixirStorage != -1) {
			stmt.setInt(21, elixirStorage);
		} else {
			stmt.setNull(21, Types.INTEGER);
		}
		stmt.execute();
	}

	private static void loadTroop(Connection conn, String username, String name, int level, int damage, int attackRate,
			String damageType, int size, String movementType, int movementSpeed, int goldCost, int elixirCost,
			int amount) throws SQLException {
		CallableStatement stmt = conn.prepareCall("{? = call LoadTroop(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}");
		stmt.registerOutParameter(1, Types.INTEGER);
		stmt.setString(2, username);
		stmt.setString(3, name);
		stmt.setInt(4, level);
		stmt.setInt(5, damage);
		stmt.setInt(6, attackRate);
		stmt.setString(7, damageType);
		stmt.setInt(8, size);
		stmt.setString(9, movementType);
		stmt.setInt(10, movementSpeed);
		stmt.setInt(11, goldCost);
		stmt.setInt(12, elixirCost);
		stmt.setInt(13, amount);
		stmt.execute();
	}

	public static void main(String[] args) {
		String jsonString;
		try {
			final String SERVER = "golem.csse.rose-hulman.edu";
			final String DB_NAME = "donovagdtest1";
			final String USERNAME = "Clashgui";
			final String PASSWORD = "Password123";
			final String URL = "jdbc:sqlserver://${dbServer};databaseName=${dbName};user=${user};password={${pass}};encrypt=false;";
			String url = URL.replace("${dbServer}", SERVER).replace("${dbName}", DB_NAME).replace("${user}", USERNAME)
					.replace("${pass}", PASSWORD);
			Connection conn = DriverManager.getConnection(url);

			// read json
			jsonString = new String(Files.readAllBytes(Paths.get("src/main/java/populate/data.json")));
			JsonObject jsonObject = (JsonObject) Jsoner.deserialize(jsonString);

			addResource(conn, "gold");
			addResource(conn, "elixir");

			// players
			JsonArray players = (JsonArray) jsonObject.get("players");
			for (Object playerObj : players) {
				JsonObject player = (JsonObject) playerObj;

				String username = (String) player.get("username");
				String password = (String) player.get("password");
				
				register(conn, username, password);

				// gold and elixir
				int gold = ((BigDecimal) player.get("gold")).intValue();
				loadResource(conn, username, "gold", gold);
				int elixir = ((BigDecimal) player.get("elixir")).intValue();
				loadResource(conn, username, "elixir", elixir);

				// buildings
				JsonArray buildings = (JsonArray) player.get("buildings");
				for (Object buildingObj : buildings) {
					JsonObject building = (JsonObject) buildingObj;

					// building type info
					String name = (String) building.get("name");
					int level = ((BigDecimal) building.get("level")).intValue();
					int buildTime = ((BigDecimal) building.get("build time")).intValue();
					int maxHealth = ((BigDecimal) building.get("max health")).intValue();
					int size = ((BigDecimal) building.get("size")).intValue();

					// cost
					int goldCost = ((BigDecimal) building.get("gold cost")).intValue();
					int elixirCost = ((BigDecimal) building.get("elixir cost")).intValue();

					// building specific info
					String creationTimeString = (String) building.get("creation time");
					LocalDateTime localDateTime = LocalDateTime.parse(creationTimeString);
					java.sql.Timestamp creationTime = Timestamp.from(localDateTime.toInstant(ZoneOffset.UTC));
					int posX = ((BigDecimal) building.get("pos x")).intValue();
					int posY = ((BigDecimal) building.get("pos y")).intValue();

					// type specific info
					String type = (String) building.get("type");
					if (type.equals("defense")) {
						int damage = ((BigDecimal) building.get("damage")).intValue();
						int attackRate = ((BigDecimal) building.get("attack rate")).intValue();
						String damageType = (String) building.get("damage type");
						String attacksMovementType = (String) building.get("attacks movement type");

						addBuilding(conn, username, name, level, buildTime, maxHealth, size, goldCost, elixirCost,
								creationTime, posX, posY, -1, -1, -1, damage, attackRate, damageType,
								attacksMovementType, -1, -1);
					} else if (type.equals("collector")) {
						int collectsGold = ((BigDecimal) building.get("collects gold")).intValue();
						int collectsElixir = ((BigDecimal) building.get("collects elixir")).intValue();

						addBuilding(conn, username, name, level, buildTime, maxHealth, size, goldCost, elixirCost,
								creationTime, posX, posY, -1, collectsGold, collectsElixir, -1, -1, null,
								null, -1, -1);
					} else if (type.equals("storage")) {
						int storesGold = ((BigDecimal) building.get("stores gold")).intValue();
						int storesElixir = ((BigDecimal) building.get("stores elixir")).intValue();

						addBuilding(conn, username, name, level, buildTime, maxHealth, size, goldCost, elixirCost,
								creationTime, posX, posY, -1, -1, -1, -1, -1, null,
								null, storesGold, storesElixir);
					} else if (type.equals("camp")) {
						int capacity = ((BigDecimal) building.get("capacity")).intValue();

						addBuilding(conn, username, name, level, buildTime, maxHealth, size, goldCost, elixirCost,
								creationTime, posX, posY, capacity, -1, -1, -1, -1, null,
								null, -1, -1);
					} else if (type.equals("none")) {
						addBuilding(conn, username, name, level, buildTime, maxHealth, size, goldCost, elixirCost,
								creationTime, posX, posY, -1, -1, -1, -1, -1, null,
								null, -1, -1);
					}
				}

				JsonArray troops = (JsonArray) player.get("troops");
				for (Object troopObj : troops) {
					JsonObject troop = (JsonObject) troopObj;
					String name = (String) troop.get("name");
					int level = ((BigDecimal) troop.get("level")).intValue();
					int damage = ((BigDecimal) troop.get("damage")).intValue();
					int attackRate = ((BigDecimal) troop.get("attack rate")).intValue();
					String damageType = (String) troop.get("damage type");
					int size = ((BigDecimal) troop.get("size")).intValue();
					String movementType = (String) troop.get("movement type");
					int movementSpeed = ((BigDecimal) troop.get("movement speed")).intValue();
					int goldCost = ((BigDecimal) troop.get("gold cost")).intValue();
					int elixirCost = ((BigDecimal) troop.get("elixir cost")).intValue();
					int amount = ((BigDecimal) troop.get("amount")).intValue();
					
					loadTroop(conn, username, name, level, damage, attackRate, damageType, size, movementType, movementSpeed, goldCost, elixirCost, amount);
				}
			}
		} catch (IOException | SQLException | JsonException e) {
			e.printStackTrace();
		}
	}
}

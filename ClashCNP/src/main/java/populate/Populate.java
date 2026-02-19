package populate;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import com.github.cliftonlabs.json_simple.JsonArray;
import com.github.cliftonlabs.json_simple.JsonException;
import com.github.cliftonlabs.json_simple.JsonObject;
import com.github.cliftonlabs.json_simple.Jsoner;

public class Populate {
	public static void main(String[] args) {
		String jsonString;
		try {
			final String SERVER = "golem.csse.rose-hulman.edu";
			final String DB_NAME = "riddleetwagnernbdonovagd";
			final String USERNAME = "Clashgui";
			final String PASSWORD = "Password123";
			final String URL = "jdbc:sqlserver://${dbServer};databaseName=${dbName};user=${user};password={${pass}};encrypt=false;";
			String url = URL
					.replace("${dbServer}", SERVER)
					.replace("${dbName}", DB_NAME)
					.replace("${user}", USERNAME)
					.replace("${pass}", PASSWORD);
            Connection conn = DriverManager.getConnection(url);
			
			// read json
			jsonString = new String(Files.readAllBytes(Paths.get("src/main/java/populate/data.json")));
			JsonObject jsonObject = (JsonObject) Jsoner.deserialize(jsonString);
			
			// players
			JsonArray players = (JsonArray) jsonObject.get("players");
			for (Object playerObj : players) {
				JsonObject player = (JsonObject) playerObj;

				// gold and elixir
				BigDecimal gold = (BigDecimal) player.get("gold");
				System.out.println(gold);
				BigDecimal elixir = (BigDecimal) player.get("elixir");
				System.out.println(elixir);
				
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
					
					// type specific info
					String type = (String) building.get("type");
					if (type.equals("defense")) {
						int damage = ((BigDecimal) building.get("damage")).intValue();
						int attackRate = ((BigDecimal) building.get("attack rate")).intValue();
						String damageType = (String) building.get("damage type");
						String attacksMovementType = (String) building.get("attacks movement type");
					}
					else if (type.equals("collector")) {
						int collectsGold = ((BigDecimal) building.get("collects gold")).intValue();
						int collectsElixir = ((BigDecimal) building.get("collects elixir")).intValue();
					}
					else if (type.equals("storage")) {
						int storesGold = ((BigDecimal) building.get("stores gold")).intValue();
						int storesElixir = ((BigDecimal) building.get("stores elixir")).intValue();
					}
					else if (type.equals("camp")) {
						int capacity = ((BigDecimal) building.get("capacity")).intValue();
					}
					else if (type.equals("none")) {
						// do nothing
					}
					
					// cost
					int goldCost = ((BigDecimal) building.get("gold cost")).intValue();
					int elixirCost = ((BigDecimal) building.get("elixir cost")).intValue();

					// building specific info
					String creationTimeString = (String) building.get("creation time");
					LocalDateTime localDateTime = LocalDateTime.parse(creationTimeString);
					java.sql.Timestamp creationTime = Timestamp.from(localDateTime.toInstant(ZoneOffset.UTC));
					int posX = ((BigDecimal) building.get("pos x")).intValue();
					int posY = ((BigDecimal) building.get("pos y")).intValue();
				}

				JsonArray troops = (JsonArray) player.get("troops");
				for (Object troopObj : troops) {
					JsonObject troop = (JsonObject) troopObj;
					String name = (String) troop.get("name");
					int level = ((BigDecimal) troop.get("level")).intValue();
					int damage = ((BigDecimal) troop.get("damage")).intValue();
					int attackRate = ((BigDecimal) troop.get("attack rate")).intValue();
					int size = ((BigDecimal) troop.get("size")).intValue();
					String movementType = (String) troop.get("movement type");
					int movementSpeed = ((BigDecimal) troop.get("movement speed")).intValue();
					int amount = ((BigDecimal) troop.get("amount")).intValue();
				}
			}
		} catch (IOException | SQLException | JsonException e) {
			e.printStackTrace();
		}
	}
}

package populate;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Paths;

import com.github.cliftonlabs.json_simple.JsonArray;
import com.github.cliftonlabs.json_simple.JsonException;
import com.github.cliftonlabs.json_simple.JsonObject;
import com.github.cliftonlabs.json_simple.Jsoner;

public class Populate {
	public static void main(String[] args) {
		System.out.println("Hello World");
		String jsonString;
		try {
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
			}
		} catch (IOException | JsonException e) {
			e.printStackTrace();
		}
	}
}

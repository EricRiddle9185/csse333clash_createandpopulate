package data;

public class BuildingType {
	public String name;
	public int level;
	public int buildTime;
	public int maxHealth;
	public int size;
	public int goldCost;
	public int elixirCost;
	
	public BuildingType(String name, int level, int buildTime, int maxHealth, int size, int goldCost, int elixirCost) {
		this.name = name;
		this.level = level;
		this.buildTime = buildTime;
		this.maxHealth = maxHealth;
		this.size = size;
		this.goldCost = goldCost;
		this.elixirCost = elixirCost;
	}
}

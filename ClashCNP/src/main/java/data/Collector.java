package data;

public class Collector extends BuildingType {
	public int collectsGold;
	public int collectsElixir;

	public Collector(BuildingType bt, int collectsGold, int collectsElixir) {
		super(bt.name, bt.level, bt.buildTime, bt.maxHealth, bt.size, bt.goldCost, bt.elixirCost);
		this.collectsGold = collectsGold;
		this.collectsElixir = collectsElixir;
	}
}

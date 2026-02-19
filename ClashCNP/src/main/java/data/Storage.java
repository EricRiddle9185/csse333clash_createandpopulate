package data;

public class Storage extends BuildingType {
	public int storesGold;
	public int storesElixir;

	public Storage(BuildingType bt, int storesGold, int storesElixir) {
		super(bt.name, bt.level, bt.buildTime, bt.maxHealth, bt.size, bt.goldCost, bt.elixirCost);
		this.storesGold = storesGold;
		this.storesElixir = storesElixir;
	}
}

package data;

public class Camp extends BuildingType {
	public int capacity;

	public Camp(BuildingType bt, int capacity) {
		super(bt.name, bt.level, bt.buildTime, bt.maxHealth, bt.size, bt.goldCost, bt.elixirCost);
		this.capacity = capacity;
	}
}

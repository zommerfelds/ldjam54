import Utils.Point2d;
import h2d.col.IPoint;
import haxe.ds.HashMap;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import signals.Signal1;
import signals.Signal;
import ldtk.Json.EntityReferenceInfos;

using hx.strings.Strings;

enum Cell {
	Empty;
	Wall;
	Door;
	Switch(groupId:Int);
	Slime(groupId:Int);
	Exit;
}

class Model {
	public static final BOARD_WIDTH = 12;

	public static final BOARD_HEIGHT = 18;

	public function new() {}

	public var playerPos = new IPoint();
	public final playerGrid = new HashMap<Point2d, Bool>();
	public final grid:Array<Array<Cell>> = [
		for (x in 0...BOARD_WIDTH) [
			for (y in 0...BOARD_HEIGHT)
				Empty
		]
	];

	public final slimeGroups:Array<Array<IPoint>> = [];
	public final switchGroups = new IntMap<{numSwitches:Int, targets:Array<EntityReferenceInfos>}>();
	public final targetEntities = new StringMap<IPoint>();
	public final doors:Array<IPoint> = []; // Note: just the initial positions, won't change if removed.
	public final switches:Array<IPoint> = [];

	// Events
	public final onPlayerMoved = new Signal();
	public final onPlayerMergedWithSlime = new Signal1<Int>(); // arg: slime group ID
	public final onWin = new Signal();
	public final onRemoveDoor = new Signal1<IPoint>(); // arg: door position

	public function loadLevel(ldtkLevel:LdtkProject.LdtkProject_Level) {
		for (y in 0...ldtkLevel.l_IntGrid.cHei) {
			for (x in 0...ldtkLevel.l_IntGrid.cWid) {
				switch (ldtkLevel.l_IntGrid.getName(x, y)) {
					case "Wall":
						grid[x][y] = Wall;
					case "Slime":
						grid[x][y] = Slime(-1);
					case "Exit":
						grid[x][y] = Exit;
					case "Player":
						playerGrid.set(new Point2d(x, y), true);
					case null:
					// empty field
					case x:
						throw 'invalid case $x';
				}
			}
		}

		for (entity in ldtkLevel.l_Entities.getAllUntyped()) {
			final pos = new IPoint(entity.cx, entity.cy);
			switch (entity.entityType) {
				case Switch:
					final switchEntity:LdtkProject.Entity_Switch = cast entity;
					final groupId = switchEntity.f_Group ?? -switchEntity.iid.hashCode();
					grid[entity.cx][entity.cy] = Switch(groupId);
					if (switchGroups.get(groupId) == null) {
						switchGroups.set(groupId, {numSwitches: 0, targets: []});
					}
					switchGroups.get(groupId).numSwitches++;
					switchGroups.get(groupId).targets = switchGroups.get(groupId).targets.concat(switchEntity.f_Targets);

					switches.push(new IPoint(entity.cx, entity.cy));
				case Door:
					doors.push(new IPoint(entity.cx, entity.cy));
					grid[entity.cx][entity.cy] = Door;
					targetEntities.set(entity.iid, pos);
			}
		}

		makeSlimeGroups();
	}

	static function isFree(cell:Cell) {
		return cell.match(Empty | Exit | Switch(_));
	}

	public function movePlayer(diff:IPoint) {
		final newPos = playerPos.add(diff);
		final slimesToBeAdded = [];
		final slimesGroupsToBeAdded = new IntMap<Bool>();
		for (p in playerGrid.keys()) {
			if (!isPointInBoard(newPos.add(Utils.toIPoint(p))) || !isFree(grid[newPos.x + p.x][newPos.y + p.y])) {
				return;
			}
			if (isPointInBoard(newPos.add(Utils.toIPoint(p)).add(diff))) {
				switch (grid[newPos.x + p.x + diff.x][newPos.y + p.y + diff.y]) {
					case Slime(groupId):
						for (s in slimeGroups[groupId]) {
							slimesToBeAdded.push(new IPoint(s.x - newPos.x, s.y - newPos.y));
							slimesGroupsToBeAdded.set(groupId, true);
						}
					case _:
				}
			}
			switch (grid[newPos.x + p.x][newPos.y + p.y]) {
				case Exit:
					onWin.dispatch();
				case _:
			}
		}
		for (s in slimesToBeAdded) {
			playerGrid.set(new Point2d(s.x, s.y), true);
			grid[newPos.x + s.x][newPos.y + s.y] = Empty;
		}
		for (g in slimesGroupsToBeAdded.keys()) {
			onPlayerMergedWithSlime.dispatch(g);
		}
		playerPos = newPos;
		onPlayerMoved.dispatch();
		checkSwitches();
	}

	// TODO: make private
	public function isPointInBoard(p) {
		return p.x >= 0 && p.x < Model.BOARD_WIDTH && p.y >= 0 && p.y < Model.BOARD_HEIGHT;
	}

	function checkSwitches() {
		final touchedGroups = new IntMap<Int>();
		for (p in playerGrid.keys()) {
			switch (grid[playerPos.x + p.x][playerPos.y + p.y]) {
				case Switch(groupId):
					if (touchedGroups.get(groupId) == null) {
						touchedGroups.set(groupId, 0);
					}
					touchedGroups.set(groupId, touchedGroups.get(groupId) + 1);
				case _:
			}
		}
		for (t in touchedGroups.keyValueIterator()) {
			if (switchGroups.get(t.key).numSwitches == t.value) {
				activateSwitch(t.key);
			}
		}
	}

	function activateSwitch(groupId) {
		for (t in switchGroups.get(groupId).targets) {
			final pt = targetEntities.get(t.entityIid);
			switch (grid[pt.x][pt.y]) {
				case Door:
					grid[pt.x][pt.y] = Empty;
					onRemoveDoor.dispatch(pt);
				case x:
					trace('WARNING: invalid target type $x');
			}
		}
	}

	static final ADJACENT_DIRECTIONS = [new IPoint(0, 1), new IPoint(0, -1), new IPoint(1, 0), new IPoint(-1, 0)];
	public static final ADJACENT_DIRECTIONS_MAP = [
		"D" => new IPoint(0, 1),
		"U" => new IPoint(0, -1),
		"R" => new IPoint(1, 0),
		"L" => new IPoint(-1, 0)
	];

	function makeSlimeGroups() {
		function floodFill(x, y, groupId) {
			if (!grid[x][y].match(Slime(-1)))
				return;
			grid[x][y] = Slime(groupId);
			slimeGroups[groupId].push(new IPoint(x, y));
			for (d in ADJACENT_DIRECTIONS) {
				if (!isPointInBoard(d))
					continue;
				floodFill(x + d.x, y + d.y, groupId);
			}
		}

		for (x in 0...BOARD_WIDTH) {
			for (y in 0...BOARD_HEIGHT) {
				switch (grid[x][y]) {
					case Slime(-1):
						slimeGroups.push([]);
						floodFill(x, y, slimeGroups.length - 1);
					case Slime(_):
					case _:
				}
			}
		}
	}
}

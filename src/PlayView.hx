import h2d.TileGroup;
import h2d.Tile;
import hxd.Res;
import h2d.SpriteBatch;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import ldtk.Json.EntityReferenceInfos;
import h2d.Flow;
import LdtkProject.Ldtk;
import Gui.TextButton;
import h2d.col.IPoint;
import haxe.ds.Option;
import hxd.Key;
import Utils.Point2d;
import haxe.ds.HashMap;

using hx.strings.Strings;

enum Cell {
	Empty;
	Wall;
	Door(el:BatchElement);
	Switch(groupId:Int);
	Slime(groupId:Int, el:BatchElement);
	Exit;
}

class PlayView extends GameState {
	static final BOARD_WIDTH = 12;

	static final BOARD_HEIGHT = 18;

	final gameArea = new h2d.Graphics();
	final staticTileGroup = new TileGroup();
	var playerPos = new IPoint();
	final playerGrid = new HashMap<Point2d, Bool>();
	final tiles = loadTileMap();
	final doors:Array<{el:BatchElement}> = [];
	var spriteBatch:SpriteBatch;
	var playerSpriteBatch:SpriteBatch;
	final slimeTiles:Map<String, {tile:Tile, r:Int}> = [];
	final playerSlimeTiles:Map<String, {tile:Tile, r:Int}> = [];

	final grid:Array<Array<Cell>> = [
		for (x in 0...BOARD_WIDTH) [
			for (y in 0...BOARD_HEIGHT)
				Empty
		]
	];

	final slimeGroups:Array<Array<IPoint>> = [];
	final switchGroups = new IntMap<{numSwitches:Int, targets:Array<EntityReferenceInfos>}>();

	final ldtkLevel:Null<LdtkProject.LdtkProject_Level>;
	final levelIndex:Int;

	final targetEntities = new StringMap<IPoint>();

	var timeSinceLastUpdate = 0.0;

	static final ADJACENT_DIRECTIONS = [new IPoint(0, 1), new IPoint(0, -1), new IPoint(1, 0), new IPoint(-1, 0)];
	static final ADJACENT_DIRECTIONS_MAP = [
		"D" => new IPoint(0, 1),
		"U" => new IPoint(0, -1),
		"R" => new IPoint(1, 0),
		"L" => new IPoint(-1, 0)
	];

	public function new(level:Int) {
		super();
		levelIndex = level;
		ldtkLevel = Ldtk.world.levels[level];
	}

	static function isFree(cell:Cell) {
		return cell.match(Empty | Exit | Switch(_));
	}

	static function loadTileMap() {
		final main = Res.sprites.toTile();

		function get(x, y) {
			final t = main.sub(x * 8, y * 8, 8, 8);
			t.scaleToSize(1, 1);
			t.setCenterRatio();
			return t;
		}
		return ["switch" => get(6, 3), "door" => get(6, 4)];
	}

	override function init() {
		if (height / width > BOARD_HEIGHT / BOARD_WIDTH) {
			// Width is limiting factor
			gameArea.scale(width / BOARD_WIDTH);
			gameArea.y = (height - BOARD_HEIGHT * gameArea.scaleY) / 2;
		} else {
			// Height is limiting factor
			gameArea.scale(height / BOARD_HEIGHT);
			gameArea.x = (width - BOARD_WIDTH * gameArea.scaleX) / 2;
		}
		addChild(gameArea);

		final ldtkTileGroup = ldtkLevel.l_AutoLayer.render();
		ldtkLevel.l_Cosmetics.render(ldtkTileGroup);
		ldtkTileGroup.scale(1 / 8);
		gameArea.addChild(ldtkTileGroup);
		gameArea.addChild(staticTileGroup);
		staticTileGroup.x = 0.5;
		staticTileGroup.y = 0.5;

		final allSprites = Res.sprites.toTile();
		final tileData = [
			"" => {x: 0, r: 0}, "R" => {x: 1, r: 0}, "D" => {x: 1, r: 1}, "L" => {x: 1, r: 2}, "U" => {x: 1, r: 3}, "DR" => {x: 2, r: 0},
			"DL" => {x: 2, r: 1}, "LU" => {x: 2, r: 2}, "RU" => {x: 2, r: 3}, "DRU" => {x: 3, r: 0}, "DLR" => {x: 3, r: 1}, "DLU" => {x: 3, r: 2},
			"LRU" => {x: 3, r: 3}, "DU" => {x: 4, r: 0}, "LR" => {x: 4, r: 1}, "DLRU" => {x: 5, r: 0},
		];
		for (kv in tileData.keyValueIterator()) {
			final tile = allSprites.sub(kv.value.x * 8, 8 * 8, 8, 8);
			tile.scaleToSize(1, 1);
			tile.setCenterRatio();
			slimeTiles.set(kv.key, {tile: tile, r: kv.value.r});
		}
		for (kv in tileData.keyValueIterator()) {
			final tile = allSprites.sub(kv.value.x * 8, 0, 8, 8);
			tile.scaleToSize(1, 1);
			tile.setCenterRatio();
			playerSlimeTiles.set(kv.key, {tile: tile, r: kv.value.r});
		}
		spriteBatch = new SpriteBatch(allSprites, gameArea);
		spriteBatch.hasRotationScale = true;
		spriteBatch.x = 0.5;
		spriteBatch.y = 0.5;
		playerSpriteBatch = new SpriteBatch(allSprites, gameArea);
		playerSpriteBatch.hasRotationScale = true;
		playerSpriteBatch.x = 0.5;
		playerSpriteBatch.y = 0.5;

		setupGame();

		for (x in 0...BOARD_WIDTH) {
			for (y in 0...BOARD_HEIGHT) {
				final pt = new IPoint(x, y);
				switch (grid[x][y]) {
					case Slime(groupId, null):
						final neighbourDirs = [];
						for (d in ADJACENT_DIRECTIONS_MAP.keyValueIterator()) {
							final neighbour = pt.add(d.value);
							if (!isPointInBoard(neighbour))
								continue;
							if (grid[neighbour.x][neighbour.y].match(Slime(_))) {
								neighbourDirs.push(d.key);
							}
						}
						neighbourDirs.sort((s1, s2) -> s1.compare(s2));
						final tileName = neighbourDirs.join("");
						final el = spriteBatch.add(new BatchElement(slimeTiles.get(tileName).tile));
						el.rotation = slimeTiles.get(tileName).r * Math.PI * 0.5;
						el.x = x;
						el.y = y;
						grid[x][y] = Slime(groupId, el);
					case _:
				}
			}
		}

		rebuildPlayerSprites();

		addEventListener(onEvent);

		final flow = new Flow(this);
		flow.x = Gui.scale(10);
		flow.y = Gui.scale(10);
		flow.layout = Vertical;
		new TextButton(flow, "Back", () -> {
			App.instance.switchState(new MenuView());
		}, Gui.Colors.GREY, false, 0.4);
		new TextButton(flow, "Reset [Backspace]", () -> {
			reset();
		}, Gui.Colors.RED, false, 0.4);

		final manager = hxd.snd.Manager.get();
		manager.masterVolume = 0.5;
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Reverb(hxd.snd.effect.ReverbPreset.DRUGGED));
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(0.5));
	}

	function reset() {
		App.instance.switchState(new PlayView(levelIndex));
	}

	function win() {
		App.instance.switchState(new PlayView(levelIndex + 1));
	}

	function setupGame() {
		for (y in 0...ldtkLevel.l_IntGrid.cHei) {
			for (x in 0...ldtkLevel.l_IntGrid.cWid) {
				switch (ldtkLevel.l_IntGrid.getName(x, y)) {
					case "Wall":
						grid[x][y] = Wall;
					case "Slime":
						grid[x][y] = Slime(-1, null);
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

					staticTileGroup.add(entity.cx, entity.cy, tiles["switch"]);
				case Door:
					final el = spriteBatch.add(new BatchElement(tiles["door"]));
					el.x = entity.cx;
					el.y = entity.cy;
					doors.push({el: el});

					grid[entity.cx][entity.cy] = Door(el);
					targetEntities.set(entity.iid, pos);
			}
		}

		makeSlimeGroups();
	}

	function makeSlimeGroups() {
		function floodFill(x, y, groupId) {
			if (!grid[x][y].match(Slime(-1, null)))
				return;
			grid[x][y] = Slime(groupId, null);
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
					case Slime(-1, _):
						slimeGroups.push([]);
						floodFill(x, y, slimeGroups.length - 1);
					case Slime(_):
					case _:
				}
			}
		}
	}

	function onEvent(event:hxd.Event) {
		var moveDiff:Option<IPoint> = None;
		switch (event.kind) {
			case EKeyDown:
				switch (event.keyCode) {
					case Key.UP:
						moveDiff = Some(new IPoint(0, -1));
					case Key.DOWN:
						moveDiff = Some(new IPoint(0, 1));
					case Key.LEFT:
						moveDiff = Some(new IPoint(-1, 0));
					case Key.RIGHT:
						moveDiff = Some(new IPoint(1, 0));
					case Key.BACKSPACE:
						reset();
					case _:
				}
			default:
		}
		switch (moveDiff) {
			case Some(diff):
				movePlayer(diff);
			case _:
		}
	}

	function isPointInBoard(p) {
		return p.x >= 0 && p.x < BOARD_WIDTH && p.y >= 0 && p.y < BOARD_HEIGHT;
	}

	function movePlayer(diff:IPoint) {
		final newPos = playerPos.add(diff);
		final slimesToBeAdded = [];
		for (p in playerGrid.keys()) {
			if (!isPointInBoard(newPos.add(Utils.toIPoint(p))) || !isFree(grid[newPos.x + p.x][newPos.y + p.y])) {
				return;
			}
			if (isPointInBoard(newPos.add(Utils.toIPoint(p)).add(diff))) {
				switch (grid[newPos.x + p.x + diff.x][newPos.y + p.y + diff.y]) {
					case Slime(groupId, _):
						for (s in slimeGroups[groupId]) {
							switch (grid[s.x][s.y]) {
								case Slime(_, el):
									slimesToBeAdded.push({pos: new IPoint(s.x - newPos.x, s.y - newPos.y), el: el});
								case _: throw "invalid slimeGroups state";
							}
						}
					case _:
				}
			}
			switch (grid[newPos.x + p.x][newPos.y + p.y]) {
				case Exit:
					win();
				case _:
			}
		}
		for (s in slimesToBeAdded) {
			playerGrid.set(new Point2d(s.pos.x, s.pos.y), true);
			grid[newPos.x + s.pos.x][newPos.y + s.pos.y] = Empty;
			s.el.remove();
		}
		if (slimesToBeAdded.length > 0) {
			rebuildPlayerSprites();
		}
		playerPos = newPos;
		playerSpriteBatch.x = playerPos.x + 0.5;
		playerSpriteBatch.y = playerPos.y + 0.5;
		checkSwitches();
	}

	function rebuildPlayerSprites() {
		playerSpriteBatch.clear();

		for (p in playerGrid.keys()) {
			final pt = new IPoint(p.x, p.y);
			final neighbourDirs = [];
			for (d in ADJACENT_DIRECTIONS_MAP.keyValueIterator()) {
				final neighbour = pt.add(d.value);
				if (!isPointInBoard(neighbour))
					continue;
				if (playerGrid.exists(new Point2d(neighbour.x, neighbour.y))) {
					neighbourDirs.push(d.key);
				}
			}
			neighbourDirs.sort((s1, s2) -> s1.compare(s2));
			final tileName = neighbourDirs.join("");
			final el = playerSpriteBatch.add(new BatchElement(playerSlimeTiles.get(tileName).tile));
			el.rotation = playerSlimeTiles.get(tileName).r * Math.PI * 0.5;
			el.x = pt.x;
			el.y = pt.y;
		}
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
				case Door(el):
					grid[pt.x][pt.y] = Empty;
					el.remove();
				case x:
					trace('WARNING: invalid target type $x');
			}
		}
	}

	override function update(dt:Float) {
		timeSinceLastUpdate += dt;

		final step = 0.5;
		while (timeSinceLastUpdate > step) {
			timeSinceLastUpdate -= step;
			tick();
		}
	}

	function tick() {}
}

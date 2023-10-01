import Utils.Int2d;
import Gui.TextButton;
import LdtkProject.Ldtk;
import PlayViewLogic.Model;
import Utils.Point2d;
import h2d.Flow;
import h2d.SpriteBatch;
import h2d.Tile;
import h2d.TileGroup;
import h2d.col.IPoint;
import haxe.ds.HashMap;
import haxe.ds.Option;
import hxd.Key;
import hxd.Res;

using hx.strings.Strings;

class View {
	public function new() {}

	public function addBatchElement(i:Int2d, el:BatchElement) {
		final p = new Point2d(i.x, i.y);
		if (batchElements.get(p) == null) {
			batchElements.set(p, []);
		}
		batchElements.get(p).push(el);
	}

	// TODO: remove?

	/*
		public function getBatchElement(i:Int2d) {
			final p = new Point2d(i.x, i.y);
			if (batchElements.get(p) == null) {
				batchElements.set(p, []);
			}
			return batchElements.get(p);
		}
	 */
	public function removeBatchElements(i:Int2d) {
		final p = new Point2d(i.x, i.y);
		if (batchElements.get(p) == null) {
			return;
		}
		for (el in batchElements.get(p)) {
			el.remove();
		}
		batchElements.remove(p);
	}

	final batchElements = new HashMap<Point2d, Array<BatchElement>>();

	public final togglingBatchElements:Array<Array<BatchElement>> = [];
	public var timeSinceLastSwap = 0.0;
}

class PlayView extends GameState {
	final gameArea = new h2d.Graphics();
	final staticTileGroup = new TileGroup();

	final tiles = loadTileMap();
	var spriteBatch:SpriteBatch;
	var playerSpriteBatch:SpriteBatch;
	final slimeTiles:Map<String, {tiles:Array<Tile>, r:Int}> = [];
	final playerSlimeTiles:Map<String, {tiles:Array<Tile>, r:Int}> = [];

	final ldtkLevel:Null<LdtkProject.LdtkProject_Level>;
	final levelIndex:Int;

	var timeSinceLastUpdate = 0.0;

	final model = new Model();
	final view = new View();

	public function new(level:Int) {
		super();
		levelIndex = level;
		ldtkLevel = Ldtk.world.levels[level];
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
		if (height / width > Model.BOARD_HEIGHT / Model.BOARD_WIDTH) {
			// Width is limiting factor
			gameArea.scale(width / Model.BOARD_WIDTH);
			gameArea.y = (height - Model.BOARD_HEIGHT * gameArea.scaleY) / 2;
		} else {
			// Height is limiting factor
			gameArea.scale(height / Model.BOARD_HEIGHT);
			gameArea.x = (width - Model.BOARD_WIDTH * gameArea.scaleX) / 2;
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
			final tiles = [
				allSprites.sub(kv.value.x * 8, 8 * 8, 8, 8),
				allSprites.sub(kv.value.x * 8, 9 * 8, 8, 8)
			];
			for (tile in tiles) {
				tile.scaleToSize(1, 1);
				tile.setCenterRatio();
			}
			slimeTiles.set(kv.key, {tiles: tiles, r: kv.value.r});
		}
		for (kv in tileData.keyValueIterator()) {
			final tiles = [
				allSprites.sub(kv.value.x * 8, 0 * 8, 8, 8),
				allSprites.sub(kv.value.x * 8, 1 * 8, 8, 8)
			];
			for (tile in tiles) {
				tile.scaleToSize(1, 1);
				tile.setCenterRatio();
			}
			playerSlimeTiles.set(kv.key, {tiles: tiles, r: kv.value.r});
		}
		spriteBatch = new SpriteBatch(allSprites, gameArea);
		spriteBatch.hasRotationScale = true;
		spriteBatch.x = 0.5;
		spriteBatch.y = 0.5;
		playerSpriteBatch = new SpriteBatch(allSprites, gameArea);
		playerSpriteBatch.hasRotationScale = true;
		playerSpriteBatch.x = 0.5;
		playerSpriteBatch.y = 0.5;

		model.loadLevel(ldtkLevel);

		for (d in model.doors) {
			final el = spriteBatch.add(new BatchElement(tiles["door"]));
			el.x = d.x;
			el.y = d.y;
			view.addBatchElement(d, el);
		}
		for (s in model.switches) {
			staticTileGroup.add(s.x, s.y, tiles["switch"]);
		}

		model.onPlayerMoved.add(() -> {
			playerSpriteBatch.x = model.playerPos.x + 0.5;
			playerSpriteBatch.y = model.playerPos.y + 0.5;
		});

		model.onPlayerMergedWithSlime.add(slimeGroupId -> {
			for (s in model.slimeGroups[slimeGroupId]) {
				view.removeBatchElements(s);
			}

			rebuildPlayerSprites();
		});

		model.onRemoveDoor.add(pos -> {
			view.removeBatchElements(pos);
		});

		model.onWin.add(win);

		for (x in 0...Model.BOARD_WIDTH) {
			for (y in 0...Model.BOARD_HEIGHT) {
				final pt = new IPoint(x, y);
				switch (model.grid[x][y]) {
					case Slime(groupId):
						final neighbourDirs = [];
						for (d in Model.ADJACENT_DIRECTIONS_MAP.keyValueIterator()) {
							final neighbour = pt.add(d.value);
							if (!model.isPointInBoard(neighbour))
								continue;
							if (model.grid[neighbour.x][neighbour.y].match(Slime(_))) {
								neighbourDirs.push(d.key);
							}
						}
						neighbourDirs.sort((s1, s2) -> s1.compare(s2));
						final tileName = neighbourDirs.join("");
						final els = [];
						for (tile in slimeTiles.get(tileName).tiles) {
							final el = spriteBatch.add(new BatchElement(tile));
							el.rotation = slimeTiles.get(tileName).r * Math.PI * 0.5;
							el.x = x;
							el.y = y;
							view.addBatchElement(new Point2d(x, y), el);
							els.push(el);
						}
						els[1].visible = false;
						view.togglingBatchElements.push(els);
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

	function rebuildPlayerSprites() {
		playerSpriteBatch.clear();

		for (p in model.playerGrid.keys()) {
			final pt = new IPoint(p.x, p.y);
			final neighbourDirs = [];
			for (d in Model.ADJACENT_DIRECTIONS_MAP.keyValueIterator()) {
				final neighbour = pt.add(d.value);
				if (!model.isPointInBoard(neighbour))
					continue;
				if (model.playerGrid.exists(new Point2d(neighbour.x, neighbour.y))) {
					neighbourDirs.push(d.key);
				}
			}
			neighbourDirs.sort((s1, s2) -> s1.compare(s2));
			final tileName = neighbourDirs.join("");

			final els = [];
			for (tile in playerSlimeTiles.get(tileName).tiles) {
				final el = playerSpriteBatch.add(new BatchElement(tile));
				el.rotation = playerSlimeTiles.get(tileName).r * Math.PI * 0.5;
				el.x = pt.x;
				el.y = pt.y;
				view.addBatchElement(pt, el);
				els.push(el);
			}
			els[1].visible = false;
			view.togglingBatchElements.push(els);
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
				model.movePlayer(diff);
			case _:
		}
	}

	override function update(dt:Float) {
		timeSinceLastUpdate += dt;

		final step = 0.5;
		while (timeSinceLastUpdate > step) {
			timeSinceLastUpdate -= step;
			tick();
		}

		view.timeSinceLastSwap += dt;
		final swapTime = 0.3;
		if (view.timeSinceLastSwap >= swapTime) {
			view.timeSinceLastSwap -= swapTime;

			for (t in view.togglingBatchElements) {
				t[0].visible = !t[0].visible;
				t[1].visible = !t[1].visible;
			}
		}
	}

	function tick() {}
}

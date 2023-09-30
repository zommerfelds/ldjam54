import h2d.Flow;
import LdtkProject.Ldtk;
import Gui.TextButton;
import Gui.Button;
import h2d.col.IPoint;
import haxe.ds.Option;
import hxd.Key;
import Utils.Point2d;
import haxe.ds.HashMap;

enum Cell {
	Empty;
	Wall;
	Slime;
	Exit;
}

class PlayView extends GameState {
	final gameArea = new h2d.Graphics();
	var playerPos = new IPoint();
	final playerGrid = new HashMap<Point2d, Bool>();

	var timeSinceLastUpdate = 0.0;

	static final BOARD_WIDTH = 12;

	static final BOARD_HEIGHT = 18;

	final grid:Array<Array<Cell>> = [
		for (x in 0...BOARD_WIDTH) [
			for (y in 0...BOARD_HEIGHT)
				Empty
		]
	];

	final ldtkLevel:Null<LdtkProject.LdtkProject_Level>;
	final levelIndex:Int;

	public function new(level:Int) {
		super();
		levelIndex = level;
		ldtkLevel = Ldtk.world.levels[level];
	}

	static final FREE_CELLS = [Empty, Exit];

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

		setupGame();

		addEventListener(onEvent);

		final flow = new Flow(this);
		flow.x = Gui.scale(10);
		flow.y = Gui.scale(10);
		flow.layout = Vertical;
		new TextButton(flow, "Back", () -> {
			App.instance.switchState(new MenuView());
		}, Gui.Colors.GREY, false, 0.4);
		new TextButton(flow, "Reset", () -> {
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
						grid[x][y] = Slime;
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
			if (!isPointInBoard(newPos.add(Utils.toIPoint(p))) || !FREE_CELLS.contains(grid[newPos.x + p.x][newPos.y + p.y])) {
				return;
			}
			if (isPointInBoard(newPos.add(Utils.toIPoint(p)).add(diff))
				&& grid[newPos.x + p.x + diff.x][newPos.y + p.y + diff.y] == Slime) {
				slimesToBeAdded.push(new IPoint(p.x + diff.x, p.y + diff.y));
			}
			if (grid[newPos.x + p.x][newPos.y + p.y] == Exit) {
				win();
			}
		}
		for (s in slimesToBeAdded) {
			playerGrid.set(new Point2d(s.x, s.y), true);
			grid[newPos.x + s.x][newPos.y + s.y] = Empty;
		}
		playerPos = newPos;
	}

	override function update(dt:Float) {
		timeSinceLastUpdate += dt;

		final step = 0.5;
		while (timeSinceLastUpdate > step) {
			timeSinceLastUpdate -= step;
			tick();
		}

		gameArea.clear();
		gameArea.beginFill(0x716CB3);
		gameArea.drawRect(0, 0, BOARD_WIDTH, BOARD_HEIGHT);

		for (x in 0...BOARD_WIDTH) {
			for (y in 0...BOARD_HEIGHT) {
				switch (grid[x][y]) {
					case Slime:
						gameArea.beginFill(0x22593D);
						gameArea.drawRect(x, y, 1, 1);
					case Wall:
						gameArea.beginFill(0x3B3B3B);
						gameArea.drawRect(x, y, 1, 1);
					case Empty:
					case Exit:
				}
			}
		}

		gameArea.beginFill(0x20AB35);
		for (p in playerGrid.keys()) {
			gameArea.drawRect(playerPos.x + p.x, playerPos.y + p.y, 1, 1);
		}
	}

	function tick() {}
}

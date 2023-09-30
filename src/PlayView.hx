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
}

class PlayView extends GameState {
	final playWidth = 16;
	final playHeight = 10;

	final gameArea = new h2d.Graphics();
	var playerPos = new IPoint();
	final playerGrid = new HashMap<Point2d, Bool>();

	var resetText:TextButton;

	var timeSinceLastUpdate = 0.0;

	static final BOARD_WIDTH = 16;

	static final BOARD_HEIGHT = 10;

	final grid:Array<Array<Cell>> = [
		for (x in 0...BOARD_WIDTH) [
			for (y in 0...BOARD_HEIGHT)
				Empty
		]
	];

	override function init() {
		if (height / width > playHeight / playWidth) {
			// Width is limiting factor
			gameArea.scale(width / playWidth);
			gameArea.y = (height - playHeight * gameArea.scaleY) / 2;
		} else {
			// Height is limiting factor
			gameArea.scale(height / playHeight);
			gameArea.x = (width - playWidth * gameArea.scaleX) / 2;
		}
		addChild(gameArea);

		setupGame();
		
		addEventListener(onEvent);

		resetText = new TextButton(this, "Reset", () -> {
			trace("reset");
			App.instance.switchState(new PlayView());
		});


		final manager = hxd.snd.Manager.get();
		manager.masterVolume = 0.5;
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Reverb(hxd.snd.effect.ReverbPreset.DRUGGED));
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(0.5));
	}

	function setupGame() {
		grid[2][2] = Slime;
		grid[5][7] = Wall;
		grid[3][8] = Slime;
		playerGrid.set(new Point2d(0, 0), true);
		playerGrid.set(new Point2d(0, 1), true);
		playerPos.x = 10;
		playerPos.y = 3;
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
			if (!isPointInBoard(newPos.add(Utils.toIPoint(p))) || grid[newPos.x + p.x][newPos.y + p.y] != Empty) {
				return;
			}
			if (isPointInBoard(newPos.add(Utils.toIPoint(p)).add(diff))
				&& grid[newPos.x + p.x + diff.x][newPos.y + p.y + diff.y] == Slime) {
				slimesToBeAdded.push(new IPoint(p.x + diff.x, p.y + diff.y));
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
		gameArea.drawRect(0, 0, playWidth, playHeight);

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

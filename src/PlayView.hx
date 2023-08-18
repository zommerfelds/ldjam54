import box2D.collision.shapes.B2EdgeShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import h2d.col.Point;

enum State {
	WaitingForTouch;
	Playing;
	MissedBall;
	Dead;
}

enum Cell {
	Empty;
	Locked;
	Falling;
}

class PlayView extends GameState {
	final playWidth = 16;
	final playHeight = 10;

	final gameArea = new h2d.Graphics();

	var state = WaitingForTouch;

	final pointsText = new Gui.Text("");
	var points = 0;

	final resetText = new Gui.Text("");
	final resetInteractive = new h2d.Interactive(0, 0);

	var timeSinceLastUpdate = 0.0;

	static final BOARD_WIDTH = 16;

	static final BOARD_HEIGHT = 10;

	final grid:Array<Array<Cell>> = [
		for (x in 0...BOARD_WIDTH) [
			for (y in 0...BOARD_HEIGHT)
				Empty
		]
	];

	static final BOX2D_VELOCITY_ITERATIONS = 8;
	static final BOX2D_POSITION_ITERATIONS = 3;

	final b2World = new B2World(new B2Vec2(0, 10.0), true);

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

		pointsText.x = width * 0.5;
		pointsText.y = width * 0.02 + gameArea.y + 1 * gameArea.scaleY;
		pointsText.textAlign = Center;
		this.addChild(pointsText);

		setupGame();

		addEventListener(onEvent);

		final manager = hxd.snd.Manager.get();
		manager.masterVolume = 0.5;
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Reverb(hxd.snd.effect.ReverbPreset.DRUGGED));
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(0.5));
	}

	function setupGame() {
		resetText.visible = false;
		points = 0;
		state = WaitingForTouch;
		grid[2][2] = Falling;
		grid[2][3] = Falling;
		grid[2][4] = Falling;
		grid[3][4] = Falling;
		grid[3][8] = Locked;
	}

	function onEvent(event:hxd.Event) {
		switch (event.kind) {
			case EPush:
				if (state == WaitingForTouch) {
					state = Playing;
					hxd.Res.start.play();
				}
			default:
		}
	}

	override function update(dt:Float) {
		// TODO: consider a fixed time step (or make it explicit).
		b2World.step(dt, BOX2D_VELOCITY_ITERATIONS, BOX2D_POSITION_ITERATIONS);
		// It seems like this version of Box2D doesn't auto-clear forces.
		// https://box2d.org/documentation/classb2_world.html#aa2bced28ddef5bbb00ed5666e5e9f620
		// https://stackoverflow.com/a/14495543/3810493
		b2World.clearForces();

		timeSinceLastUpdate += dt;

		final step = 0.5;
		while (timeSinceLastUpdate > step) {
			timeSinceLastUpdate -= step;
			tick();
		}

		gameArea.clear();
		gameArea.beginFill(0x3B32B4);
		gameArea.drawRect(0, 0, playWidth, playHeight);

		for (x in 0...BOARD_WIDTH) {
			for (y in 0...BOARD_HEIGHT) {
				switch (grid[x][y]) {
					case Falling:
						gameArea.beginFill(0x34BE79);
						gameArea.drawRect(x, y, 1, 1);
					case Locked:
						gameArea.beginFill(0xB827A5);
						gameArea.drawRect(x, y, 1, 1);
					case Empty:
				}
			}
		}

		pointsText.text = "" + points;

		if (state == WaitingForTouch || state == Dead)
			return;

		if (App.loadHighScore() < points) {
			App.writeHighScore(points);
		}
	}

	function tick() {
		for (x in 0...BOARD_WIDTH) {
			var y = BOARD_HEIGHT - 1;
			while (y >= 0) {
				if (grid[x][y] == Falling) {
					if (y == BOARD_HEIGHT - 1 || grid[x][y + 1] == Locked) {
						grid[x][y] = Locked;
					} else {
						grid[x][y + 1] = Falling;
						grid[x][y] = Empty;
					}
				}
				y--;
			}
		}
	}

	public static function toB2Vec2(pt:{x:Float, y:Float}) {
		return new B2Vec2(pt.x, pt.y);
	}
}

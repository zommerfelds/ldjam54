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

class PlayView extends GameState {
	final playWidth = 16;
	final playHeight = 10;

	final gameArea = new h2d.Graphics();

	final ball = new h2d.Graphics();
	final ballSize = 0.5;
	var ballVel = new Point();

	final wallSize = 0.2;

	var state = WaitingForTouch;

	final pointsText = new Gui.Text("");
	var points = 0;

	final resetText = new Gui.Text("");
	final resetInteractive = new h2d.Interactive(0, 0);

	final wallDefitition = [
		new Point(1, 1),
		new Point(12, 3),
		new Point(15, 9),
		new Point(6, 9),
		new Point(5, 7),
		new Point(2, 9),
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
		gameArea.beginFill(0x330000);
		gameArea.drawRect(0, 0, playWidth, playHeight);
		addChild(gameArea);

		initWalls();

		ball.beginFill(0xffffff);
		ball.drawRect(-ballSize / 2, -ballSize / 2, ballSize, ballSize);
		gameArea.addChild(ball);

		pointsText.x = width * 0.5;
		pointsText.y = width * 0.02 + gameArea.y + wallSize * gameArea.scaleY;
		pointsText.textAlign = Center;
		this.addChild(pointsText);

		setupGame();

		addEventListener(onEvent);

		final manager = hxd.snd.Manager.get();
		manager.masterVolume = 0.5;
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Reverb(hxd.snd.effect.ReverbPreset.DRUGGED));
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(0.5));
	}

	function initWalls() {
		final walls = new h2d.Graphics(gameArea);
		walls.lineStyle(wallSize, 0xffffff);
		final bodyDef = new B2BodyDef();
		final body = b2World.createBody(bodyDef);

		for (def in wallDefitition) {
			walls.lineTo(def.x, def.y);
		}
		walls.lineTo(wallDefitition[0].x, wallDefitition[0].y);

		for (i in 0...wallDefitition.length - 1) {
			final fixture = new B2FixtureDef();
			fixture.density = 1;
			fixture.shape = new B2EdgeShape(toB2Vec2(wallDefitition[i]), toB2Vec2(wallDefitition[i + 1]));
		}
	}

	function setupGame() {
		resetText.visible = false;
		points = 0;
		ball.x = 8;
		ball.y = 8;
		state = WaitingForTouch;
	}

	function onEvent(event:hxd.Event) {
		switch (event.kind) {
			case EPush:
				if (state == WaitingForTouch) {
					state = Playing;
					setRandomBallVel();
					hxd.Res.start.play();
				}
			default:
		}
	}

	function setRandomBallVel() {
		ballVel = new Point(0, -(3 + points));
		ballVel.rotate((Math.random() - 0.5) * Math.PI * 0.8);
	}

	override function update(dt:Float) {
		// TODO: consider a fixed time step (or make it explicit).
		b2World.step(dt, BOX2D_VELOCITY_ITERATIONS, BOX2D_POSITION_ITERATIONS);
		// It seems like this version of Box2D doesn't auto-clear forces.
		// https://box2d.org/documentation/classb2_world.html#aa2bced28ddef5bbb00ed5666e5e9f620
		// https://stackoverflow.com/a/14495543/3810493
		b2World.clearForces();

		pointsText.text = "" + points;

		if (state == WaitingForTouch || state == Dead)
			return;

		ball.x += ballVel.x * dt;
		ball.y += ballVel.y * dt;

		if (ball.y - ballSize * 0.5 < wallSize) {
			ball.y = wallSize + ballSize * 0.5;
			ballVel.y *= -1;
			points += 1;
			hxd.Res.blip.play();
		}
		if (ball.x - ballSize * 0.5 < wallSize) {
			ball.x = wallSize + ballSize * 0.5;
			ballVel.x *= -1;
			points += 1;
			hxd.Res.blip.play();
		}
		if (ball.x + ballSize * 0.5 > playWidth - wallSize) {
			ball.x = playWidth - wallSize - ballSize * 0.5;
			ballVel.x *= -1;
			points += 1;
			hxd.Res.blip.play();
		}
		if (ball.y + ballSize * 0.5 > playHeight - wallSize) {
			ball.y = playHeight - wallSize - ballSize * 0.5;
			ballVel.y *= -1;
			points += 1;
			hxd.Res.blip.play();
		}
		if (App.loadHighScore() < points) {
			App.writeHighScore(points);
		}
	}

	public static function toB2Vec2(pt:{x:Float, y:Float}) {
		return new B2Vec2(pt.x, pt.y);
	}
}

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
		new Point(1,1),
		new Point(12, 3),
		new Point(15, 9),
		new Point(6, 9),
		new Point(5, 7),
		new Point(2, 9),
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
		gameArea.beginFill(0x330000);
		gameArea.drawRect(0, 0, playWidth, playHeight);
		addChild(gameArea);

		final wall = new h2d.Graphics(gameArea);
		wall.beginFill(0xffffff);
		wall.drawRect(0, 0, playWidth, wallSize);
		wall.drawRect(0, 0, wallSize, playHeight);
		wall.drawRect(playWidth - wallSize, 0, wallSize, playHeight);
		wall.drawRect(0, playHeight - wallSize, playWidth, wallSize);

		final walls = new h2d.Graphics(gameArea);
		walls.lineStyle(wallSize, 0xffffff);
		for (def in wallDefitition) {
			walls.lineTo(def.x, def.y);
		}
		walls.lineTo(wallDefitition[0].x, wallDefitition[0].y);

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
}

import motion.easing.Sine;
import motion.Actuate;
import LdtkProject.Ldtk;

class MenuView extends GameState {
	override function init() {
		final centeringFlow = new h2d.Flow(this);
		centeringFlow.backgroundTile = h2d.Tile.fromColor(0x082036);
		centeringFlow.fillWidth = true;
		centeringFlow.fillHeight = true;
		centeringFlow.horizontalAlign = Middle;
		centeringFlow.verticalAlign = Middle;
		centeringFlow.maxWidth = width;
		centeringFlow.layout = Vertical;
		centeringFlow.verticalSpacing = Gui.scaleAsInt(50);

		new Gui.Text("Wellcome to...", centeringFlow, 0.5);
		new Gui.Text("Free The Slime!", centeringFlow);

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		new Gui.TextButton(centeringFlow, "Toggle fullscreen", () -> {
			HerbalTeaApp.toggleFullScreen();
			centeringFlow.reflow();
		}, Gui.Colors.GREEN, 0.5);

		final levels = new h2d.Flow(centeringFlow);
		levels.overflow = Limit;
		levels.multiline = true;
		levels.maxWidth = Std.int(centeringFlow.maxWidth * 0.8);
		levels.horizontalAlign = Middle;
		levels.horizontalSpacing = Gui.scaleAsInt(10);
		levels.verticalSpacing = Gui.scaleAsInt(10);
		final unlockedLevel = App.loadUnlockedLevel();
		/*new Gui.TextButton(levels, "Intro", () -> {
			App.instance.switchState(new PlayView(0));
		}, Gui.Colors.BLUE, 0.8);*/
		for (i in 0...Ldtk.proj.all_worlds.Default.levels.length) {
			if (i > unlockedLevel)
				break;
			new Gui.TextButton(levels, "Exp. " + (i + 1), () -> {
				App.instance.switchState(new PlayView(i));
			}, Gui.Colors.BLUE, 0.8);
		}

		if (unlockedLevel >= Ldtk.proj.all_worlds.Default.levels.length) {
			final winText = new Gui.Text("You beat the game!", centeringFlow);
			Utils.tween(winText, 0.5, {alpha: 0.5}).ease(Sine.easeInOut).reflect().repeat();
		}

		// new Gui.Text("Highscore: " + App.loadHighScore(), centeringFlow, 0.8);

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		new Gui.Text("version: " + hxd.Res.version.entry.getText(), centeringFlow, 0.5);
	}
}

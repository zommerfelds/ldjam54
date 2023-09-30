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

		new Gui.Text("Wellcome to...", centeringFlow, 0.8);
		new Gui.Text("Sticky Block", centeringFlow);

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		new Gui.TextButton(centeringFlow, "Toggle fullscreen", () -> {
			HerbalTeaApp.toggleFullScreen();
			centeringFlow.reflow();
		}, Gui.Colors.BLUE, 0.8);

		final levels = new h2d.Flow(centeringFlow);
		levels.overflow = Limit;
		levels.multiline = true;
		levels.maxWidth = Std.int(centeringFlow.maxWidth * 0.8);
		levels.horizontalAlign = Middle;
		levels.horizontalSpacing = Gui.scaleAsInt(10);
		levels.verticalSpacing = Gui.scaleAsInt(10);
		for (i in 0...Ldtk.proj.all_worlds.Default.levels.length) {
			new Gui.TextButton(levels, "L" + i, () -> {
				App.instance.switchState(new PlayView(i));
			}, Gui.Colors.BLUE, 0.8);
		}

		// new Gui.Text("Highscore: " + App.loadHighScore(), centeringFlow, 0.8);

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		new Gui.Text("version: " + hxd.Res.version.entry.getText(), centeringFlow, 0.5);
	}
}

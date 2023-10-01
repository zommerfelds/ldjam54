import motion.easing.Cubic;
import LdtkProject.Ldtk;
import hxd.Key;
import Gui.TextButton;
import h2d.Flow;

class StoryView extends GameState {
	final storyText:String;
	final levelIndex:Int;

	public function new(storyText:String, levelIndex:Int) {
		super();
		this.storyText = storyText;
		this.levelIndex = levelIndex;
	}

	override function init() {
		final centeringFlow = new Flow(this);
		centeringFlow.backgroundTile = h2d.Tile.fromColor(0x082036);
		centeringFlow.fillWidth = true;
		centeringFlow.fillHeight = true;
		centeringFlow.horizontalAlign = Middle;
		centeringFlow.verticalAlign = Middle;
		centeringFlow.maxWidth = Std.int(width * 0.6);
		centeringFlow.layout = Vertical;
		centeringFlow.verticalSpacing = Gui.scaleAsInt(50);

		final text = new Gui.Text("Experiment #" + (levelIndex + 1) + " - Research Report", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Utils.tween(text, 2.0, {alpha: 1.0}).ease(Cubic.easeInOut);

		centeringFlow.addSpacing(Gui.scaleAsInt(50));

		var enableEnter = false;
		final text = new Gui.Text(storyText, centeringFlow, 0.5);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Utils.tween(text, 2.0, {alpha: 1.0})
			.delay(1.5)
			.ease(Cubic.easeInOut)
			.onComplete(() -> {
				enableEnter = true;
			});

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		final text = levelIndex < Ldtk.world.levels.length ? "Continue experimentation" : "You reached the end!";
		final button = new Gui.TextButton(centeringFlow, text + " [ENTER]", () -> {
			done();
		}, Gui.Colors.GREEN, 0.5);
		button.alpha = 0.0;
		Utils.tween(button, 2.0, {alpha: 1.0}).ease(Cubic.easeInOut).delay(3.0);

		final flow = new Flow(this);
		flow.x = Gui.scale(10);
		flow.y = Gui.scale(10);
		flow.layout = Vertical;
		new TextButton(flow, "Back", () -> {
			App.instance.switchState(new MenuView());
		}, Gui.Colors.GREY, false, 0.4);

		addEventListener(e -> {
			if (enableEnter && e.kind == EKeyDown && e.keyCode == Key.ENTER) {
				done();
			}
		});
	}

	function done() {
		App.instance.switchState(new MenuView());
	}
}

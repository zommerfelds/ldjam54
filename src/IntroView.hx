import Gui.TextButton;
import h2d.Flow;

class IntroView extends GameState {
	override function init() {
		final centeringFlow = new Flow(this);
		centeringFlow.backgroundTile = h2d.Tile.fromColor(0x082036);
		centeringFlow.fillWidth = true;
		centeringFlow.fillHeight = true;
		centeringFlow.horizontalAlign = Middle;
		centeringFlow.verticalAlign = Middle;
		centeringFlow.maxWidth = Std.int(width * 0.8);
		centeringFlow.layout = Vertical;
		centeringFlow.verticalSpacing = Gui.scaleAsInt(50);

		final text = new Gui.Text("The Evil Monster Research Corporation captured our slime friends.", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Utils.tween(text, 2.0, {alpha: 1.0}).delay(0.5);
		final text = new Gui.Text("They are conducting intelligence tests on our species.", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Utils.tween(text, 2.0, {alpha: 1.0}).delay(3.0);
		final text = new Gui.Text("How evil!", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Utils.tween(text, 2.0, {alpha: 1.0}).delay(6.0);

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		final button = new Gui.TextButton(centeringFlow, "See the experiments", () -> {
			App.writeUnlockedLevel(0);
			App.instance.switchState(new MenuView());
		}, Gui.Colors.GREEN, 0.5);
		button.alpha = 0.0;
		Utils.tween(button, 2.0, {alpha: 1.0}).delay(9.0);

		final flow = new Flow(this);
		flow.x = Gui.scale(10);
		flow.y = Gui.scale(10);
		flow.layout = Vertical;
		new TextButton(flow, "Back", () -> {
			App.instance.switchState(new MenuView());
		}, Gui.Colors.GREY, false, 0.4);
	}
}

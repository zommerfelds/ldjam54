import hxd.snd.Channel;
import hxd.snd.effect.Pitch;
import motion.Actuate;
import hxd.Res;
import motion.easing.Cubic;
import hxd.Key;
import Gui.TextButton;
import h2d.Flow;

class IntroView extends GameState {
	var loopSound:Null<Channel>;

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

		loopSound = Res.sounds.scary.play(true);

		final text = new Gui.Text("The Evil Monster Research Corporation captured our slime friends.", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Actuate.timer(0.7).onComplete(() -> {
			final s = Res.sounds.research.play();
			s.addEffect(new Pitch(1.0));
		});
		Utils.tween(text, 0.5, {alpha: 1.0}).delay(0.5).ease(Cubic.easeInOut);
		final text = new Gui.Text("They are conducting intelligence tests on our species.", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		Actuate.timer(3.2).onComplete(() -> {
			final s = Res.sounds.research.play();
			s.addEffect(new Pitch(1.2));
		});
		Utils.tween(text, 0.5, {alpha: 1.0}).delay(3.0).ease(Cubic.easeInOut);
		final text = new Gui.Text("How evil!", centeringFlow, 0.8);
		text.textAlign = MultilineCenter;
		text.alpha = 0.0;
		var enableEnter = false;
		Actuate.timer(6.2).onComplete(() -> {
			final s = Res.sounds.research.play();
			s.addEffect(new Pitch(1.5));
		});
		Utils.tween(text, 0.5, {alpha: 1.0})
			.delay(6.0)
			.ease(Cubic.easeInOut)
			.onComplete(() -> {
				enableEnter = true;
			});

		centeringFlow.addSpacing(Gui.scaleAsInt(100));

		final button = new Gui.TextButton(centeringFlow, "See the experiments [ENTER]", done, Gui.Colors.GREEN, 0.5);
		button.alpha = 0.0;
		Utils.tween(button, 1.0, {alpha: 1.0}).delay(9.0).ease(Cubic.easeInOut);

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
		Res.sounds.done.play();
		App.writeUnlockedLevel(0);
		App.instance.switchState(new MenuView());
	}

	override function cleanup() {
		if (loopSound != null) {
			loopSound.fadeTo(0.0, loopSound.stop);
		}
	}
}

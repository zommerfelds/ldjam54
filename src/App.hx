class App extends HerbalTeaApp {
	public static var instance:App;

	static function main() {
		instance = new App();
	}

	override function onload() {
		final params = new js.html.URLSearchParams(js.Browser.window.location.search);
		final view = switch (params.get("start")) {
			case "play":
				final levelIndex = params.get("level") == null ? 0 : Std.parseInt(params.get("level"));
				new PlayView(levelIndex);
			case "menu" | null:
				new MenuView();
			case x: throw 'invavid "start" query param "$x"';
		}
		switchState(view);
	}

	// TODO: move this to HerbalTeaApp
	public static function loadUnlockedLevel():Int {
		return hxd.Save.load({unlockedLevel: 0}).unlockedLevel;
	}

	public static function writeUnlockedLevel(unlockedLevel:Int) {
		hxd.Save.save({unlockedLevel: unlockedLevel});
	}
}

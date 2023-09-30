class App extends HerbalTeaApp {
	public static var instance:App;

	static function main() {
		instance = new App();
	}

	override function onload() {
		// TODO: load the menu when the game is ready:
		// switchState(new MenuView());
		switchState(new PlayView(0));
	}

	// TODO: move this to HerbalTeaApp
	public static function loadHighScore():Int {
		return hxd.Save.load({highscore: 0}).highscore;
	}

	public static function writeHighScore(highscore:Int) {
		hxd.Save.save({highscore: highscore});
	}
}

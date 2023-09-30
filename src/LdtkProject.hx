// This line is needed to create LdtkProject class at compile time.
private typedef _Tmp = haxe.macro.MacroType<[ldtk.Project.build("res/heaps/map.ldtk")]>;

/** Usage example:

	import LdtkProject.Ldtk;

	...
	final ldtkLevel:LdtkProject.LdtkProject_Level = Ldtk.proj.all_worlds.Default.levels[0];
**/
class Ldtk {
	public static final proj = new LdtkProject();
    public static final world = proj.all_worlds.Default;

	#if debug
	static final validated = validate();

	public static function validate() {
		trace("Debug: validating level");
		for (level in Ldtk.proj.all_worlds.Default.levels) {
			switch (level.f_LevelGoal) {
				case null:
					throw 'LDtk level "${level.identifier}" has no LevelGoal';
				case Score if (level.f_LevelGoalValue == null || level.f_LevelGoalValue <= 0):
					throw 'LDtk level "${level.identifier}" has invalid LevelGoalValue (must be a valid score)';
				case ClearBlockers if (level.f_LevelGoalValue != null):
					trace("WARNING: LevelGoalValue is ignored for ClearBlockers");

				default: // OK
			}
		}
		return true;
	}
	#end
}
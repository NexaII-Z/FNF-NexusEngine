package backend;

/**
 * Keeps track of the difficulty names for the current week / song
 * and turns a difficulty index into a chart file suffix.
 */
class Difficulty
{
	public static var defaultList(default, never):Array<String> = ['Easy', 'Normal', 'Hard'];
	public static var list:Array<String> = [];

	// The chart with no suffix, and the difficulty Freeplay / Story Mode start on.
	private static var defaultDifficulty(default, never):String = 'Normal';

	inline public static function getFilePath(num:Null<Int> = null):String
	{
		var name:String = getString(num);
		var suffix:String = (name == defaultDifficulty) ? '' : '-' + name;
		return Paths.formatToSongPath(suffix);
	}

	inline public static function loadFromWeek(week:WeekData = null):Void
	{
		if (week == null) week = WeekData.getCurrentWeek();

		var raw:String = week.difficulties;
		if (raw == null || raw.length < 1)
		{
			resetList();
			return;
		}

		var parsed:Array<String> = [for (name in raw.trim().split(',')) name.trim()];
		parsed = parsed.filter(function(name:String) return name.length > 0);

		if (parsed.length > 0) list = parsed;
		else resetList();
	}

	inline public static function resetList():Void
	{
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>):Void
	{
		list = diffs.copy();
	}

	inline public static function getString(num:Null<Int> = null):String
	{
		return list[num == null ? PlayState.storyDifficulty : num];
	}

	inline public static function getDefault():String
	{
		return defaultDifficulty;
	}
}

package backend;

/**
 * Per-song / per-week best scores, stored in the save file.
 * Keys look like "tutorial" (Normal) or "tutorial-hard".
 */
class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();

	// ---- keys --------------------------------------------------------------------

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	// ---- reading -------------------------------------------------------------------

	public static function getScore(song:String, diff:Int):Int
	{
		var key:String = formatSong(song, diff);
		if (!songScores.exists(key)) writeScore(key, 0);
		return songScores.get(key);
	}

	public static function getRating(song:String, diff:Int):Float
	{
		var key:String = formatSong(song, diff);
		if (!songRating.exists(key)) writeRating(key, 0);
		return songRating.get(key);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var key:String = formatSong(week, diff);
		if (!weekScores.exists(key)) writeWeekScore(key, 0);
		return weekScores.get(key);
	}

	// ---- saving a result (only keeps a new best) -------------------------------------

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1):Void
	{
		var key:String = formatSong(song, diff);
		var isNewBest:Bool = !songScores.exists(key) || songScores.get(key) < score;
		if (!isNewBest) return;

		writeScore(key, score);
		if (rating >= 0) writeRating(key, rating);
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var key:String = formatSong(week, diff);
		if (!weekScores.exists(key) || weekScores.get(key) < score)
			writeWeekScore(key, score);
	}

	// ---- resetting -----------------------------------------------------------------------

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var key:String = formatSong(song, diff);
		writeScore(key, 0);
		writeRating(key, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		writeWeekScore(formatSong(week, diff), 0);
	}

	// ---- save file ---------------------------------------------------------------------------

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null) weekScores = FlxG.save.data.weekScores;
		if (FlxG.save.data.songScores != null) songScores = FlxG.save.data.songScores;
		if (FlxG.save.data.songRating != null) songRating = FlxG.save.data.songRating;
	}

	// These expect keys that were already built with formatSong().
	static function writeScore(key:String, score:Int):Void
	{
		songScores.set(key, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function writeWeekScore(key:String, score:Int):Void
	{
		weekScores.set(key, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function writeRating(key:String, rating:Float):Void
	{
		songRating.set(key, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}
}

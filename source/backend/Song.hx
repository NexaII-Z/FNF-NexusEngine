package backend;

import haxe.Json;
import lime.utils.Assets;

import backend.Section;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

/**
 * Loads chart files.
 * Both chart layouts are accepted:
 *   {"song": { ...chart... }}   (classic)
 *   { ...chart... }             (flat, used by newer charts)
 */
class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	// ---- loading -----------------------------------------------------------------

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var chartName:String = Paths.formatToSongPath(jsonInput);
		var chartFolder:String = Paths.formatToSongPath(folder);

		var raw:String = readChartText(chartFolder, chartName);
		var chart:Dynamic = parseJSONshit(trimTrailingGarbage(raw));

		if (jsonInput != 'events') StageData.loadDirectory(chart);
		upgradeOldChart(chart);
		return chart;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var root:Dynamic = Json.parse(rawJson);

		// Classic charts keep the chart under "song"; flat charts use "song" for the title.
		var wrapped:Dynamic = root.song;
		if (wrapped != null && !Std.isOfType(wrapped, String)) return cast wrapped;
		return cast root;
	}

	static function readChartText(folder:String, name:String):String
	{
		#if MODS_ALLOWED
		var modFile:String = Paths.modsJson(folder + '/' + name);
		if (FileSystem.exists(modFile)) return File.getContent(modFile).trim();
		#end

		var path:String = Paths.json(folder + '/' + name);

		#if sys
		if (FileSystem.exists(path)) return File.getContent(path).trim();
		#end

		return Assets.getText(path).trim();
	}

	// Some editors leave stray characters after the closing brace.
	static function trimTrailingGarbage(raw:String):String
	{
		var end:Int = raw.lastIndexOf('}');
		return (end >= 0) ? raw.substr(0, end + 1) : raw;
	}

	// ---- old chart formats ----------------------------------------------------------

	/** Converts very old charts (player3, note-based events) to the current layout. */
	static function upgradeOldChart(chart:Dynamic):Void
	{
		if (chart.gfVersion == null)
		{
			chart.gfVersion = chart.player3;
			chart.player3 = null;
		}

		if (chart.events != null) return;

		chart.events = [];
		for (sectionIndex in 0...chart.notes.length)
		{
			var section:SwagSection = chart.notes[sectionIndex];
			var sectionNotes:Array<Dynamic> = section.sectionNotes;

			var i:Int = 0;
			while (i < sectionNotes.length)
			{
				var note:Array<Dynamic> = sectionNotes[i];
				if (note[1] < 0) // notes with a negative lane are events
				{
					chart.events.push([note[0], [[note[2], note[3], note[4]]]]);
					sectionNotes.remove(note);
				}
				else i++;
			}
		}
	}
}

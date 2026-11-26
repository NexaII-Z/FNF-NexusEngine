package backend;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

/**
 * A week as shown in Story Mode / Freeplay.
 * Base game weeks come from  assets/shared/nexus/weeks/  and mod weeks from  mods/<mod>/weeks/.
 */
class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	/** The mod folder this week came from ('' for the base game). */
	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		return {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
	}

	/** Copies every field of the json file that this class also has. */
	public function new(weekFile:WeekFile, fileName:String)
	{
		var own:Array<String> = Reflect.fields(this);
		for (field in Reflect.fields(weekFile))
			if (own.contains(field))
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
	}

	// ---- loading -------------------------------------------------------------------

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false):Void
	{
		weeksList = [];
		weeksLoaded.clear();

		// Search order: mods root, base game, then every enabled mod.
		var sources:Array<String> = [];
		#if MODS_ALLOWED
		sources.push(Paths.mods());
		#end
		sources.push(Paths.getSharedPath());
		var firstModIndex:Int = sources.length;

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled)
			sources.push(Paths.mods(mod + '/'));
		#end

		// 1) weeks named in the base game's weekList.txt keep that order
		for (name in CoolUtil.coolTextFile(weeksFolder(Paths.getSharedPath()) + 'weekList.txt'))
		{
			for (i in 0...sources.length)
				registerWeek(name, weeksFolder(sources[i]) + name + '.json', sources[i], i >= firstModIndex, isStoryMode);
		}

		// 2) weeks from other folders / mods
		#if MODS_ALLOWED
		for (i in 0...sources.length)
		{
			var directory:String = weeksFolder(sources[i]);
			if (!FileSystem.exists(directory)) continue;

			for (name in CoolUtil.coolTextFile(directory + 'weekList.txt'))
				registerWeek(name, directory + name + '.json', sources[i], i >= firstModIndex, isStoryMode);

			for (file in Paths.readDirectory(directory))
			{
				var path:String = haxe.io.Path.join([directory, file]);
				if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					registerWeek(file.substr(0, file.length - 5), path, sources[i], i >= firstModIndex, isStoryMode);
			}
		}
		#end
	}

	/** "<source>weeks/", sending the base game folder through the Nexus layout. */
	static function weeksFolder(source:String):String
	{
		return (source == Paths.getSharedPath()) ? Paths.getSharedPath('weeks/') : source + 'weeks/';
	}

	static function registerWeek(name:String, path:String, source:String, fromMod:Bool, isStoryMode:Null<Bool>):Void
	{
		if (weeksLoaded.exists(name)) return;

		var file:WeekFile = readWeekFile(path);
		if (file == null) return;

		var week:WeekData = new WeekData(file, name);
		#if MODS_ALLOWED
		if (fromMod) week.folder = source.substring(Paths.mods().length, source.length - 1);
		#end

		var visible:Bool = isStoryMode == null
			|| (isStoryMode && !week.hideStoryMode)
			|| (!isStoryMode && !week.hideFreeplay);

		if (!visible) return;

		weeksLoaded.set(name, week);
		weeksList.push(name);
	}

	static function readWeekFile(path:String):WeekFile
	{
		var raw:String = null;

		#if MODS_ALLOWED
		if (FileSystem.exists(path)) raw = File.getContent(path);
		#else
		if (OpenFlAssets.exists(path)) raw = Assets.getText(path);
		#end

		if (raw == null || raw.length < 1) return null;

		try
		{
			return cast tjson.TJSON.parse(raw);
		}
		catch (e:Dynamic)
		{
			trace('Could not read week file "$path": $e');
		}
		return null;
	}

	// ---- current week ------------------------------------------------------------------

	/** File name (without .json) of the week being played. */
	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null):Void
	{
		Mods.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
	}
}

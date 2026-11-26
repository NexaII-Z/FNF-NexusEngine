package backend;

#if ACHIEVEMENTS_ALLOWED
import objects.AchievementPopup;
import haxe.Exception;
import haxe.Json;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

typedef Achievement =
{
	var name:String;
	var description:String;
	@:optional var hidden:Bool;
	@:optional var maxScore:Float;
	@:optional var maxDecimals:Int;

	// handled automatically, ignore these two
	@:optional var mod:String;
	@:optional var ID:Int;
}

/**
 * Achievements: the built-in list, mod lists (mods/<mod>/data/achievements.json), progress
 * scores for the ones that count something, and the unlock popups.
 */
class Achievements
{
	public static var achievements:Map<String, Achievement> = new Map<String, Achievement>();
	public static var variables:Map<String, Float> = [];
	public static var achievementsUnlocked:Array<String> = [];

	// Haxe maps are unordered, so every achievement remembers the order it was created in.
	static var _sortID:Int = 0;
	static var _builtInCount:Int = -1;
	static var _firstLoad:Bool = true;

	// ======================================================================================
	//  The built-in list
	// ======================================================================================

	public static function init()
	{
		createAchievement('friday_night_play',  {name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", hidden: true});
		createAchievement('week1_nomiss',       {name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses."});
		createAchievement('week2_nomiss',       {name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses."});
		createAchievement('week3_nomiss',       {name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses."});
		createAchievement('week4_nomiss',       {name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses."});
		createAchievement('week5_nomiss',       {name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses."});
		createAchievement('week6_nomiss',       {name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses."});
		createAchievement('week7_nomiss',       {name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses."});
		createAchievement('weekend1_nomiss',    {name: "Just a Friendly Sparring", description: "Beat Weekend 1 on Hard with no Misses."});
		createAchievement('ur_bad',             {name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%."});
		createAchievement('ur_good',            {name: "Perfectionist", description: "Complete a Song with a rating of 100%."});
		createAchievement('roadkill_enthusiast', {name: "Roadkill Enthusiast", description: "Watch the Henchmen die 50 times.", maxScore: 50, maxDecimals: 0});
		createAchievement('oversinging',        {name: "Oversinging Much...?", description: "Sing for 10 seconds without going back to Idle."});
		createAchievement('hype',               {name: "Hyperactive", description: "Finish a Song without going back to Idle."});
		createAchievement('two_keys',           {name: "Just the Two of Us", description: "Finish a Song pressing only two keys."});
		createAchievement('toastie',            {name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?"});
		createAchievement('debugger',           {name: "Debugger", description: "Beat the \"Test\" Stage from the Chart Editor.", hidden: true});

		// everything created after this point comes from mods
		_builtInCount = _sortID;
	}

	public static function createAchievement(name:String, data:Achievement, ?mod:String = null)
	{
		data.ID = _sortID;
		data.mod = mod;
		achievements.set(name, data);
		_sortID++;
	}

	public static function get(name:String):Achievement
		return achievements.get(name);

	public static function exists(name:String):Bool
		return achievements.exists(name);

	inline public static function isUnlocked(name:String)
		return achievementsUnlocked.contains(name);

	// ======================================================================================
	//  Save file
	// ======================================================================================

	public static function load():Void
	{
		if (!_firstLoad) return;
		if (_builtInCount < 0) init();

		if (FlxG.save.data == null) return;

		if (FlxG.save.data.achievementsUnlocked != null)
			achievementsUnlocked = FlxG.save.data.achievementsUnlocked;

		var savedScores:Map<String, Float> = cast FlxG.save.data.achievementsVariables;
		if (savedScores != null)
			for (key => value in savedScores)
				variables.set(key, value);

		_firstLoad = false;
	}

	public static function save():Void
	{
		FlxG.save.data.achievementsUnlocked = achievementsUnlocked;
		FlxG.save.data.achievementsVariables = variables;
	}

	// ======================================================================================
	//  Progress scores (for achievements that have a maxScore)
	// ======================================================================================

	public static function getScore(name:String):Float
		return updateScore(name, GET);

	public static function setScore(name:String, value:Float, saveIfNotUnlocked:Bool = true):Float
		return updateScore(name, SET, value, saveIfNotUnlocked);

	public static function addScore(name:String, value:Float = 1, saveIfNotUnlocked:Bool = true):Float
		return updateScore(name, ADD, value, saveIfNotUnlocked);

	static function updateScore(name:String, mode:ScoreMode, amount:Float = 1, saveIfNotUnlocked:Bool = true):Float
	{
		if (!variables.exists(name)) variables.set(name, 0);
		if (!achievements.exists(name)) return -1;

		var achievement:Achievement = achievements.get(name);
		if (achievement.maxScore < 1)
			throw new Exception('Achievement has score disabled or is incorrectly configured: $name');

		if (achievementsUnlocked.contains(name)) return achievement.maxScore;

		var value:Float = amount;
		switch (mode)
		{
			case GET: return variables.get(name);
			case ADD: value += variables.get(name);
			case SET:
		}

		if (value >= achievement.maxScore)
		{
			unlock(name);
			value = achievement.maxScore;
		}
		variables.set(name, value);

		Achievements.save();
		if (saveIfNotUnlocked || value >= achievement.maxScore) FlxG.save.flush();
		return value;
	}

	// ======================================================================================
	//  Unlocking
	// ======================================================================================

	static var _lastUnlock:Int = -999;

	public static function unlock(name:String, autoStartPopup:Bool = true):String
	{
		if (!achievements.exists(name))
		{
			FlxG.log.error('Achievement "$name" does not exists!');
			throw new Exception('Achievement "$name" does not exists!');
		}

		if (isUnlocked(name)) return null;

		trace('Completed achievement "$name"');
		achievementsUnlocked.push(name);

		// no sound spam when several unlock in the same moment
		var now:Int = openfl.Lib.getTimer();
		if (Math.abs(now - _lastUnlock) >= 100)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.5);
			_lastUnlock = now;
		}

		Achievements.save();
		FlxG.save.flush();

		if (autoStartPopup) startPopup(name);
		return name;
	}

	// ======================================================================================
	//  Popups
	// ======================================================================================

	@:allow(objects.AchievementPopup)
	private static var _popups:Array<AchievementPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopup(achieve:String, endFunc:Void->Void = null)
	{
		// push the ones already on screen down to make room
		for (popup in _popups)
			if (popup != null) popup.intendedY += 150;

		_popups.push(new AchievementPopup(achieve, endFunc));
	}

	// ======================================================================================
	//  Mod achievements
	// ======================================================================================

	#if MODS_ALLOWED
	public static function reloadList()
	{
		// forget the achievements of the previous mod list
		var modded:Array<String> = [for (key => value in achievements) if (value.mod != null) key];
		for (key in modded) achievements.remove(key);

		_sortID = _builtInCount;

		var previousMod:String = Mods.currentModDirectory;
		Mods.currentModDirectory = null;
		loadAchievementJson(Paths.mods('data/achievements.json'));

		for (mod in Mods.parseList().enabled)
		{
			Mods.currentModDirectory = mod;
			loadAchievementJson(Paths.mods('$mod/data/achievements.json'));
		}
		Mods.currentModDirectory = previousMod;
	}

	static function modLabel():String
	{
		return 'Mod name: ' + (Mods.currentModDirectory != null ? Mods.currentModDirectory : "None");
	}

	inline static function loadAchievementJson(path:String, addMods:Bool = true)
	{
		var list:Array<Dynamic> = null;
		if (!FileSystem.exists(path)) return list;

		try
		{
			var raw:String = File.getContent(path).trim();
			if (raw != null && raw.length > 0) list = tjson.TJSON.parse(raw);

			if (addMods && list != null)
			{
				for (i in 0...list.length)
				{
					var entry:Dynamic = list[i];
					if (entry == null)
					{
						CoolUtil.showPopUp('Achievement #${i + 1} is invalid.', modLabel());
						continue;
					}

					var key:String = entry.save;
					if (key == null || key.trim().length < 1)
					{
						CoolUtil.showPopUp('Missing valid "save" value.', 'Error on Achievement: ' + (entry.name != null ? entry.name : entry.save));
						continue;
					}

					key = key.trim();
					if (achievements.exists(key)) continue;

					createAchievement(key, entry, Mods.currentModDirectory);
				}
			}
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Error loading achievements.json: $e', modLabel());
		}
		return list;
	}
	#end

	// ======================================================================================
	//  Lua
	// ======================================================================================

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getAchievementScore", function(name:String):Float
		{
			if (!achievements.exists(name))
			{
				FunkinLua.luaTrace('getAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return getScore(name);
		});
		Lua_helper.add_callback(lua, "setAchievementScore", function(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		{
			if (!achievements.exists(name))
			{
				FunkinLua.luaTrace('setAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return setScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "addAchievementScore", function(name:String, ?value:Float = 1, ?saveIfNotUnlocked:Bool = true):Float
		{
			if (!achievements.exists(name))
			{
				FunkinLua.luaTrace('addAchievementScore: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return -1;
			}
			return addScore(name, value, saveIfNotUnlocked);
		});
		Lua_helper.add_callback(lua, "unlockAchievement", function(name:String):Dynamic
		{
			if (!achievements.exists(name))
			{
				FunkinLua.luaTrace('unlockAchievement: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return unlock(name);
		});
		Lua_helper.add_callback(lua, "isAchievementUnlocked", function(name:String):Dynamic
		{
			if (!achievements.exists(name))
			{
				FunkinLua.luaTrace('isAchievementUnlocked: Couldnt find achievement: $name', false, false, FlxColor.RED);
				return null;
			}
			return isUnlocked(name);
		});
		Lua_helper.add_callback(lua, "achievementExists", function(name:String) return achievements.exists(name));
	}
	#end
}

private enum ScoreMode
{
	GET;
	SET;
	ADD;
}
#end

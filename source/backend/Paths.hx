package backend;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;

#if MODS_ALLOWED
import backend.Mods;
#end

/**
 * Asset lookup and cache for Nexus Engine.
 *
 * Search order for a file:
 *   1. mods (current mod, global mods, mods/)
 *   2. the current week folder   assets/week_assets/<level>/   (or assets/<level>/ inside a build)
 *   3. the base game             assets/shared/
 *
 * Base game data folders (weeks, stages, characters, data) live under assets/shared/nexus/,
 * see NexusLayout. getSharedPath() applies that, so callers keep using the short names.
 */
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	// ======================================================================================
	//  Memory management
	// ======================================================================================

	/** Assets that survive clearUnusedMemory() even when no state is using them. */
	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	/** Graphics currently kept alive by the engine, by file path. */
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	/** Sounds currently kept alive, by file path. */
	public static var currentTrackedSounds:Map<String, Sound> = [];

	/** Files the current state asked for. Everything else can be freed. */
	public static var localTrackedAssets:Array<String> = [];

	/** Frees graphics nobody in the current state is using. */
	public static function clearUnusedMemory()
	{
		for (key in currentTrackedAssets.keys())
		{
			if (localTrackedAssets.contains(key) || dumpExclusions.contains(key)) continue;

			var graphic = currentTrackedAssets.get(key);
			if (graphic == null) continue;

			@:privateAccess
			{
				FlxG.bitmap._cache.remove(key);
				openfl.Assets.cache.removeBitmapData(key);
				currentTrackedAssets.remove(key);

				graphic.persist = false; // lets the garbage collector actually free it
				graphic.destroyOnNoUse = true;
				graphic.destroy();
			}
		}

		System.gc();
		#if cpp
		cpp.NativeGc.run(true);
		#end
	}

	/** Called when a new state starts: forgets what the old one was using. */
	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var graphic = FlxG.bitmap._cache.get(key);
			if (graphic != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				graphic.destroy();
			}
		}

		for (key => sound in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && sound != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		// everything is unused until the next state asks for it again
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	// ======================================================================================
	//  Path resolution
	// ======================================================================================

	/** The week folder (assets/week_assets/<level>) searched before the base game. */
	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
		{
			var modded:String = modFolders((library != null) ? '$library/$file' : file);
			if (FileSystem.exists(modded)) return modded;
		}
		#end

		if (library == "mobile") return getSharedPath('mobile/$file');
		if (library != null) return getLibraryPath(file, library);

		var level:String = findInLevel(file, type);
		if (level != null) return level;

		return getSharedPath(file);
	}

	/** Looks for `file` in the current week folder; null when it is not there. */
	static function findInLevel(file:String, type:AssetType):Null<String>
	{
		if (currentLevel == null || currentLevel == 'shared') return null;

		// library form: assets/week_assets/<level> is registered as the "week_assets" library
		var inLibrary:String = getLibraryPathForce(file, 'week_assets', currentLevel);
		if (OpenFlAssets.exists(inLibrary, type)) return inLibrary;

		// plain form: a build flattens assets/week_assets/<level> into assets/<level>
		if (currentLevel.length > 0)
		{
			var plain:String = 'assets/$currentLevel/$file';
			if (OpenFlAssets.exists(plain, type)) return plain;
		}
		return null;
	}

	static public function getLibraryPath(file:String, library = "shared")
	{
		return (library == "shared") ? getSharedPath(file) : getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if (level == null) level = library;
		return '$library:assets/$level/$file';
	}

	/** assets/shared/<file>, with the Nexus data folders redirected (see NexusLayout). */
	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/' + NexusLayout.redirect(file);
	}

	// ---- typed shortcuts -------------------------------------------------------------------

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	inline static public function shaderFragment(key:String, ?library:String)
		return getPath('shaders/$key.frag', TEXT, library);

	inline static public function shaderVertex(key:String, ?library:String)
		return getPath('shaders/$key.vert', TEXT, library);

	inline static public function lua(key:String, ?library:String)
		return getPath('$key.lua', TEXT, library);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var modded:String = modsVideo(key);
		if (FileSystem.exists(modded)) return modded;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var modded:String = modsFont(key);
		if (FileSystem.exists(modded)) return modded;
		#end
		return 'assets/fonts/$key';
	}

	// ======================================================================================
	//  Text
	// ======================================================================================

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var modded:String = modFolders(key);
			if (FileSystem.exists(modded)) return File.getContent(modded);
		}
		#end

		var shared:String = getSharedPath(key);
		if (FileSystem.exists(shared)) return File.getContent(shared);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var inLibrary:String = getLibraryPathForce(key, 'week_assets', currentLevel);
			if (FileSystem.exists(inLibrary)) return File.getContent(inLibrary);

			if (currentLevel.length > 0)
			{
				var plain:String = 'assets/$currentLevel/$key';
				if (FileSystem.exists(plain)) return File.getContent(plain);
			}
		}
		#end

		var path:String = getPath(key, TEXT);
		if (OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;
		}
		#end

		return OpenFlAssets.exists(getPath(key, type, library, false));
	}

	// ======================================================================================
	//  Images
	// ======================================================================================

	static public function image(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
		#end

		if (bitmap == null)
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);
		}

		if (bitmap != null)
		{
			var graphic:FlxGraphic = cacheBitmap(file, bitmap, allowGPU);
			if (graphic != null) return graphic;
		}

		trace('Image not found or could not be loaded: $file');
		return null;
	}

	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true)
	{
		if (bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
			else
			#end
			if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null) return null;
		}

		localTrackedAssets.push(file);

		// Optionally keep the pixels on the GPU only (saves RAM, but the texture can not be read back).
		if (allowGPU && ClientPrefs.data.cacheOnGPU)
		{
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, graphic);
		return graphic;
	}

	// ======================================================================================
	//  Sprite sheets
	// ======================================================================================

	/** Loads a sheet described by Sparrow xml, a TexturePacker json, or a packer txt (in that order). */
	static public function getAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var graphic:FlxGraphic = image(key, library, allowGPU);

		var xmlPath:Dynamic = getPath('images/$key.xml', TEXT, library, true);
		if (OpenFlAssets.exists(xmlPath) #if MODS_ALLOWED || (FileSystem.exists(xmlPath) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(graphic, (useMod ? File.getContent(xmlPath) : xmlPath));
			#else
			return FlxAtlasFrames.fromSparrow(graphic, xmlPath);
			#end
		}

		var jsonPath:Dynamic = getPath('images/$key.json', TEXT, library, true);
		if (OpenFlAssets.exists(jsonPath) #if MODS_ALLOWED || (FileSystem.exists(jsonPath) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromTexturePackerJson(graphic, (useMod ? File.getContent(jsonPath) : jsonPath));
			#else
			return FlxAtlasFrames.fromTexturePackerJson(graphic, jsonPath);
			#end
		}

		return getPackerAtlas(key, library);
	}

	/** Several sheets merged into one set of frames (character json "image": "a, b, c"). */
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var frames:FlxAtlasFrames = getAtlas(keys[0].trim(), parentFolder, allowGPU);
		if (keys.length < 2) return frames;

		var first:FlxAtlasFrames = frames;
		frames = new FlxAtlasFrames(first.parent);
		frames.addAtlas(first, true);

		for (i in 1...keys.length)
		{
			var extra:FlxAtlasFrames = getAtlas(keys[i].trim(), parentFolder, allowGPU);
			if (extra != null) frames.addAtlas(extra, true);
		}
		return frames;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var graphic:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var modXml:String = modsXml(key);
		var hasModXml:Bool = FileSystem.exists(modXml);
		return FlxAtlasFrames.fromSparrow(graphic, hasModXml ? File.getContent(modXml) : getPath('images/$key.xml', library));
		#else
		return FlxAtlasFrames.fromSparrow(graphic, getPath('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var graphic:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var modTxt:String = modsTxt(key);
		var hasModTxt:Bool = FileSystem.exists(modTxt);
		return FlxAtlasFrames.fromSpriteSheetPacker(graphic, hasModTxt ? File.getContent(modTxt) : getPath('images/$key.txt', library));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(graphic, getPath('images/$key.txt', library));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var graphic:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var modJson:String = modsImagesJson(key);
		var hasModJson:Bool = FileSystem.exists(modJson);
		return FlxAtlasFrames.fromTexturePackerJson(graphic, hasModJson ? File.getContent(modJson) : getPath('images/$key.json', library));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(graphic, getPath('images/$key.json', library));
		#end
	}

	// ======================================================================================
	//  Sounds
	// ======================================================================================

	static public function sound(key:String, ?library:String):Sound
	{
		return returnSound('sounds', key, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		return returnSound('music', key, library);
	}

	inline static public function voices(song:String, postfix:String = null):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postfix != null) songKey += '-' + postfix;
		return returnSound(null, songKey, 'songs');
	}

	inline static public function inst(song:String):Any
	{
		return returnSound(null, '${formatToSongPath(song)}/Inst', 'songs');
	}

	/** Lower-case, dashes for spaces, no punctuation: "Dad Battle!" -> "dad-battle". */
	inline static public function formatToSongPath(path:String)
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var dashed = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(dashed).join("").toLowerCase();
	}

	public static function returnSound(path:Null<String>, key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library/';
		if (path != null) modLibPath += '$path';

		var modded:String = modsSounds(modLibPath, key);
		if (FileSystem.exists(modded))
		{
			if (!currentTrackedSounds.exists(modded))
				currentTrackedSounds.set(modded, Sound.fromFile(modded));
			localTrackedAssets.push(modded);
			return currentTrackedSounds.get(modded);
		}
		#end

		var gottenPath:String = '$key.$SOUND_EXT';
		if (path != null) gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length); // drop the "library:" prefix

		if (!currentTrackedSounds.exists(gottenPath))
		{
			var assetKey:String = (path != null) ? '$path/$key' : key;
			assetKey = ((path == 'songs') ? 'songs:' : '') + getPath('$assetKey.$SOUND_EXT', SOUND, library);
			if (OpenFlAssets.exists(assetKey, SOUND))
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(assetKey));
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	// ======================================================================================
	//  Mods
	// ======================================================================================

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
	{
		return #if mobile Sys.getCwd() + #end 'mods/' + key;
	}

	inline static public function modsFont(key:String)
		return modFolders('fonts/' + key);

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	/** The first mod folder that has `key` (current mod, then global mods); mods/<key> when none does. */
	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var inCurrent:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(inCurrent)) return inCurrent;
		}

		for (mod in Mods.getGlobalMods())
		{
			var inGlobal:String = mods(mod + '/' + key);
			if (FileSystem.exists(inGlobal)) return inGlobal;
		}
		return #if mobile Sys.getCwd() + #end 'mods/' + key;
	}
	#end

	// ======================================================================================
	//  Adobe Animate atlases
	// ======================================================================================

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var haveAnimJson = false;
		var haveAtlasJson = false;
		var haveImage = false;

		if (spriteJson != null)
		{
			haveAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if (animationJson != null)
		{
			haveAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// a folder name (or image path): look for spritemap.json, spritemap2.json, ... inside it
		if (Std.isOfType(folderOrImg, String))
		{
			var folder:String = folderOrImg;
			for (i in 0...10)
			{
				var suffix:String = (i == 0) ? '' : '$i';

				if (!haveAtlasJson)
				{
					spriteJson = getTextFromFile('images/$folder/spritemap$suffix.json');
					if (spriteJson != null)
					{
						haveImage = true;
						haveAtlasJson = true;
						folderOrImg = Paths.image('$folder/spritemap$suffix');
						break;
					}
				}
				else if (Paths.fileExists('images/$folder/spritemap$suffix.png', IMAGE))
				{
					haveImage = true;
					folderOrImg = Paths.image('$folder/spritemap$suffix');
					break;
				}
			}

			if (!haveImage)
			{
				haveImage = true;
				folderOrImg = Paths.image(folder);
			}

			if (!haveAnimJson)
			{
				haveAnimJson = true;
				animationJson = getTextFromFile('images/$folder/Animation.json');
			}
		}

		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	// ======================================================================================
	//  Folders
	// ======================================================================================

	public static function readDirectory(directory:String):Array<String>
	{
		#if MODS_ALLOWED
		return FileSystem.readDirectory(directory);
		#else
		var dirs:Array<String> = [];
		for (dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for (library in lime.utils.Assets.libraries.keys())
			{
				if (library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if (Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs.map(dir -> dir.substr(dir.lastIndexOf("/") + 1));
		#end
	}
}

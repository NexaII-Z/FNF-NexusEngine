package backend;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

/**
 * Small general-purpose helpers shared across the engine.
 */
class CoolUtil
{
	// ---- numbers -------------------------------------------------------------

	/** Rounds `f` to the nearest 1/snap. */
	inline public static function quantize(f:Float, snap:Float):Float
	{
		return Math.fround(f * snap) / snap;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);

		var multiplier:Float = Math.pow(10, decimals);
		return Math.floor(value * multiplier) / multiplier;
	}

	/** [min, min + 1, ... max - 1] */
	inline public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
	{
		var out:Array<Int> = [];
		for (i in min...max) out.push(i);
		return out;
	}

	// ---- text ------------------------------------------------------------------

	inline public static function capitalize(text:String):String
	{
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	/** Splits text into trimmed lines. */
	inline public static function listFromString(string:String):Array<String>
	{
		return [for (line in string.trim().split('\n')) line.trim()];
	}

	/** Reads a text file and returns its lines (empty when the file does not exist). */
	inline public static function coolTextFile(path:String):Array<String>
	{
		var content:String = null;

		#if (sys && MODS_ALLOWED)
		// drop library prefixes such as "shared:" or "preload:"
		var parts:Array<String> = path.split(':');
		path = parts[parts.length - 1];
		if (FileSystem.exists(path)) content = File.getContent(path);
		#else
		if (Assets.exists(path)) content = Assets.getText(path);
		#end

		return (content != null) ? listFromString(content) : [];
	}

	public static function setTextBorderFromString(text:FlxText, border:String):Void
	{
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	// ---- colors ------------------------------------------------------------------

	/** Accepts "FF00FF", "#FF00FF", "0xFFFF00FF" or a color name; falls back to white. */
	inline public static function colorFromString(color:String):FlxColor
	{
		var cleaned:String = ~/[\t\n\r]/.split(color).join('').trim();
		if (cleaned.startsWith('0x')) cleaned = cleaned.substring(cleaned.length - 6);

		var parsed:Null<FlxColor> = FlxColor.fromString(cleaned);
		if (parsed == null) parsed = FlxColor.fromString('#$cleaned');
		return (parsed != null) ? parsed : FlxColor.WHITE;
	}

	/** The most common non-transparent color of a sprite (ignores black). */
	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var counts:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var pixel:Int = sprite.pixels.getPixel32(col, row);
				if (pixel == 0) continue;
				counts[pixel] = counts.exists(pixel) ? counts[pixel] + 1 : 1;
			}
		}

		counts[FlxColor.BLACK] = 0;

		var bestCount:Int = 0;
		var bestColor:Int = 0;
		for (color in counts.keys())
		{
			if (counts[color] >= bestCount)
			{
				bestCount = counts[color];
				bestColor = color;
			}
		}
		return bestColor;
	}

	// ---- system --------------------------------------------------------------------

	inline public static function browserLoad(site:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false):Void
	{
		#if sys
		if (!absolute) folder = Sys.getCwd() + '$folder';

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		folder = folder.replace('/', '\\');
		#end

		Sys.command(command, [folder]);
		trace('$command $folder');
		#else
		FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/** Where the save file lives: "<company>/<file name>". */
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}
}

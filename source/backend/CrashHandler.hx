package backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using flixel.util.FlxArrayUtil;

/**
 * Catches crashes, shows the error with its call stack, and saves it to logs/.
 * @author YoshiCrafter29, Ne_Eo, MAJigsaw77 and Lily Ross (mcagabe19)
 */
class CrashHandler
{
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	// ---- script / haxe errors ----------------------------------------------------------------------

	private static function onUncaughtError(event:UncaughtErrorEvent):Void
	{
		event.preventDefault();
		event.stopPropagation();
		event.stopImmediatePropagation();

		var message:String = event.error;
		if (Std.isOfType(event.error, Error))
		{
			var error:Error = cast event.error;
			message = error.message;
		}
		else if (Std.isOfType(event.error, ErrorEvent))
		{
			var errorEvent:ErrorEvent = cast event.error;
			message = errorEvent.text;
		}

		finish('$message\n${describeStack(haxe.CallStack.exceptionStack())}', "Error!");
	}

	// ---- native crashes ----------------------------------------------------------------------------

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final lines:Array<String> = [];

		if (message != null && message.length > 0)
			lines.push(message);

		lines.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));

		finish(lines.join('\n'), "Critical Error!");
	}
	#end

	// ---- shared ---------------------------------------------------------------------------------------

	/** Saves the report, shows it, and closes the game. */
	private static function finish(report:String, title:String):Void
	{
		#if sys
		saveErrorMessage(report);
		#end

		CoolUtil.showPopUp(report, title);
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}

	private static function describeStack(stack:Array<haxe.CallStack.StackItem>):String
	{
		var lines:Array<String> = [];

		for (item in stack)
		{
			switch (item)
			{
				case CFunction:
					lines.push("Non-Haxe (C) Function");
				case Module(name):
					lines.push('Module ${name}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							lines.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							lines.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(name):
					lines.push('Local Function ${name}');
				case Method(cl, method):
					lines.push('${cl} - ${method}');
			}
		}
		return lines.join('\r\n');
	}

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent('logs/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', message);
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
	}
	#end
}

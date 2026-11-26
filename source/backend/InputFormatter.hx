package backend;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

/**
 * Turns key / button ids into the short labels shown in the controls menu.
 */
class InputFormatter
{
	// ======================================================================================
	//  Keyboard
	// ======================================================================================

	public static function getKeyName(key:FlxKey):String
	{
		switch (key)
		{
			case NONE: return '---';

			case BACKSPACE: return "BckSpc";
			case CONTROL: return "Ctrl";
			case ALT: return "Alt";
			case CAPSLOCK: return "Caps";
			case PAGEUP: return "PgUp";
			case PAGEDOWN: return "PgDown";
			case PRINTSCREEN: return "PrtScrn";

			// number row
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";

			// number pad ("#" marks the pad)
			case NUMPADZERO: return "#0";
			case NUMPADONE: return "#1";
			case NUMPADTWO: return "#2";
			case NUMPADTHREE: return "#3";
			case NUMPADFOUR: return "#4";
			case NUMPADFIVE: return "#5";
			case NUMPADSIX: return "#6";
			case NUMPADSEVEN: return "#7";
			case NUMPADEIGHT: return "#8";
			case NUMPADNINE: return "#9";
			case NUMPADMULTIPLY: return "#*";
			case NUMPADPLUS: return "#+";
			case NUMPADMINUS: return "#-";
			case NUMPADPERIOD: return "#.";

			// punctuation
			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case RBRACKET: return "]";
			case QUOTE: return "'";

			default: return prettify(Std.string(key));
		}
	}

	// ======================================================================================
	//  Gamepad
	// ======================================================================================

	public static function getGamepadName(key:FlxGamepadInputID):String
	{
		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = (gamepad != null) ? gamepad.detectedModel : UNKNOWN;

		switch (key)
		{
			case NONE: return '---';

			// left stick
			case LEFT_STICK_DIGITAL_LEFT: return "Left";
			case LEFT_STICK_DIGITAL_RIGHT: return "Right";
			case LEFT_STICK_DIGITAL_UP: return "Up";
			case LEFT_STICK_DIGITAL_DOWN: return "Down";
			case LEFT_STICK_CLICK: return byModel(model, "L3", "LS", "Analog Click");

			// right stick
			case RIGHT_STICK_DIGITAL_LEFT: return "C. Left";
			case RIGHT_STICK_DIGITAL_RIGHT: return "C. Right";
			case RIGHT_STICK_DIGITAL_UP: return "C. Up";
			case RIGHT_STICK_DIGITAL_DOWN: return "C. Down";
			case RIGHT_STICK_CLICK: return byModel(model, "R3", "RS", "C. Click");

			// d-pad
			case DPAD_LEFT: return "D. Left";
			case DPAD_RIGHT: return "D. Right";
			case DPAD_UP: return "D. Up";
			case DPAD_DOWN: return "D. Down";

			// shoulders and triggers
			case LEFT_SHOULDER: return byModel(model, "L1", "LB", "L. Bumper");
			case RIGHT_SHOULDER: return byModel(model, "R1", "RB", "R. Bumper");
			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON: return byModel(model, "L2", "LT", "L. Trigger");
			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON: return byModel(model, "R2", "RT", "R. Trigger");

			// face buttons ("[" and "]" get their picture swapped in by the controls menu)
			case A: return byModel(model, "X", "A", "Action Down");
			case B: return byModel(model, "O", "B", "Action Right");
			case X: return byModel(model, "[", "X", "Action Left");
			case Y: return byModel(model, "]", "Y", "Action Up");

			case BACK: return byModel(model, "Share", "Back", "Select");
			case START: return byModel(model, "Options", "Start", "Start");

			default: return prettify(Std.string(key));
		}
	}

	// ======================================================================================
	//  Helpers
	// ======================================================================================

	/** Label for a PlayStation 4 pad, an Xbox (XInput) pad, or anything else. */
	static function byModel(model:FlxGamepadModel, ps4:String, xinput:String, other:String):String
	{
		return switch (model)
		{
			case PS4: ps4;
			case XINPUT: xinput;
			default: other;
		}
	}

	/** "SOME_KEY_NAME" -> "Some Key Name"; unknown values become "---". */
	static function prettify(label:String):String
	{
		if (label.toLowerCase() == 'null') return '---';

		var words:Array<String> = label.split('_');
		for (i in 0...words.length)
			words[i] = CoolUtil.capitalize(words[i]);
		return words.join(' ');
	}
}

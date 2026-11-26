package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

/**
 * Reads input from the keyboard, gamepads and the mobile controls, all through the same
 * named actions ("ui_up", "note_left", "accept", ...). The binds live in ClientPrefs.
 *
 * You do not need a getter for every new action, just call:
 *     controls.justPressed("my_action")   // pressed this frame
 *     controls.pressed("my_action")       // held
 *     controls.justReleased("my_action")  // released this frame
 */
class Controls
{
	public static var instance:Controls;

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var mobileBinds:Map<String, Array<MobileInputID>>;

	/** True after the last input came from a gamepad or the touch controls (not the keyboard). */
	public var controllerMode:Bool = false;

	public function new()
	{
		gamepadBinds = ClientPrefs.gamepadBinds;
		keyboardBinds = ClientPrefs.keyBinds;
		mobileBinds = ClientPrefs.mobileBinds;
	}

	// ======================================================================================
	//  Shortcuts for the common actions
	// ======================================================================================

	// pressed this frame
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// held
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// released this frame
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	// other actions (pressed this frame)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	// ======================================================================================
	//  Generic queries
	// ======================================================================================

	public function justPressed(key:String)
	{
		var typed:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
		if (typed) controllerMode = false;

		return typed
			|| gamepadQuery(gamepadBinds[key], JUST_PRESSED)
			|| mobileControlsQuery(mobileBinds[key], JUST_PRESSED)
			|| touchPadQuery(mobileBinds[key], JUST_PRESSED);
	}

	public function pressed(key:String)
	{
		var typed:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
		if (typed) controllerMode = false;

		return typed
			|| gamepadQuery(gamepadBinds[key], HELD)
			|| mobileControlsQuery(mobileBinds[key], HELD)
			|| touchPadQuery(mobileBinds[key], HELD);
	}

	public function justReleased(key:String)
	{
		var typed:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
		if (typed) controllerMode = false;

		return typed
			|| gamepadQuery(gamepadBinds[key], JUST_RELEASED)
			|| mobileControlsQuery(mobileBinds[key], JUST_RELEASED)
			|| touchPadQuery(mobileBinds[key], JUST_RELEASED);
	}

	// ---- per device ------------------------------------------------------------------------------

	private function gamepadQuery(buttons:Array<FlxGamepadInputID>, state:InputState):Bool
	{
		if (buttons == null) return false;

		for (button in buttons)
		{
			var active:Bool = switch (state)
			{
				case JUST_PRESSED: FlxG.gamepads.anyJustPressed(button) == true;
				case HELD: FlxG.gamepads.anyPressed(button) == true;
				case JUST_RELEASED: FlxG.gamepads.anyJustReleased(button) == true;
			}
			if (active)
			{
				controllerMode = true;
				return true;
			}
		}
		return false;
	}

	// The on-screen touch pad of the current state / substate.
	private function touchPadQuery(buttons:Array<MobileInputID>, state:InputState):Bool
	{
		if (buttons == null || requestedInstance.touchPad == null) return false;

		var active:Bool = switch (state)
		{
			case JUST_PRESSED: requestedInstance.touchPad.anyJustPressed(buttons) == true;
			case HELD: requestedInstance.touchPad.anyPressed(buttons) == true;
			case JUST_RELEASED: requestedInstance.touchPad.anyJustReleased(buttons) == true;
		}

		// !!DO NOT DISABLE THIS: without it the touch input is ignored on mobile!!
		if (active) controllerMode = true;
		return active;
	}

	// The in-game hitbox / note buttons (PlayState and EditorPlayState).
	private function mobileControlsQuery(buttons:Array<MobileInputID>, state:InputState):Bool
	{
		if (buttons == null || requestedMobileC == null) return false;

		var active:Bool = switch (state)
		{
			case JUST_PRESSED: requestedMobileC.instance.anyJustPressed(buttons);
			case HELD: requestedMobileC.instance.anyPressed(buttons);
			case JUST_RELEASED: requestedMobileC.instance.anyJustReleased(buttons);
		}

		if (active) controllerMode = true;
		return active;
	}

	// ======================================================================================
	//  Which state owns the touch controls
	// ======================================================================================

	/** Set to true and false by MusicBeatSubstate itself. */
	public var isInSubstate:Bool = false;

	/** The MusicBeatState or MusicBeatSubstate that is currently on screen. */
	public var requestedInstance(get, default):Dynamic;

	/** Its in-game mobile controls (PlayState and EditorPlayState). */
	public var requestedMobileC(get, default):IMobileControls;

	/** True when the touch controls are visible enough to count as "playing on mobile". */
	public var mobileC(get, never):Bool;

	@:noCompletion
	private function get_requestedInstance():Dynamic
	{
		return isInSubstate ? MusicBeatSubstate.instance : MusicBeatState.getState();
	}

	@:noCompletion
	private function get_requestedMobileC():IMobileControls
	{
		return requestedInstance.mobileControls;
	}

	@:noCompletion
	private function get_mobileC():Bool
	{
		return ClientPrefs.data.controlsAlpha >= 0.1;
	}
}

private enum InputState
{
	JUST_PRESSED;
	HELD;
	JUST_RELEASED;
}

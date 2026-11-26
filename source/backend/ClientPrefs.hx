package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.TitleState;

/**
 * Every option the player can change. Add a variable here and it is saved and loaded automatically.
 * Defaults are what a fresh install gets.
 */
@:structInit class SaveVariables
{
	// ---- mobile and mobile controls ----------------------------------------------------------
	public var extraButtons:String = "NONE";   // extra button of the mobile controls
	public var hitboxPos:Bool = true;          // where the extra hitbox button sits
	public var dynamicColors:Bool = true;
	public var controlsAlpha:Float = FlxG.onMobile ? 0.6 : 0;
	public var screensaver:Bool = false;
	public var wideScreen:Bool = false;
	#if android
	public var storageType:String = "EXTERNAL_DATA";
	#end
	public var hitboxType:String = "Gradient";
	public var popUpRating:Bool = true;
	public var vsync:Bool = false;
	public var gameOverVibration:Bool = false;

	// ---- gameplay layout -------------------------------------------------------------------------
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var ghostTapping:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var comboStacking:Bool = true;

	// ---- visuals ------------------------------------------------------------------------------------
	public var showFPS:Bool = true;
	public var flashing:Bool = true;
	public var antialiasing:Bool = true;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = #if !switch false #else true #end;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var scoreZoom:Bool = true;
	public var healthBarAlpha:Float = 1;
	public var timeBarType:String = 'Time Left';
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;

	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	// ---- system ----------------------------------------------------------------------------------------
	public var autoPause:Bool = true;
	public var framerate:Int = 60;
	public var checkForUpdates:Bool = true;
	public var discordRPC:Bool = true;
	public var noReset:Bool = false;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';

	// ---- timing ---------------------------------------------------------------------------------------------
	public var noteOffset:Int = 0;
	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;

	/**
	 * Modifiers from the Gameplay Changers menu.
	 *   scrolltype: "multiplicative" (chart speed x multiplier) or "constant" (fixed speed).
	 */
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
}

class ClientPrefs
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	// Controls are stored in their own save file so they can be deleted without losing scores.
	static inline var CONTROLS_SAVE:String = 'controls_v3';

	// ======================================================================================
	//  Key binds (every action has up to two binds). To add one, also add it in
	//  options/ControlsSubState.hx and Controls.hx.
	// ======================================================================================

	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_up'     => [W, UP],
		'note_left'   => [A, LEFT],
		'note_down'   => [S, DOWN],
		'note_right'  => [D, RIGHT],

		'ui_up'       => [W, UP],
		'ui_left'     => [A, LEFT],
		'ui_down'     => [S, DOWN],
		'ui_right'    => [D, RIGHT],

		'accept'      => [SPACE, ENTER],
		'back'        => [BACKSPACE, ESCAPE],
		'pause'       => [ENTER, ESCAPE],
		'reset'       => [R],

		'volume_mute' => [ZERO],
		'volume_up'   => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],

		'debug_1'     => [SEVEN],
		'debug_2'     => [EIGHT],

		'fullscreen'  => [F11]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'     => [DPAD_UP, Y],
		'note_left'   => [DPAD_LEFT, X],
		'note_down'   => [DPAD_DOWN, A],
		'note_right'  => [DPAD_RIGHT, B],

		'ui_up'       => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'     => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'     => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'    => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'accept'      => [A, START],
		'back'        => [B],
		'pause'       => [START],
		'reset'       => [BACK]
	];

	public static var mobileBinds:Map<String, Array<MobileInputID>> = [
		'note_up'     => [NOTE_UP, UP2],
		'note_left'   => [NOTE_LEFT, LEFT2],
		'note_down'   => [NOTE_DOWN, DOWN2],
		'note_right'  => [NOTE_RIGHT, RIGHT2],

		'ui_up'       => [UP, NOTE_UP],
		'ui_left'     => [LEFT, NOTE_LEFT],
		'ui_down'     => [DOWN, NOTE_DOWN],
		'ui_right'    => [RIGHT, NOTE_RIGHT],

		'accept'      => [A],
		'back'        => [B],
		'pause'       => [#if android NONE #else P #end],
		'reset'       => [NONE]
	];

	public static var defaultMobileBinds:Map<String, Array<MobileInputID>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	/** Snapshot of the binds above, used by "reset to default". */
	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
		defaultMobileBinds = mobileBinds.copy();
	}

	/** controller: null = keyboard and gamepad, false = keyboard only, true = gamepad only. */
	public static function resetKeys(controller:Null<Bool> = null)
	{
		if (controller != true)
			for (action in keyBinds.keys())
				if (defaultKeys.exists(action))
					keyBinds.set(action, defaultKeys.get(action).copy());

		if (controller != false)
			for (action in gamepadBinds.keys())
				if (defaultButtons.exists(action))
					gamepadBinds.set(action, defaultButtons.get(action).copy());
	}

	/** Removes unbound ("NONE") slots from an action. */
	public static function clearInvalidKeys(key:String)
	{
		var keyboard:Array<FlxKey> = keyBinds.get(key);
		var gamepad:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		var mobile:Array<MobileInputID> = mobileBinds.get(key);

		while (keyboard != null && keyboard.contains(NONE)) keyboard.remove(NONE);
		while (gamepad != null && gamepad.contains(NONE)) gamepad.remove(NONE);
		while (mobile != null && mobile.contains(NONE)) mobile.remove(NONE);
	}

	// ======================================================================================
	//  Saving
	// ======================================================================================

	public static function saveSettings()
	{
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		var controls:FlxSave = new FlxSave();
		controls.bind(CONTROLS_SAVE, CoolUtil.getSavePath());
		controls.data.keyboard = keyBinds;
		controls.data.gamepad = gamepadBinds;
		controls.data.mobile = mobileBinds;
		controls.flush();

		FlxG.log.add("Settings saved!");
	}

	// ======================================================================================
	//  Loading
	// ======================================================================================

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;

		// first launch: match the screen's refresh rate
		if (FlxG.save.data.framerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		applyFramerate();

		if (FlxG.save.data.gameplaySettings != null)
		{
			var saved:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in saved)
				data.gameplaySettings.set(name, value);
		}

		// flixel keeps the volume in the save file by itself
		if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end

		loadControls();
	}

	// Raising the frame rate must update the draw rate last (and lowering it first) to avoid hitches.
	static function applyFramerate()
	{
		if (data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}
	}

	static function loadControls()
	{
		var controls:FlxSave = new FlxSave();
		controls.bind(CONTROLS_SAVE, CoolUtil.getSavePath());
		if (controls == null) return;

		if (controls.data.keyboard != null)
		{
			var saved:Map<String, Array<FlxKey>> = controls.data.keyboard;
			for (action => keys in saved)
				if (keyBinds.exists(action)) keyBinds.set(action, keys);
		}
		if (controls.data.gamepad != null)
		{
			var saved:Map<String, Array<FlxGamepadInputID>> = controls.data.gamepad;
			for (action => buttons in saved)
				if (gamepadBinds.exists(action)) gamepadBinds.set(action, buttons);
		}
		if (controls.data.mobile != null)
		{
			var saved:Map<String, Array<MobileInputID>> = controls.data.mobile;
			for (action => buttons in saved)
				if (mobileBinds.exists(action)) mobileBinds.set(action, buttons);
		}
		reloadVolumeKeys();
	}

	// ======================================================================================
	//  Helpers
	// ======================================================================================

	/** Reads a gameplay modifier; `customDefaultValue` makes `defaultValue` the fallback instead of the stock default. */
	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue;
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	/** Turns the volume hotkeys on or off (they are always off with the mobile controls). */
	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final none = [];
		final enabled:Bool = !Controls.instance.mobileC && turnOn;

		FlxG.sound.muteKeys = enabled ? TitleState.muteKeys : none;
		FlxG.sound.volumeDownKeys = enabled ? TitleState.volumeDownKeys : none;
		FlxG.sound.volumeUpKeys = enabled ? TitleState.volumeUpKeys : none;
	}
}

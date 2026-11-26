package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import backend.MusicBeatState;

import objects.Note;
import objects.Character;

enum Countdown
{
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

/**
 * Base class of every hard-coded stage (states/stages/*.hx).
 *
 * A stage overrides the callbacks it needs. It talks to the running PlayState through
 * `game`, and the shortcuts below (boyfriend, camGame, add(), ...) save typing.
 */
class BaseStage extends FlxBasic
{
	private var game(default, set):Dynamic = PlayState.instance;
	public var onPlayState:Bool = false;

	// ---- shortcuts into the state ----------------------------------------------------------
	public var paused(get, never):Bool;
	public var songName(get, never):String;
	public var isStoryMode(get, never):Bool;
	public var seenCutscene(get, never):Bool;
	public var inCutscene(get, set):Bool;
	public var canPause(get, set):Bool;
	public var members(get, never):Dynamic;

	public var boyfriend(get, never):Character;
	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriendGroup(get, never):FlxSpriteGroup;
	public var dadGroup(get, never):FlxSpriteGroup;
	public var gfGroup(get, never):FlxSpriteGroup;

	public var unspawnNotes(get, never):Array<Note>;

	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camOther(get, never):FlxCamera;

	public var defaultCamZoom(get, set):Float;
	public var camFollow(get, never):FlxObject;

	public function new()
	{
		this.game = MusicBeatState.getState();
		if (this.game == null)
		{
			FlxG.log.warn('Invalid state for the stage added!');
			destroy();
			return;
		}

		this.game.stages.push(this);
		super();
		create();
	}

	// ---- main callbacks -------------------------------------------------------------------
	public function create() {}
	public function createPost() {}
	public function countdownTick(count:Countdown, num:Int) {}
	public function startSong() {}

	// ---- steps, beats and sections ----------------------------------------------------------
	public var curBeat:Int = 0;
	public var curDecBeat:Float = 0;
	public var curStep:Int = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public function beatHit() {}
	public function stepHit() {}
	public function sectionHit() {}

	// ---- substates (for pausing tweens / timers) ----------------------------------------------
	public function closeSubState() {}
	public function openSubState(SubState:FlxSubState) {}

	// ---- events -----------------------------------------------------------------------------------
	public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {}
	public function eventPushed(event:EventNote) {}
	public function eventPushedUnique(event:EventNote) {}

	// ---- note hits and misses ---------------------------------------------------------------------
	public function goodNoteHit(note:Note) {}
	public function opponentNoteHit(note:Note) {}
	public function noteMiss(note:Note) {}
	public function noteMissPress(direction:Int) {}

	// ---- put sprites straight into the state --------------------------------------------------------
	function add(object:FlxBasic) game.add(object);
	function remove(object:FlxBasic, splice:Bool = false) game.remove(object, splice);
	function insert(position:Int, object:FlxBasic) game.insert(position, object);

	public function addBehindGF(obj:FlxBasic) insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxBasic) insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxBasic) insert(members.indexOf(game.dadGroup), obj);

	/** Lets the chart editor show the right girlfriend on base game stages. */
	public function setDefaultGF(name:String)
	{
		var gfVersion:String = PlayState.SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
			PlayState.SONG.gfVersion = name;
	}

	// ---- start / end callbacks -----------------------------------------------------------------------
	public function setStartCallback(myfn:Void->Void)
	{
		if (!onPlayState) return;
		PlayState.instance.startCallback = myfn;
	}

	public function setEndCallback(myfn:Void->Void)
	{
		if (!onPlayState) return;
		PlayState.instance.endCallback = myfn;
	}

	// ---- PlayState actions -----------------------------------------------------------------------------
	function startCountdown() if (onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if (onPlayState) return PlayState.instance.endSong(); else return false;
	function moveCameraSection() if (onPlayState) PlayState.instance.moveCameraSection();
	function moveCamera(isDad:Bool) if (onPlayState) PlayState.instance.moveCamera(isDad);

	// ---- property accessors ----------------------------------------------------------------------------
	inline private function get_paused() return game.paused;
	inline private function get_songName() return game.songName;
	inline private function get_isStoryMode() return PlayState.isStoryMode;
	inline private function get_seenCutscene() return PlayState.seenCutscene;

	inline private function get_inCutscene() return game.inCutscene;
	inline private function set_inCutscene(value:Bool)
	{
		game.inCutscene = value;
		return value;
	}

	inline private function get_canPause() return game.canPause;
	inline private function set_canPause(value:Bool)
	{
		game.canPause = value;
		return value;
	}

	inline private function get_members() return game.members;
	inline private function set_game(value:MusicBeatState)
	{
		onPlayState = (Std.isOfType(value, states.PlayState));
		game = value;
		return value;
	}

	inline private function get_boyfriend():Character return game.boyfriend;
	inline private function get_dad():Character return game.dad;
	inline private function get_gf():Character return game.gf;

	inline private function get_boyfriendGroup():FlxSpriteGroup return game.boyfriendGroup;
	inline private function get_dadGroup():FlxSpriteGroup return game.dadGroup;
	inline private function get_gfGroup():FlxSpriteGroup return game.gfGroup;

	inline private function get_unspawnNotes():Array<Note> return cast game.unspawnNotes;

	inline private function get_camGame():FlxCamera return game.camGame;
	inline private function get_camHUD():FlxCamera return game.camHUD;
	inline private function get_camOther():FlxCamera return game.camOther;

	inline private function get_defaultCamZoom():Float return game.defaultCamZoom;
	inline private function set_defaultCamZoom(value:Float):Float
	{
		game.defaultCamZoom = value;
		return game.defaultCamZoom;
	}
	inline private function get_camFollow():FlxObject return game.camFollow;
}

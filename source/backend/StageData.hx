package backend;

import openfl.utils.Assets;
import haxe.Json;
import backend.Song;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;
	var stageUI:String;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

/**
 * Stage json lookup. Base game stages live in assets/shared/nexus/stages/,
 * mod stages in mods/<mod>/stages/.
 */
class StageData
{
	public static var forceNextDirectory:String = null;

	// Which stage the base game songs use when a chart does not name one.
	static final SONG_STAGES:Map<String, String> = [
		'spookeez' => 'spooky', 'south' => 'spooky', 'monster' => 'spooky',
		'pico' => 'philly', 'blammed' => 'philly', 'philly' => 'philly', 'philly-nice' => 'philly',
		'milf' => 'limo', 'satin-panties' => 'limo', 'high' => 'limo',
		'cocoa' => 'mall', 'eggnog' => 'mall',
		'winter-horrorland' => 'mallEvil',
		'senpai' => 'school', 'roses' => 'school',
		'thorns' => 'schoolEvil',
		'ugh' => 'tank', 'guns' => 'tank', 'stress' => 'tank',
		'2hot' => 'phillyStreets', 'darnell' => 'phillyStreets', 'lit-up' => 'phillyStreets',
		'blazin' => 'phillyBlazin'
	];

	public static function dummy():StageFile
	{
		return {
			directory: "",
			defaultZoom: 0.9,
			isPixelStage: false,
			stageUI: "normal",

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};
	}

	/** Remembers the asset folder of the stage this song uses (read later by LoadingState). */
	public static function loadDirectory(SONG:SwagSong):Void
	{
		var stage:String = 'stage';
		if (SONG.stage != null)
			stage = SONG.stage;
		else if (SONG.song != null)
			stage = vanillaSongStage(SONG.song.toLowerCase().replace(' ', '-'));

		var file:StageFile = getStageFile(stage);
		forceNextDirectory = (file == null) ? '' : file.directory; // an empty directory prevents crashes
	}

	public static function getStageFile(stage:String):StageFile
	{
		var raw:String = null;
		var path:String = Paths.getSharedPath('stages/' + stage + '.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('stages/' + stage + '.json');
		if (FileSystem.exists(modPath)) raw = File.getContent(modPath);
		else if (FileSystem.exists(path)) raw = File.getContent(path);
		#else
		if (Assets.exists(path)) raw = Assets.getText(path);
		#end

		if (raw == null) return null;
		return cast tjson.TJSON.parse(raw);
	}

	public static function vanillaSongStage(songName):String
	{
		var stage:String = SONG_STAGES.get(songName);
		return (stage != null) ? stage : 'stage';
	}
}

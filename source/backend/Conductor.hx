package backend;

import backend.Song;
import backend.Section;
import objects.Note;

/** A point in the song where the tempo changes. */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

/**
 * Song clock: converts between time, steps and beats and holds the BPM map.
 * All values are in milliseconds unless noted.
 */
class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // one beat
	public static var stepCrochet:Float = crochet / 4;     // one step (a quarter beat)
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;

	public static var safeZoneOffset:Float = 0; // calculated in PlayState.create()

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	// ---- judgement ---------------------------------------------------------

	/** Picks the rating for a hit that was `diff` ms off. The last tier is the fallback. */
	public static function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating
	{
		for (i in 0...arr.length - 1)
			if (diff <= arr[i].hitWindow)
				return arr[i];

		return arr[arr.length - 1];
	}

	// ---- bpm map lookups -----------------------------------------------------

	static inline function startingChange():BPMChangeEvent
	{
		return {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var found:BPMChangeEvent = startingChange();
		for (change in bpmChangeMap)
			if (time >= change.songTime)
				found = change;
		return found;
	}

	public static function getBPMFromStep(step:Float):BPMChangeEvent
	{
		var found:BPMChangeEvent = startingChange();
		for (change in bpmChangeMap)
			if (change.stepTime <= step)
				found = change;
		return found;
	}

	public static function getCrotchetAtTime(time:Float):Float
	{
		return getBPMFromSeconds(time).stepCrochet * 4;
	}

	// ---- conversions -----------------------------------------------------------

	public static function beatToSeconds(beat:Float):Float
	{
		var step:Float = beat * 4;
		var change:BPMChangeEvent = getBPMFromStep(step);
		return change.songTime + ((step - change.stepTime) / (change.bpm / 60) / 4) * 1000;
	}

	public static function getStep(time:Float):Float
	{
		var change:BPMChangeEvent = getBPMFromSeconds(time);
		return change.stepTime + (time - change.songTime) / change.stepCrochet;
	}

	public static function getStepRounded(time:Float):Float
	{
		var change:BPMChangeEvent = getBPMFromSeconds(time);
		return change.stepTime + Math.floor(time - change.songTime) / change.stepCrochet;
	}

	public static function getBeat(time:Float):Float
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	// ---- building the map --------------------------------------------------------

	public static function mapBPMChanges(song:SwagSong):Void
	{
		bpmChangeMap = [];

		var currentBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalTime:Float = 0;

		for (i in 0...song.notes.length)
		{
			var section:SwagSection = song.notes[i];
			if (section.changeBPM && section.bpm != currentBPM)
			{
				currentBPM = section.bpm;
				bpmChangeMap.push({
					stepTime: totalSteps,
					songTime: totalTime,
					bpm: currentBPM,
					stepCrochet: calculateCrochet(currentBPM) / 4
				});
			}

			var stepsInSection:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += stepsInSection;
			totalTime += ((60 / currentBPM) * 1000 / 4) * stepsInSection;
		}
	}

	static function getSectionBeats(song:SwagSong, index:Int):Float
	{
		var beats:Null<Float> = (song.notes[index] != null) ? song.notes[index].sectionBeats : null;
		return (beats != null) ? beats : 4;
	}

	inline public static function calculateCrochet(bpm:Float):Float
	{
		return (60 / bpm) * 1000;
	}

	public static function set_bpm(newBPM:Float):Float
	{
		bpm = newBPM;
		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;
		return bpm;
	}
}

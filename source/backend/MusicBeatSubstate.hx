package backend;

import flixel.FlxSubState;

/**
 * Base class of every substate (pause menu, game over, popups).
 * Same song clock as MusicBeatState, without stages.
 */
class MusicBeatSubstate extends FlxSubState
{
	/** The substate that is currently open (read by Controls to find the touch pad). */
	public static var instance:MusicBeatSubstate;

	public function new()
	{
		instance = this;
		controls.isInSubstate = true;
		super();
	}

	// ---- song clock ---------------------------------------------------------------------------
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	private var controls(get, never):Controls;
	inline function get_controls():Controls
		return Controls.instance;

	// ======================================================================================
	//  Mobile controls
	// ======================================================================================

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if (touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad == null) return;

		touchPadCam = new FlxCamera();
		touchPadCam.bgColor.alpha = 0;
		FlxG.cameras.add(touchPadCam, defaultDrawTarget);
		touchPad.cameras = [touchPadCam];
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: // LEFT_FULL
				mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: // CUSTOM
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: // HITBOX
				mobileControls = new Hitbox(extraMode);
		}

		mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

		mobileControls.instance.cameras = [mobileControlsCam];
		mobileControls.instance.visible = false;
		add(mobileControls.instance);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	// ======================================================================================
	//  Lifecycle
	// ======================================================================================

	override function destroy()
	{
		controls.isInSubstate = false;
		removeTouchPad();
		removeMobileControls();

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		// the state underneath is not counting time while this one pauses it
		if (!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var previousStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (previousStep != curStep)
		{
			if (curStep > 0) stepHit();

			if (PlayState.SONG != null)
			{
				if (previousStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		super.update(elapsed);
	}

	// ======================================================================================
	//  Steps, beats, sections
	// ======================================================================================

	private function updateCurStep():Void
	{
		var change = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var stepsIntoChange:Float = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - change.songTime) / change.stepCrochet;
		curDecStep = change.stepTime + stepsIntoChange;
		curStep = change.stepTime + Math.floor(stepsIntoChange);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);

		while (curStep >= stepsToDo)
		{
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;

		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] == null) continue;

			stepsToDo += Math.round(getBeatsOnSection() * 4);
			if (stepsToDo > curStep) break;

			curSection++;
		}

		if (curSection > lastSection) sectionHit();
	}

	function getBeatsOnSection()
	{
		var beats:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			beats = PlayState.SONG.notes[curSection].sectionBeats;
		return (beats == null) ? 4 : beats;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
	}

	// Substates have no beat or section behaviour of their own; override these to add some.
	public function beatHit():Void {}

	public function sectionHit():Void {}
}

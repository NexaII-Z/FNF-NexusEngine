package backend;

import flixel.util.FlxGradient;
import flixel.FlxSubState;

/**
 * The swipe used when moving between states: a black wall with a soft gradient edge
 * that slides down the screen (closing in) or off it (opening up).
 */
class CustomFadeTransition extends FlxSubState
{
	/** Runs once when the swipe reaches the end. */
	public static var finishCallback:Void->Void;

	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float;

	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		// draw over everything: use the camera that was added last
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var zoom:Float = Math.max(camera.zoom, 0.001);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);

		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		transGradient.y = isTransIn ? transBlack.y - transBlack.height : -transGradient.height;

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		final zoom:Float = Math.max(camera.zoom, 0.001);
		final screenHeight:Float = FlxG.height * zoom;
		final endPosition:Float = transGradient.height + 50 * zoom;

		if (duration > 0)
			transGradient.y += (screenHeight + endPosition) * elapsed / duration;
		else
			transGradient.y = endPosition * elapsed;

		transBlack.y = isTransIn ? transGradient.y + transGradient.height : transGradient.y - transBlack.height;

		if (transGradient.y >= endPosition)
		{
			close();
			if (finishCallback != null) finishCallback();
			finishCallback = null;
		}
	}
}

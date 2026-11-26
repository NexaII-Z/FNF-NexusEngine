package backend.animation;

import flixel.animation.FlxAnimationController;

/**
 * Animation controller that can follow FlxG.animationTimeScale
 * (used by the playback rate option), unless followGlobalSpeed is turned off.
 */
class NexusAnimationController extends FlxAnimationController
{
	public var followGlobalSpeed:Bool = true;

	public override function update(elapsed:Float):Void
	{
		if (_curAnim != null)
		{
			var speed:Float = timeScale;
			if (followGlobalSpeed) speed *= FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		}
		else if (_prerotated != null)
		{
			_prerotated.angle = _sprite.angle;
		}
	}
}

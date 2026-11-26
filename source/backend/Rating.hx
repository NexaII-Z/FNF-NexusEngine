package backend;

/**
 * One judgement tier (sick / good / bad / shit).
 * Hit windows come from the player's options (ClientPrefs.data.<name>Window).
 */
class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; // milliseconds
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = readWindow(name);
	}

	static function readWindow(name:String):Null<Int>
	{
		try
		{
			return Reflect.field(ClientPrefs.data, name + 'Window');
		}
		catch (e)
		{
			FlxG.log.error(e);
		}
		return 0;
	}

	// Highest tier first. Only the best tier spawns note splashes.
	static final TIERS:Array<{name:String, mod:Float, score:Int, splash:Bool}> = [
		{name: 'sick', mod: 1.00, score: 350, splash: true},
		{name: 'good', mod: 0.67, score: 200, splash: false},
		{name: 'bad', mod: 0.34, score: 100, splash: false},
		{name: 'shit', mod: 0.00, score: 50, splash: false}
	];

	public static function loadDefault():Array<Rating>
	{
		var list:Array<Rating> = [];
		for (tier in TIERS)
		{
			var rating:Rating = new Rating(tier.name);
			rating.ratingMod = tier.mod;
			rating.score = tier.score;
			rating.noteSplash = tier.splash;
			list.push(rating);
		}
		return list;
	}
}

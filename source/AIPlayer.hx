package;

import flixel.FlxG;
import flixel.math.FlxMath;

class AIPlayer
{
	public static var BadNoteTypes:Array<String> = ['Hurt Note', 'Kill Note', 'Burst Note', 'Sleep Note', 'Fake Note'];

	public static function GeneratePlayMap(map:Song.SwagSong, rules:AI_Rulesets)
	{
	}
}

typedef AI_Rulesets =
{
	var Decrease_Weight:{Min:Float, Max:Float};
}

typedef Hand =
{
	var Finger1:Finger;
	var Finger2:Finger;
}

class Finger
{
	public var noteDirection:Int;
	public var tiredness:Float = 1.0;

	public function new(noteDirection:Int)
	{
		this.noteDirection = noteDirection;
	}
}

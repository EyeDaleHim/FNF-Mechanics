package;

import flixel.FlxG;
import flixel.math.FlxMath;
import noisehx.Perlin;

class AIPlayer
{
	public static var BadNoteTypes:Array<String> = ['Hurt Note', 'Kill Note', 'Burst Note', 'Sleep Note', 'Fake Note'];

	/*
	 * make a humidity system type of shit by calculating how many notes there are
	 * the closer the humidity is to the best humidity, this benefits the AI best
	 * although higher humidity will guarantee higher accuracy
	 * 
	 * 
	 * 
	 * the fps will always be locked to 80 fps for the ai
	 */
	public static function GeneratePlayMap(map:Song.SwagSong, rules:AI_Rulesets):Array<Array<Float>>
	{
		var perlin:Perlin = new Perlin();

		var AI_FPS:Float = 1 / 80;
		var Section_Humidity:Array<Float> = [];
		var Lerping_Humidity:Float;

		var strumList:Array<Array<Float>> = [];

		for (section in map.notes)
		{
			// > 4.0 is the limit, and we can go beyond
			var countedNotes:Int = 0;

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = section.mustHitSection;

				if (note[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				if (!gottaHitNote)
					countedNotes++;
			}

			strumList[map.notes.indexOf(section)] = [];

			Section_Humidity[map.notes.indexOf(section)] = FlxMath.remapToRange(countedNotes, 0, section.lengthInSteps * rules.Humidity_Magnitude, -2.5, 4.0);
		}

		Lerping_Humidity = rules.Best_Humidity;

		for (section in map.notes)
		{
			Lerping_Humidity = FlxMath.lerp(Lerping_Humidity, Section_Humidity[map.notes.indexOf(section)],
				CoolUtil.boundTo(((Conductor.stepCrochet / 1000) * AI_FPS) * 10.25, 0, 1));

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = section.mustHitSection;

				if (note[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				if (!gottaHitNote)
				{
					var decreasePenalty:Float = 0.0;
					if (Lerping_Humidity > 4.0)
						decreasePenalty += Lerping_Humidity - 4.0 * 0.777;

					if (Math.abs(Lerping_Humidity - Section_Humidity[map.notes.indexOf(section)]) > Math.abs(Lerping_Humidity - 4.0))
					{
						decreasePenalty -= Math.abs(Lerping_Humidity - Section_Humidity[map.notes.indexOf(section)]) * 0.1116;
						decreasePenalty += (Math.abs(Lerping_Humidity - 4.0) * 0.43) / 2.33;
					}
					else
					{
						decreasePenalty += Math.abs(Lerping_Humidity - Section_Humidity[map.notes.indexOf(section)]) * 0.43;
					}

					strumList[map.notes.indexOf(section)][section.sectionNotes.indexOf(note)] = FlxMath.roundDecimal((perlin.noise2d(note[0] / Conductor.stepCrochet,
						(note[0] / Conductor.stepCrochet) * -1)) * decreasePenalty, 6);
					trace(Std.string(strumList[map.notes.indexOf(section)][section.sectionNotes.indexOf(note)])
						+ ' ms'
						+ ' penalty: ${decreasePenalty}'
						+ ' lerping humidity: ${Lerping_Humidity}');
				}
			}
		}

		return strumList;
	}
}

typedef AI_Rulesets =
{
	var Humidity_Magnitude:Float;
	var Best_Humidity:Float;
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

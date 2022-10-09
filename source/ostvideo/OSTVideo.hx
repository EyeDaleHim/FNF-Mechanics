package ostvideo;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

// for the source geeks, i will not be fixing the errors here
class OSTVideo extends MusicBeatState
{
	public var bg:FlxSprite;
	public var logo:FlxSprite;

	public var barsList:Array<FlxSprite> = [];

	private var _amplitudeList:Array<Null<Float>> = [];

	public var _vocals:FlxSound;

	override function create()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('ost/bg', 'shared'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		for (i in 0...32)
		{
			var barSprite:FlxSprite = new FlxSprite(2 + (34 * i), FlxG.height - 20).makeGraphic(32, 30);
			add(barSprite);
			barsList.push(barSprite);
		}

		for (spr in barsList)
		{
			spr.screenCenter(X);
			spr.x += (34 * (barsList.indexOf(spr) - (barsList.length / 2))) + 2;
		}

		logo = new FlxSprite();
		logo.frames = Paths.getSparrowAtlas('logoBumpin');
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		logo.animation.addByIndices('bump', 'logo bumpin', [0], '', 0, false);
		logo.animation.play('bump');
		logo.scale.set(0.8, 0.8);
		logo.updateHitbox();
		logo.screenCenter();
		add(logo);

		_vocals = new FlxSound();
		_vocals.loadEmbedded(Paths.voices('comedown'), true, false, function()
		{
			_runLoop = !_runLoop;
			savedSteps = cast steps;
			trace(savedSteps);
		});

		FlxG.sound.list.add(_vocals);

		new FlxTimer().start(5, function(tmr:FlxTimer)
		{
			FlxG.sound.playMusic(Paths.inst('comedown'), true);
			_vocals.play();

			Conductor.changeBPM(180);
		});

		for (i in 0...ampMult.length)
		{
			if (ampMult[i] != null)
				ampMult[i] *= 1.5;
		}

		FlxG.mouse.visible = false;
		Main.fpsVar.fps.visible = false;
	}

	private var stepLogo:Int = 8;
	private var _runLoop:Bool = true;
	private var steps:Array<{position:Float, step:Int}> = [
		{position: 10659, step: 1},
		{position: 42717, step: 2},
		{position: 45297, step: 1},
		{position: 47957, step: 2},
		{position: 50657, step: 1},
		{position: 53317, step: 2},
		{position: 95994, step: 1},
		{position: 114593, step: 2},
		{position: 115853, step: 9999},
		{position: 117273, step: 1},
		{position: 146692, step: 2},
		{position: 149352, step: 4},
		{position: 154691, step: 8},
		{position: 164151, step: 9999}
	];

	/*(slocal
		amplitude = getPropertyFromClass("flixel.FlxG", "sound.music.amplitude") / 1.4 + getProperty("vocals.amplitude")
		amplitudeAvg = amplitudeAvg - ((amplitudeAvg + .1) * (elapsed * 6))
		if (amplitude > amplitudeAvg)
			then
		amplitudeAvg = amplitude
		end
		gameZoom
		, hudZoom = (amplitudeAvg / 7.5) - .1, (amplitudeAvg / 4) - .1 cgProperty("camGame.zoom",
		gameZoom) cgProperty("camHUD.zoom", hudZoom) */
	private static var savedSteps:Array<
		{
			position:Float,
			step:Int
		}> = [];

	private var ampMult:Array<Null<Float>> = [
		0.34, 0.38, 0.44, 0.52, 0.62, 0.74, 0.88, 0.96, 1.16, 1.36, 1.54, 1.44, 1.32, 1.24, 1.12, 1.04, 0.98, 0.92, 0.84, 0.72, 0.64, 0.56, 0.44, 0.32, 0.36,
		0.46, 0.58, 0.76, 1.08, 1.24, 1.44
	];

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.watch.addQuick('curBeat', curBeat);
		FlxG.watch.addQuick('curStep', curStep);
		FlxG.watch.addQuick('songPos', Conductor.songPosition);

		for (i in 0...barsList.length)
		{
			if (_amplitudeList[i] == null)
			{
				_amplitudeList[i] = ((FlxG.sound.music.amplitudeLeft * i) / barsList.length)
					+ ((FlxG.sound.music.amplitudeRight * (barsList.length - i)) / barsList.length);
				_amplitudeList[i] /= 1.4;
				_amplitudeList[i] += ((_vocals.amplitudeLeft * i) / barsList.length) + ((_vocals.amplitudeRight * (barsList.length - i)) / barsList.length);
			}
			else
			{
				var calculatedAmp:Float = 0.0;
				calculatedAmp = ((FlxG.sound.music.amplitudeLeft * i) / barsList.length)
					+ ((FlxG.sound.music.amplitudeRight * (barsList.length - i)) / barsList.length);
				calculatedAmp /= 1.4;
				calculatedAmp += ((_vocals.amplitudeLeft * i) / barsList.length) + ((_vocals.amplitudeRight * (barsList.length - i)) / barsList.length);

				if (calculatedAmp > _amplitudeList[i])
					_amplitudeList[i] = calculatedAmp;

				_amplitudeList[i] -= _amplitudeList[i] * (elapsed * 6);

				var ampMultiThing:Float = 1.0;

				if (ampMult[i] != null)
					ampMultiThing = ampMult[i];

				barsList[i].scale.y = 1 + (_amplitudeList[i] * (10.75 / 2) * ampMultiThing);
			}
		}

		if (FlxG.keys.justPressed.ONE)
		{
			stepLogo = 1;
			steps.push({position: Conductor.songPosition, step: stepLogo});
			trace(Conductor.songPosition);
		}
		else if (FlxG.keys.justPressed.TWO)
		{
			stepLogo = 2;
			steps.push({position: Conductor.songPosition, step: stepLogo});
			trace(Conductor.songPosition);
		}
		else if (FlxG.keys.justPressed.THREE)
		{
			stepLogo = 4;
			steps.push({position: Conductor.songPosition, step: stepLogo});
			trace(Conductor.songPosition);
		}
		else if (FlxG.keys.justPressed.FOUR)
		{
			stepLogo = 8;
			steps.push({position: Conductor.songPosition, step: stepLogo});
			trace(Conductor.songPosition);
		}
		else if (FlxG.keys.justPressed.FIVE)
		{
			stepLogo = 9999;
			steps.push({position: Conductor.songPosition, step: stepLogo});
			trace(Conductor.songPosition);
		}

		if (_runLoop)
		{
			if (steps.length > 0)
			{
				if (Conductor.songPosition > steps[0].position)
				{
					var stepThing = steps.shift();

					stepLogo = stepThing.step;
					trace('es');
				}
			}
		}

		logo.scale.set(FlxMath.lerp(logo.scale.x, 0.8, CoolUtil.boundTo(elapsed * 4.85, 0, 1)),
			FlxMath.lerp(logo.scale.y, 0.8, CoolUtil.boundTo(elapsed * 4.85, 0, 1)));
		logo.updateHitbox();
		logo.screenCenter();

		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
			if (_vocals != null)
			{
				if (Math.abs(Conductor.songPosition - _vocals.time) > 20)
					_vocals.time = FlxG.sound.music.time;
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % stepLogo == 0)
		{
			logo.scale.set(0.875, 0.875);
			logo.updateHitbox();
			logo.screenCenter();
		}
	}
}

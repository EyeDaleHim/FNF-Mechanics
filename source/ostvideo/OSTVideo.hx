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

	public var _vocals:FlxSound;

	override function create()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('ost/bg', 'shared'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

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
		_vocals.loadEmbedded(Paths.voices('comedown'), true);

		new FlxTimer().start(5, function(tmr:FlxTimer)
		{
			FlxG.sound.playMusic(Paths.inst('comedown'), true);
			_vocals.play();
		});
	}

	private var stepLogo:Int = 8;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ONE)
			stepLogo = 2;
		else if (FlxG.keys.justPressed.TWO)
			stepLogo = 4;
		else if (FlxG.keys.justPressed.THREE)
			stepLogo = 8;
		else if (FlxG.keys.justPressed.FOUR)
			stepLogo = 16;
		else if (FlxG.keys.justPressed.FIVE)
			stepLogo = 9999;

		logo.scale.set(FlxMath.lerp(logo.scale.x, 0.8, CoolUtil.boundTo(elapsed * 4.85, 0, 1)),
			FlxMath.lerp(logo.scale.y, 0.8, CoolUtil.boundTo(elapsed * 4.85, 0, 1)));
		logo.updateHitbox();
		logo.screenCenter();

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	}

	override function stepHit()
	{
		super.stepHit();

		if (curStep % stepLogo == 0)
		{
			logo.scale.set(1, 1);
			logo.updateHitbox();
			logo.screenCenter();
		}
	}
}

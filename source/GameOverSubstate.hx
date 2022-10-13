package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	public static final tankmanSubtitles:Array<String> = [
		'I said "Let\'s rock!" Not "Suck cock!" Wha-',
		'Oh my god! What the hell was that? What the hell was that.',
		'I guess your shitty blue hair dye got in your eyes! It\'s okay!\nIt happens to all of us.',
		'Maybe you should go play Week 1 again! Hehehe!',
		'Can you even feed yourself? Can you even walk straight?',
		'Maybe if you had more friends, you\'d be less depressed and play better. Hm?',
		'Man, are you tired of eating shit yet?\nHahaha.',
		'Yeah, you\'re getting closer. I wouldn\'t\nbrag about it though.',
		'No wonder your parents hate you.\nHahaha.',
		'If you can\'t beat me, how are you gonna survive\nthis harsh cruel world. Hm?',
		'The only thing funkin\' tonight is your sock!',
		'Why am I wasting my time against some baggy pants FUCK? Hahaha.',
		'Why am I wasting my time against some baggy pants PUNK?!',
		'Hey here\'s some \"Friday Night Funkin\" lore for ya!\nI don\'t like you!',
		'You just make me wanna cry...',
		'You know, I\'m running out of shit to say here, so you better beat this\nsometime today asshole!',
		'Congratulations, you won!\nThat\'s what I would say if you weren\'t such a goddamn failure!',
		'You gotta press the arrows kid! Not slap your keyboard like your whine uncle. \nWhat?',
		'You feel that? That\'s called failure, and you better get used to it.',
		'Open your fucking eyes, Jeez!',
		'I hope you\'re not some internet streamer streaming like a sociopath right now.',
		'That waaas terrible...\nJust terrible...',
		'My DEAD grandmother has more nimble fingers, Come on!',
		'Good lord! What the hell is your problem man?\n*burp* Just do it right, pleease!'
	];

	public var hudCamera:FlxCamera;

	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;
	public var damageText:FlxText;
	public var titleText:FlxText;
	public var infoText:FlxText;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public var resultText:FlxText;

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		hudCamera = new FlxCamera();
		hudCamera.bgColor.alpha = 0;
		FlxG.cameras.add(hudCamera, false);

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.cameras = [PlayState.instance.camGame];
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		leftArrow = new FlxSprite();
		leftArrow.loadGraphic(Paths.image('mechanicArr', 'shared'));
		leftArrow.scale.set(1.3, 1.3);
		leftArrow.setPosition(920, 510);
		leftArrow.antialiasing = true;
		leftArrow.scrollFactor.set();
		leftArrow.updateHitbox();
		leftArrow.alpha = 0.0;
		leftArrow.cameras = [hudCamera];
		add(leftArrow);

		rightArrow = new FlxSprite();
		rightArrow.loadGraphic(Paths.image('mechanicArr', 'shared'));
		rightArrow.scale.set(1.3, 1.3);
		rightArrow.setPosition(1200, 510);
		rightArrow.antialiasing = true;
		rightArrow.scrollFactor.set();
		rightArrow.updateHitbox();
		rightArrow.flipX = true;
		rightArrow.alpha = 0.0;
		rightArrow.cameras = [hudCamera];
		add(rightArrow);

		var firstResult:PlayState.MechanicResults = {name: '', text: '', value: 0};
		if (PlayState.instance.mechanicsResult.length > 0)
		{
			var firstAvailable:Int = 0;
			do
			{
				firstAvailable = FlxMath.wrap(firstAvailable + 1, 0, PlayState.instance.mechanicsResult.length - 1);
			}
			while (PlayState.instance.mechanicsResult[firstAvailable] == null);

			firstResult = PlayState.instance.mechanicsResult[firstAvailable];
		}

		titleText = new FlxText(0, 0, 0, firstResult.name, 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 1.75;
		titleText.antialiasing = true;
		titleText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (titleText.width / 2), 460);
		titleText.alpha = 0.0;
		titleText.cameras = [hudCamera];
		add(titleText);

		damageText = new FlxText(0, 0, 0, CoolUtil.flattenNumber(firstResult.value), 56);
		damageText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		damageText.borderSize = 1.75;
		damageText.antialiasing = true;
		damageText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (damageText.width / 2), leftArrow.y);
		damageText.alpha = 0.0;
		damageText.cameras = [hudCamera];
		add(damageText);

		infoText = new FlxText(0, 0, 0, firstResult.text, 24);
		infoText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 1.75;
		infoText.antialiasing = true;
		infoText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (infoText.width / 2), leftArrow.y + leftArrow.height + 12);
		infoText.alpha = 0.0;
		infoText.cameras = [hudCamera];
		add(infoText);

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	var isFollowingAlready:Bool = false;
	var isOnLoop:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			if (!isOnLoop)
				skipBullshit();
			else
				endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				skipBullshit();
			}
		}

		if (isOnLoop)
		{
			if (controls.UI_LEFT_P)
				changeSelection(-1);
			else if (controls.UI_RIGHT_P)
				changeSelection(1);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.log.add('beat');
	}

	private var curSelected:Int = 0;

	public function changeSelection(select:Int = 0)
	{
		if (PlayState.instance.mechanicsResult.length > 1)
		{
			do
			{
				curSelected = FlxMath.wrap(curSelected + select, 0, PlayState.instance.mechanicsResult.length - 1);
			}
			while (PlayState.instance.mechanicsResult[curSelected] == null);

			titleText.text = PlayState.instance.mechanicsResult[curSelected].name;
			damageText.text = CoolUtil.flattenNumber(FlxMath.roundDecimal(PlayState.instance.mechanicsResult[curSelected].value, 2));
			infoText.text = PlayState.instance.mechanicsResult[curSelected].text;

			titleText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (titleText.width / 2), 460);
			damageText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (damageText.width / 2), leftArrow.y);
			infoText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (infoText.width / 2), leftArrow.y + leftArrow.height + 12);

			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}
	}

	var isEnding:Bool = false;

	private function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume * ClientPrefs.musicVolume / 10);
	}

	private function skipBullshit():Void
	{
		if (PlayState.SONG.stage == 'tank')
		{
			playingDeathSound = true;
			coolStartDeath(0.2);

			var exclude:Array<Int> = [];
			// if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

			var random:Int = FlxG.random.int(1, 25, exclude);

			var tankSound = FlxG.sound.load(Paths.sound('jeffGameover/jeffGameover-' + random, 'week7'), 1, false, null, true, false, null, function()
			{
				if (!isEnding)
				{
					FlxG.sound.music.fadeIn(0.5, FlxG.sound.music.volume, ClientPrefs.musicVolume / 8);
				}
			});

			tankSound.play(false);

			SubtitleHandler.addSub(tankmanSubtitles[random + 1], (tankSound.length / 1000) + 1.5);
		}
		else
		{
			coolStartDeath();
		}

		if (PlayState.instance.mechanicsResult.length > 0)
		{
			FlxTween.num(0, 1, 0.5, {ease: FlxEase.quadOut}, function(v:Float)
			{
				leftArrow.alpha = rightArrow.alpha = titleText.alpha = damageText.alpha = infoText.alpha = v;
			});
		}

		boyfriend.playAnim('deathLoop', true);

		isOnLoop = true;
		boyfriend.startedDeath = true;
	}

	private function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));

			if (PlayState.instance.mechanicsResult.length > 0)
			{
				FlxTween.num(1, 0, 0.5, {ease: FlxEase.quadOut}, function(v:Float)
				{
					leftArrow.alpha = rightArrow.alpha = titleText.alpha = damageText.alpha = infoText.alpha = v;
				});
			}

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					if (PlayState.isStoryMode && ClientPrefs.getGameplaySetting('permaDeath', false))
					{
						trace(PlayState.storyPlaylist);
						PlayState.storyPlaylist = PlayState.fullStoryPlaylist;
						trace(PlayState.fullStoryPlaylist);

						PlayState.firstSong = true;

						PlayState.SONG = Song.loadFromJson(PlayState.fullStoryPlaylist[0] + '-' + CoolUtil.difficulties[PlayState.storyDifficulty],
							PlayState.fullStoryPlaylist[0]);
						PlayState.campaignScore = 0;
						PlayState.campaignMisses = 0;
					}

					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}

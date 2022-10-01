package;

import flixel.FlxG;
import flixel.FlxObject;
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

	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

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

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	var isFollowingAlready:Bool = false;

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

					SubtitleHandler.addSub(tankmanSubtitles[random - 1], (tankSound.length / 1000) + 2.5);
				}
				else
				{
					coolStartDeath();
				}
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);

		for (sub in SubtitleHandler.subtitleList)
		{
			if (sub != null)
			{
				sub.subBG.draw();
				sub.subText.draw();

				sub.update(elapsed);
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume * ClientPrefs.musicVolume / 10);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					if (ClientPrefs.getGameplaySetting('permaDeath', false))
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

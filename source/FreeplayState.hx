package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	static var songs:Array<SongMetadata> = [];
	public static var cachedEvents:Map<String, Dynamic> = [];

	var selector:FlxText;

	public static var curBPM:Float = 100;
	private static var curSelected:Int = 0;

	var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var gradientSprite:FlxSprite;

	public static var cameraShader:ColorSwap = new ColorSwap();

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (songs.length == 0)
		{
			for (i in 0...WeekData.weeksList.length)
			{
				if (weekIsLocked(WeekData.weeksList[i]))
					continue;

				var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
				var leSongs:Array<String> = [];
				var leChars:Array<String> = [];

				for (j in 0...leWeek.songs.length)
				{
					leSongs.push(leWeek.songs[j][0]);
					leChars.push(leWeek.songs[j][1]);
				}

				WeekData.setDirectoryFromWeek(leWeek);
				for (song in leWeek.songs)
				{
					var colors:Array<Int> = song[2];
					if (colors == null || colors.length < 3)
					{
						colors = [146, 113, 253];
					}
					addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				}
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

			var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
			for (i in 0...initSonglist.length)
			{
				if(initSonglist[i] != null && initSonglist[i].length > 0) {
					var songArray:Array<String> = initSonglist[i].split(":");
					addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
				}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		gradientSprite = FlxGradient.createGradientFlxSprite(Math.floor(bg.width), Math.floor(bg.height / 1.5), [FlxColor.WHITE, FlxColor.TRANSPARENT], 1,
			270);
		gradientSprite.antialiasing = ClientPrefs.globalAntialiasing;
		gradientSprite.scrollFactor.set();
		gradientSprite.y = FlxG.height - gradientSprite.height;
		gradientSprite.scale.y = 0;
		gradientSprite.updateHitbox();
		gradientSprite.screenCenter();
		add(gradientSprite);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
				// songText.updateHitbox();
				// trace(songs[i].songName + ' new scale: ' + textScale);
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var filter = new ShaderFilter(cameraShader.shader);

		FlxG.camera.setFilters([filter]);

		var formattedInput:Array<Array<Int>> = 
		[
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('accept')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('reset')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('interact'))
		];
		formattedInput[0].remove(formattedInput[0][1]);
		#if PRELOAD_ALL
		var leText:String = '[${InputFormatter.keyListAsString(formattedInput[0])}] Listen Song | [${InputFormatter.keyListAsString(formattedInput[2])}] Gameplay Changers Menu | [${InputFormatter.keyListAsString(formattedInput[1])}] Reset Progress on Song';
		var size:Int = 16;
		#else
		var leText:String = '[${InputFormatter.keyListAsString(formattedInput[2])}] Gameplay Changers Menu / [${InputFormatter.keyListAsString(formattedInput[1])}] Reset Progress on Song';
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		super.create();

		if (events != null && events.length > 0)
		{
			if (events[nextEventIndex] != null)
			{
				while (Conductor.songPosition > events[nextEventIndex].position)
				{
					nextEventIndex++;
				}
			}
		}
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
		{
			if (songCharacters == null)
				songCharacters = ['bf'];

			var num:Int = 0;
			for (song in songs)
			{
				addSong(song, weekNum, songCharacters[num]);
				this.songs[this.songs.length-1].color = weekColor;

				if (songCharacters.length != 1)
					num++;
			}
	}*/
	public static var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		scoreText.text = 'PERSONAL BEST: '
			+ FlxStringUtil.formatMoney(lerpScore, false)
			+ ' ('
			+ CoolUtil.formatAccuracy(Highscore.floorDecimal(lerpRating * 100, 2))
			+ '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftMult = 3;

		if (songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP)
			changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('interact'))))
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (space)
		{
			if (instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				events = [];
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var name:String = songs[curSelected].songName.toLowerCase();
				var poop:String = Highscore.formatSong(name, curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, name);
				Conductor.mapBPMChanges(PlayState.SONG);
				Conductor.changeBPM(curBPM = PlayState.SONG.bpm);

				camBeat = 1;
				cameraShader.saturation = 0.0;

				var exists:Bool = false;
				#if sys
				exists = (FileSystem.exists(Paths.modsJson(name + '/events')) || FileSystem.exists(Paths.json(name + '/events')));
				#else
				exists = OpenFlAssets.exists(Paths.json(name + '/events'));
				#end
				nextEventIndex = 0;
				if (exists)
				{
					var eventsData:Array<Dynamic> = Song.loadFromJson('events', name).events;
					for (event in eventsData) // Event Notes
					{
						for (i in 0...event[1].length)
						{
							var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
							var subEvent = {
								position: newEventNote[0],
								event: newEventNote[1],
								value1: newEventNote[2],
								value2: newEventNote[3]
							};
							events.push(subEvent);
						}
					}
				}

				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				FlxG.sound.music.onComplete = function()
				{
					nextEventIndex = 0;
				}
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;

				gradientSprite.color = CoolUtil.dominantColor(iconArray[curSelected], [FlxColor.WHITE]);
				#end
			}
		}
		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
				if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
				#else
				if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
				#end
					poop = songLowercase;
					curDifficulty = 1;
					trace('Couldnt find file');
			}*/
			trace(poop);

			camBeat = 1;

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if (colorTween != null)
			{
				colorTween.cancel();
			}

			events = [];

			if (FlxG.keys.pressed.SHIFT)
			{
				LoadingState.loadAndSwitchState(new ChartingState());
			}
			else
			{
				LoadingState.loadAndSwitchState(new PlayState());
			}

			FlxG.sound.music.volume = 0;

			destroyFreeplayVocals();
		}
		else if (controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		if (events[nextEventIndex] != null)
		{
			if (Conductor.songPosition >= events[nextEventIndex].position)
			{
				triggerEvent(events[nextEventIndex]);
				nextEventIndex++;
			}
		}

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, CoolUtil.boundTo(elapsed * 4 * (curBPM / 100), 0, 1));

		scaleLerp = FlxMath.lerp(scaleLerp, 0, CoolUtil.boundTo(elapsed * 4.85 * (curBPM / 100), 0, 1));
		gradientSprite.scale.y = scaleLerp;
		if (gradientSprite.scale.y < 0)
			gradientSprite.scale.y = 0;
		gradientSprite.updateHitbox();
		gradientSprite.y = FlxG.height - gradientSprite.height;
	}

	public var scaleLerp:Float = 0;

	public static var events:Array<
		{
			event:String,
			position:Float,
			value1:String,
			value2:String
		}> = [];
	public static var nextEventIndex:Int = 0;

	override public function beatHit():Void
	{
		super.beatHit();

		if (vocals != null)
		{
			if (PlayState.SONG.notes[Math.floor(curStep / 16)] != null)
			{
				if (PlayState.SONG.notes[Math.floor(curStep / 16)].changeBPM)
				{
					Conductor.changeBPM(PlayState.SONG.notes[Math.floor(curStep / 16)].bpm);
					curBPM = PlayState.SONG.notes[Math.floor(curStep / 16)].bpm;
				}
			}

			if (curBeat % camBeat == 0)
				FlxG.camera.zoom += 0.015;
		}
	}

	override function destroy():Void
	{
		camBeat = 1;
		FlxG.camera.setFilters([]);
		super.destroy();
	}

	static private var camBeat:Int = 1;

	override public function stepHit():Void
	{
		super.stepHit();
	}

	private var listedEvents:Array<String> = [];

	public function triggerEvent(event:
		{
			event:String,
			position:Float,
			value1:String,
			value2:String
		})
	{
		switch (event.event)
		{
			case 'Add Camera Zoom':
				{
					scaleLerp = 1;
					gradientSprite.scale.y = 1;
					gradientSprite.updateHitbox();
					gradientSprite.y = FlxG.height - gradientSprite.height;
				}
			case 'Freeplay Beat Speed' | 'Set GF Speed':
				{
					if (event.event == 'Set GF Speed') 
					// prob big issue is that if you add this event before freeplay beat speed, it'll still be added regardless
					{
						if (listedEvents.contains('Freeplay Beat Speed'))
							return;
					}
					if (Math.isNaN(Std.parseInt(event.value1)))
						event.value1 = '1';

					camBeat = Std.parseInt(event.value1);
				}
			case 'Freeplay Shader':
				{
					if (Math.isNaN(Std.parseFloat(event.value1)))
						event.value1 = '0.0';
					if (Math.isNaN(Std.parseFloat(event.value2)))
						event.value2 = '0.0';

					if (Std.parseFloat(event.value2) <= 0)
					{
						cameraShader.saturation = Std.parseFloat(event.value1);
					}
					else
					{
						FlxTween.tween(cameraShader, {saturation: Std.parseFloat(event.value1)}, Std.parseFloat(event.value2), {ease: FlxEase.quadOut});
					}
				}
		}

		if (listedEvents.indexOf(event.event) == -1) // if it doesn't exist, then push it! lol
			listedEvents.push(event.event);
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if (diffStr != null)
			diffStr = diffStr.trim(); // Fuck you HTML5

		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1)
						diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}

		if (CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var bpm:Float = -1;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if (this.folder == null)
			this.folder = '';
	}
}

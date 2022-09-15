package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs
{
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var timeHit:Bool = false;
	public static var showFPS:Bool = true;
	public static var performanceCounter:String = 'fps-mem-peak';
	public static var musicSync:Bool = false;
	public static var autoPause:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var pauseSecond:Float = 1.2;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var channel:String = 'Stereo';
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var imagesPersist:String = 'None';
	public static var chartCache:String = 'None';
	public static var debugMode:Bool = #if debug true #else false #end;
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var musicVolume:Int = 8;
	public static var vocalVolume:Int = 10;
	public static var safeScript:String = 'Off';
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'sickonly' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false,
		'duetMode' => false,
		'enemyMode' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	// -4 = LMOUSE, -5 = RMOUSE
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'interact' => [CONTROL, ALT],
		'dodge' => [SPACE, NONE],
		'select-rps' => [R, NONE],
		'choose-rps' => [T, NONE],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		// trace(defaultKeys);
	}

	public static var defaultSave:FlxSave = new FlxSave();

	public static function saveSettings()
	{
		defaultSave.bind('fnfmechanics-settings', 'eyedalehim');

		defaultSave.data.downScroll = downScroll;
		defaultSave.data.middleScroll = middleScroll;
		defaultSave.data.showFPS = showFPS;
		defaultSave.data.performanceCounter = performanceCounter;
		defaultSave.data.timeHit = timeHit;
		defaultSave.data.flashing = flashing;
		defaultSave.data.globalAntialiasing = globalAntialiasing;
		defaultSave.data.noteSplashes = noteSplashes;
		defaultSave.data.lowQuality = lowQuality;
		defaultSave.data.framerate = framerate;
		// defaultSave.data.cursing = cursing;
		// defaultSave.data.violence = violence;
		defaultSave.data.camZooms = camZooms;
		defaultSave.data.noteOffset = noteOffset;
		defaultSave.data.hideHud = hideHud;
		defaultSave.data.arrowHSV = arrowHSV;
		defaultSave.data.imagesPersist = imagesPersist;
		defaultSave.data.chartCache = chartCache;
		defaultSave.data.debugMode = debugMode;
		defaultSave.data.musicSync = musicSync;
		defaultSave.data.autoPause = autoPause;
		defaultSave.data.ghostTapping = ghostTapping;
		defaultSave.data.timeBarType = timeBarType;
		defaultSave.data.scoreZoom = scoreZoom;
		defaultSave.data.pauseSecond = pauseSecond;
		defaultSave.data.noReset = noReset;
		defaultSave.data.healthBarAlpha = healthBarAlpha;
		defaultSave.data.comboOffset = comboOffset;
		defaultSave.data.safeScript = safeScript;
		defaultSave.data.channel = channel;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		defaultSave.data.ratingOffset = ratingOffset;
		defaultSave.data.sickWindow = sickWindow;
		defaultSave.data.goodWindow = goodWindow;
		defaultSave.data.badWindow = badWindow;
		defaultSave.data.safeFrames = safeFrames;
		defaultSave.data.gameplaySettings = gameplaySettings;
		defaultSave.data.controllerMode = controllerMode;
		defaultSave.data.hitsoundVolume = hitsoundVolume;
		defaultSave.data.pauseMusic = pauseMusic;

		defaultSave.data.volume = FlxG.sound.volume;
		defaultSave.data.muted = FlxG.sound.muted;

		defaultSave.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		defaultSave.bind('fnfmechanics-settings', 'eyedalehim');

		var lastTime = openfl.Lib.getTimer();
		if (defaultSave.data.firstTime == null)
		{
			defaultSave.data.downScroll = FlxG.save.data.downScroll;
			defaultSave.data.middleScroll = FlxG.save.data.middleScroll;
			defaultSave.data.showFPS = FlxG.save.data.showFPS;
			defaultSave.data.flashing = FlxG.save.data.flashing;
			defaultSave.data.globalAntialiasing = FlxG.save.data.globalAntialiasing;
			defaultSave.data.noteSplashes = FlxG.save.data.noteSplashes;
			defaultSave.data.lowQuality = FlxG.save.data.lowQuality;
			defaultSave.data.framerate = FlxG.save.data.framerate;
			// defaultSave.data.cursing = FlxG.save.data.cursing;
			// defaultSave.data.violence = FlxG.save.data.violence;
			defaultSave.data.camZooms = FlxG.save.data.camZooms;
			defaultSave.data.noteOffset = FlxG.save.data.noteOffset;
			defaultSave.data.hideHud = FlxG.save.data.hideHud;
			defaultSave.data.arrowHSV = FlxG.save.data.arrowHSV;
			defaultSave.data.imagesPersist = FlxG.save.data.imagesPersist;
			if (Std.isOfType(FlxG.save.data.imagesPersist, Bool))
				defaultSave.data.imagesPersist = 'None';
			defaultSave.data.chartCache = FlxG.save.data.chartCache;
			defaultSave.data.debugMode = FlxG.save.data.debugMode;
			defaultSave.data.ghostTapping = FlxG.save.data.ghostTapping;
			defaultSave.data.timeBarType = FlxG.save.data.timeBarType;
			defaultSave.data.scoreZoom = FlxG.save.data.scoreZoom;
			defaultSave.data.noReset = FlxG.save.data.noReset;
			defaultSave.data.healthBarAlpha = FlxG.save.data.healthBarAlpha;
			defaultSave.data.comboOffset = FlxG.save.data.comboOffset;

			defaultSave.data.ratingOffset = FlxG.save.data.ratingOffset;
			defaultSave.data.sickWindow = FlxG.save.data.sickWindow;
			defaultSave.data.goodWindow = FlxG.save.data.goodWindow;
			defaultSave.data.badWindow = FlxG.save.data.badWindow;
			defaultSave.data.safeFrames = FlxG.save.data.safeFrames;
			defaultSave.data.gameplaySettings = FlxG.save.data.gameplaySettings;
			defaultSave.data.controllerMode = FlxG.save.data.controllerMode;
			defaultSave.data.hitsoundVolume = FlxG.save.data.hitsoundVolume;
			defaultSave.data.pauseMusic = FlxG.save.data.pauseMusic;
			defaultSave.data.firstTime = -1;
			trace('finished transferring data in ${openfl.Lib.getTimer() - lastTime}ms');
			return loadPrefs();
		}

		if (defaultSave.data.downScroll != null)
		{
			downScroll = defaultSave.data.downScroll;
		}
		if (defaultSave.data.middleScroll != null)
		{
			middleScroll = defaultSave.data.middleScroll;
		}
		if (defaultSave.data.timeHit != null)
		{
			timeHit = defaultSave.data.timeHit;
		}
		if (defaultSave.data.showFPS != null)
		{
			showFPS = defaultSave.data.showFPS;
			if (Main.fpsVar != null)
			{
				Main.fpsVar.visible = showFPS;
			}
		}
		if (defaultSave.data.performanceCounter != null)
		{
			performanceCounter = defaultSave.data.performanceCounter;
		}
		if (defaultSave.data.flashing != null)
		{
			flashing = defaultSave.data.flashing;
		}
		if (defaultSave.data.globalAntialiasing != null)
		{
			globalAntialiasing = defaultSave.data.globalAntialiasing;
		}
		if (defaultSave.data.noteSplashes != null)
		{
			noteSplashes = defaultSave.data.noteSplashes;
		}
		if (defaultSave.data.lowQuality != null)
		{
			lowQuality = defaultSave.data.lowQuality;
		}
		if (defaultSave.data.pauseSecond != null)
		{
			pauseSecond = defaultSave.data.pauseSecond;
		}
		if (defaultSave.data.framerate != null)
		{
			framerate = defaultSave.data.framerate;
			if (framerate > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			}
			else
			{
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		/*if(defaultSave.data.cursing != null) {
				cursing = defaultSave.data.cursing;
			}
			if(defaultSave.data.violence != null) {
				violence = defaultSave.data.violence;
		}*/
		if (defaultSave.data.channel != null)
		{
			channel = defaultSave.data.channel;
		}
		if (defaultSave.data.musicSync != null)
		{
			musicSync = defaultSave.data.musicSync;
		}
		if (defaultSave.data.autoPause != null)
		{
			FlxG.autoPause = autoPause = defaultSave.data.autoPause;
		}
		if (defaultSave.data.imagesPersist != null)
		{
			imagesPersist = defaultSave.data.imagesPersist;
		}
		if (defaultSave.data.chartCache != null)
		{
			chartCache = defaultSave.data.chartCache;
		}
		if (defaultSave.data.debugMode != null)
		{
			debugMode = defaultSave.data.debugMode;
		}
		if (defaultSave.data.camZooms != null)
		{
			camZooms = defaultSave.data.camZooms;
		}
		if (defaultSave.data.hideHud != null)
		{
			hideHud = defaultSave.data.hideHud;
		}
		if (defaultSave.data.noteOffset != null)
		{
			noteOffset = defaultSave.data.noteOffset;
		}
		if (defaultSave.data.arrowHSV != null)
		{
			arrowHSV = defaultSave.data.arrowHSV;
		}
		if (defaultSave.data.ghostTapping != null)
		{
			ghostTapping = defaultSave.data.ghostTapping;
		}
		if (defaultSave.data.timeBarType != null)
		{
			timeBarType = defaultSave.data.timeBarType;
		}
		if (defaultSave.data.scoreZoom != null)
		{
			scoreZoom = defaultSave.data.scoreZoom;
		}
		if (defaultSave.data.noReset != null)
		{
			noReset = defaultSave.data.noReset;
		}
		if (defaultSave.data.healthBarAlpha != null)
		{
			healthBarAlpha = defaultSave.data.healthBarAlpha;
		}
		if (defaultSave.data.comboOffset != null)
		{
			comboOffset = defaultSave.data.comboOffset;
		}
		if (defaultSave.data.safeScript != null)
		{
			safeScript = defaultSave.data.safeScript;
		}
		if (defaultSave.data.ratingOffset != null)
		{
			ratingOffset = defaultSave.data.ratingOffset;
		}
		if (defaultSave.data.sickWindow != null)
		{
			sickWindow = defaultSave.data.sickWindow;
		}
		if (defaultSave.data.goodWindow != null)
		{
			goodWindow = defaultSave.data.goodWindow;
		}
		if (defaultSave.data.badWindow != null)
		{
			badWindow = defaultSave.data.badWindow;
		}
		if (defaultSave.data.safeFrames != null)
		{
			safeFrames = defaultSave.data.safeFrames;
		}
		if (defaultSave.data.controllerMode != null)
		{
			controllerMode = defaultSave.data.controllerMode;
		}
		if (defaultSave.data.hitsoundVolume != null)
		{
			hitsoundVolume = defaultSave.data.hitsoundVolume;
		}
		if (defaultSave.data.pauseMusic != null)
		{
			pauseMusic = defaultSave.data.pauseMusic;
		}
		if (defaultSave.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = defaultSave.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if (defaultSave.data.volume != null)
		{
			FlxG.sound.volume = defaultSave.data.volume;
		}
		if (defaultSave.data.muted != null)
		{
			FlxG.sound.muted = defaultSave.data.muted;
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if (save != null && save.data.customControls != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls)
			{
				keyBinds.set(control, keys);
			}
			reloadControls();
		}

		return null;
	}

	public static function resetSettings():Void
	{
		defaultSave.erase();

		defaultSave.data.firstTime = -1;

		downScroll = false;
		middleScroll = false;
		timeHit = false;
		showFPS = true;
		flashing = true;
		globalAntialiasing = true;
		noteSplashes = true;
		lowQuality = false;
		framerate = 60;
		cursing = true;
		violence = true;
		musicSync = false;
		camZooms = true;
		hideHud = false;
		noteOffset = 0;
		arrowHSV = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
		imagesPersist = 'None';
		chartCache = 'None';
		debugMode = #if debug true #else false #end;
		ghostTapping = true;
		timeBarType = 'Time Left';
		scoreZoom = true;
		noReset = false;
		pauseSecond = 1.2;
		healthBarAlpha = 1;
		controllerMode = false;
		hitsoundVolume = 0;
		pauseMusic = 'Outpost Alpha';
		performanceCounter = 'fps-mem-peak';
		channel = 'Stereo';
		

		comboOffset = [0, 0, 0, 0];
		ratingOffset = 0;
		sickWindow = 45;
		goodWindow = 90;
		badWindow = 135;
		safeFrames = 10;

		saveSettings();
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}

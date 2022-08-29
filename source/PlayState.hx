package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import shaders.WiggleEffect;
import shaders.WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxVelocity;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxDirection;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.display.BitmapData;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
#if sys
import sys.FileSystem;
#end
import shaders.ColorSwap;
import shaders.ColorSwap.ColorSwapShader;
import shaders.BuildingShaders;
#if VIDEOS_ALLOWED
import VideoHandler;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var leftMusic:FlxSound;
	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:StrumGroups;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	public var noteLength:Int = 0;

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private var camFollowPixel:FlxPoint;
	private var camFollowOffset:FlxPoint = FlxPoint.get();

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;
	private static var prevCamZoom:Null<Float>;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public static var firstSong:Bool = false;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;

	public var maxHealth(default, set):Float = 2;
	public var minHealth:Float = 0;
	public var maxHealthOffset:Float = 0;
	public var minHealthOffset:Float = 0;

	public var combo:Int = 0;

	private var healthBarTween:FlxTween;
	private var healthBarBG:AttachedSprite;
	private var healthBarShader:ColorSwap;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;

	public var timeBar:FlxBar;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var playBothMode:Bool = false;
	public var playEnemy:Bool = false;
	public var sickOnly:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var healthBarBlock:FlxSprite;
	public var minBarBlock:FlxSprite;

	public var sleepFog:FlxSprite;
	public var dodgeFog:FlxSprite;
	public var dodgeText:FlxText;

	// public var ticTacToeSpr:TicTacToe;
	public var iconPixelScale:{p1:FlxPoint, p2:FlxPoint} = {p1: new FlxPoint(1, 1), p2: new FlxPoint(1, 1)};
	public var iconPixelTimer:FlxTimer;
	public var iconPixelTime:Float = 1 / 20;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var phillyWall:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var lightFadeShader:BuildingShaders;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var snowSprites:Array<MallSnow> = [];
	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var shapeGroup:FlxTypedGroup<Shape>;

	var shapeTmr:FlxTimer;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var songIsCutscene:Bool = false;
	public static var seenTransition:Bool = false;
	public static var deathCounter:Int = 0;

	public var zoomTween:FlxTween = null;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// Mechanics
	public var moveStrumSections:Array<Null<Bool>> = [];

	var precacheList:Map<String, String> = new Map<String, String>();

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		luckMechanic();

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		sickOnly = ClientPrefs.getGameplaySetting('sickonly', false);
		instakillOnMiss = (ClientPrefs.getGameplaySetting('instakill', false) || sickOnly);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		playBothMode = ClientPrefs.getGameplaySetting('duetMode', false);
		playEnemy = ClientPrefs.getGameplaySetting('enemyMode', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		// trace('stage is: ' + curStage);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': // Week 2
				if (!ClientPrefs.lowQuality)
				{
					halloweenBG = new BGSprite(['halloween_bg', 'week2'], -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				}
				else
				{
					halloweenBG = new BGSprite(['halloween_bg_low', 'week2'], -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				// PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': // Week 3
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite(['philly/sky', 'week3'], -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite(['philly/city', 'week3'], -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				lightFadeShader = new BuildingShaders();

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite(['philly/window', 'week3'], city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.shader = lightFadeShader.shader;

				if (!ClientPrefs.lowQuality)
				{
					var streetBehind:BGSprite = new BGSprite(['philly/behindTrain', 'week3'], -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite(['philly/train', 'week3'], 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite(['philly/street', 'week3'], -40, 50);
				add(phillyStreet);

				phillyWall = new BGSprite(['philly/wall', 'week3'], -290, -10);
				phillyWall.scale.set(1.2, 1.2);
				phillyWall.scrollFactor.set(0.65, 0.04);

			case 'limo': // Week 4
				var skyBG:BGSprite = new BGSprite(['limo/limoSunset', 'week4'], -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!ClientPrefs.lowQuality)
				{
					limoMetalPole = new BGSprite(['gore/metalPole', 'week4'], -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite(['limo/bgLimo', 'week4'], -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite(['gore/noooooo', 'week4'], -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite(['gore/noooooo', 'week4'], -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite(['gore/coldHeartKiller', 'week4'], limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					// PRECACHE BLOOD
					var particle:BGSprite = new BGSprite(['gore/stupidBlood', 'week4'], -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					// PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite(['limo/limoDrive', 'week4'], -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite(['limo/fastCarLol', 'week4'], -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': // Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite(['christmas/bgWalls', 'week5'], -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!ClientPrefs.lowQuality)
				{
					upperBoppers = new BGSprite(['christmas/upperBop', 'week5'], -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite(['christmas/bgEscalator', 'week5'], -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);

					var snowSprite = new MallSnow({
						x: -900,
						y: -1200,
						width: 2400,
						height: 400
					});
					snowSprite.scrollFactor.set(0.15, 0.15);
					snowSprite.antialiasing = ClientPrefs.globalAntialiasing;
					snowSprites.push(snowSprite);
					add(snowSprite);
				}

				var tree:BGSprite = new BGSprite(['christmas/christmasTree', 'week5'], 370, -250, 0.40, 0.40);
				add(tree);

				if (!ClientPrefs.lowQuality)
				{
					var snowSprite = new MallSnow({
						x: -900,
						y: -1200,
						width: 2400,
						height: 400
					});
					snowSprite.scrollFactor.set(0.3, 0.3);
					snowSprite.antialiasing = ClientPrefs.globalAntialiasing;
					snowSprite.scaleFactor += 0.2;
					snowSprites.push(snowSprite);
					add(snowSprite);
				}

				bottomBoppers = new BGSprite(['christmas/bottomBop', 'week5'], -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite(['christmas/fgSnow', 'week5'], -600, 700);
				add(fgSnow);

				santa = new BGSprite(['christmas/santa', 'week5'], -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': // Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite(['christmas/evilBG', 'week5'], -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite(['christmas/evilTree', 'week5'], 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite(['christmas/evilSnow', 'week5'], -200, 700);
				add(evilSnow);

			case 'school': // Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if (!ClientPrefs.lowQuality)
				{
					var fgTrees:BGSprite = new BGSprite(['weeb/weebTreesBack', 'week6'], repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if (!ClientPrefs.lowQuality)
				{
					var treeLeaves:BGSprite = new BGSprite(['weeb/petals', 'week6'], repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if (!ClientPrefs.lowQuality)
				{
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': // Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite(['weeb/animatedEvilSchool', 'week6'], posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite(['weeb/bgGhouls', 'week6'], -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite(['weeb/animatedEvilSchool_low', 'week6'], posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': // Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite(['tankSky', 'week7'], -400, -400, 0, 0);
				add(sky);

				if (!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite(['tankClouds', 'week7'], FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite(['tankMountains', 'week7'], -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite(['tankBuildings', 'week7'], -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite(['tankRuins', 'week7'], -200, 0, .35, .35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite(['smokeLeft', 'week7'], -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite(['smokeRight', 'week7'], 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite(['tankWatchtower', 'week7'], 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite(['tankRolling', 'week7'], 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite(['tankGround', 'week7'], -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite(['tank0', 'week7'], -500, 650, 1.7, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite(['tank1', 'week7'], -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite(['tank2', 'week7'], 450, 940, 1.5, 1.5, ['foreground']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite(['tank4', 'week7'], 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite(['tank5', 'week7'], 1620, 700, 1.5, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite(['tank3', 'week7'], 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch (Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); // Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch (curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'philly':
				add(phillyWall);
			case 'mall':
				var snowSprite = new MallSnow({
					x: -600,
					y: -1200,
					width: 2800,
					height: 400
				});
				snowSprite.scrollFactor.set(0.7, 0.7);
				snowSprite.antialiasing = ClientPrefs.globalAntialiasing;
				snowSprites.push(snowSprite);
				snowSprite.scaleFactor += 0.4;
				add(snowSprite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch (Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if (gfVersion == 'pico-speaker')
			{
				if (!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if (FlxG.random.bool(16))
						{
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		switch (curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); // nice
				addBehindDad(evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled' || (MechanicManager.mechanics['click_time'].points > 0));
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 44;

		if (ClientPrefs.timeBarType == 'Song Name' && !(MechanicManager.mechanics['click_time'].points > 0))
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = Math.floor(timeBar.width); // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if (ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPixel = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}

		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		if (prevCamZoom != null && isStoryMode)
		{
			FlxG.camera.zoom = prevCamZoom;
			prevCamZoom = null;

			if (!inCutscene)
				zoomTween = FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
		}
		else
		{
			FlxG.camera.zoom = defaultCamZoom;
		}
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		healthBarShader = new ColorSwap();
		healthBarBG.shader = healthBarShader.shader;
		healthBarShader.brightness = -1;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, maxHealth);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		healthBar.numDivisions = Math.floor(healthBar.width);
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		barCursor = new FlxSprite(healthBarBG.x + 4,
			healthBarBG.y + 4).makeGraphic(Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), FlxColor.LIME);
		barCursor.scrollFactor.set();
		barCursor.alpha = 0;
		add(barCursor);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);

		healthBarBlock = new FlxSprite(-16, 0).makeGraphic(10, 20, FlxColor.RED);
		healthBarBlock.y = healthBar.getGraphicMidpoint().y - (healthBarBlock.height / 2);
		healthBarBlock.scrollFactor.set();
		healthBarBlock.alpha = MechanicManager.mechanics['limit_health'].points > 0 ? ClientPrefs.healthBarAlpha : 0;
		add(healthBarBlock);

		minBarBlock = new FlxSprite(-16, 0).makeGraphic(10, 20, FlxColor.BLUE);
		minBarBlock.y = healthBar.getGraphicMidpoint().y - (minBarBlock.height / 2);
		minBarBlock.scrollFactor.set();
		minBarBlock.alpha = MechanicManager.mechanics['minimum_hp'].points > 0 ? ClientPrefs.healthBarAlpha : 0;
		add(minBarBlock);

		if (PlayState.isPixelStage)
		{
			iconPixelTimer = new FlxTimer().start(iconPixelTime, function(tmr:FlxTimer)
			{
				iconP1.scale.set(iconPixelScale.p1.x, iconPixelScale.p1.y);
				iconP2.scale.set(iconPixelScale.p2.x, iconPixelScale.p2.y);
				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}, 0);
		}

		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.5;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, null, FlxColor.TRANSPARENT);
		botplayTxt.alpha = 0.25;
		botplayTxt.blend = INVERT;
		botplayTxt.scrollFactor.set();
		// botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.downScroll)
		{
			botplayTxt.y = timeBarBG.y - 78;
		}

		var pixelPrefix:String = 'pixelUI/';
		if (!PlayState.isPixelStage)
			pixelPrefix = '';
		sleepFog = new FlxSprite().loadGraphic(Paths.image(pixelPrefix + "sleepyFog"));
		sleepFog.scrollFactor.set();
		sleepFog.antialiasing = ClientPrefs.globalAntialiasing;
		sleepFog.alpha = 0;
		// sleepFog.blend = ADD;
		add(sleepFog);

		dodgeFog = new FlxSprite().loadGraphic(Paths.image('dodgeVignette'));
		dodgeFog.scrollFactor.set();
		dodgeFog.antialiasing = ClientPrefs.globalAntialiasing;
		dodgeFog.alpha = 0;
		add(dodgeFog);

		dodgeText = new FlxText(0, 0, FlxG.width * 0.9, "", 24);
		dodgeText.text = 'Press ${ClientPrefs.keyBinds['dodge'][0].toString()}${(ClientPrefs.keyBinds['dodge'][1] != NONE ? "or" + ClientPrefs.keyBinds['dodge'][1].toString() : "")} to dodge!';
		dodgeText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		dodgeText.borderSize = 2.5;
		dodgeText.antialiasing = ClientPrefs.globalAntialiasing;
		dodgeText.screenCenter(X);
		dodgeText.y = FlxG.height * 0.8;
		dodgeText.alpha = 0;
		add(dodgeText);

		/*if (MechanicManager.mechanics['tictactoe'].points > 0)
			{
				ticTacToeSpr = new TicTacToe(FlxG.width * 0.05, FlxG.height * 0.6);
				ticTacToeSpr.cameras = [camOther];
				add(ticTacToeSpr);
		}*/

		var mouseList:Array<String> = ['mouse_follower', 'click_time'];

		for (listed in mouseList)
		{
			if (MechanicManager.mechanics[listed].points > 0)
			{
				mouseCursor = new FlxSprite().loadGraphic(Paths.image('cursor'));
				mouseCursor.scrollFactor.set();
				mouseCursor.antialiasing = ClientPrefs.globalAntialiasing;
				mouseCursor.alpha = 0;
				mouseCursor.cameras = [camOther];
				FlxG.mouse.visible = false;
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					FlxTween.tween(mouseCursor, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
					add(mouseCursor);
				});
				break;
			}
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		sleepFog.cameras = [camHUD];
		dodgeFog.cameras = [camHUD];
		dodgeText.cameras = [camHUD];
		healthBarBlock.cameras = minBarBlock.cameras = [camHUD];
		barCursor.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					songIsCutscene = true;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if (gf != null)
						gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					songIsCutscene = true;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						songIsCutscene = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if (daSong == 'roses')
						FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
					songIsCutscene = true;
				case 'ugh' | 'guns' | 'stress':
					songIsCutscene = true;
					tankIntro();

				default:
					songIsCutscene = false;
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0)
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
		{
			precacheList.set(PauseSubState.songName, 'music');
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

			for (array in keysArray)
			{
				var daArray:Array<Int> = array;
				for (checkKey in daArray)
				{
					// no im not givin you all duplicate inputs, cuz you suck
					if (checkKey == -4)
					{
						FlxG.stage.addEventListener(MouseEvent.CLICK, leftMousePress);
						FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
					}
					else if (checkKey == -5)
					{
						FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_CLICK, rightMousePress);
						FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
					}
				}
			}
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * FlxG.timeScale;
		callOnLuas('onCreatePost', []);

		super.create();

		maxHealth = 2;

		if (MechanicManager.mechanics['limit_health'].points > 0)
		{
			var formerMaxHealth = cast(maxHealth, Float);

			maxHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 0, 20, 0, formerMaxHealth / 2));

			if (maxHealthOffset > 1.9)
				maxHealthOffset = 1.9;
			healthBarBlock.x = healthBar.x + FlxMath.remapToRange(maxHealthOffset, 0, formerMaxHealth, 0, healthBar.width);

			var time:Float = 15;
			var changeTime:Void->Void = function()
			{
				time = 15;
				var chanceBool:Bool = false;
				var chance:Float = FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 1, 20, 90, 10);
				var chanceDecre:Float = cast(chance, Float);

				while (!chanceBool && time >= 3)
				{
					chanceBool = FlxG.random.bool(100 - chance);
					if (chanceBool)
						time -= FlxG.random.float(0.5, 1.5);
					else
					{
						time -= FlxG.random.float(0.5, 1.5);
						chance += chanceDecre / FlxG.random.float(5, 15);
					}
				}
			}

			new FlxTimer().start(20 - time, function(tmr:FlxTimer)
			{
				changeTime();

				maxHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 0, 20, 0, formerMaxHealth / 2));
			}, 0);
		}

		if (MechanicManager.mechanics['minimum_hp'].points > 0)
		{
			var firstNoteTime:Float = 0;

			var idx:Int = 0;
			while (unspawnNotes[idx].noteType != null && !unspawnNotes[idx].mustPress)
			{
				idx++;
			}

			firstNoteTime = unspawnNotes[idx].strumTime;
			new FlxTimer().start((firstNoteTime / 1000) + 7.5, function(tmr:FlxTimer)
			{
				var formerMaxHealth = cast(maxHealth, Float);

				minHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 0, 20, 0, formerMaxHealth / 4));

				if (minHealthOffset > 0.9)
					minHealthOffset = 0.9;
				minBarBlock.x = (healthBar.x + healthBar.width) - ((minHealthOffset * healthBar.width) / 2);

				var time:Float = 15;
				var changeTime:Void->Void = function()
				{
					time = 15;
					var chanceBool:Bool = false;
					var chance:Float = FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 1, 20, 90, 10);
					var chanceDecre:Float = cast(chance, Float);

					while (!chanceBool && time >= 3)
					{
						chanceBool = FlxG.random.bool(100 - chance);
						if (chanceBool)
							time -= FlxG.random.float(0.5, 1.5);
						else
						{
							time -= FlxG.random.float(0.5, 1.5);
							chance += chanceDecre / FlxG.random.float(5, 15);
						}
					}
				}

				new FlxTimer().start(20 - time, function(tmr:FlxTimer)
				{
					changeTime();

					minHealthOffset = FlxG.random.float(0,
						FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 0, 20, 0, formerMaxHealth / 4));
					minHealthOffset /= 3;
				}, 0);
			});
		}

		FlxG.sound.music.pan = 1;
		FlxG.sound.music.volume /= 2;
		if (leftMusic != null)
		{
			leftMusic.pan = -1;
			leftMusic.volume /= 2;
		}

		PlayState.firstSong = false;

		letterMechanicGroup = new FlxTypedGroup<FlxObject>();
		add(letterMechanicGroup);

		var cappedPoints:Float = MechanicManager.mechanics['shape_obst'].points;

		if (cappedPoints >= 1000)
			cappedPoints = 1000;

		if (cappedPoints > 0)
		{
			shapeGroup = new FlxTypedGroup<Shape>();
			shapeGroup.memberAdded.add(function(s:Shape) // now we dont gotta manually set the camera
			{
				s.cameras = [camOther];
			});
			add(shapeGroup);

			shapeTmr = new FlxTimer();

			var shapeChance:Array<Float> = [77.35, 44.15, 11.45];
			var shapeNames:Array<String> = ['square', 'triangle', 'pentagon'];
			var directionList:Array<FlxDirection> = [LEFT, DOWN, UP, RIGHT];

			var spawnShapes:FlxTimer->Void = function(tmr:Null<FlxTimer>)
			{
				for (i in 0...Math.floor(FlxG.random.float(FlxMath.remapToRange(cappedPoints, 1, 20, 2, 8),
					FlxMath.remapToRange(cappedPoints, 1, 20, 10, 30)) * FlxG.random.float(1, 4.5)))
				{
					if (FlxG.random.bool(FlxMath.remapToRange(cappedPoints, 0, 20, 30, 70)))
					{
						new FlxTimer().start(FlxG.random.float(0.5, 2), function(shapeTmr:FlxTimer)
						{
							var newShape:Shape = new Shape(directionList[FlxG.random.int(0, directionList.length - 1)],
								shapeNames[FlxG.random.weightedPick(shapeChance)]);
							newShape.scale.set(0.6, 0.6);
							newShape.updateHitbox();
							newShape.antialiasing = ClientPrefs.globalAntialiasing;
							shapeGroup.add(newShape);
						});
					}
				}
				if (tmr != null)
					tmr.reset(FlxG.random.float(5, 20));
			};

			spawnShapes(null);

			shapeTmr.start(FlxG.random.float(5, 10), spawnShapes);

			new FlxTimer().start(5, function(tmr:FlxTimer)
			{
				shapeGroup.forEachDead(function(s:Shape)
				{
					s.destroy();
					shapeGroup.remove(s);
				});
			}, 0);
		}

		Paths.clearUnusedMemory();

		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes.globalNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, FlxColor.RED));
		#end
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
		{
			for (lua in luaArray)
			{
				if (lua.scriptName == luaFile)
					return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartObjects.exists(tag))
			return modchartObjects.get(tag);
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, loop:Bool = false, haccelerated:Bool = true, pauseMusic:Bool = false)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.cameras = [camHUD];
		add(bg);

		var video:VideoHandler = new VideoHandler();
		new FlxTimer().start(0.001, function(_)
		{
			video.playVideo(filepath, loop, haccelerated, pauseMusic);
		});
		video.finishCallback = function()
		{
			remove(bg);
			startAndEnd();
			Paths.clearUnusedMemory();
			return;
		}
		return;
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		// inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch (songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12.2;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});
			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);

					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					if (++calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') // Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, zoomBack);

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					var random:String = FlxG.random.getObject(['LEFT', 'DOWN', 'UP', 'RIGHT']);
					boyfriend.playAnim('sing' + random + 'miss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'sing' + random + 'miss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, zoomBack);
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				// if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;
			if (isStoryMode && !PlayState.firstSong && !songIsCutscene && !seenTransition)
			{
				seenTransition = true;
				healthBarBG.alpha = 0;
				healthBar.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				scoreTxt.alpha = 0;
				timeBarBG.alpha = 0;
				timeBar.alpha = 0;
				timeTxt.alpha = 0;
				if (!ClientPrefs.hideHud)
				{
					FlxTween.tween(scoreTxt, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(iconP1, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(iconP2, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(healthBar, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(healthBarBG, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(timeBar, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(timeBarBG, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
					FlxTween.tween(timeTxt, {alpha: 1}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
				}
				playerStrums.forEach(function(spr:StrumNote)
				{
					FlxTween.tween(spr, {alpha: 1}, 0.7, {ease: FlxEase.quadInOut});
				});
				opponentStrums.forEach(function(spr:StrumNote)
				{
					FlxTween.tween(spr, {alpha: 1}, 0.7, {ease: FlxEase.quadInOut});
				});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
				FlxTween.tween(camFollowPos, {y: camFollow.y}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
				FlxTween.tween(camFollowPos, {x: camFollow.x}, (Conductor.stepCrochet * 16 / 1000), {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween)
					{
						camZooming = true;
					}
				});
				swagCounter = 5;
			}

			if (skipCountdown || startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (!isStoryMode)
				{
					if (gf != null
						&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
						&& gf.animation.curAnim != null
						&& !gf.animation.curAnim.name.startsWith("sing")
						&& !gf.stunned)
					{
						gf.dance();
					}
					if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
						&& boyfriend.animation.curAnim != null
						&& !boyfriend.animation.curAnim.name.startsWith('sing')
						&& !boyfriend.stunned)
					{
						boyfriend.dance();
					}
					if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
						&& dad.animation.curAnim != null
						&& !dad.animation.curAnim.name.startsWith('sing')
						&& !dad.stunned)
					{
						dad.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if (isPixelStage)
				{
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if (curStage == 'mall')
				{
					if (!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();
						countdownReady.cameras = [camHUD];

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						countdownSet.cameras = [camHUD];
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();
						countdownGo.cameras = [camHUD];
						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if (ClientPrefs.middleScroll && !note.mustPress)
					{
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		if (leftMusic != null)
			leftMusic.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		if (leftMusic != null)
		{
			leftMusic.time = time;
			leftMusic.play();
		}
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
	}

	function startNextDialogue()
	{
		callOnLuas('onNextDialogue', [++dialogueCount]);
	}

	function skipDialogue()
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		if (ClientPrefs.channel == 'Stereo')
		{
			leftMusic = cast FlxG.sound.music;
			leftMusic.play();
		}
		FlxG.sound.music.onComplete = finishSong.bind(false);
		vocals.play();

		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			if (leftMusic != null)
				leftMusic.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		if (MechanicManager.mechanics['mouse_follower'].points > 0)
		{
			fakeCursor();
		}

		if (MechanicManager.mechanics['click_time'].points > 0)
		{
			clickTime();
		}

		if (MechanicManager.mechanics['morale'].points > 0)
		{
			activateMorale();
		}

		if (MechanicManager.mechanics['dodging'].points > 0)
		{
			dodgeWant = FlxG.random.float(6, 18);
		}

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new StrumGroups();
		add(notes);

		add(notes.opponentNotes);
		add(notes.hittableNotes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		var spawnedNotes:Array<Note> = [];
		var originalNotes:Array<Note> = [];

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);

				swagNote.formerPress = swagNote.mustPress = gottaHitNote;
				if (playBothMode)
					swagNote.mustPress = true;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.scrollSpeed = songSpeed;
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				var setPos:Bool = true;

				if ((swagNote.noteType == null || (swagNote.noteType == '' || swagNote.noteType.length == 0)) && swagNote.mustPress)
				{
					if (FlxG.random.bool(MechanicManager.mechanics['swap_note'].points * 0.16))
					{
						setPos = false;
						swagNote.noteType = 'Swap Note';
						swagNote.copyX = false;
					}
				}
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);
				originalNotes.push(swagNote);
				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrochet * susNote)
							+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote,
							true);

						sustainNote.formerPress = sustainNote.mustPress = gottaHitNote;
						if (playBothMode)
							sustainNote.mustPress = true;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollSpeed = swagNote.scrollSpeed;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						swagNote.tail.push(sustainNote);
						unspawnNotes.push(sustainNote);
						originalNotes.push(sustainNote);
						var setPos:Bool = true;

						if (sustainNote.noteType == 'Swap Note')
							setPos = false;
						if (setPos)
						{
							var originalSusPos:Float = sustainNote.x;

							if (sustainNote.formerPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							else if (ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if (daNoteData > 1) // Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
							if (playBothMode)
							{
								sustainNote.x = originalSusPos;
							}
						}
						else
							sustainNote.copyX = false;
					}
				}
				if (setPos)
				{
					var originalPos:Float = swagNote.x;
					if (swagNote.formerPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if (ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if (daNoteData > 1) // Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
					if (playBothMode)
					{
						swagNote.x = originalPos;
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			var sectionStartTime:Float = (Conductor.stepCrochet * daBeats) * section.lengthInSteps;

			// note placement
			var weightedChances:Array<Null<Float>> = [];
			var getChance:Int->Float = function(i)
			{
				if (weightedChances[i] == null)
				{
					weightedChances[i] = 0;
				}

				return weightedChances[i];
			};

			// [MECHANIC NAME, NOTE TYPE]
			var generatedTypes:Array<Array<Dynamic>> = [
				[
					'hurt_note',
					'Hurt Note',
					Math.min(MechanicManager.mechanics['hurt_note'].points * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1, 6) / noteData.length * 0.2,
						1),
					0.5,
					1
				],
				[
					'kill_note',
					'Kill Note',
					Math.min(MechanicManager.mechanics['kill_note'].points * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1, 6) / noteData.length * 0.2,
						1),
					0.2,
					0.5
				],
				[
					'burst_note',
					'Burst Note',
					Math.min(MechanicManager.mechanics['burst_note'].points * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1, 6) / noteData.length * 0.2,
						1),
					0.35,
					0.9
				],
				[
					'sleep_note',
					'Sleep Note',
					Math.min(MechanicManager.mechanics['sleep_note'].points * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1, 6) / noteData.length * 0.2,
						1),
					0.35,
					0.75
				],
				[
					'fake_note',
					'Fake Note',
					Math.min((MechanicManager.mechanics['fake_note'].points / 2) * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1,
						6) / noteData.length * 0.2, 1),
					0.5,
					0.9
				],
				[
					'note_random',
					'No Animation',
					Math.min(MechanicManager.mechanics['note_random'].points * FlxMath.remapToRange(section.lengthInSteps, 0, 16, 1, 6) / noteData.length * 0.2,
						1),
					0.9,
					1.1
				]
			];

			for (j in [false, true])
			{
				for (ii in 0...weightedChances.length)
				{
					weightedChances[ii] = 0;
				}
				var hitSectionMulti:Float = 1;

				if (section.mustHitSection != j)
				{
					hitSectionMulti = 0.2;
				}
				if (section.sectionNotes.length < 8)
					hitSectionMulti = 0.04;
				for (i in 0...section.lengthInSteps)
				{
					for (jj in 0...generatedTypes.length)
					{
						var chance:Float = generatedTypes[jj][2] + (getChance(jj) * generatedTypes[jj][4]);
						if (generatedTypes[jj][0] == 'note_random')
							chance *= hitSectionMulti;
						else if (generatedTypes[jj][0] == 'restore_note' && (!j && !playBothMode))
							break;
						var placeNote:Note = placeNote(chance, generatedTypes[jj][1], [
							sectionStartTime + (Conductor.stepCrochet * i),
							FlxG.random.int(0, 3),
							j,
							generatedTypes[jj][3]
						]);

						if (placeNote == null)
						{
							weightedChances[jj] += FlxG.random.float(0,
								FlxMath.remapToRange(MechanicManager.mechanics[generatedTypes[jj][0]].points, 0, 20, 0, 2)) * 0.75;
							continue;
						}
						unspawnNotes.push(placeNote);
						spawnedNotes.push(placeNote);
						weightedChances[jj] = 0;
					}
				}
			}
			var strumSwapPoints:Int = MechanicManager.mechanics['strum_swap'].points;

			if (FlxG.random.bool(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 8) + getChance(7)))
			{
				moveStrumSections[daBeats] = true;
				weightedChances[7] = 0;
			}
			else
			{
				moveStrumSections[daBeats] = false;
				weightedChances[7] += FlxG.random.float(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 0.4));
			}
			daBeats += 1;
		}
		var dupeNotes:Array<Note> = [];

		for (note in spawnedNotes)
		{
			for (songNote in unspawnNotes)
			{
				if (Math.abs(songNote.strumTime - note.strumTime) < 10
					&& songNote.noteData == note.noteData
					&& songNote.mustPress == note.mustPress
					&& songNote != note)
				{
					dupeNotes.push(note);
				}
			}
		}
		for (dumbNote in dupeNotes)
		{
			FlxArrayUtil.clearArray(dumbNote.tail);
			unspawnNotes.remove(dumbNote);
			if (notes != null)
			{
				if (notes.length > 0)
					notes.remove(dumbNote, true);
			}
			dumbNote.kill();
			dumbNote.destroy();
		}
		if (MechanicManager.mechanics["note_speed"].points > 0)
		{
			for (note in unspawnNotes)
			{
				if (note.isSustainNote)
					continue;
				var speedBound:{min:Float, max:Float};
				var points:Float = MechanicManager.mechanics["note_speed"].points;

				speedBound = {min: FlxMath.remapToRange(points, 0, 20, -0, -0.5), max: FlxMath.remapToRange(points, 0, 20, 0, 0.5)};
				note.scrollSpeed = songSpeed + FlxG.random.float(speedBound.min, speedBound.max);
				for (sus in note.tail)
				{
					sus.scrollSpeed = note.scrollSpeed;
				}
			}
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		noteLength = unspawnNotes.length;
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
		if (MechanicManager.mechanics['drain_hp'].points > 0)
		{
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				if (!paused && !startingSong && !endingSong && health > minHealth + minHealthOffset + 0.1)
				{
					if (MechanicManager.mechanics['drain_hp'].points > 0)
					{
						if (FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['drain_hp'].points, 0, 20, 0, 75)))
						{
							noTriggerKarma = true;
							var loss:Float = FlxMath.remapToRange(0.1, 0, 100, 0, 2);
							if (restoreActivated)
								lastHealth -= loss;
							else
								health -= loss;
							noTriggerKarma = false;
						}
					}
					else
					{
						tmr.cancel();
					}
				}
			}, 0);
		}
	}

	private function placeNote(chance:Float, noteType:String, attributes:Array<Dynamic>):Note
	{
		if (FlxG.random.bool(chance))
		{
			var dataNote:Note = new Note(attributes[0], attributes[1], null, false);
			dataNote.autoGenerated = true;
			dataNote.earlyHitMult = attributes[3];
			dataNote.mustPress = dataNote.formerPress = attributes[2];
			if (playBothMode)
				dataNote.mustPress = true;
			dataNote.noteType = noteType;
			dataNote.scrollSpeed = songSpeed;
			dataNote.scrollFactor.set();

			return dataNote;
		}

		return null;
	}

	private var burstTime:{min:Float, max:Float, value:Float} = null;
	private var allowBurstTween:Bool = true;

	private function burstNote():Void
	{
		if (burstTime == null)
		{
			burstTime = {min: 0, max: 5, value: 0};
		}
		var points:Float = MechanicManager.mechanics['burst_note'].points;

		var minimum:Float = FlxMath.remapToRange(points, 0, 20, 1, 2);
		var maximum:Float = FlxMath.remapToRange(points, 0, 20, 8, 14);
		var value:Float = FlxG.random.float((minimum + maximum / 2), maximum);

		burstTime = {min: minimum, max: maximum, value: value};
	}

	private var sleepTime:{max:Float, value:Float, lerpValue:Float} = null;
	private var sleepTimer:FlxTimer = null;

	private function sleepNote():Void
	{
		if (sleepTime == null)
		{
			var max = FlxMath.remapToRange(MechanicManager.mechanics['sleep_note'].points, 0, 20, 15, 7);
			var value = 1;
			sleepTime = {max: max, value: value, lerpValue: 0};

			sleepTimer = new FlxTimer().start(2.5, function(tmr:FlxTimer)
			{
				sleepTime.value -= FlxG.random.float(0.15, 0.25);
			}, 0);
		}
		else
		{
			sleepTime.value += FlxG.random.float(1, 1.25);
		}

		if (sleepTime.value >= sleepTime.max)
		{
			health = -40;
			doDeathCheck(true);
		}
	}

	private var lastHealth:Float = 0;
	private var healthTimer:FlxTimer;
	private var restoreActivated:Bool = false;

	private function restoreNote():Void
	{
		if (restoreActivated)
			return;

		lastHealth = cast health;
		var calculateHealth:Float = FlxMath.remapToRange(lastHealth / 50, 0, maxHealth, minHealth, maxHealth);
		healthTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			noTriggerKarma = true;
			health -= calculateHealth;
			if (tmr.elapsedLoops > 15)
			{
				if (FlxG.random.bool(5 + (tmr.elapsedLoops * 1.25)))
				{
					var time:Float = 3100;
					if (songSpeed < 1)
						time /= songSpeed;
					var restoreNote:Note = new Note(Conductor.songPosition + time, FlxG.random.int(0, 3), null);

					restoreNote.mustPress = restoreNote.formerPress = true;
					restoreNote.scrollSpeed = songSpeed;
					restoreNote.noteType = 'Restore Note';
					restoreNote.x += FlxG.width / 2; // general offset
					restoreNoteGroup.push(restoreNote);
					unspawnNotes.unshift(restoreNote);
				}
			}
			noTriggerKarma = false;

			calculateHealth = FlxMath.remapToRange(lastHealth / 50, 0, maxHealth, minHealth, maxHealth);
		}, 60);
		restoreActivated = true;

		FlxG.sound.play(Paths.sound('restoreActivate', 'shared'));

		var vignetteAppear:FlxSprite = new FlxSprite().loadGraphic(Paths.image('restoreVignette', 'shared'));
		vignetteAppear.y = -vignetteAppear.height;
		vignetteAppear.cameras = [camOther];
		add(vignetteAppear);

		FlxTween.tween(vignetteAppear, {y: 0}, 0.5, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				FlxTween.tween(vignetteAppear, {alpha: 0.0}, 0.5, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween)
				{
					remove(vignetteAppear);
					vignetteAppear.destroy();
				}, startDelay: 2.5});
			}
		});
	}

	private var restoreNoteGroup:Array<Note> = [];

	private function restoreNoteHit():Void
	{
		FlxG.sound.play(Paths.sound('restoreActivate', 'shared'), 0.6);

		if (healthTimer != null)
			healthTimer.cancel();
		for (restoreNote in restoreNoteGroup)
		{
			if (notes.members.contains(restoreNote))
				notes.remove(restoreNote, true);
			if (unspawnNotes.contains(restoreNote))
				unspawnNotes.remove(restoreNote);

			restoreNote.kill();
			restoreNote.destroy();
		}

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.noteType == 'Restore Note')
			{
				daNote.noteType = null;

				if (MechanicManager.mechanics['flashlight'].points > 0 && daNote.canBeHit && daNote.mustPress)
					goodNoteHit(daNote);
			}
		});

		healthTimer = null;
		health = cast lastHealth;
		restoreActivated = false;
	}

	private var noteSwapTweens:Array<FlxTween> = [];
	private var wasSwapped:Bool = false;
	private var swapCooldown:Int = 0;

	private function swapStrums():Void
	{
		if (wasSwapped)
		{
			playerStrums.forEachAlive(function(strum:StrumNote)
			{
				@:privateAccess
				{
					strum.positionData = strum.noteData;
				}
				noteSwapTweens.push(FlxTween.tween(strum, {x: strum.formerPosition.x, y: strum.formerPosition.y}, 0.4, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						noteSwapTweens.remove(twn);
					}
				}));
			});

			opponentStrums.forEachAlive(function(strum:StrumNote)
			{
				@:privateAccess
				{
					strum.positionData = strum.noteData;
				}
				noteSwapTweens.push(FlxTween.tween(strum, {x: strum.formerPosition.x, y: strum.formerPosition.y}, 0.4, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						noteSwapTweens.remove(twn);
					}
				}));
			});
			swapCooldown = FlxG.random.int(2, 8);
			wasSwapped = !wasSwapped;
			return;
		}

		var chosenStrum:Int = FlxG.random.int(0, 3);
		var tweenToStrum:Int = FlxG.random.int(0, 3, [chosenStrum]);

		playerStrums.members[chosenStrum].positionData = tweenToStrum;
		playerStrums.members[tweenToStrum].positionData = chosenStrum;

		noteSwapTweens.push(FlxTween.tween(playerStrums.members[chosenStrum],
			{x: playerStrums.members[tweenToStrum].formerPosition.x, y: playerStrums.members[tweenToStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));
		noteSwapTweens.push(FlxTween.tween(playerStrums.members[tweenToStrum],
			{x: playerStrums.members[chosenStrum].formerPosition.x, y: playerStrums.members[chosenStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));

		opponentStrums.members[chosenStrum].positionData = tweenToStrum;
		opponentStrums.members[tweenToStrum].positionData = chosenStrum;

		noteSwapTweens.push(FlxTween.tween(opponentStrums.members[chosenStrum],
			{x: opponentStrums.members[tweenToStrum].formerPosition.x, y: opponentStrums.members[tweenToStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));
		noteSwapTweens.push(FlxTween.tween(opponentStrums.members[tweenToStrum],
			{x: opponentStrums.members[chosenStrum].formerPosition.x, y: opponentStrums.members[chosenStrum].formerPosition.y}, 0.4, {
				ease: FlxEase.cubeOut,
				onComplete: function(twn:FlxTween)
				{
					noteSwapTweens.remove(twn);
				}
			}));

		swapCooldown = FlxG.random.int(4, 12);

		wasSwapped = !wasSwapped;
	}

	private var dodgeTimers:Array<FlxTimer> = [];
	private var canDodge:Bool = false;
	private var dodgeTimer:Float = 0;
	private var failedDodges:Int = 0;
	private var failedTotalDodges:Int = 0;
	private var dodgeWant:Float = 0;
	private var dodgeInput:Bool = false;
	private var dodged:Bool = false;
	private var forceDodge:Int = 16;

	// dodging is based on reaction time, frequency really isn't the main focus here
	private var dodgeSound:FlxSound = null;

	private function doDodge():Void
	{
		var formerFocus:Bool = cameraFocus;
		var dodgeWindowTime:Float = FlxMath.remapToRange(MechanicManager.mechanics['dodging'].points, 0, 20, 2.5, 1);
		// originally 0.25 seconds to the max, but i nerfed it because it was faster than the human reaction time

		moveCamera(false);

		dodgeSound = FlxG.sound.load(Paths.soundRandom('dodgeStart', 0, 2));
		FlxG.sound.list.add(dodgeSound);
		dodgeSound.play();

		dodgeFog.alpha = 1;
		new FlxTimer().start(dodgeWindowTime + 2, function(tmr:FlxTimer)
		{
			dodgeFog.alpha = 0;
		});

		dodgeInput = true;
		dodgeTimers.push(new FlxTimer().start(dodgeWindowTime, function(tmr:FlxTimer)
		{
			if (dodged)
			{
				dodgeSound.play(true);
				failedDodges = 0;
			}
			else
			{
				failedDodge();
				if (++failedTotalDodges >= 3 || FlxG.save.data.firstTimeDodging == null)
				{
					FlxG.save.data.firstTimeDodging = true;
					failedTotalDodges = 0;

					FlxTween.tween(dodgeText, {alpha: 1}, 0.2, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							FlxTween.tween(dodgeText, {alpha: 0}, 0.5, {
								ease: FlxEase.quadOut,
								startDelay: 3
							});
						}
					});
				}
			}

			resetDodgeValues();
			FlxG.sound.list.remove(dodgeSound);
			moveCamera(formerFocus);
		}));
	}

	private function resetDodgeValues():Void
	{
		dodgeTimers = [];
		dodgeInput = false;
		canDodge = false;

		dodgeFog.alpha = 0;

		dodgeTimer = 0;
		dodgeWant = FlxG.random.float(6, 18);
	}

	private function failedDodge():Void
	{
		noTriggerKarma = true;
		if (health < 0.4)
			health -= 40;
		else
			health /= 2;
		failedDodges++;
		noTriggerKarma = false;
		FlxTween.color(iconP1, 0.3, 0xFFFF0000, 0xFFFFFFFF, {ease: FlxEase.cubeOut});
	}

	private var ghostCursor:FlxSprite;
	private var mouseCursor:FlxSprite;
	private var barCursor:FlxSprite;
	private var cursorValue:Float = 0;
	private var cpuPos:FlxPoint = FlxPoint.get();

	private function fakeCursor():Void
	{
		ghostCursor = new FlxSprite().loadGraphic(Paths.image('ghostCursor'));
		ghostCursor.scrollFactor.set();
		ghostCursor.antialiasing = ClientPrefs.globalAntialiasing;
		ghostCursor.alpha = 0.6;
		ghostCursor.screenCenter();
		ghostCursor.cameras = [camOther];
		add(ghostCursor);

		cpuPos.set(FlxG.random.float(FlxG.width * 0.2, FlxG.width * 0.8), FlxG.random.float(FlxG.height * 0.2, FlxG.height * 0.8));

		mouseCursor.visible = true;

		FlxTween.tween(ghostCursor, {alpha: 0.35}, 0.5, {ease: FlxEase.quadOut});

		new FlxTimer().start(Math.max(FlxMath.remapToRange(MechanicManager.mechanics['mouse_follower'].points, 1, 20, 3, 1), 0.002), function(tmr:FlxTimer)
		{
			var lerpValue:Float = 1 + (FlxG.elapsed * 3.7) * 2.5;

			FlxVelocity.moveTowardsObject(ghostCursor, mouseCursor, 175 * lerpValue, 0);

			if (FlxMath.distanceBetween(ghostCursor, mouseCursor) < 48)
			{
				ghostCursor.velocity.set();
				FlxTween.tween(ghostCursor, {x: mouseCursor.x, y: mouseCursor.y}, 0.25);
			}
			else
			{
				new FlxTimer().start(0.25, function(tmr:FlxTimer)
				{
					ghostCursor.velocity.set();
				});
			}
		}, 0);
	}

	private var timeActivated:Bool = false;
	private var timeBlockGroup:FlxSpriteGroup;
	private var timeBox:FlxSprite;
	private var overlapBox:FlxSprite;
	private var timeClickText:FlxText;
	private var timeNeed:Float = 0;
	private var timeSine:Float = 0;
	private var timeDisabled:Bool = false;
	private var timeAttempts:Int = 0;
	private var maximumAttempts:Int = 2;
	private var offsetPos:FlxPoint = FlxPoint.get();
	private var grabbedTime:Bool = false;
	private var timeTweenIsActive:Bool = false;

	private function updateTimeMechanic()
	{
		if (timeBlockGroup == null || timeDisabled)
			return;

		if (Conductor.songPosition - 1500 >= timeNeed) // +0.5 sec for pacifist
		{
			changeTime(2.5);
			timeAttempts++;
			changeMorale(0.9);
		}

		var wantedColor = FlxColor.BLACK;

		timeBox.setGraphicSize(Std.int(timeClickText.width + 8), Std.int(timeClickText.height + 8));
		timeBox.updateHitbox();
		timeBox.setPosition(timeBlockGroup.x, timeBlockGroup.y);

		overlapBox.setGraphicSize(Std.int(timeClickText.width + 8), Std.int(timeClickText.height + 8));
		overlapBox.updateHitbox();
		overlapBox.setPosition(timeBlockGroup.x, timeBlockGroup.y);

		timeClickText.setPosition(timeBlockGroup.x + 4, timeBlockGroup.y + 4);

		timeSine += FlxG.elapsed * 2.5;
		overlapBox.alpha = FlxMath.remapToRange(1 - Math.sin((Math.PI * timeSine)), 0, 1, 0.2, 0.8);

		var lastPosition = mouseCursor.getPosition();
		if (cpuControlled)
		{
			if (Math.abs(Conductor.songPosition - timeNeed) < 1800 && !timeTweenIsActive) // allow a larger range
			{
				timeTweenIsActive = true;
				FlxTween.tween(mouseCursor, {x: timeBlockGroup.x + (overlapBox.width / 2), y: timeBlockGroup.y + (overlapBox.height / 2)}, 0.5, {
					ease: FlxEase.cubeOut,
					onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(mouseCursor, {x: lastPosition.x, y: lastPosition.y}, 0.5, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								new FlxTimer().start(0.25, function(tmr:FlxTimer)
								{
									timeTweenIsActive = false;
								});
							}
						});
					}
				});
				changeTime(2.23);
			}
		}

		var keyPress:Bool = FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get("interact")));

		var pos = !cpuControlled ? FlxG.mouse.getScreenPosition(camOther) : lastPosition;

		var wantX:Bool = (pos.x >= timeBox.x && pos.x <= timeBox.x + timeBox.width);
		var wantY:Bool = (pos.y >= timeBox.y && pos.y <= timeBox.y + timeBox.height);

		if ((overlapBox.visible = (wantX && wantY) || keyPress) || grabbedTime)
		{
			if (grabbedTime = FlxG.mouse.pressedMiddle && !cpuControlled)
			{
				if (FlxG.mouse.justPressedMiddle)
					offsetPos.set(pos.x - timeBlockGroup.x, pos.y - timeBlockGroup.y);

				timeBlockGroup.setPosition(CoolUtil.boundTo(Math.round(pos.x - offsetPos.x), 0, FlxG.width - timeBlockGroup.width),
					CoolUtil.boundTo(Math.round(pos.y - offsetPos.y), 0, FlxG.height - timeBlockGroup.height));
			}
			if ((FlxG.mouse.justPressed || keyPress) || (cpuControlled && Math.abs(Conductor.songPosition - timeNeed) < 1750))
			{
				var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
				if (curTime < 0)
					curTime = 0;

				var songCalc:Float = (songLength - curTime);
				if (ClientPrefs.timeBarType == 'Time Elapsed')
					songCalc = curTime;

				var secondsTotal:Int = Math.floor(songCalc / 1000);
				if (secondsTotal < 0)
					secondsTotal = 0;

				if (Math.abs(Conductor.songPosition - timeNeed) < 1750) // allow a larger range
				{
					changeTime(2.23);
					changeMorale(1.025);
				}
				else
				{
					timeAttempts++;
					changeTime(1.5);
					changeMorale(0.8);
				}
			}

			if (!FlxG.mouse.pressedMiddle)
			{
				grabbedTime = false;
				offsetPos.set();
			}
		}

		if (Math.abs(Conductor.songPosition - timeNeed) < 1750)
			wantedColor = FlxColor.RED;

		timeBox.color = FlxColor.interpolate(timeBox.color, wantedColor, CoolUtil.boundTo(FlxG.elapsed * 27, 0, 1));
	}

	private function clickTime()
	{
		timeActivated = true;

		timeBlockGroup = new FlxSpriteGroup(FlxG.random.float(FlxG.width * 0.2, FlxG.width * 0.8), FlxG.random.float(FlxG.height * 0.2, FlxG.height * 0.8));
		timeBlockGroup.cameras = [camOther];

		if (mouseCursor != null)
			remove(mouseCursor);

		add(timeBlockGroup);

		if (mouseCursor != null)
			add(mouseCursor);

		timeBox = new FlxSprite().makeGraphic(60, 40, FlxColor.BLACK);
		timeBox.alpha = 0;
		timeBlockGroup.add(timeBox);

		overlapBox = new FlxSprite().makeGraphic(60, 40, FlxColor.WHITE);
		overlapBox.visible = false;
		timeBlockGroup.add(overlapBox);

		timeClickText = new FlxText(4, 4, 0, '', 24);
		timeClickText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeClickText.borderSize = 1.5;
		timeClickText.alpha = 0;
		timeBlockGroup.add(timeClickText);

		FlxTween.tween(timeBox, {alpha: 0.4}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(timeClickText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

		maximumAttempts = Math.ceil(CoolUtil.boundTo(songLength / 100000, 4, 10) + 2);

		changeTime();
	}

	private function changeTime(multi:Float = 1)
	{
		var random:Float = FlxG.random.float(1, 3);
		random += FlxMath.remapToRange(MechanicManager.mechanics['click_time'].points, 0, 20, 5, 1);
		random *= multi;
		timeNeed += FlxG.random.float(Conductor.crochet * random * 3, Conductor.crochet * random * 8);
		if (timeNeed >= songLength)
		{
			timeDisabled = true;
			FlxTween.tween(timeBox, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
			FlxTween.tween(timeClickText, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
			FlxTween.tween(overlapBox, {alpha: 0}, 0.5, {ease: FlxEase.sineOut});
		}

		timeNeed = Math.min(timeNeed, songLength);

		var calcTime:Float = songLength - timeNeed;
		if (ClientPrefs.timeBarType == 'Time Elapsed')
			calcTime = timeNeed;
		timeClickText.text = FlxStringUtil.formatTime(Math.floor(calcTime / 1000), false);

		noTriggerKarma = true;
		if (timeAttempts >= maximumAttempts)
		{
			// dont accidentally trigger it
			timeBlockGroup.setPosition(9999999, -9999999);
			health -= 500;
		}
		noTriggerKarma = false;
	}

	private var moraleActivated:Bool = false;
	private var moraleValue:Float = 20;
	private var moraleLerp:Float = 20;
	private var maxMoraleValue:Float = 35;
	private var badMoraleMulti:Float = 0.7;
	private var goodMoraleMulti:Float = 1;
	private var moraleBarOutline:AttachedSprite;
	private var moraleBar:FlxBar;
	private var moraleTitle:FlxSprite;

	private function activateMorale()
	{
		moraleActivated = true;

		moraleBarOutline = new AttachedSprite('moraleBar');
		moraleBarOutline.setPosition(80, 80);
		moraleBarOutline.scrollFactor.set();
		moraleBarOutline.cameras = [camHUD];
		moraleBarOutline.antialiasing = ClientPrefs.globalAntialiasing;
		moraleBarOutline.alpha = 0;
		add(moraleBarOutline);

		moraleBar = new FlxBar(moraleBarOutline.x + 7, moraleBarOutline.y + 7, LEFT_TO_RIGHT, Std.int(moraleBarOutline.width - 14),
			Std.int(moraleBarOutline.height - 14), this, 'moraleLerp', 0, maxMoraleValue);
		moraleBar.scrollFactor.set();
		moraleBar.cameras = [camHUD];
		moraleBar.antialiasing = ClientPrefs.globalAntialiasing;
		moraleBar.alpha = 0;

		moraleBar.createFilledBar(0xFFFFFFFF, 0xFF8400FF);
		moraleBar.numDivisions = Math.floor(moraleBar.width);
		add(moraleBar);

		moraleBarOutline.xAdd = -7;
		moraleBarOutline.yAdd = -7;

		FlxTween.tween(moraleBarOutline, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(moraleBar, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
	}

	private function updateMorale()
	{
		moraleLerp = FlxMath.lerp(moraleLerp, moraleValue, CoolUtil.boundTo(FlxG.elapsed * 3.775, 0, 1));

		moraleValue = CoolUtil.boundTo(moraleValue, -1, maxMoraleValue);
		if (moraleValue <= 0)
		{
			health -= 500;
			doDeathCheck(true);
		}
	}

	private function changeMorale(mod:Float = 1)
	{
		if (mod == 1 && !moraleActivated)
			return;

		if (mod > 1)
		{
			goodMoraleMulti += ((mod * 0.07) / MechanicManager.mechanics['morale'].points) / 48.0;
			badMoraleMulti -= ((mod * 0.07) * FlxMath.remapToRange(MechanicManager.mechanics['morale'].points, 0, 20, 0, 7.5)) / 48.0;
		}
		else if (mod < 1)
		{
			goodMoraleMulti -= ((mod * 0.07) * FlxMath.remapToRange(MechanicManager.mechanics['morale'].points, 0, 20, 0, 7.5)) / 24.0;
			badMoraleMulti += ((mod * 0.07) / MechanicManager.mechanics['morale'].points) / 12.0;
		}

		goodMoraleMulti = CoolUtil.boundTo(goodMoraleMulti, 0.7, 8);
		badMoraleMulti = CoolUtil.boundTo(badMoraleMulti, 1, 240);

		if (mod > 1)
			moraleValue += (mod * goodMoraleMulti) * 0.3;
		else
			moraleValue -= ((1 + mod) * badMoraleMulti) * 0.4;
	}

	private var currentLetter:String = '';
	private var wantedLetter:String = '';
	private var atChance:Float = 10;
	private var letterTime:Float = 20;
	private var allowTime:Bool = true;
	private var failedTimes:Int = 0;

	private function letterMechanic():Void
	{
		if (MechanicManager.mechanics['letter_placement'].points > 0 && allowTime)
		{
			if (FlxG.random.bool(atChance))
			{
				atChance = 10;

				currentLetter = '';
				wantedLetter = KeyboardMechanic.generateLetter(MechanicManager.mechanics['letter_placement'].points * FlxG.random.float(2, 4),
					Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['letter_placement'].points, 0, 20, 4, 7)));

				letterTime = FlxG.random.float(20, 30);

				createLetterMechanic();
			}
			else
				atChance += FlxG.random.float(MechanicManager.mechanics['letter_placement'].points / 20,
					MechanicManager.mechanics['letter_placement'].points / 10) / (Conductor.bpm / 100);
		}
	}

	private var letterMechanicGroup:FlxTypedGroup<FlxObject>;
	private var letterVignetteSprite:FlxSprite;
	private var letterVignetteTime:FlxText;
	private var letterVignetteText:Array<Alphabet> = [];

	private function createLetterMechanic():Void
	{
		letterMechanicActive = true;

		letterVignetteSprite = new FlxSprite().loadGraphic(Paths.image('keyboardVignette', 'shared'));
		letterVignetteSprite.antialiasing = ClientPrefs.globalAntialiasing;
		letterVignetteSprite.alpha = 0.0;
		letterVignetteSprite.cameras = [camOther];
		letterMechanicGroup.add(letterVignetteSprite);

		letterVignetteTime = new FlxText(0, 0, 0, "", 32);
		letterVignetteTime.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		letterVignetteTime.borderSize = 2;
		letterVignetteTime.antialiasing = ClientPrefs.globalAntialiasing;
		letterVignetteTime.alpha = 0.0;
		letterVignetteTime.screenCenter();
		letterVignetteTime.cameras = [camOther];
		letterMechanicGroup.add(letterVignetteTime);

		for (i in 0...wantedLetter.length)
		{
			var letterText:Alphabet = new Alphabet(0, 0, wantedLetter.charAt(i), true, false);
			letterText.screenCenter();
			letterText.y = FlxG.height * 0.7;
			letterText.x += (100 * (i - (wantedLetter.length / 2))) + 50;
			letterText.ID = i;
			letterText.cameras = [camOther];
			letterVignetteText.push(letterText);
			letterMechanicGroup.add(letterText);
		}

		FlxTween.num(0.0, 1.0, 0.9, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				allowUpdate = true;
			}
		}, function(value:Float)
		{
			letterVignetteSprite.alpha = value;
			letterVignetteTime.alpha = value;
			for (mem in letterVignetteText)
			{
				mem.alpha = value;
			}
		});

		allowTime = false;
	}

	private var letterMechanicActive:Bool = false;
	private var allowUpdate:Bool = false;
	private var letterBotplayTime:Float = 0;

	private function updateLetterMechanic():Void
	{
		if (letterMechanicActive && allowUpdate)
		{
			letterTime -= FlxG.elapsed;
			letterBotplayTime += FlxG.elapsed;

			var fromColor:{r:Int, g:Int, b:Int} = {r: 255, g: 255, b: 255};
			var toColor:{r:Int, g:Int, b:Int} = {r: 255, b: 0, g: 0};
			var ratio:Float = FlxMath.remapToRange(letterTime, 30, 0, 0, 1);

			var convertColors:{r:Int, g:Int, b:Int} -> FlxColor = function(color)
			{
				return FlxColor.fromRGB(color.r, color.g, color.b, Math.floor(letterVignetteTime.alpha * 255));
			}

			letterVignetteTime.color = convertColors({
				r: FlxColor.interpolate(fromColor.r, toColor.r, ratio),
				g: FlxColor.interpolate(fromColor.g, toColor.g, ratio),
				b: FlxColor.interpolate(fromColor.b, toColor.b, ratio),
			});

			letterVignetteTime.text = '' + Math.floor(Math.max(letterTime, 0));

			if (!cpuControlled)
			{
				if (String.fromCharCode(FlxG.keys.firstJustPressed()).toLowerCase() == wantedLetter.charAt(currentLetter.length).toLowerCase())
				{
					currentLetter += String.fromCharCode(FlxG.keys.firstJustPressed()).toLowerCase();
				}
			}
			else
			{
				while (letterBotplayTime >= 0.2)
				{
					letterBotplayTime -= 0.2;
					if (wantedLetter.length >= 18)
					{
						for (i in 0...FlxG.random.int(2, 4))
						{
							if (currentLetter.length >= wantedLetter.length)
								break;
							currentLetter += wantedLetter.charAt(currentLetter.length).toLowerCase();
						}
					}
					else
					{
						currentLetter += wantedLetter.charAt(currentLetter.length).toLowerCase();
					}
				}
			}

			for (i in 0...currentLetter.length)
			{
				letterVignetteText[i].alpha = 0.6;
			}

			if (letterTime <= 0)
			{
				allowUpdate = false;

				letterFinishMechanic();

				if (++failedTimes >= 5)
					doDeathCheck(true);
			}
			else if (currentLetter.toLowerCase() == wantedLetter.toLowerCase())
			{
				allowUpdate = false;
				letterFinishMechanic();
			}
		}
	}

	private function letterFinishMechanic():Void
	{
		FlxTween.num(1.0, 0.0, 0.9, {
			ease: FlxEase.quadOut,
			onComplete: function(twn:FlxTween)
			{
				letterMechanicGroup.remove(letterVignetteSprite);
				letterMechanicGroup.remove(letterVignetteTime);

				letterVignetteSprite.destroy();
				letterVignetteTime.destroy();

				for (mem in letterVignetteText)
				{
					letterVignetteText.remove(mem);
					letterMechanicGroup.remove(mem);

					mem.destroy();
				}

				FlxArrayUtil.clearArray(letterVignetteText);

				letterMechanicActive = false;
				new FlxTimer().start(5, function(tmr:FlxTimer)
				{
					allowTime = true;
				});
			}
		}, function(value:Float)
		{
			letterVignetteSprite.alpha = value;
			letterVignetteTime.alpha = value;
			for (mem in letterVignetteText)
			{
				mem.alpha = value * 0.6;
			}
		});
	}

	private var chosenMechanic:String = '';

	// luck mechanic does not affect score multiplier
	private function luckMechanic():Void
	{
		if (MechanicManager.mechanics['luck'].points > 0)
		{
			var listedMechanics:Array<String> = [];
			for (mechanic in MechanicManager.mechanics.keys())
			{
				if (mechanic != 'luck')
					listedMechanics.push(mechanic);
			}

			chosenMechanic = FlxG.random.getObject(listedMechanics);

			MechanicManager.mechanics[chosenMechanic].points += Std.int(MechanicManager.mechanics['luck'].points / 2);
		}
	}

	private function luckMechanicDestroy():Void
	{
		if (MechanicManager.mechanics['luck'].points > 0)
		{
			MechanicManager.mechanics[chosenMechanic].points -= Std.int(MechanicManager.mechanics['luck'].points / 2);
		}
	}

	private var rpsList:Map<String, {name:String, destroys:Array<String>, id:Int}> = [
		'rock' => {name: 'rock', destroys: ['scissors'], id: 0},
		'paper' => {name: 'paper', destroys: ['rock'], id: 1},
		'scissors' => {name: 'scissors', destroys: ['paper'], id: 2}
	];

	private var rpsSelect:Int = 0;
	private var rpsGroup:FlxTypedGroup<FlxSprite>;

	private function createRPS():Void
	{
		rpsGroup = new FlxTypedGroup<FlxSprite>();
		rpsGroup.memberAdded.add(function(sprite:FlxSprite)
		{
			sprite.cameras = [camOther];
		});
		add(rpsGroup);
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						2;
					case 'dad' | 'opponent' | '0':
						1;
					default:
						(Math.isNaN(Std.parseInt(event.value1))) ? 0 : Std.parseInt(event.value1);
				};

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			case 'Subtitle':

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes = new FlxSpriteGroup();
				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5,
					FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite(['philly/window', 'week3'], phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);

				precacheList.set('philly/particle', 'image'); // precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);

				phillyWall.visible = false;
		}

		if (!eventPushedMap.exists(event.event))
		{
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if (ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (leftMusic != null)
					leftMusic.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			for (timer in dodgeTimers)
			{
				if (timer != null && !timer.finished)
					timer.active = false;
			}
			if (songSpeedTween != null)
				songSpeedTween.active = false;
			if (pixelCamTween != null)
				pixelCamTween.active = false;
			for (tween in noteSwapTweens)
			{
				if (tween != null)
					tween.active = false;
			}

			if (sleepTimer != null)
				sleepTimer.active = false;
			if (shapeTmr != null)
				shapeTmr.active = false;

			if (carTimer != null)
				carTimer.active = false;
			if (iconPixelTimer != null)
				iconPixelTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			for (timer in dodgeTimers)
			{
				if (timer != null && !timer.finished)
					timer.active = true;
			}
			if (songSpeedTween != null)
				songSpeedTween.active = true;
			if (pixelCamTween != null)
				pixelCamTween.active = true;
			for (tween in noteSwapTweens)
			{
				if (tween != null)
					tween.active = true;
			}

			if (sleepTimer != null)
				sleepTimer.active = true;
			if (shapeTmr != null)
				shapeTmr.active = true;

			if (carTimer != null)
				carTimer.active = true;
			if (iconPixelTimer != null)
				iconPixelTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		if (leftMusic != null)
			leftMusic.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;
	var ignoreFrame:Bool = true;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
	}*/

		if (ignoreFrame)
		{
			ignoreFrame = false;
			super.update(elapsed);
			return;
		}

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if (!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished)
				{
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					while (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming -= 1 / 24;
					}
				}
				lightFadeShader.update(1.5 * (Conductor.crochet / 1000) * FlxG.elapsed);

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length - 1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if (particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130)
								{
									switch (i)
									{
										case 0 | 3:
											if (i == 0)
												FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite(['gore/noooooo', 'week4'], dancers[i].x + 200, dancers[i].y, 0.4, 0.4,
												['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite(['gore/noooooo', 'week4'], dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
												['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite(['gore/noooooo', 'week4'], dancers[i].x, dancers[i].y + 50, 0.4, 0.4,
												['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'],
												false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000)
								limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length)
						{
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if (!inCutscene)
		{
			if (!endingSong && !camLocked)
			{
				if (PlayState.isPixelStage)
					camFollowPos.setPosition(camFollowPixel.x, camFollowPixel.y);
				else
				{
					var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
					camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x + camFollowOffset.x + cameraTrainOffset, lerpVal),
						FlxMath.lerp(camFollowPos.y, camFollow.y + camFollowOffset.y, lerpVal));
				}
			}

			if (!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		// scuffed
		ratingPercent = CoolUtil.boundTo(totalNotesHit / totalPlayed, 0, 1);

		super.update(elapsed);

		for (arrUpdate in updateArray)
		{
			if (arrUpdate != null)
			{
				try
				{
					arrUpdate();
				}
				catch (e)
				{
					trace(e.message);
				}
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if (MechanicManager.mechanics['burst_note'].points > 0 && burstTime != null)
			{
				if (burstTime.value > burstTime.min)
				{
					burstTime.value = CoolUtil.boundTo(burstTime.value - elapsed, burstTime.min - 0.1, burstTime.max);
					if (allowBurstTween)
					{
						allowBurstTween = false;
						if (healthBarTween != null)
							healthBarTween.cancel();

						healthBarTween = FlxTween.tween(healthBarShader, {brightness: 0, hue: 0.5}, 1, {ease: FlxEase.cubeOut});
					}
				}
				else
				{
					allowBurstTween = true;
					if (healthBarTween != null)
						healthBarTween.cancel();

					healthBarTween = FlxTween.tween(healthBarShader, {brightness: -1, hue: 0}, 1, {ease: FlxEase.cubeOut});
				}
			}

			if (MechanicManager.mechanics['sleep_note'].points > 0)
			{
				if (sleepTime != null)
				{
					sleepTime.lerpValue = FlxMath.lerp(sleepTime.lerpValue, sleepTime.value, CoolUtil.boundTo(elapsed * 3, 0, 1));
					sleepFog.alpha = FlxMath.remapToRange(sleepTime.lerpValue, 0, sleepTime.max, 0, 1);
				}
			}

			if (MechanicManager.mechanics['dodging'].points > 0)
			{
				if (dodgeInput)
				{
					if (cpuControlled || FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('dodge'))))
					{
						dodged = true;
						for (tmr in dodgeTimers)
						{
							tmr.onComplete(tmr);
						}
						dodgeFog.alpha = 0;
					}
				}
				else
				{
					dodgeTimer += elapsed;
					if (canDodge = (dodgeTimer >= dodgeWant) && ((!cameraFocus || playBothMode)))
					{
						doDodge();
					}
				}
			}

			if (MechanicManager.mechanics['limit_health'].points > 0)
			{
				healthBarBlock.x = FlxMath.lerp(healthBarBlock.x, healthBar.x + FlxMath.remapToRange(maxHealthOffset, 0, maxHealth, 0, healthBar.width),
					CoolUtil.boundTo(elapsed * 3.7, 0, 1));
			}

			if (MechanicManager.mechanics['minimum_hp'].points > 0)
			{
				minBarBlock.x = FlxMath.lerp(minBarBlock.x, (healthBar.x + healthBar.width) - ((minHealthOffset * healthBar.width) / 2),
					CoolUtil.boundTo(elapsed * 3.7, 0, 1));
			}

			if (MechanicManager.mechanics['mouse_follower'].points > 0)
			{
				if (mouseCursor != null)
				{
					if (cpuControlled)
					{
						mouseCursor.x = FlxMath.lerp(mouseCursor.x, cpuPos.x, CoolUtil.boundTo(elapsed * 4.65, 0, 1));
						mouseCursor.y = FlxMath.lerp(mouseCursor.y, cpuPos.y, CoolUtil.boundTo(elapsed * 4.65, 0, 1));
					}
					else
					{
						mouseCursor.x = FlxG.mouse.getScreenPosition(camOther).x;
						mouseCursor.y = FlxG.mouse.getScreenPosition(camOther).y;
					}
				}

				if (mouseCursor != null && ghostCursor != null)
				{
					if (FlxG.overlap(mouseCursor, ghostCursor))
					{
						if (cpuControlled)
						{
							cpuPos.x = FlxG.random.float(0, FlxG.width);
							cpuPos.y = FlxG.random.float(0, FlxG.height);
						}
						cursorValue += elapsed;
					}
					else
						cursorValue -= elapsed;
				}

				cursorValue = FlxMath.bound(cursorValue, 0, 3);

				noTriggerKarma = true;
				if (cursorValue >= 2.75)
					health -= 40;
				noTriggerKarma = false;

				barCursor.alpha = FlxMath.remapToRange(cursorValue, 0, 2, 0, ClientPrefs.healthBarAlpha);
			}
			else
			{
				if (mouseCursor != null)
				{
					mouseCursor.x = FlxG.mouse.getScreenPosition(camOther).x;
					mouseCursor.y = FlxG.mouse.getScreenPosition(camOther).y;
				}
			}

			if (MechanicManager.mechanics['click_time'].points > 0)
			{
				updateTimeMechanic();
			}

			if (moraleActivated)
			{
				if (moraleActivated)
					updateMorale();
			}

			if (MechanicManager.mechanics['letter_placement'].points > 0)
			{
				updateLetterMechanic();
			}
		}

		/*
		scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		if (ratingName != '?')
			scoreTxt.text += ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;
	 */
		scoreTxt.text = ScoreText.generateText(songScore, songMisses, ratingName, Highscore.floorDecimal(ratingPercent * 100, 2), ratingFC);

		if (botplayTxt.visible)
		{
			/*botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180); */
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if (ret != FunkinLua.Function_Stop)
			{
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else { */
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.pause();
					if (leftMusic != null)
						leftMusic.pause();
					vocals.pause();
				}

				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				// }

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && ClientPrefs.debugMode)
		{
			openChartEditor();
		}

		#if debug
		if (FlxG.keys.anyJustPressed([FlxKey.F3]))
			openSubState(new VictorySubstate());
		#end

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (!PlayState.isPixelStage)
		{
			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();
		}
		else
		{
			var mult:Float = FlxMath.lerp(1, iconPixelScale.p1.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconPixelScale.p1.set(mult, mult);

			var mult:Float = FlxMath.lerp(1, iconPixelScale.p2.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconPixelScale.p2.set(mult, mult);
		}

		var iconOffset:Int = 26;
		var realPrt:Float = healthBar.percent;
		@:privateAccess
		{
			realPrt = ((healthBar.value - healthBar.min) / healthBar.range) * healthBar._maxPercent;
		}

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(realPrt, 0, 100, 100, 0) * 0.01))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(realPrt, 0, 100, 100, 0) * 0.01))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene && ClientPrefs.debugMode)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000 * FlxG.timeScale;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * FlxG.timeScale;
			if (FlxG.timeScale != 1 || ClientPrefs.musicSync)
				Conductor.songPosition = FlxG.sound.music.time;

			FlxG.sound.music.pitch = FlxG.timeScale;
			if (leftMusic != null)
				leftMusic.pitch = FlxG.timeScale;
			if (vocals != null)
				vocals.pitch = FlxG.timeScale;
			if (!paused)
			{
				songTime += (FlxG.game.ticks - previousFrameTime) * FlxG.timeScale;
				previousFrameTime = Std.int(FlxG.game.ticks * FlxG.timeScale);

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength);

					var timeType:String = ClientPrefs.timeBarType;
					if (timeType == 'Song Name' && MechanicManager.mechanics['click_time'].points > 0)
						timeType = 'Time Left';

					var songCalc:Float = (songLength - curTime);
					if (timeType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0)
						secondsTotal = 0;

					if (timeType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (zoomTween != null)
		{
			if (camZooming && zoomTween.finished)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			}
		}
		else
		{
			if (camZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
				camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			}
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && startedCountdown && !endingSong && !letterMechanicActive)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000; // shit be werid on 4:3
			if (unspawnNotes[0].scrollSpeed < 1)
				time /= unspawnNotes[0].scrollSpeed;
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes.shift();
				if (!dunceNote.isSustainNote
					&& MechanicManager.mechanics['note_change'].points > 0
					&& FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['note_change'].points, 0, 20, 0,
						3) * (1 + Math.abs(Conductor.songPosition / FlxG.sound.music.length))))
				{
					dunceNote.expectedData = FlxG.random.int(0, 3);
					if (dunceNote.tail.length > 0)
					{
						for (sustain in dunceNote.tail)
						{
							sustain.expectedData = dunceNote.expectedData;
						}
					}
				}
				if (restoreActivated
					&& (dunceNote.noteType != null || dunceNote.noteType.length == 0)
					&& FlxG.random.bool(30)
					&& dunceNote.mustPress
					&& !dunceNote.autoGenerated)
				{
					if (!dunceNote.isSustainNote)
					{
						var last:Bool = dunceNote.autoGenerated;
						dunceNote.autoGenerated = true;
						dunceNote.noteType = 'Restore Note';
						dunceNote.autoGenerated = last;
					}
				}
				notes.insert(0, dunceNote);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled)
				{
					keyShit();
				}
				else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
					// boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			// dunno how to make it say its actually used
			var invertStrumGroup:FlxTypedGroup<StrumNote>->FlxTypedGroup<StrumNote> = function(strum:FlxTypedGroup<StrumNote>)
			{
				if (strum == playerStrums)
					return opponentStrums;
				else if (strum == opponentStrums)
					return playerStrums;
				return strumLineNotes;
			}

			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if ((!daNote.formerPress && playBothMode) || (!daNote.mustPress && !playBothMode))
					strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) // Downscroll
				{
					// daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.scrollSpeed);
				}
				else // Upscroll
				{
					// daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.scrollSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if (daNote.copyAlpha)
				{
					daNote.alpha = strumAlpha;
				}

				if (daNote.noteType != 'Fake Note' || daNote.noteType != 'Swap Note')
				{
					var points:Int = MechanicManager.mechanics['flashlight'].points;
					if (points > 0)
					{
						var centerPoint:Float = FlxG.height;
						var multi:Float = switch (ClientPrefs.downScroll)
						{
							case true:
								FlxMath.remapToRange(points, 0, 20, 0.4, 0.2);
							case false:
								FlxMath.remapToRange(points, 0, 20, 0.2, 0.4);
						}
						var notePos:Null<Float> = daNote.y;
						var curAlpha:Float = FlxMath.remapToRange(notePos, centerPoint * multi,
							ClientPrefs.downScroll ? strumY - (7.5 * points) : strumY + (7.5 * points), daNote.alphaLimit, 0.2);
						daNote.alpha = curAlpha;
						if (daNote.isSustainNote)
						{
							if (daNote.alpha > 0.6)
								daNote.alpha = 0.6;
						}
						/* wanted it to have the same alpha as its parent but it got a bit janky
						for (sustain in daNote.tail)
						{
							if (Math.isNaN(notePos) || notePos == null)
							{
								sustain.alpha = FlxMath.remapToRange(sustain.y, centerPoint * multi,
									ClientPrefs.downScroll ? strumY - (7.5 * points) : strumY + (7.5 * points), sustain.alphaLimit, 0);
							}
					}*/
					}
				}

				if (daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if (strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim != null && daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if (PlayState.isPixelStage)
							{
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							}
							else
							{
								daNote.y -= 19;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				var lastCopyX:Bool = cast daNote.copyX;
				if (daNote.expectedData != -1 && Math.abs(daNote.strumTime - Conductor.songPosition) < 500)
				{
					daNote.copyX = false;
					if (daNote != null && daNote.animation != null && daNote.animation.curAnim != null)
					{
						if (daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.contains('end'))
								daNote.animation.play(Note.colors[daNote.expectedData % 4]
									+ 'hold'
									+ ((daNote.animation.curAnim.name.contains('end')) ? 'end' : ''));
						}
						else
							daNote.animation.play(Note.colors[daNote.expectedData % 4] + 'Scroll');
					}

					var gottenStrum = strumGroup;

					if (daNote.noteType == 'Swap Note')
						gottenStrum = invertStrumGroup(gottenStrum);

					FlxTween.tween(daNote, {x: gottenStrum.members[daNote.expectedData].x}, 1, {
						ease: FlxEase.quadOut,
						onStart: function(twn:FlxTween)
						{
							daNote.noteData = daNote.expectedData;
						},
						onComplete: function(twn:FlxTween)
						{
							daNote.copyX = lastCopyX;
						}
					});
					if (daNote.tail.length > 0)
					{
						for (sustain in daNote.tail)
						{
							lastCopyX = cast sustain.copyX;
							sustain.copyX = false;
							if (sustain != null && sustain.animation != null && sustain.animation.curAnim != null)
							{
								if (sustain.animation.curAnim.name.endsWith('end'))
									sustain.animation.play(Note.colors[sustain.expectedData % 4] + 'holdend');
								else
									sustain.animation.play(Note.colors[sustain.expectedData % 4] + 'hold');
							}
							FlxTween.tween(sustain, {x: gottenStrum.members[sustain.expectedData].x + (Note.swagWidth / 2)}, 1, {
								ease: FlxEase.quadOut,
								onStart: function(twn:FlxTween)
								{
									sustain.noteData = sustain.expectedData;
								},
								onComplete: function(twn:FlxTween)
								{
									sustain.copyX = lastCopyX;
								}
							});
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (!daNote.autoGenerated || (daNote.noteType == 'No Animation' && daNote.autoGenerated))
						opponentNoteHit(daNote);
				}

				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit)
						{
							goodNoteHit(daNote);
							changeMorale(1.15);
						}
					}
					else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
					{
						goodNoteHit(daNote);
						changeMorale(3);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;

				if (daNote.alpha != 0 && daNote.visible)
				{
					if (strumGroup.members[daNote.noteData].sustainReduce
						&& daNote.isSustainNote
						&& (daNote.mustPress || !daNote.ignoreNote)
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
					{
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					if (modchartObjects.exists('note${daNote.ID}'))
						modchartObjects.remove('note${daNote.ID}');
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		noTriggerKarma = true;
		if (health > maxHealth - maxHealthOffset)
			health = maxHealth - maxHealthOffset;
		noTriggerKarma = false;

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss)
			|| (health <= minHealth + minHealthOffset || (restoreActivated && lastHealth <= minHealth + minHealthOffset)))
			&& !practiceMode
			&& !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();
				if (leftMusic != null)
					leftMusic.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
					boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	var camDirectionMovement:Bool = false;

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null)
					val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3: // enable and target dad
						if (val == 1) // enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							camDirectionMovement = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2)
							who = boyfriend;
						// 2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer)
						{
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						camDirectionMovement = false;
						camFollowOffset.set(0, 0);
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {
							onComplete: function(twn:FlxTween)
							{
								dadbattleSmokes.visible = false;
							}
						});
				}
			case 'Hey!':
				var value:Int = switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						0;
					case 'gf' | 'girlfriend' | '1':
						1;
					default:
						2;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if (curStage == 'mall')
					{
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId))
					lightId = 0;

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch (lightId)
				{
					case 0:
						if (phillyGlowGradient.visible)
						{
							FlxG.camera.flash(FlxColor.WHITE, 0.15, null, true);
							FlxG.camera.zoom += 0.5;
							if (ClientPrefs.camZooms)
								camHUD.zoom += 0.1;

							camDirectionMovement = false;
							camFollowOffset.set(0, 0);
							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							phillyWall.visible = true;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: // turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							FlxG.camera.flash(FlxColor.WHITE, 0.15, null, true);
							FlxG.camera.zoom += 0.5;
							if (ClientPrefs.camZooms)
								camHUD.zoom += 0.1;

							camDirectionMovement = true;
							camFollowOffset.set(0, 0);
							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
							phillyWall.visible = false;
						}
						else if (ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.3;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						for (who in chars)
						{
							who.color = color;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						var colorDark:FlxColor = color;
						colorDark.brightness *= 0.5;
						phillyStreet.color = colorDark;

					case 2: // spawn particles
						if (!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400
										+ width * i
										+ FlxG.random.float(-width / 5, width / 5),
										phillyGlowGradient.originalY
										+ 200
										+ (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.beatHit();
						});
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && !ClientPrefs.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = switch (value1)
				{
					case 'gf' | 'girlfriend':
						2;
					case 'dad' | 'opponent':
						1;
					default:
						Std.parseInt(value1);
				};
				if (Math.isNaN(charType))
					charType = 0;

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if (bgGirls != null)
					bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = (Math.isNaN(Std.parseFloat(value1))) ? 1 : Std.parseFloat(value1);
				var val2:Float = (Math.isNaN(Std.parseFloat(value2))) ? 0 : Std.parseFloat(value2);

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if (killMe.length > 1)
				{
					Reflect.setProperty(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
				}
				else
				{
					Reflect.setProperty(this, value1, value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	var pixelCamTween:FlxTween;

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] == null)
			return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			if (PlayState.isPixelStage)
			{
				if (pixelCamTween == null)
				{
					pixelCamTween = FlxTween.tween(camFollowPixel, {x: camFollow.x, y: camFollow.y}, Conductor.crochet * 0.002 * cameraSpeed, {
						ease: FlxEase.linear,
						onUpdate: function(twn:FlxTween)
						{
							camFollowPos.setPosition(camFollowPixel.x, camFollowPixel.y);
							pixelCamTween = null;
						}
					});
				}
			}
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	var cameraFocus:Bool = false;

	public function moveCamera(isDad:Bool)
	{
		cameraFocus = !isDad;

		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
		if (PlayState.isPixelStage)
		{
			if (pixelCamTween == null)
			{
				pixelCamTween = FlxTween.tween(camFollowPixel, {x: camFollow.x, y: camFollow.y}, Conductor.crochet * 0.001 * cameraSpeed, {
					ease: FlxEase.linear,
					onUpdate: function(twn:FlxTween)
					{
						camFollowPos.setPosition(camFollowPixel.x, camFollowPixel.y);
						pixelCamTween = null;
					}
				});
			}
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPixel.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	private var camLocked:Bool = false;

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (leftMusic != null)
			leftMusic.volume = 0;
		vocals.pause();
		if (isStoryMode && boyfriend.animOffsets.exists('hey'))
		{
			seenTransition = true;

			camZooming = false;
			camLocked = true;

			var lockCam:Bool = false;

			playerStrums.forEach(function(spr:StrumNote)
			{
				FlxTween.tween(spr, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
			});
			opponentStrums.forEach(function(spr:StrumNote)
			{
				FlxTween.tween(spr, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
			});
			FlxTween.tween(iconP1, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(iconP2, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(healthBar, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(healthBarBG, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(timeBar, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(timeBarBG, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(timeTxt, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(scoreTxt, {alpha: 0}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(FlxG.camera, {zoom: 1.4}, (Conductor.stepCrochet * 16 / 1000), {ease: FlxEase.quadInOut});
			FlxTween.tween(camFollowPos, {x: boyfriend.getGraphicMidpoint().x - 60, y: boyfriend.getGraphicMidpoint().y - 60},
				(Conductor.stepCrochet * 16 / 1000), {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween)
					{
						lockCam = true;
					}
				});

			new FlxTimer().start(0.00001, function(tmr:FlxTimer)
			{
				if (lockCam)
				{
					lockCam = false;
					// do the tween again to prevent jittering???
					FlxTween.tween(camFollowPos, {x: boyfriend.getGraphicMidpoint().x - 60, y: boyfriend.getGraphicMidpoint().y - 60},
						(Conductor.stepCrochet * 16 / 1000), {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								lockCam = true;
							}
						});
				}
			}, 0);

			var offset:Float = 0;

			if (!boyfriend.animOffsets.exists('hey'))
				offset = 0.1;

			new FlxTimer().start((Conductor.stepCrochet * 12 / 1000), function(tmr:FlxTimer)
			{
				boyfriend.playAnim('hey', true);
			});

			new FlxTimer().start((Conductor.stepCrochet * 20 / 1000) + offset, function(tmr:FlxTimer)
			{
				prevCamFollowPos = camFollowPos;
				prevCamZoom = FlxG.camera.zoom;
				if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
				{
					finishCallback();
				}
				else
				{
					finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
					{
						finishCallback();
					});
				}
			});
		}
		else
		{
			if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
			{
				finishCallback();
			}
			else
			{
				finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
				{
					finishCallback();
				});
			}
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			noTriggerKarma = true;
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss * (playBothMode ? 2 : 1);
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss * (playBothMode ? 2 : 1);
				}
			}
			noTriggerKarma = false;

			if (doDeathCheck())
			{
				return;
			}
		}

		if (!isStoryMode)
		{
			timeBarBG.visible = false;
			timeBar.visible = false;
			timeTxt.visible = false;
		}
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement([
				'week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss', 'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'challenger', 'ur_bad',
				'ur_good',
				'hype', 'two_keys', 'toastie', 'debugger'
			]);

			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
					if (leftMusic != null)
						leftMusic.stop();

					if (winterHorrorlandNext)
					{
						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					}
					else
					{
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
		}
	}
	#end

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			if (modchartObjects.exists('note${daNote.ID}'))
				modchartObjects.remove('note${daNote.ID}');
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var showCombo:Bool = true;
	public var showRating:Bool = true;
	public var ratingColors:Map<String, Int> = ['sick' => 0x00AEFF, 'good' => 0x0EBE2C, 'bad' => 0xFFA600, 'shit' => 0xFF0000];
	private var ratingTxt:FlxText;
	private var updateArray:Array<Void->Void> = [];

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		if (cpuControlled)
			noteDiff = 0;
		// trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;
		var moraleFactor:Float = 1;

		// tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if (!note.ratingDisabled)
					shits++;
				moraleFactor = 0.05;
			case "bad": // bad
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if (!note.ratingDisabled)
					bads++;
				moraleFactor = Math.sqrt(3); // ~0.87
			case "good": // good
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if (!note.ratingDisabled)
					goods++;
				moraleFactor = 1.15;
			case "sick": // sick
				totalNotesHit += 1;
				note.ratingMod = 1;
				if (!note.ratingDisabled)
					sicks++;
				moraleFactor = 2.75;
		}

		if (sickOnly)
		{
			if (daRating != 'sick')
			{
				vocals.volume = 0;
				health -= 150;
				doDeathCheck(true);
			}
		}

		note.rating = daRating;

		changeMorale(moraleFactor);

		if (daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if (!practiceMode /* && !cpuControlled */)
		{
			if (!note.autoGenerated)
			{
				songScore += Math.ceil(score * MechanicManager.multiplier);
				if (!note.ratingDisabled)
				{
					songHits++;
					totalPlayed++;
				}

				if (ClientPrefs.scoreZoom)
				{
					if (scoreTxtTween != null)
					{
						scoreTxtTween.cancel();
					}

					scoreTxt.scale.set(1.075, 1.075);

					if (PlayState.isPixelStage)
					{
						var pixelFrames:Int = 6;
						var time:Float = 0;
						var values:FlxPoint = new FlxPoint(1.075, 1.075);
						scoreTxtTween = FlxTween.tween(values, {x: 1, y: 1}, 0.3, {
							ease: FlxEase.cubeOut,
							onUpdate: function(twn:FlxTween)
							{
								if (time == 0)
									time = 1 / pixelFrames;

								if (twn.percent > time)
								{
									scoreTxt.scale.set(values.x, values.y);
									pixelFrames--;
									time = 1 / pixelFrames;
								}
							},
							onComplete: function(twn:FlxTween)
							{
								scoreTxtTween = null;
							}
						});
					}
					else
					{
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.3, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								scoreTxtTween = null;
							},
						});
					}
				}
			}
			RecalculateRating();
		}

		/* if (combo > 60)
			daRating = 'sick';
		else if (combo > 12)
			daRating = 'good'
		else if (combo > 4)
			daRating = 'bad';
	 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		if (!PlayState.isPixelStage)
		{
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
		}
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		if (PlayState.isPixelStage)
		{
			var pixelRating:FlxObject = new FlxObject(rating.x, rating.y, rating.width, rating.height);
			pixelRating.cameras = [camHUD];
			pixelRating.acceleration.y = 550;
			pixelRating.velocity.y -= FlxG.random.int(140, 175);
			pixelRating.velocity.x -= FlxG.random.int(0, 10);
			insert(0, pixelRating);

			new FlxTimer().start(1 / 20, function(tmr:FlxTimer)
			{
				if (rating == null || rating.alpha <= 0)
				{
					tmr.destroy();
					remove(pixelRating);
					return;
				}

				rating.x = pixelRating.x;
				rating.y = pixelRating.y;
			}, 0);
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));

		if (PlayState.isPixelStage)
		{
			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
			comboSpr.x += ClientPrefs.comboOffset[0];
			comboSpr.y -= ClientPrefs.comboOffset[1];

			var pixelCombo:FlxObject = new FlxObject(comboSpr.x, comboSpr.y, comboSpr.width, comboSpr.height);
			pixelCombo.acceleration.y = 600;
			pixelCombo.velocity.y -= 150;
			pixelCombo.velocity.x += FlxG.random.int(1, 10);

			new FlxTimer().start(1 / 20, function(tmr:FlxTimer)
			{
				if (comboSpr == null || comboSpr.alpha <= 0)
				{
					tmr.destroy();
					remove(pixelCombo);
					return;
				}

				comboSpr.x = pixelCombo.x;
				comboSpr.y = pixelCombo.y;
			}, 0);
			insert(members.indexOf(strumLineNotes), rating);
		}
		else
		{
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
			comboSpr.x += ClientPrefs.comboOffset[0];
			comboSpr.y -= ClientPrefs.comboOffset[1];

			comboSpr.velocity.x += FlxG.random.int(1, 10);
			insert(members.indexOf(strumLineNotes), rating);
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			if (!PlayState.isPixelStage)
			{
				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
			}
			numScore.visible = !ClientPrefs.hideHud;

			if (PlayState.isPixelStage)
			{
				var pixelScore:FlxObject = new FlxObject(numScore.x, numScore.y, numScore.width, numScore.height);
				pixelScore.cameras = [camHUD];
				pixelScore.acceleration.y = FlxG.random.int(200, 300);
				pixelScore.velocity.y -= FlxG.random.int(140, 160);
				pixelScore.velocity.x = FlxG.random.float(-5, 5);
				insert(0, pixelScore);

				new FlxTimer().start(1 / 20, function(tmr:FlxTimer)
				{
					if (numScore == null || numScore.alpha <= 0)
					{
						tmr.destroy();
						remove(pixelScore);
						return;
					}

					numScore.x = pixelScore.x;
					numScore.y = pixelScore.y;
				}, 0);
			}

			if (ClientPrefs.timeHit)
			{
				if (ratingTxt != null)
				{
					FlxTween.cancelTweensOf(ratingTxt);
					ratingTxt.destroy();
					remove(ratingTxt);
					ratingTxt = null;
				}

				ratingTxt = new FlxText(rating.x + 130, rating.y + 130, 0, CoolUtil.formatAccuracy(FlxMath.roundDecimal(noteDiff, 2)) + ' ms', 32);
				ratingTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, null, OUTLINE, FlxColor.BLACK);
				ratingTxt.color = ratingColors[daRating];
				ratingTxt.cameras = [camHUD];
				add(ratingTxt);

				FlxTween.tween(ratingTxt, {alpha: 0}, 0.2, {
					onComplete: function(twn:FlxTween)
					{
						ratingTxt.destroy();
						remove(ratingTxt);
						ratingTxt = null;
					}
				});
			}

			// if (combo >= 10 || combo == 0)
			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
		trace(combo);
		trace(seperatedScore);
	 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	// very innovative?
	private function leftMousePress(event:MouseEvent):Void
	{
		onMousePress(-4);
	}

	private function rightMousePress(event:MouseEvent):Void
	{
		onMousePress(-5);
	}

	private function leftMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-4);
	}

	private function rightMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-5);
	}

	private function onMousePress(key:Int):Void
	{
		var keyDirection:Int = getMouseFromEvent(key);
		var focusOnEnemy:Bool = cast cameraFocus;

		if (!cpuControlled && startedCountdown && !paused && keyDirection != -1)
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var possibleNotes:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				notes.forEachAlive(function(daNote:Note)
				{
					if (!strumsBlocked[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key)
						{
							possibleNotes.push(daNote);
							// notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				}, false, HITTABLE);

				if (possibleNotes.length > 20)
				{
					possibleNotes.splice(20, possibleNotes.length);
				}

				// if there is a list of notes that exists for that control
				if (possibleNotes.length > 0)
				{
					possibleNotes.sort(sortHitNotes);

					var eligible = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNotes)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligible = false;
						}

						if (possibleNotes.length > 4
							&& coolNote.hitCausesMiss
							&& coolNote.autoGenerated
							&& possibleNotes[possibleNotes.indexOf(coolNote) + 1] != null)
							continue;

						if (eligible)
						{
							goodNoteHit(coolNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}

					focusOnEnemy = pressedNotes[0].formerPress;
				}
				else
				{
					callOnLuas('onGhostTap', [key]);
					if (canMiss)
					{
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = previousTime;
			}

			var groupStrums = playerStrums;
			if (focusOnEnemy && playBothMode)
				groupStrums = opponentStrums;
			var spr:StrumNote = groupStrums.members[keyDirection];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [keyDirection]);
		}
	}

	private function onMouseRelease(key:Int):Void
	{
		var direction:Int = getMouseFromEvent(key);
		if (!cpuControlled && startedCountdown && !paused && direction != -1)
		{
			for (groupStrum in [playerStrums, opponentStrums])
			{
				var spr:StrumNote = groupStrum.members[direction];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
			callOnLuas('onKeyRelease', [direction]);
		}
		// trace('released: ' + controlArray);
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		var focusOnEnemy:Bool = cast cameraFocus;
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled
			&& startedCountdown
			&& !paused
			&& key > -1
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var possibleNotes:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				notes.forEachAlive(function(daNote:Note)
				{
					if (!strumsBlocked[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key)
						{
							possibleNotes.push(daNote);
							// notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				}, false, HITTABLE);

				if (possibleNotes.length > 8)
				{
					possibleNotes.splice(8, possibleNotes.length);
				}

				// if there is a list of notes that exists for that control
				if (possibleNotes.length > 0)
				{
					possibleNotes.sort(sortHitNotes);

					var eligible = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNotes)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligible = false;
						}

						if (eligible)
						{
							goodNoteHit(coolNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}

					focusOnEnemy = pressedNotes[0].formerPress;
				}
				else
				{
					callOnLuas('onGhostTap', [key]);
					if (canMiss)
					{
						noteMissPress(key);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = previousTime;
			}

			callOnLuas('onKeyPress', [key]);
		}
		// trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!strumsBlocked[key] && !cpuControlled && startedCountdown && !paused && key > -1)
		{
			for (groupStrum in [playerStrums, opponentStrums])
			{
				var spr:StrumNote = groupStrum.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
			callOnLuas('onKeyRelease', [key]);
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function getMouseFromEvent(pressed:Int):Int
	{
		for (i in 0...keysArray.length)
		{
			for (j in 0...keysArray[i].length)
			{
				if (pressed == keysArray[i][j])
				{
					return i;
				}
			}
		}

		return -1;
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private var pressedDirections:Array<Null<Int>> = [];

	// Hold notes (and handling strum line animation)
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i] && !strumsBlocked[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (!strumsBlocked[daNote.noteData] && daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && !daNote.tooLate
					&& !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			}, false, HITTABLE);

			for (i in 0...controlHoldArray.length)
			{
				var groupStrums = playerStrums;
				if (!cameraFocus && playBothMode)
					groupStrums = opponentStrums;
				var spr:StrumNote = groupStrums.members[i];

				if (controlHoldArray[i])
				{
					if (spr != null && spr.animation.curAnim.name != 'confirm' && spr.animation.curAnim.name != 'pressed')
					{
						if (pressedDirections[i] != -1)
						{
							spr.playAnim('confirm', true);
						}
						else
						{
							spr.playAnim('pressed');
							spr.resetAnim = 0;
						}
					}
				}
				else
				{
					if (spr != null && spr.animation.curAnim.name != 'static')
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
					pressedDirections[i] = -1;
				}
			}

			if (controlHoldArray.contains(true) && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				if (modchartObjects.exists('note${note.ID}'))
					modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}, false, HITTABLE);
		combo = 0;

		if (moraleActivated)
		{
			if (goodMoraleMulti > 5)
				goodMoraleMulti -= 4;
			else if (goodMoraleMulti > 2)
				goodMoraleMulti -= 1.125;
			else if (goodMoraleMulti > 1.25)
				goodMoraleMulti -= 0.125;
			badMoraleMulti *= 1.1;
			changeMorale(0.025);
		}

		var loss = daNote.missHealth * healthLoss;
		if (restoreActivated)
			lastHealth -= loss;
		else
			health -= loss;

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		totalPlayed++;
		RecalculateRating();
		vocals.volume = 0;

		if (!practiceMode)
			songScore -= Math.ceil(25 * MechanicManager.multiplier);

		var char:Character = boyfriend;
		if (!daNote.formerPress)
			char = dad;
		if (daNote.gfNote)
		{
			char = gf;
		}

		if (char != null && char.hasMissAnimations)
		{
			var daAlt = '';
			if (daNote.noteType == 'Alt Animation')
				daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote
		]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			noTriggerKarma = true;
			var loss = 0.05 * healthLoss;
			if (restoreActivated)
				lastHealth -= loss;
			else
				health -= loss;
			noTriggerKarma = false;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (ClientPrefs.ghostTapping)
				return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode)
				songScore -= Math.ceil(25 * MechanicManager.multiplier);
			if (!endingSong)
			{
				songMisses++;
			}

			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/

			if (boyfriend.hasMissAnimations)
			{
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if (note.gfNote)
			{
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (!note.autoGenerated)
		{
			if (MechanicManager.mechanics["hit_hp"].points > 0)
			{
				var lossHealth:Float = FlxMath.remapToRange(MechanicManager.mechanics["hit_hp"].points, 0, 20, note.hitHealth / 8.5, note.hitHealth / 1.5);
				if (note.isSustainNote)
					lossHealth /= 5;
				noTriggerKarma = true;
				if (restoreActivated)
					lastHealth = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				else
					health = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				noTriggerKarma = false;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
		{
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (camDirectionMovement)
		{
			if (!cameraFocus)
			{
				camFollowOffset.set(0, 0);
				switch (note.noteData)
				{
					case 0:
						camFollowOffset.x = -30;
					case 1:
						camFollowOffset.y = 30;
					case 2:
						camFollowOffset.y = -30;
					case 3:
						camFollowOffset.x = 30;
				}
			}
		}

		callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			var char:Character = boyfriend;
			if (!note.formerPress)
				char = dad;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (note.expectedData != -1)
				FlxTween.cancelTweensOf(note);

			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				switch (note.noteType)
				{
					case 'Hurt Note': // Hurt note
						if (char.animation.getByName('hurt') != null)
						{
							char.playAnim('hurt', true);
							char.specialAnim = true;
						}
					case 'Kill Note':
						FlxG.sound.play(Paths.sound('explosion'));
					case 'Burst Note':
						burstNote();
					case 'Sleep Note':
						sleepNote();
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					if (modchartObjects.exists('note${note.ID}'))
						modchartObjects.remove('note${note.ID}');
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			switch (note.noteType)
			{
				case 'Kill Note':
					noTriggerKarma = true;
					health -= 400;
					noTriggerKarma = false;
					FlxG.sound.play(Paths.sound('explosion'));
				case 'Restore Note':
					if (restoreActivated)
						restoreNoteHit();
			}

			camZooming = true;

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if (combo > 9999)
					combo = 9999;
			}
			if (MechanicManager.mechanics['burst_note'].points == 0 || (burstTime == null || burstTime.value < burstTime.min))
			{
				if (!restoreActivated)
					health += note.hitHealth * healthGain;
				else
					lastHealth += note.hitHealth * healthGain;
			}

			if (!note.noAnimation)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation')
					daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					char.playAnim(animToPlay + daAlt, true);
					char.holdTimer = 0;
				}

				if (note.noteType == 'Hey!')
				{
					if (char.animOffsets.exists('hey'))
					{
						char.playAnim('hey', true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				StrumPlayAnim(!note.formerPress, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				var groupStrums = playerStrums;
				if (!note.formerPress)
					groupStrums = opponentStrums;

				groupStrums.members[Math.floor(Math.abs(note.noteData))].playAnim('confirm', true);
				pressedDirections[Math.floor(Math.abs(note.noteData))] = Math.floor(Math.abs(note.noteData));
			}

			if (camDirectionMovement)
			{
				if (playBothMode || cameraFocus)
				{
					camFollowOffset.set(0, 0);
					switch (note.noteData)
					{
						case 0:
							camFollowOffset.x = -30;
						case 1:
							camFollowOffset.y = 30;
						case 2:
							camFollowOffset.y = -30;
						case 3:
							camFollowOffset.x = 30;
					}
				}
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			var indexNote = notes.members.indexOf(note);
			var callString:String = 'goodNoteHit';
			if (!note.formerPress)
				callString = 'opponentNoteHit';

			callOnLuas(callString, [indexNote, leData, leType, isSus, note.formerPress]);

			if (!note.isSustainNote)
			{
				if (modchartObjects.exists('note${note.ID}'))
					modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (!note.formerPress)
				strum = opponentStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;

	function fastCarDrive()
	{
		// trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;
	var cameraTrainOffset:Float = 0;
	var cameraTrainElapsed:Float = 0;
	var cameraTrainDirection:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.playing)
			trainSound.pan = FlxMath.remapToRange(trainSound.time, 0, trainSound.length, 1, -1);

		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		cameraTrainElapsed += FlxG.elapsed;

		if (cameraTrainElapsed > 0.02)
		{
			cameraTrainDirection = !cameraTrainDirection;
			cameraTrainElapsed = 0;
		}

		if (startedMoving)
		{
			cameraTrainOffset += (cameraTrainDirection ? 2000 : -2000) * FlxG.elapsed;
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if (gf != null)
		{
			gf.danced = false; // Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		cameraTrainOffset = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (!ClientPrefs.lowQuality)
			halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared'))
		{
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if (!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				FlxG.save.data.henchmenDeath = ++Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				else
				{
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	private var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		luckMechanicDestroy();

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

			FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, leftMousePress);
			FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
			FlxG.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMousePress);
			FlxG.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
		}

		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove)
		{
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (!isDead)
		{
			if (FlxG.timeScale == 1)
			{
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
					|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
				{
					resyncVocals();
				}
			}
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				// FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong)
		{
			if (!isCameraOnForcedPos)
				moveCameraSection(Std.int(curStep / 16));
		}
		if (curBeat % 4 == 0)
		{
			if (generatedMusic && PlayState.SONG.notes[Std.int(curBeat / 4)] != null && !endingSong)
			{
				if (MechanicManager.mechanics['restore_note'].points > 0)
				{
					if (FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['restore_note'].points, 0, 20, 0, 10)))
					{
						restoreNote();
						// trace('we\'re gonna check donations to see who activated the great reset');
					}
				}

				letterMechanic();
			}
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}

		if (!PlayState.isPixelStage)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
		}
		else
		{
			iconPixelScale.p1.set(1.2, 1.2);
			iconPixelScale.p2.set(1.2, 1.2);
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
				if (Paths.formatToSongPath(SONG.song) == 'stress')
				{
					if (curBeat >= 352)
					{
						camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
						camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
						camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
					}
				}
			case 'school':
				if (!ClientPrefs.lowQuality)
				{
					bgGirls.dance();
				}

			case 'mall':
				if (curBeat % 2 == 0)
				{
					for (snowSprite in snowSprites)
					{
						var spawnMin = FlxG.random.int(3, 12);
						var spawnMax = spawnMin + FlxG.random.int(12, 16);
						snowSprite.spawnGroup(spawnMin, spawnMax, 0.8, 1.4, 120, 360);
					}
				}

				if (!ClientPrefs.lowQuality)
				{
					upperBoppers.dance(true);
				}

				if (heyTimer <= 0)
					bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
					lightFadeShader.reset();
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		if (MechanicManager.mechanics['strum_swap'].points > 0)
		{
			if (generatedMusic && PlayState.SONG.notes[Math.floor(curBeat / 4)] != null && !endingSong)
			{
				if (wasSwapped && curBeat % 4 == 0)
				{
					swapCooldown--;
					if (swapCooldown < 0)
						swapCooldown = 0;
				}

				if (moveStrumSections[Math.floor(curBeat / 4)] != null && curBeat % 4 == 0)
				{
					if (moveStrumSections[Math.floor(curBeat / 4)] == true)
					{
						swapStrums();
					}
					else if (swapCooldown == 0 && wasSwapped)
					{
						swapStrums();
					}
				}
			}
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if (ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			if (ret != FunkinLua.Function_Continue)
				returnVal = ret;
		}
		#end
		// trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (chartingMode)
			return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length)
		{
			var achievementName:String = achievesToCheck[i];
			if (!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled)
			{
				var unlock:Bool = false;

				switch (achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if (isStoryMode
							&& campaignMisses + songMisses < 1
							&& CoolUtil.difficultyString() == 'HARD'
							&& storyPlaylist.length <= 1
							&& !changedDifficulty
							&& !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							if (achievementName == '${weekName}_nomiss')
								unlock = true;
						}
					#if debug
					case 'challenger':
						if (noteLength > 100 && ClientPrefs.safeFrames <= 2 && !usedPractice)
							unlock = true;
					#end
					case 'ur_bad':
						if (ratingPercent < 0.2 && !practiceMode)
						{
							unlock = true;
						}
					case 'ur_good':
						if (ratingPercent >= 1 && !usedPractice)
						{
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100)
						{
							unlock = true;
						}
					case 'oversinging':
						if (boyfriend.holdTimer >= 10 && !usedPractice)
						{
							unlock = true;
						}
					case 'hype':
						if (!boyfriendIdled && !usedPractice)
						{
							unlock = true;
						}
					case 'two_keys':
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length)
							{
								if (keysPressed[j])
									howManyPresses++;
							}

							if (howManyPresses <= 2)
							{
								unlock = true;
							}
						}
					case 'toastie':
						if (/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && ClientPrefs.imagesPersist == 'None')
						{
							unlock = true;
						}
					case 'debugger':
						if (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice)
						{
							unlock = true;
						}
				}

				if (unlock)
				{
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	private var karmaTmr:FlxTimer;
	private var karmaBarTmr:FlxTimer;
	private var karmaActive:Bool = false;
	private var noTriggerKarma:Bool = false; // helper variable to prevent other mechanics

	private function set_health(value:Float)
	{
		if (MechanicManager.mechanics['karma'].points > 0
			&& !noTriggerKarma
			&& value < health
			&& (value != maxHealth)
			&& !karmaActive)
		{
			if (karmaTmr != null)
			{
				karmaTmr.update(10e9 * 1000); // update by a billion seconds
				karmaTmr.cancel();
				karmaTmr = null;
			}

			if (karmaBarTmr != null)
			{
				karmaBarTmr.update(10e9 * 1000);
				karmaBarTmr.cancel();
				karmaBarTmr = null;
			}

			karmaActive = true;

			if (health - value <= 0)
			{
				return (health = value);
			}

			var difference:Float = Math.min(health - value, 0.07) / FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 10, 2.225);

			var min:Int = Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 5, 13));
			var max:Int = Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 11, 30));

			if (MechanicManager.mechanics['karma'].points >= 10)
			{
				if (min <= 3)
					min = 3;
			}

			healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), 0xFFFF00EA);
			healthBar.updateBar();

			var loop:Int = FlxG.random.int(min, max);
			karmaTmr = new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				health -= difference;
			}, loop);

			karmaBarTmr = new FlxTimer().start(0.1 * loop, function(tmr:FlxTimer)
			{
				reloadHealthBarColors();
				karmaActive = false;
			});
		}
		else
		{
			health = value;
		}

		doDeathCheck();

		return value;
	}

	private function set_maxHealth(value:Float):Float
	{
		if (playBothMode)
			value *= 2;

		maxHealth = value;

		healthBar.setRange(0, maxHealth);

		return maxHealth;
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}

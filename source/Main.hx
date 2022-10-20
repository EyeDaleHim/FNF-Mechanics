package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.system.scaleModes.*;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPSSprite;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;

class Main extends Sprite
{
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	public static var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	public static var framerate:Int = 60; // How many frames per second the game should run at.
	public static var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	public static var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPSSprite;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// Application.current.window.borderless = true;

		#if !debug
		initialState = TitleState;
		#end

		ClientPrefs.loadDefaultKeys();
		FlxG.save.bind('mechanics-mod', 'eyedalehim');

		fpsVar = new FPSSprite(10, 3, 0xFFFFFF);

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		// FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode(true, true);

		#if !mobile
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar.fps != null)
		{
			fpsVar.fps.visible = (ClientPrefs.performanceCounter != 'hide');
		}
		#end

		MultiplayerHandler.initialize();

		FlxG.console.registerClass(MechanicManager);
		FlxG.console.registerClass(Paths);
		FlxG.console.registerClass(CoolUtil);
		FlxG.console.registerClass(KeyboardMechanic);
		FlxG.console.registerClass(ScoreHandler);
		FlxG.console.registerClass(SubtitleHandler);

		/*FlxG.console.registerFunction("sendMessage", function(msg:String)
			{
				MultiplayerHandler.
		});*/

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
	}
}

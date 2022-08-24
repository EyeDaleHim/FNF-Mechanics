package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import openfl.Lib;

class PreloadState extends MusicBeatState
{
	public static final MIN_TIME:Float = 3.0;
    public var CUR_TIME:Float = 0.0;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public var logoBG:FlxSprite;

	override function create()
	{        
        FlxG.stage.application.window.x += Std.int(FlxG.width / 2);
        FlxG.stage.application.window.y += Std.int(FlxG.height / 2);
        
        FlxG.resizeGame(403, 215);
        FlxG.resizeWindow(403, 215);

        FlxG.stage.application.window.x -= Std.int(403 / 2);
        FlxG.stage.application.window.y -= Std.int(215 / 2);

        WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		ClientPrefs.loadPrefs();

		FlxG.sound.volume = ClientPrefs.defaultSave.data.volume;

		Highscore.load();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			// trace('LOADED FULLSCREEN SETTING!!');
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add(function(exitCode)
			{
				if (ClientPrefs.defaultSave != null)
					ClientPrefs.defaultSave.flush();
				FlxG.save.flush();
				DiscordClient.shutdown();
			});
		}
		#end

        logoBG = new FlxSprite().loadGraphic(Paths.image('logo'));
        add(logoBG);

		super.create();
	}

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        CUR_TIME += elapsed;

        if (CUR_TIME >= MIN_TIME + 2.0)
        {
            MusicBeatState.switchState(new TitleState());

            Main.fpsVar.fps.visible = (ClientPrefs.performanceCounter != 'hide');
        }
    }
}

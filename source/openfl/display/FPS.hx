package openfl.display;

import haxe.Timer;
import openfl.events.Event;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import openfl.display.FPSSprite;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end
import flixel.FlxGame;
import flixel.util.FlxColor;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end
import openfl.system.System;

using StringTools;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	public var curMemory:Float;
	public var maxMemory:Float;
	public var realAlpha:Float = 1;
	public var lagging:Bool = false;
	public var forceUpdateText(default, set):Bool = false;

	public var spriteParent:FPSSprite;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(getFont(Paths.font("vcr.ttf")), 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	public function getFont(Font:String):String
	{
		embedFonts = true;

		var newFontName:String = Font;

		if (Font != null)
		{
			if (Assets.exists(Font, AssetType.FONT))
			{
				newFontName = Assets.getFont(Font).fontName;
			}
		}
		return newFontName;
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if (spriteParent != null)
		{
			// spriteParent.outlineFPS = this;
			spriteParent.updateFPS(deltaTime);
		}

		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		if (!lagging)
			realAlpha = CoolUtil.boundTo(realAlpha - (deltaTime / 1000), 0.5, 1);
		else
			realAlpha = CoolUtil.boundTo(realAlpha + (deltaTime / 1000), 0.5, 1);

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.framerate)
			currentFPS = ClientPrefs.framerate;

		if (currentCount != cacheCount /*&& visible*/)
		{
			updateText();
		}

		cacheCount = currentCount;

		alpha = realAlpha;
	}

	private function set_forceUpdateText(value:Bool):Bool
	{
		updateText();
		return value;
	}

	private function updateText():Void
	{
		text = "FPS: " + currentFPS;

		var ms:Float = 1 / currentFPS;
		ms *= 1000;
		#if debug
		text += ' (${FlxMath.roundDecimal(ms, 2)}ms)';
		#end

		lagging = false;

		textColor = FlxColor.fromRGBFloat(1, 1, 1, realAlpha);
		if (currentFPS <= ClientPrefs.framerate / 2)
		{
			textColor = FlxColor.fromRGBFloat(1, 0, 0, realAlpha);
			lagging = true;
		}

		text += '\n';

		if (ClientPrefs.performanceCounter.contains('mem'))
		{
			curMemory = System.totalMemory;
			if (curMemory >= maxMemory)
				maxMemory = curMemory;
			text += 'MEM: ${CoolUtil.formatMemory(Std.int(curMemory))}';
			if (ClientPrefs.performanceCounter.contains('peak'))
				text += ' / ${CoolUtil.formatMemory(Std.int(maxMemory))}';
			text += '\n';
		}
		#if debug
		text += 'CPU: ${FlxGame.updateMS}ms\nGPU: ${FlxGame.drawMS}ms';
		text += '\nRUNTIME: ${FlxStringUtil.formatTime(currentTime / 1000)}';
		text += "\n";
		#end
	}

	public var textAfter:String = '';
}

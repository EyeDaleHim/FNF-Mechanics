package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import openfl.utils.Assets;

class MechanicPortrait extends FlxSpriteGroup
{
	public var portrait:MechanicSprite;
	public var arrowL:MechanicSprite;
	public var arrowR:MechanicSprite;
	public var text:MechanicText;

	public var data:String = '';

	public function new(x:Float, y:Float, data:String, image:String, scrollFactor:FlxPoint = null)
	{
		super(0, 0);

		if (scrollFactor == null)
			scrollFactor = new FlxPoint(0, 0);

		if (!Assets.exists(Paths.getPath('images/portraits/${image}.png', IMAGE, 'shared')))
			image = 'blank';
		portrait = new MechanicSprite(x, y);
		portrait.loadGraphic(Paths.image('portraits/${image}', 'shared'));
		portrait.antialiasing = true;
		portrait.scrollFactor.set();
		portrait.unselectedColor = 0.4;
		add(portrait);
		// portrait.x + portrait.width - 10

		arrowL = new MechanicSprite(portrait.x + 10, portrait.y + portrait.height - 60);
		arrowL.loadGraphic(Paths.image('mechanicArr', 'shared'));
		arrowL.antialiasing = true;
		arrowL.scrollFactor.set();
		add(arrowL);

		arrowL.unselectedColor = 1;
		arrowL.selectedColor = 0.7;
		arrowL.selectedScale = 1.3;
		arrowL.scaleSpeed *= 5;
		arrowL.colorSpeed *= 2;

		arrowR = new MechanicSprite(portrait.x + portrait.width - 40, portrait.y + portrait.height - 60);
		arrowR.loadGraphic(Paths.image('mechanicArr', 'shared'));
		arrowR.antialiasing = true;
		arrowR.scrollFactor.set();
		arrowR.flipX = true;
		add(arrowR);

		arrowR.unselectedColor = 1;
		arrowR.selectedColor = 0.7;
		arrowR.selectedScale = 1.3;
		arrowR.scaleSpeed *= 5;
		arrowR.colorSpeed *= 2;

		text = new MechanicText((x + portrait.width / 2) - 12, (portrait.y + portrait.height) - 55, 0, "0");
		text.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		text.antialiasing = true;
		text.scrollFactor.set();
		formerTextX = text.x;
		add(text);

		FlxMouseEventManager.add(portrait, null, null, function(spr:MechanicSprite)
		{
			spr.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			spr.isSelected = false;
		}, true);
	}

	var formerTextX:Float = 0;

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (MechanicManager.mechanics.exists(data))
			text.text = '' + MechanicManager.mechanics[data].points;

		text.x = formerTextX;
		if (text.text.length == 2)
			text.x -= 14;

		if (MechanicManager.mechanics.exists(data))
		{
			arrowL.points = MechanicManager.mechanics[data].points;
			arrowR.points = MechanicManager.mechanics[data].points;

			if (MechanicManager.mechanics[data].points != 0)
				portrait.unselectedColor = 0.8;
			else
				portrait.unselectedColor = 0.4;
		}
	}
}

class MechanicText extends FlxText
{
	public var value:Int = 0;

	override function update(elapsed:Float)
	{
		var newColor:FlxColor = cast color;
		
		newColor.red = Math.floor(FlxMath.lerp(newColor.red, FlxMath.remapToRange(value, 0, 20, 255, 195), elapsed * 24));
		newColor.blue = Math.floor(FlxMath.lerp(newColor.blue, FlxMath.remapToRange(value, 0, 20, 255, 25), elapsed * 24));
		newColor.green = Math.floor(FlxMath.lerp(newColor.green, FlxMath.remapToRange(value, 0, 20, 255, 35), elapsed * 24));

		this.color = newColor;

		super.update(elapsed);
	}

	override function set_text(Text:String):String
	{
		value = Std.parseInt(Text);
		
		return super.set_text(Text);
	}
}

class MechanicSprite extends FlxSprite
{
	public var unselectedColor:Float = 0;
	public var selectedColor:Float = 1;

	public var unselectedScale:Float = 1;
	public var selectedScale:Float = 1;
	public var isSelected:Bool = false;

	public var colorSpeed:Float = 3.1;
	public var scaleSpeed:Float = 2.5;

	public var holding:Bool = false;
	public var holdFunction:Void->Void;
	public var forceStop:Bool = false;

	public var points:Int = -1;

	var _firstFrame:Bool = true;
	var _timerHold:FlxTimer = null;
	var _timerValue:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (_firstFrame)
		{
			if (isSelected)
			{
				setColorTransform(selectedColor, selectedColor, selectedColor);
				scale.set(selectedScale);
			}
			else
			{
				setColorTransform(unselectedColor, unselectedColor, unselectedColor);
				scale.set(unselectedScale);
			}
			_firstFrame = false;
			return;
		}

		if (holding && FlxG.mouse.pressed)
		{
			if (_timerValue >= 0.5)
			{
				_timerValue = 0.5;
				if (_timerHold == null)
				{
					_timerHold = new FlxTimer().start(0.06, function(tmr:FlxTimer)
					{
						if ((holdFunction == null || !FlxG.mouse.pressed) || !isSelected)
						{
							tmr.active = false;
							forceStop = true;
							return;
						}

						if ((!flipX && points == 0) || (flipX && points == 20)) // bruh
						{
							tmr.active = false;
							forceStop = true;
							return;
						}


						holdFunction();
					}, 0);
				}
			}
			else
			{
				_timerValue += elapsed;
			}
		}
		else if (!FlxG.mouse.pressed && holding || forceStop)
		{
			_timerValue = 0;
			_timerHold = null;
			holding = false;
			forceStop = false;
		}

		if (!isSelected)
		{
			colorTransform.redMultiplier = FlxMath.lerp(colorTransform.redMultiplier, unselectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));
			colorTransform.blueMultiplier = FlxMath.lerp(colorTransform.blueMultiplier, unselectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));
			colorTransform.greenMultiplier = FlxMath.lerp(colorTransform.greenMultiplier, unselectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));

			var lerpScale:Float = FlxMath.lerp(scale.x, unselectedScale, CoolUtil.boundTo(elapsed * scaleSpeed, 0, 1));

			scale.x = lerpScale;
			scale.y = lerpScale;
		}
		else
		{
			colorTransform.redMultiplier = FlxMath.lerp(colorTransform.redMultiplier, selectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));
			colorTransform.blueMultiplier = FlxMath.lerp(colorTransform.blueMultiplier, selectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));
			colorTransform.greenMultiplier = FlxMath.lerp(colorTransform.greenMultiplier, selectedColor, CoolUtil.boundTo(elapsed * colorSpeed, 0, 1));

			var lerpScale:Float = FlxMath.lerp(scale.x, selectedScale, CoolUtil.boundTo(elapsed * scaleSpeed, 0, 1));

			scale.x = lerpScale;
			scale.y = lerpScale;
		}
	}
}

package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;

class MechanicTooltip extends FlxTypedGroup<FlxSprite>
{
	public static var offset:{x:Float, y:Float} = {x: 0, y: 0};

	public var title:String;
	public var description:String;

	public var titleText:TooltipText;
	public var descriptionText:TooltipText;
	public var baseBG:TooltipSprite;
	public var titleBG:TooltipSprite;

	public var position:FlxPoint = new FlxPoint(-1, -1);
	public var scrollFactor(default, set):FlxPoint = new FlxPoint(1, 1);

	public override function new(x:Float, y:Float, width:Float, height:Float, title:String, description:String)
	{
		super();

		this.title = title;
		this.description = description;
		this.position.set(x, y);

		var RWidth:Int = Math.ceil(width);
		var RHeight:Int = Math.ceil(height);
		var SColor:Int = FlxColor.fromRGBFloat(255, 255, 255, 0.4);

		// stupid references
		baseBG = new TooltipSprite(x, y - 20);
		baseBG.makeGraphic(RWidth, RHeight, SColor);
		baseBG.scrollFactor.set(0, 0.4);

		titleBG = new TooltipSprite(x, y - 20);
		titleBG.makeGraphic(RWidth, Math.ceil(RHeight * 0.2), SColor);
		titleBG.scrollFactor.set(0, 0.4);

		titleText = new TooltipText(x + 2, y + 22, 0, title, Math.ceil(titleBG.height / 2));
		titleText.scrollFactor.set(0, 0.4);
		titleText.setFormat(Paths.font("vcr.ttf"), titleText.size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.x = titleBG.getGraphicMidpoint().x - (titleText.width / 2);
		titleText.borderSize = 2;
		titleText.antialiasing = true;
		add(titleText);

		descriptionText = new TooltipText(x + 6, y + titleBG.height + 4, baseBG.width, description, 20);
		descriptionText.scrollFactor.set(0, 0.4);
		descriptionText.setFormat(Paths.font("vcr.ttf"), descriptionText.size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		descriptionText.antialiasing = true;
		descriptionText.borderSize = 2;
		add(descriptionText);

		titleText.y -= 140;
		descriptionText.y -= 140;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (member in members)
		{
			if (member != null)
			{
				var coolMember:TooltipSprite;
				var mem:Dynamic = member; // TooltipText extends FlxSprite, and the group accepts FlxSprite, win-win

				coolMember = mem;

				if (coolMember != null)
				{
					coolMember.tooltipPosition.x = position.x;
					coolMember.tooltipPosition.y = position.y;
				}
			}
		}
	}

	function set_scrollFactor(newValue:FlxPoint):FlxPoint
	{
		scrollFactor = newValue;

		baseBG.scrollFactor.set(newValue.x, newValue.y);
		titleBG.scrollFactor.set(newValue.x, newValue.y);
		titleText.scrollFactor.set(newValue.x, newValue.y);
		descriptionText.scrollFactor.set(newValue.x, newValue.y);

		return newValue;
	}
}

class TooltipSprite extends FlxSprite
{
	public var tooltipPosition:{x:Float, y:Float} = {x: 0, y: 0};
	public var actualPosition:{x:Float, y:Float} = {x: 0, y: 0};

	public override function new(x:Float, y:Float)
	{
		super(x, y);

		this.actualPosition.x = x;
		this.actualPosition.y = y;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		x = actualPosition.x + tooltipPosition.x;
		y = actualPosition.y + tooltipPosition.y;
	}
}

class TooltipText extends FlxText
{
	public var tooltipPosition:{x:Float, y:Float} = {x: 0, y: 0};
	public var actualPosition:{x:Float, y:Float} = {x: 0, y: 0};

	public override function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);

		this.actualPosition.x = X;
		this.actualPosition.y = Y;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		x = actualPosition.x + tooltipPosition.x;
		y = actualPosition.y + tooltipPosition.y;
	}
}

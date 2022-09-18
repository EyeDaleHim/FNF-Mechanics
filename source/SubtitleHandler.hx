package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

class SubtitleHandler
{
	// If the camera = null, just creates another camera anyways.
	public static var camera = null;

	public static var subtitleList:Array<SubtitleSprite> = [];

	// Adds a subtitle to the list
	public static function addSub(subtitle:String, duration:Float = 5.0)
	{
		if (camera == null)
		{
			camera = new FlxCamera();
			camera.bgColor.alpha = 0;
			FlxG.cameras.add(camera);
		}

		var subSprite:SubtitleSprite = new SubtitleSprite(subtitle, duration);
		subSprite.subBG.screenCenter();
		subSprite.subText.screenCenter();

		subSprite.subBG.y = subSprite.subText.y = FlxG.height * 0.85;
		subtitleList.unshift(subSprite);

		for (sub in subtitleList)
			sub.ID = subtitleList.indexOf(sub);

		for (sub in subtitleList)
		{
			if (sub != null)
			{
				if (sub.ID != 0)
				{
					sub.lerpTo = subtitleList[sub.ID - 1].subBG.y - sub.subBG.height - 8;
					sub.lerpValue = 0.0;
				}
			}
		}

		FlxG.state.add(subSprite);
	}

	// Called if the state is destroyed
	public static function destroy()
	{
		camera = null;
		FlxDestroyUtil.destroyArray(subtitleList);
		subtitleList = [];
	}
}

class SubtitleSprite extends FlxTypedGroup<FlxSprite>
{
	public var lifeTime:Float = -0.2; // -0.2 because we have to give them a fade-in
	public var killTime:Float = 5.0;

	public var willKill:Bool = false;

	public var subBG:FlxSprite;
	public var subText:FlxText;

	public var lerpValue:Float = 1.0;
	public var lerpFrom:Float = FlxG.height * 0.85;
	public var lerpTo:Float = FlxG.height * 0.85;

	override public function new(text:String, durationTime:Float = 5.0)
	{
		super();

		// can't go below 0.2
		killTime = Math.max(0.2, durationTime);

		subText = new FlxText(0, 0, 0, text, 24);
		subText.setFormat(Paths.font("vcr.ttf"), 24);
		subText.alpha = 0.0;
		subText.cameras = [SubtitleHandler.camera];

		var bfFormat:FlxTextFormat = new FlxTextFormat(FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0],
			PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]),
			false, false, 0x00000000);

		var dadFormat:FlxTextFormat = new FlxTextFormat(FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0],
			PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]),
			false, false, 0x00000000);

		var gfFormat:FlxTextFormat = new FlxTextFormat(FlxColor.fromRGB(PlayState.instance.gf.healthColorArray[0],
			PlayState.instance.gf.healthColorArray[1], PlayState.instance.gf.healthColorArray[2]),
			false, false, 0x00000000);

		subText.applyMarkup(text, [new FlxTextFormatMarkerPair(bfFormat, '<bf>'), new FlxTextFormatMarkerPair(gfFormat, '<gf>'), new FlxTextFormatMarkerPair(dadFormat, '<dad>')]);

		subBG = new FlxSprite().makeGraphic(Math.floor(subText.width + 8), Math.floor(subText.height + 8), FlxColor.BLACK);
		subBG.alpha = 0.0;
		subBG.cameras = [SubtitleHandler.camera];

		add(subBG);
		add(subText);

		FlxTween.tween(subText, {alpha: 1.0}, 0.2, {
			ease: FlxEase.quadOut,
			onUpdate: function(twn:FlxTween)
			{
				subBG.alpha = subText.alpha * 0.6;
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((willKill = ((lifeTime += elapsed) >= killTime)))
		{
			subText.alpha -= elapsed * 1.6;
			subBG.alpha = subText.alpha * 0.6;
		}

		if ((lerpValue += elapsed * 6.0) >= 1.0)
		{
			lerpValue = 1.0;

			lerpFrom = lerpTo;
		}
		else
		{
			subBG.y = subText.y = FlxMath.lerp(lerpFrom, lerpTo, lerpValue);
		}

		if (subText.alpha <= 0)
		{
			FlxTween.cancelTweensOf(subText);
			FlxTween.cancelTweensOf(subBG);

			destroy();

			FlxDestroyUtil.destroy(subText);
			FlxDestroyUtil.destroy(subBG);

			SubtitleHandler.subtitleList.remove(this);
		}
	}
}

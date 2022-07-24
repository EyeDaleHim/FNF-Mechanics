package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:Dynamic, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false)
	{
		super(x, y);

		if (Std.isOfType(image, String))
		{
			if (animArray != null)
			{
				frames = Paths.getSparrowAtlas(image);
				for (i in 0...animArray.length)
				{
					var anim:String = animArray[i];
					animation.addByPrefix(anim, anim, 24, loop);
					if (idleAnim == null)
					{
						idleAnim = anim;
						animation.play(anim);
					}
				}
			}
			else
			{
				if (image != null)
				{
					loadGraphic(Paths.image(cast(image, String)));
				}
				active = false;
			}
		}
		else if (Std.isOfType(image, Array))
		{
			if (animArray != null)
			{
				frames = Paths.getSparrowAtlas(cast(image[0], String), cast(image[1], String));
				for (i in 0...animArray.length)
				{
					var anim:String = animArray[i];
					animation.addByPrefix(anim, anim, 24, loop);
					if (idleAnim == null)
					{
						idleAnim = anim;
						animation.play(anim);
					}
				}
			}
			else
			{
				if (image != null)
				{
					loadGraphic(Paths.image(cast(image[0], String), cast(image[1], String)));
				}
				active = false;
			}
		}
		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function dance(?forceplay:Bool = false)
	{
		if (idleAnim != null)
		{
			animation.play(idleAnim, forceplay);
		}
	}
}

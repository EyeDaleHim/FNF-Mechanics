package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxDirection;

class Shape extends FlxSprite
{
	public static var _fileRef:Map<String, String> = ['square' => 'yellow', 'triangle' => 'red', 'pentagon' => 'blue'];
	public var allowCollision:Bool = false;

	public function new(spawnFrom:FlxDirection, shape:String)
	{
		super();

		var decidedX:Float;
		var decidedY:Float;

		switch (spawnFrom)
		{
			case LEFT:
				decidedX = -FlxG.random.float(10, 30);
				decidedY = FlxG.random.float(0, FlxG.height);
			case DOWN:
				decidedX = FlxG.random.float(0, FlxG.width);
				decidedY = FlxG.height + FlxG.random.float(10, 30);
			case UP:
				decidedX = FlxG.random.float(0, FlxG.width);
				decidedY = -FlxG.random.float(10, 30);
			case RIGHT:
				decidedX = FlxG.width + FlxG.random.float(10, 30);
				decidedY = FlxG.random.float(0, FlxG.height);
			default:
				decidedX = decidedY = 0;
		}

		if (_fileRef.exists(shape))
			loadGraphic(Paths.image('shape_${_fileRef.get(shape)}', 'shared'));
		else
			loadGraphic(Paths.image('shape_yellow', 'shared'));

		switch (spawnFrom)
		{
			case LEFT:
				decidedX -= width;
			case DOWN:
				decidedY += height;
			case UP:
				decidedY -= height;
			case RIGHT:
				decidedX += width;
			default:
                //
		}
		
		var cappedPoints:Float = MechanicManager.mechanics['shape_obst'].points;
		if (cappedPoints >= 1000)
			cappedPoints = 1000;

		setPosition(decidedX, decidedY);

		// chance for min to be above max, but that's fine
		lifeTime = FlxG.random.float(FlxMath.remapToRange(cappedPoints, 1, 20, 6, 40) * FlxG.random.float(1, 1.6) / 2,
			FlxMath.remapToRange(cappedPoints, 1, 20, 23, 93) * FlxG.random.float(1, 1.6) * 1.5) * 1.2;

		// i know this is strange but i didn't wanna have a nightmarish crap there
		switch (spawnFrom)
		{
			case LEFT:
                velocity.x += FlxG.random.float(20, 35);
                velocity.y += FlxG.random.float(-3, 3);
            case DOWN:
                velocity.y -= FlxG.random.float(20, 35);
                velocity.x += FlxG.random.float(-3, 3);
			case UP:
				velocity.y += FlxG.random.float(20, 35);
                velocity.x += FlxG.random.float(-3, 3);
            case RIGHT:
                velocity.x -= FlxG.random.float(20, 35);
                velocity.y += FlxG.random.float(-3, 3);
			default:
                //
		}

        angularVelocity += FlxG.random.float(-25, 25);

		allowCollision = FlxG.random.bool(25);
	}

	public var lifeTime:Float = 0;
	public var triggerDeath:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		lifeTime -= elapsed;

		if (lifeTime <= 0 && !triggerDeath)
		{
			triggerDeath = true;
			FlxTween.tween(this, {alpha: 0}, 0.35, {
				ease: FlxEase.quintOut,
				onComplete: function(twn:FlxTween)
				{
					kill();
				}
			});
		}
		if (triggerDeath && alive)
			scale.set(Math.min(scale.x + elapsed, 3), Math.min(scale.y + elapsed, 3));

        centerOffsets();
        centerOrigin();
        updateHitbox();
	}
}

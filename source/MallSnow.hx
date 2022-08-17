package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import noisehx.Perlin;

class MallSnow extends FlxTypedGroup<SnowSprite>
{
	public var spawnPosition:SpawnPosition;
	public var scrollFactor:FlxPoint = FlxPoint.get(1, 1);
    public var scaleFactor:Float = 0;
	public var antialiasing:Bool = true;

	public override function new(spawnPos:SpawnPosition)
	{
		this.spawnPosition = spawnPos;

		super();

		SnowSprite.perlin = new Perlin();

		spawnGroup(FlxG.random.int(3, 6), FlxG.random.int(9, 16), 0.8, 1.4, 120, 360);

		for (member in members)
		{
			if (member != null)
			{
				member.update(2);
			}
		}
	}

	override function update(elapsed:Float)
	{
		for (member in members)
		{
			if (member != null)
			{
				if (!member.alive)
				{
					remove(member);
					member.destroy();
				}
                else if (members.indexOf(member) > 128 || member.y > 900) // y = 900 is the limit of where we see our little ones
                    member.lifeTime = 0;
			}
		}

		super.update(elapsed);
	}

	public function spawnGroup(spawnMin:Int, spawnMax:Int, scaleMin:Float, scaleMax:Float, speedMin:Float, speedMax:Float)
	{
		var spawnedValues:Int = FlxG.random.int(spawnMin, spawnMax);

		for (i in 0...spawnedValues)
		{
			if (FlxG.random.bool(100 / 3))
			{
				var snowSprite = recycle(SnowSprite);
				snowSprite.totalElapsed = 0;
				snowSprite.lifeTime = FlxG.random.float(4, 16);
				snowSprite.scrollFactor.set(scrollFactor.x, scrollFactor.y);
				snowSprite.antialiasing = antialiasing;
				snowSprite.angle = FlxG.random.float(-90, 90);
				snowSprite.startScale = FlxG.random.float(scaleMin + scaleFactor, scaleMax + scaleFactor);
				snowSprite.velocity.y = FlxG.random.float(speedMin, speedMax);
				snowSprite.scale.set(snowSprite.startScale, snowSprite.startScale);
				snowSprite.x = FlxG.random.float(spawnPosition.x, spawnPosition.x + spawnPosition.width);
				snowSprite.y = FlxG.random.float(spawnPosition.y, spawnPosition.y + spawnPosition.height);
				add(snowSprite);
			}
		}
	}
}

class SnowSprite extends FlxSprite
{
	public static var perlin:Perlin;
	public var lifeTime:Float;
	public var startScale:Float = 1.0;
	public var totalElapsed:Float = 0;

	public override function new(?x:Float, ?y:Float)
	{
		super(x, y);

		loadGraphic(Paths.image('christmas/snowParticle', 'week5'));
		lifeTime = FlxG.random.float(4, 16);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		totalElapsed += elapsed;

		velocity.x = perlin.noise2d(totalElapsed, 0) * 60;

		if (lifeTime <= 0)
		{
			scale.set(scale.x - (elapsed * 0.8), scale.y - (elapsed * 0.8));
			alpha = FlxMath.remapToRange(scale.x, 0.1, startScale, 0, 1);
			if (scale.x <= 0)
				scale.x = 0;
			if (scale.y <= 0)
				scale.y = 0;
		}
		else
		{
			lifeTime -= elapsed;
		}

		if (alpha <= 0 && (scale.x <= 0 && scale.y <= 0))
			kill();
	}
}

typedef SpawnPosition =
{
	var x:Float;
	var y:Float;
	var width:Float;
	var height:Float;
}

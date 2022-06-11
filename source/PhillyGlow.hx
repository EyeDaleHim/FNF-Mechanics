import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxPoint;

class PhillyGlowParticle extends FlxSprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;
	var originalScale:Float = 1;
	var originalVelocity:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, color:FlxColor)
	{
		super(x, y);
		this.color = color;

		loadGraphic(Paths.image('philly/particle'));
		antialiasing = ClientPrefs.globalAntialiasing;
		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);

		originalScale = FlxG.random.float(0.75, 1);
		scale.set(originalScale, originalScale);

		scrollFactor.set(FlxG.random.float(0.3, 0.75), FlxG.random.float(0.65, 0.75));
		originalVelocity.set(FlxG.random.float(-40, 40), FlxG.random.float(-175, -250));
		velocity.set(originalVelocity.x, originalVelocity.y);
		acceleration.set(FlxG.random.float(-10, 10), 25);
	}

	override function update(elapsed:Float)
	{
		lifeTime -= elapsed;
		if (lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed;
			if(alpha > 0)
			{
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}

		velocity.set(originalVelocity.x - (velocityBeatOffset * 0.1), originalVelocity.y - (velocityBeatOffset * 2));

		if (velocityBeatOffset < 0)
			velocityBeatOffset = 0;
		else
			velocityBeatOffset -= elapsed * 5;

		super.update(elapsed);
	}

	var velocityBeatOffset:Float = 0;

	public function beatHit():Void
	{
		velocityBeatOffset = CoolUtil.boundTo(velocityBeatOffset + 140, 0, 300);
	}
}

class PhillyGlowGradient extends FlxSprite
{
	public var originalY:Float;
	public var originalHeight:Int = 400;
	public function new(x:Float, y:Float)
	{
		super(x, y);
		originalY = y;

		loadGraphic(Paths.image('philly/gradient'));
		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set(0, 0.75);
		setGraphicSize(2000, originalHeight);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		var newHeight:Int = Math.round(height - 1000 * elapsed);
		if(newHeight > 0)
		{
			alpha = 1;
			setGraphicSize(2000, newHeight);
			updateHitbox();
			y = originalY + (originalHeight - height);
		}
		else
		{
			alpha = 0;
			y = -5000;
		}

		super.update(elapsed);
	}

	public function bop()
	{
		setGraphicSize(2000, originalHeight);
		updateHitbox();
		y = originalY;
		alpha = 1;
	}
}
package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.particles.FlxEmitter;

class VictorySubstate extends MusicBeatSubstate
{
	public var emit:FlxEmitter;

	public var scoreTitle:Alphabet;
	public var missTitle:Alphabet;
	public var accuracyTitle:Alphabet;

	public var scoreGroup:FlxTypedGroup<FlxSprite>;
	public var missGroup:FlxTypedGroup<FlxSprite>;
	public var accuracyGroup:FlxTypedGroup<FlxSprite>;

	public var background:FlxSprite;

	public function new()
	{
		super();

		background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0.2;
		background.scrollFactor.set();
		add(background);

		scoreTitle = new Alphabet(0, 40, "SCORE", true, false, 0, 0.9);
		scoreTitle.x = 10;
		scoreTitle.scrollFactor.set();
		add(scoreTitle);

		missTitle = new Alphabet(0, 240, "MISSES", true, false, 0, 0.9);
		missTitle.x = 10;
		missTitle.scrollFactor.set();
		add(missTitle);

		accuracyTitle = new Alphabet(0, 440, "ACCURACY", true, false, 0, 0.9);
		accuracyTitle.x = 10;
		accuracyTitle.scrollFactor.set();
		add(accuracyTitle);

		scoreGroup = new FlxTypedGroup<FlxSprite>();
		add(scoreGroup);

		missGroup = new FlxTypedGroup<FlxSprite>();
		add(missGroup);

		accuracyGroup = new FlxTypedGroup<FlxSprite>();
		add(accuracyGroup);

		var scoreConvert:(String, Int)->Array<String> = function(s:String, l:Int)
		{
			var scoreText:Array<String> = [];
			for (i in 0...Std.string(s).length)
			{
				scoreText.push(Std.string(s).charAt(i));
			}
			while (scoreText.length < l)
				scoreText.unshift('0');
			return scoreText;
		}

		var missConvert:(String, Int)->Array<String> = function(s:String, l:Int)
		{
			var missText:Array<String> = [];
			for (i in 0...Std.string(s).length)
			{
				missText.push(Std.string(s).charAt(i));
			}

			while (missText.length < l)
				missText.unshift('0');

			return missText;
		}

		var accuracyConvert:(String, Int)->Array<String> = function(s:String, l:Int)
		{
			var accuracyText:Array<String> = [];
			var value:Float = CoolUtil.floorDecimal(PlayState.instance.ratingPercent * 100, 2);
			if (value <= 0)
				value = 0;

			var accuracy:String = CoolUtil.formatAccuracy(value);
			for (i in 0...accuracy.length)
			{
				accuracyText.push(accuracy.charAt(i));
			}

			accuracyText.push('%');

			return accuracyText;
		}

		updateGroup(scoreGroup, 120, [
			for (i in 0...Std.int(Math.max(scoreConvert(Std.string(PlayState.instance.songScore), 5).length, 5)))
				'0'
		]);
		updateGroup(missGroup, 310, [
			for (i in 0...Std.int(Math.max(missConvert(Std.string(PlayState.instance.songMisses), 2).length, 2)))
				'0'
		]);
		updateGroup(accuracyGroup, 520, ['0', '.', '0', '0', '%']);

		var groupAppear:Array<
			{
				group:FlxTypedGroup<FlxSprite>,
				yPos:Float,
				lerpTo:Float,
				convert:(String, Int)->Array<String>,
				length:Int
			}> = [
				{
					group: scoreGroup,
					yPos: 120,
					lerpTo: PlayState.instance.songScore,
					convert: scoreConvert,
					length: 5
				},
				{
					group: missGroup,
					yPos: 310,
					lerpTo: PlayState.instance.songMisses,
					convert: missConvert,
					length: 2
				},
				{
					group: accuracyGroup,
					yPos: 520,
					lerpTo: CoolUtil.floorDecimal(PlayState.instance.ratingPercent * 100, 2),
					convert: accuracyConvert,
					length: 0
				}
			];
		var index:Int = 0;

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			if (groupAppear[index] != null)
			{
				if (groupAppear[index].lerpTo == 0)
					index++;
				
				FlxTween.num(0, groupAppear[index].lerpTo, 1.5, {
					ease: FlxEase.linear,
					onStart: function(twn:FlxTween)
					{
						new FlxTimer().start(0.025, function(tmr:FlxTimer)
						{
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}, 60);
					},
					onComplete: function(twn:FlxTween)
					{
						FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
						index++;
					}
				}, function(v:Float)
				{
					updateGroup(groupAppear[index].group, groupAppear[index].yPos, groupAppear[index].convert(Std.string(v), groupAppear[index].length));
				});
			}
		}, groupAppear.length - 1);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		for (member in members)
		{
			if (Std.isOfType(member, FlxSprite))
			{
				var sprite:FlxSprite = cast(member, FlxSprite);

				var formerAlpha:Float = sprite.alpha;
				sprite.alpha = 0;
				FlxTween.tween(sprite, {alpha: formerAlpha}, 0.5, {ease: FlxEase.quadOut});
			}
			else if (Std.isOfType(member, SpriteGroup))
			{
				var group:FlxTypedGroup<FlxSprite> = cast member; // wish i could make the casting safe here

				group.forEach(function(sprite:FlxSprite)
				{
					var formerAlpha:Float = sprite.alpha;
					sprite.alpha = 0;
					FlxTween.tween(sprite, {alpha: formerAlpha}, 0.5, {ease: FlxEase.quadOut});
				});
			}
		}
	}

	private var camTmr:FlxTimer;

	override public function update(elapsed:Float)
	{
		if (controls.UI_RIGHT)
			close();

		super.update(elapsed);
	}

	override public function destroy()
	{
		camTmr.destroy();

		super.destroy();
	}

	private function updateGroup(group:FlxTypedGroup<FlxSprite>, numY:Float, text:Array<String>)
	{
		while ((group != null && group.members != null) && group.members.length > 0)
			group.remove(group.members[0], true);

		if (group == null)
			return;

		var sprPosition:Array<Null<Float>> = [];

		for (idx in 0...text.length)
		{
			var numX:Float = 10;
			if (sprPosition[idx - 1] != null)
				numX = sprPosition[idx - 1];
			var numSprite:FlxSprite;
			switch (text[idx])
			{
				case '.':
					numSprite = new FlxSprite(numX, numY).loadGraphic(Paths.image('period'));
					numSprite.scale.set(0.6, 0.6);
					numSprite.updateHitbox();
					numSprite.setPosition(numX, numY);
					numSprite.antialiasing = ClientPrefs.globalAntialiasing;
					numSprite.scrollFactor.set();
					group.add(numSprite);
				case '%':
					numSprite = new FlxSprite(numX, numY).loadGraphic(Paths.image('percentage'));
					numSprite.scale.set(0.6, 0.6);
					numSprite.updateHitbox();
					numSprite.setPosition(numX, numY);
					numSprite.antialiasing = ClientPrefs.globalAntialiasing;
					numSprite.scrollFactor.set();
					group.add(numSprite);
				default:
					numSprite = new FlxSprite(numX, numY).loadGraphic(Paths.image('num${text[idx]}'));
					numSprite.scale.set(0.6, 0.6);
					numSprite.updateHitbox();
					numSprite.setPosition(numX, numY);
					numSprite.antialiasing = ClientPrefs.globalAntialiasing;
					numSprite.scrollFactor.set();
					group.add(numSprite);
			}

			sprPosition[idx] = numSprite.x + numSprite.width;
		}
	}
}

// a way to shut up haxe from telling me shit
typedef SpriteGroup = FlxTypedGroup<FlxSprite>;

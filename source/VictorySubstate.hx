package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
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

	public var acceptButton:Alphabet;

	// damage text
	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;
	public var damageText:FlxText;
	public var titleText:FlxText;
	public var infoText:FlxText;

	public var curSelected:Int = 0;
	public var selectAccept:Bool = false;

	private var finishCallback:Void->Void = null;

	private var groupAppear:Array<
		{
			group:FlxTypedGroup<FlxSprite>,
			yPos:Float,
			lerpTo:Float,
			convert:(String, Int) -> Array<String>,
			length:Int
		}> = null;

	private var mechanicsEnabled:Bool = false;

	public function new(finishCallback:Void->Void = null)
	{
		super();

		this.finishCallback = finishCallback;

		mechanicsEnabled = MechanicManager.multiplier > 1;

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

		acceptButton = new Alphabet(0, 720, (PlayState.storyPlaylist.length != 0 ? "NEXT SONG" : (PlayState.isStoryMode ? "STORY MENU" : "FREEPLAY MENU")),
			true, false, 0, 0.9);
		acceptButton.setPosition(FlxG.width - acceptButton.width - 4, FlxG.height - acceptButton.height - 4);
		acceptButton.scrollFactor.set();
		acceptButton.alpha = 0.0;
		add(acceptButton);

		leftArrow = new FlxSprite();
		leftArrow.loadGraphic(Paths.image('mechanicArr', 'shared'));
		leftArrow.scale.set(1.3, 1.3);
		leftArrow.setPosition(920, 510);
		leftArrow.antialiasing = true;
		leftArrow.scrollFactor.set();
		leftArrow.updateHitbox();
		add(leftArrow);

		rightArrow = new FlxSprite();
		rightArrow.loadGraphic(Paths.image('mechanicArr', 'shared'));
		rightArrow.scale.set(1.3, 1.3);
		rightArrow.setPosition(1100, 510);
		rightArrow.antialiasing = true;
		rightArrow.scrollFactor.set();
		rightArrow.updateHitbox();
		rightArrow.flipX = true;
		add(rightArrow);

		var firstResult:PlayState.MechanicResults = {name: '', text: '', value: 0};
		if (PlayState.instance.mechanicsResult[0] != null)
			firstResult = PlayState.instance.mechanicsResult[0];

		titleText = new FlxText(0, 0, 0, firstResult.name, 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 1.75;
		titleText.antialiasing = true;
		titleText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (titleText.width / 2), 460);
		add(titleText);

		damageText = new FlxText(0, 0, 0, CoolUtil.flattenNumber(firstResult.value), 56);
		damageText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		damageText.borderSize = 1.75;
		damageText.antialiasing = true;
		damageText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (damageText.width / 2), leftArrow.y);
		add(damageText);

		infoText = new FlxText(0, 0, 0, firstResult.text, 24);
		infoText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 1.75;
		infoText.antialiasing = true;
		infoText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (infoText.width / 2), leftArrow.y + leftArrow.height + 12);
		add(infoText);

		if (!mechanicsEnabled)
		{
			leftArrow.visible = false;
			rightArrow.visible = false;
			titleText.visible = false;
			damageText.visible = false;
			infoText.visible = false;
		}

		var scoreConvert:(String, Int) -> Array<String> = function(s:String, l:Int)
		{
			var scoreText:Array<String> = [];
			for (i in 0...Std.string(s).length)
			{
				if (Std.string(s).charAt(i) == '.')
					break;
				scoreText.push(Std.string(s).charAt(i));
			}
			while (scoreText.length < l)
				scoreText.unshift('0');
			return scoreText;
		}

		var missConvert:(String, Int) -> Array<String> = function(s:String, l:Int)
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

		var accuracyConvert:(String, Int) -> Array<String> = function(s:String, l:Int)
		{
			var accuracyText:Array<String> = [];

			// idk how to do it with strings
			if (s.split('.')[1].length > 2)
				s = s.substring(0, s.indexOf('.') + 2);

			for (i in 0...Std.string(s).length)
			{
				accuracyText.push(Std.string(s).charAt(i));
			}

			accuracyText.push('%');

			return accuracyText;
		}

		groupAppear = [
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

		updateGroup(scoreGroup, 120, [
			for (i in 0...Std.int(Math.max(scoreConvert(Std.string(PlayState.instance.songScore), 5).length, 5)))
				'0'
		]);
		updateGroup(missGroup, 310, [
			for (i in 0...Std.int(Math.max(missConvert(Std.string(PlayState.instance.songMisses), 2).length, 2)))
				'0'
		]);
		updateGroup(accuracyGroup, 520, ['0', '.', '0', '0', '%']);

		var index:Int = 0;

		(animTmr = new FlxTimer()).start(2, function(bTmr:FlxTimer)
		{
			if (groupAppear[index] != null)
			{
				if (groupAppear[index].lerpTo <= 0)
					index++;

				currentTween = (FlxTween.num(0, groupAppear[index].lerpTo, 1.5, {
					ease: FlxEase.linear,
					onStart: function(twn:FlxTween)
					{
						startedAnim = true;

						var loops:Int = 60;

						if (index == groupAppear.length - 2)
							loops = Std.int(Math.min(60, PlayState.instance.songMisses));
						new FlxTimer().start(0.025, function(tmr:FlxTimer)
						{
							if (finishedAnim)
							{
								tmr.cancel();
								return;
							}

							if (index == groupAppear.length - 2)
							{
								var remapped:Float = FlxMath.remapToRange(60 - tmr.loopsLeft, 0, 60, 0, PlayState.instance.songMisses);

								updateGroup(groupAppear[index].group, groupAppear[index].yPos,
									groupAppear[index].convert(Std.string(Math.floor(remapped)), groupAppear[index].length));
							}

							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}, loops);
					},
					onComplete: function(twn:FlxTween)
					{
						currentTween = null;

						FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
						index++;
						if (index == bTmr.loops + 1)
							finishedAnim = true;
					}
				}, function(v:Float)
				{
					if (index != groupAppear.length - 2)
					{
						if (index == groupAppear.length - 1) // accuracy
							updateGroup(groupAppear[index].group, groupAppear[index].yPos,
								groupAppear[index].convert(Std.string(CoolUtil.formatAccuracy(v)), groupAppear[index].length));
						else
							updateGroup(groupAppear[index].group, groupAppear[index].yPos,
								groupAppear[index].convert(Std.string(v), groupAppear[index].length));
					}
				}));
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

	private var currentTween:FlxTween;
	private var animTmr:FlxTimer;
	private var finishedAnim:Bool = false;
	private var startedAnim:Bool = false;

	private var _allowControls:Bool = false;

	override public function update(elapsed:Float)
	{
		if (controls.ACCEPT && startedAnim)
		{
			if (!finishedAnim)
			{
				finishedAnim = true;
				animTmr.cancel();

				@:privateAccess
				if (currentTween != null)
					currentTween.update(FlxMath.MAX_VALUE_FLOAT);

				var listedGroup:Array<FlxTypedGroup<FlxSprite>> = [scoreGroup, missGroup, accuracyGroup];
				var conversion:Array<{convert:Array<String>}> = [
					{convert: groupAppear[0].convert(Std.string(Math.max(0, PlayState.instance.songScore)), 5)},
					{convert: groupAppear[1].convert(Std.string(PlayState.instance.songMisses), 2)},
					{convert: groupAppear[2].convert(Std.string(CoolUtil.floorDecimal(PlayState.instance.ratingPercent * 100, 2)), groupAppear[2].length)}
				];

				for (list in listedGroup)
				{
					updateGroup(list, groupAppear[listedGroup.indexOf(list)].yPos, conversion[listedGroup.indexOf(list)].convert);
				}

				// FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			}
			else
			{
				if (selectAccept)
				{
					if (finishCallback != null)
						finishCallback();
					close();
				}
			}
		}

		if (finishedAnim)
		{
			if (!_allowControls)
			{
				_allowControls = true;

				FlxTween.num(0, 1, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						actualControls = true;
					}
				}, function(v:Float)
				{
					if (mechanicsEnabled)
						acceptButton.alpha = v;
					else
					{
						acceptButton.alpha = v;
						leftArrow.alpha = rightArrow.alpha = damageText.alpha = titleText.alpha = infoText.alpha = v * 0.6;
					}
				});
			}

			if (actualControls)
			{
				if (mechanicsEnabled)
				{
					if (finishedAnim)
					{
						if (controls.UI_UP_P || controls.UI_DOWN_P)
						{
							if (((selectAccept = !selectAccept)) == false)
							{
								acceptButton.alpha = 0.6;
								if (mechanicsEnabled)
									leftArrow.alpha = rightArrow.alpha = damageText.alpha = infoText.alpha = titleText.alpha = 1.0;
							}
							else
							{
								acceptButton.alpha = 1.0;
								if (mechanicsEnabled)
									leftArrow.alpha = rightArrow.alpha = damageText.alpha = infoText.alpha = titleText.alpha = 0.6;
							}

							FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
						}

						if (!selectAccept)
						{
							if (controls.UI_LEFT_P)
								changeSelection(-1);
							else if (controls.UI_RIGHT_P)
								changeSelection(1);
						}
					}
				}
			}
		}

		super.update(elapsed);
	}

	private var actualControls:Bool = false;

	public function changeSelection(select:Int = 0)
	{
		if (PlayState.instance.mechanicsResult.length > 1)
		{
			do
			{
				curSelected = FlxMath.wrap(curSelected + select, 0, PlayState.instance.mechanicsResult.length - 1);
			}
			while (PlayState.instance.mechanicsResult[curSelected] == null);

			titleText.text = PlayState.instance.mechanicsResult[curSelected].name;
			damageText.text = CoolUtil.flattenNumber(FlxMath.roundDecimal(PlayState.instance.mechanicsResult[curSelected].value, 2));
			infoText.text = PlayState.instance.mechanicsResult[curSelected].text;

			titleText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (titleText.width / 2), 460);
			damageText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (damageText.width / 2), leftArrow.y);
			infoText.setPosition(((leftArrow.x + rightArrow.x + rightArrow.width) * 0.5) - (infoText.width / 2), leftArrow.y + leftArrow.height + 12);

			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}
	}

	override public function destroy()
	{
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

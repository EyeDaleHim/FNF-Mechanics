package;

import ColorSwap.ColorSwapShader;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxGradient;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.tweens.misc.VarTween;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import MechanicPortrait.MechanicSprite;

class MechanicMenu extends MusicBeatState
{
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var vignette:FlxSprite;
	var blackGrid:FlxBackdrop;
	var gridBG:FlxBackdrop;
	var randomTxt:FlxText;

	var mechanicGrp:FlxSpriteGroup;
	var mechanicTooltips:FlxTypedGroup<MechanicTooltip>;

	var camFollow:FlxObject;
	var smoothY:Float = 0;

	var pointTxt:Alphabet;
	var rightBG:FlxSprite;
	var socialLogos:Array<FlxSprite> = [];
	var socialTxt:FlxText;
	var globalPointTxt:FlxSprite;
	var pointArrowL:MechanicSprite;
	var pointArrowR:MechanicSprite;
	var setButton:MechanicSprite;
	var multiplierTxt:FlxText;
	var multiplierDisplay:FlxText;
	var multiplierBar:FlxBar;

	static var globalPoints:Int = 0;
	public static var multiplierPoints:Float = 0;

	var multiPointsDisplay:Float = 0;

	var gridShader = new ColorSwap();

	override public function create()
	{
		super.create();

		FlxG.mouse.visible = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.scrollFactor.set();
		add(camFollow);

		FlxG.camera.bgColor = FlxColor.GRAY;
		FlxG.camera.follow(camFollow, LOCKON, 1);

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.antialiasing = true;
		bg.scale.set(1.6, 1.6);
		bg.angle = FlxG.random.float(-15, 15);
		add(bg);

		var rotationSide:Int = 0;
		var maxRotations:Int = 5;

		var lockedAngles:{min:Float, max:Float} = {min: -15, max: 15};
		var state:Int = 1;
		/*
		 * 0 = small angles, increment rotationSide until maxRotations
		 * 1 = big angles, set rotationSide to 0 and random value for maxRotations
		 */

		var doTweenAngle:FlxTween->Void = null;

		doTweenAngle = function(tween:FlxTween)
		{
			switch (state)
			{
				case 0:
					{
						FlxTween.tween(bg, {angle: FlxG.random.float(lockedAngles.min, lockedAngles.max)}, FlxG.random.float(1, 2.25), {
							ease: FlxEase.backOut,
							onComplete: function(twn:FlxTween)
							{
								if (bg == null)
									return;

								if (rotationSide >= maxRotations)
									state = 1;
								else
									rotationSide++;

								doTweenAngle(twn);
							}
						});
					}
				case 1:
					{
						var newMin:Float = FlxG.random.float(-25, -20);
						var newMax:Float = FlxG.random.float(20, 25);

						lockedAngles = {min: newMin, max: newMax};

						FlxTween.tween(bg, {angle: FlxG.random.float(lockedAngles.min, lockedAngles.max)}, FlxG.random.float(1, 2.25), {
							ease: FlxEase.backOut,
							onComplete: function(twn:FlxTween)
							{
								if (bg == null)
									return;

								rotationSide = 0;
								maxRotations = FlxG.random.int(5, 10);

								doTweenAngle(twn);
							}
						});
					}
			}
		}

		var doTweenZoom:Void->Void = null;
		doTweenZoom = function()
		{
			var random:Float = FlxG.random.float(1.3, 1.6);
			FlxTween.tween(bg.scale, {x: random, y: random}, 3, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween)
				{
					if (bg == null)
						return;

					doTweenZoom();
				},
				startDelay: FlxG.random.float(2, 5)
			});
		};

		doTweenAngle(null);
		doTweenZoom();

		gradient = FlxGradient.createGradientFlxSprite(Math.floor(bg.width), Math.floor(bg.height), [randomColor(), randomColor()]);
		gradient.scrollFactor.set();
		gradient.antialiasing = true;
		gradient.blend = MULTIPLY;
		var gradientShader = new ColorSwap();
		gradient.shader = gradientShader.shader;
		gradientShader.hue = -1.0;
		add(gradient);

		FlxTween.tween(gradientShader, {hue: 1}, 20, {ease: FlxEase.linear, type: PINGPONG});

		vignette = new FlxSprite().loadGraphic(Paths.image('bgVignette', 'shared'));
		vignette.scrollFactor.set();
		vignette.antialiasing = true;
		add(vignette);

		gridBG = new FlxBackdrop(Paths.image('checker'), 0.2, 0.2, true, true);
		gridBG.scrollFactor.set(0.1, -0.1);
		gridBG.antialiasing = true;
		gridBG.useScaleHack = false;
		gridBG.alpha = 0.2;

		gridShader.hue = FlxG.random.int(-360, 360);
		gridBG.shader = gridShader.shader;
		add(gridBG);

		blackGrid = new FlxBackdrop(Paths.image('bgGrid'), 0.2, 0.2, true, true);
		blackGrid.x -= 2;
		blackGrid.y -= 2;
		blackGrid.scrollFactor.set();
		blackGrid.antialiasing = true;
		add(blackGrid);

		rightBG = new FlxSprite(FlxG.width * 0.75, 0);
		rightBG.makeGraphic(Std.int(FlxG.width * 0.25), FlxG.height, FlxColor.fromRGB(0, 0, 0));
		rightBG.alpha = 0.3;
		rightBG.scrollFactor.set();
		add(rightBG);

		var logoSpr:FlxSprite = new FlxSprite((FlxG.width * 0.7) - 8, (FlxG.height * 0.9) - 12).loadGraphic(Paths.image('tikTok0', 'shared'));
		logoSpr.scrollFactor.set();
		logoSpr.visible = false;
		logoSpr.alpha = 0.1;
		add(logoSpr);
		socialLogos.push(logoSpr);

		var logoSpr:FlxSprite = new FlxSprite((FlxG.width * 0.7) - 8, (FlxG.height * 0.9) - 12).loadGraphic(Paths.image('tikTok1', 'shared'));
		logoSpr.scrollFactor.set();
		logoSpr.visible = false;
		logoSpr.alpha = 0.1;
		add(logoSpr);
		socialLogos.push(logoSpr);

		var idx:Int = 0;
		new FlxTimer().start(1 / 4, function(tmr:FlxTimer)
		{
			for (logo in socialLogos)
			{
				logo.visible = false;
			}
			if (socialLogos[idx] == null)
				idx = 0;
			socialLogos[idx].visible = true;

			idx++;
		}, 0);

		socialTxt = new FlxText(socialLogos[0].x + socialLogos[0].width + 5, socialLogos[0].getGraphicMidpoint().y, 'Check out mod progresses on TikTok');
		socialTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		socialTxt.visible = false;
		socialTxt.scrollFactor.set();
		add(socialTxt);

		mechanicGrp = new FlxSpriteGroup();
		mechanicGrp.scrollFactor.set(0, 0.4);
		add(mechanicGrp);

		mechanicTooltips = new FlxTypedGroup<MechanicTooltip>();
		add(mechanicTooltips);

		globalPointTxt = new FlxSprite(0, FlxG.height * 0.1).loadGraphic(Paths.image('globalPoints', 'shared'));
		globalPointTxt.x = rightBG.getGraphicMidpoint().x;
		globalPointTxt.x -= globalPointTxt.width / 2;
		globalPointTxt.scrollFactor.set();
		globalPointTxt.antialiasing = true;
		add(globalPointTxt);

		pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
		pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
		if (globalPoints >= 10)
		{
			pointTxt.x -= 22;
		}
		if (globalPoints >= 20)
		{
			pointTxt.x -= 10;
		}
		pointTxt.scrollFactor.set();
		pointTxt.antialiasing = true;
		add(pointTxt);

		pointArrowL = new MechanicSprite(1031.8, FlxG.height * 0.15);
		pointArrowL.loadGraphic(Paths.image('mechanicArr', 'shared'));

		pointArrowL.unselectedScale = 1.4;
		pointArrowL.selectedScale = 1.3;
		pointArrowL.selectedColor = 0.8;
		pointArrowL.unselectedColor = 1;

		pointArrowL.scale.set(1.4, 1.4);
		pointArrowL.updateHitbox();
		pointArrowL.scrollFactor.set();
		pointArrowL.antialiasing = true;
		add(pointArrowL);

		pointArrowR = new MechanicSprite(1168.2, FlxG.height * 0.15);
		pointArrowR.loadGraphic(Paths.image('mechanicArr', 'shared'));

		pointArrowR.unselectedScale = 1.4;
		pointArrowR.selectedScale = 1.3;
		pointArrowR.selectedColor = 0.8;
		pointArrowR.unselectedColor = 1;

		pointArrowR.scale.set(1.4, 1.4);
		pointArrowR.updateHitbox();
		pointArrowR.scrollFactor.set();
		pointArrowR.antialiasing = true;
		pointArrowR.flipX = true;
		add(pointArrowR);

		FlxMouseEventManager.add(pointArrowL, function(spr:MechanicSprite)
		{
			if (globalPoints - 1 == -1)
				return;

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints - 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			pointArrowL.holding = true;
		}, null, function(spr:MechanicSprite)
		{
			pointArrowL.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			pointArrowL.isSelected = false;
		});

		pointArrowL.holdFunction = function()
		{
			if (globalPoints - 1 == -1)
			{
				pointArrowL.forceStop = true;
				pointArrowL.holding = false;
				return;
			}

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints - 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 12;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 14;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
		}

		FlxMouseEventManager.add(pointArrowR, function(spr:MechanicSprite)
		{
			if (globalPoints + 1 == 21)
				return;

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints + 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			if (globalPoints >= 20)
			{
				pointTxt.x -= 6;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			pointArrowR.holding = true;
		}, null, function(spr:MechanicSprite)
		{
			pointArrowR.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			pointArrowR.isSelected = false;
		});

		pointArrowR.holdFunction = function()
		{
			if (globalPoints + 1 == 21)
			{
				pointArrowR.forceStop = true;
				pointArrowR.holding = false;
				return;
			}

			globalPoints = Std.int(CoolUtil.boundTo(globalPoints + 1, 0, 20));

			pointTxt.destroy();
			pointTxt = null;

			pointTxt = new Alphabet(0, FlxG.height * 0.155, '' + globalPoints, true);
			pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;
			if (globalPoints >= 10)
			{
				pointTxt.x -= 22;
			}
			if (globalPoints >= 20)
			{
				pointTxt.x -= 10;
			}
			pointTxt.scrollFactor.set();
			pointTxt.antialiasing = true;
			add(pointTxt);

			FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
		}

		setButton = new MechanicSprite(globalPointTxt.getGraphicMidpoint().x, FlxG.height * 0.275);
		setButton.loadGraphic(Paths.image('setAllPoints', 'shared'));
		setButton.x = rightBG.getGraphicMidpoint().x;
		setButton.x -= globalPointTxt.width / 4;
		setButton.x += 10;
		setButton.scrollFactor.set();
		setButton.antialiasing = true;
		setButton.unselectedColor = 1;
		setButton.selectedColor = 0.7;
		setButton.colorSpeed *= 2.5;
		add(setButton);

		FlxMouseEventManager.add(setButton, function(spr:MechanicSprite)
		{
			var changed:Bool = false;

			for (mechanic in MechanicManager.mechanics.keys())
			{
				if (MechanicManager.mechanics[mechanic].points == globalPoints)
					continue;

				changed = true;

				MechanicManager.mechanics[mechanic].points = globalPoints;
				if (MechanicManager.mechanics[mechanic].spriteParent != null)
					MechanicManager.mechanics[mechanic].spriteParent.text.text = '' + globalPoints;
			}

			if (changed)
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.8);
			if (setButton != null) // no bitches?
			{
				FlxTween.cancelTweensOf(setButton.colorTransform);
				setButton.colorTransform.redOffset = 255;
				setButton.colorTransform.blueOffset = 255;
				setButton.colorTransform.greenOffset = 255;
				FlxTween.tween(setButton.colorTransform, {redOffset: 0, blueOffset: 0, greenOffset: 0}, 0.6, {ease: FlxEase.quadOut});
			}
		}, null, function(spr:MechanicSprite)
		{
			setButton.isSelected = true;
		}, function(spr:MechanicSprite)
		{
			setButton.isSelected = false;
		});

		multiplierDisplay = new FlxText(0, FlxG.height * 0.4, 0, 'MULTIPLIER', 32);
		multiplierDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		multiplierDisplay.borderSize = 2;
		multiplierDisplay.updateHitbox();
		multiplierDisplay.scrollFactor.set();
		multiplierDisplay.antialiasing = true;
		multiplierDisplay.x = rightBG.getGraphicMidpoint().x - (multiplierDisplay.width / 2);
		multiplierDisplay.x += 4;
		add(multiplierDisplay);

		multiplierTxt = new FlxText(0, FlxG.height * 0.45, 0, '0.0X', 64);
		multiplierTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		multiplierTxt.borderSize = 3.5;
		multiplierTxt.updateHitbox();
		multiplierTxt.scrollFactor.set();
		multiplierTxt.antialiasing = true;
		multiplierTxt.x = rightBG.getGraphicMidpoint().x - (multiplierTxt.width / 2);
		multiplierTxt.x += 4;
		add(multiplierTxt);

		multiplierBar = new FlxBar(multiplierTxt.x, multiplierTxt.y + multiplierTxt.height + 4, LEFT_TO_RIGHT, Std.int(multiplierTxt.width), 4, this,
			'multiPointsDisplay', 1, 3.4);
		multiplierBar.scrollFactor.set();
		multiplierBar.antialiasing = true;
		multiplierBar.numDivisions = FlxG.width * 2;
		multiplierBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE, false, FlxColor.TRANSPARENT);
		add(multiplierBar);

		smoothY = 800;

		var i:Int = 0;

		// someone please make a PR on this
		var mechanicPositions:Array<Array<Float>> = [
			[40, 180], // 0
			[240, 180], // 1
			[440, 180], // 2
			[640, 180], // 3
			[40, 540], // 4
			[240, 540], // 5
			[440, 540], // 6
			[640, 540], // 7
			[40, 900], // 8
			[240, 900], // 9
			[440, 900], // 10
			[640, 900], // 11
			[40, 1260], // 12
			[240, 1260], // 13
			[440, 1260], // 14
			[640, 1260], // 15
			[40, 1620], // 16
			[240, 1620], // 17
			[440, 1620], // 18
			[640, 1620], // 19
			[40, 1980], // 20
			[240, 1980], // 21
			[440, 1980], // 22
			[640, 1980] // 23
		];

		for (i in mechanicPositions)
			i[0] += 2;

		var sortedMechanics:Array<MechanicManager.MechanicData> = [];
		var stackedTooltips:Array<MechanicTooltip> = [];

		for (mechanic in MechanicManager.mechanics.keys())
		{
			sortedMechanics.push(MechanicManager.mechanics[mechanic]);
		}

		var sortByValue = function(_1, _2)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, _1.ID, _2.ID);
		}

		sortedMechanics.sort(sortByValue);

		for (mechanic in sortedMechanics)
		{
			var mechanicSpr:MechanicPortrait;
			mechanicSpr = new MechanicPortrait(mechanicPositions[i][0], mechanicPositions[i][1], mechanic, null);
			mechanicSpr.scrollFactor.set(0, 0.4);
			mechanic.spriteParent = mechanicSpr;
			mechanicSpr.text.text = '' + mechanic.points;
			mechanicSpr.tooltip.scrollFactor.set(0, 0.4);

			FlxMouseEventManager.add(mechanicSpr.arrowL, function(spr:MechanicSprite)
			{
				if (mechanic.points == 0)
				{
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points - 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
				mechanicSpr.arrowL.holding = true;
			}, null, function(spr:MechanicSprite)
			{
				spr.isSelected = true;
			}, function(spr:MechanicSprite)
			{
				spr.isSelected = false;
			}, true);

			mechanicSpr.arrowL.holdFunction = function()
			{
				if (mechanic.points == 0)
				{
					mechanicSpr.arrowL.forceStop = true;
					mechanicSpr.arrowL.holding = false;
					return;
				}

				if (mechanic.points - 1 != -1 || (mechanic.points + 1 == 1 && mechanic.points == 0))
					FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points - 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
			};

			FlxMouseEventManager.add(mechanicSpr.arrowR, function(spr:MechanicSprite)
			{
				if (mechanic.points == 20)
				{
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points + 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
				mechanicSpr.arrowR.holding = true;
			}, null, function(spr:MechanicSprite)
			{
				spr.isSelected = true;
			}, function(spr:MechanicSprite)
			{
				spr.isSelected = false;
			}, true);

			mechanicSpr.arrowR.holdFunction = function()
			{
				if (mechanic.points == 20)
				{
					mechanicSpr.arrowR.forceStop = true;
					mechanicSpr.arrowR.holding = false;
					return;
				}

				mechanic.points = Std.int(CoolUtil.boundTo(mechanic.points + 1, 0, 20));
				mechanicSpr.text.text = '' + mechanic.points;
				FlxG.sound.play(Paths.sound('mechanicSel'), 0.6);
			};

			mechanicGrp.add(mechanicSpr);
			stackedTooltips.push(mechanicSpr.tooltip);

			i++;
		}

		for (tooltip in stackedTooltips)
		{
			mechanicTooltips.add(tooltip);
		}
	}

	var moveBG:Bool = true;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.R)
			FlxG.switchState(new MainMenuState());

		gridShader.hue += elapsed * 0.1;

		if (moveBG)
		{
			var multiplier:Float = 1.4;

			if (FlxG.mouse.getScreenPosition().x > rightBG.x)
				multiplier = 0.2;

			if (socialTxt.visible = FlxMath.mouseInFlxRect(false,
				new FlxRect(socialLogos[0].x, socialLogos[0].y, socialLogos[0].width, socialLogos[0].height)))
			{
				multiplier = 0;
				if (FlxG.mouse.justPressed)
					FlxG.openURL('https://www.tiktok.com/@eyedalehim');
			}

			if (FlxG.mouse.getScreenPosition().y > FlxG.height * 0.8)
				smoothY += 420 * (elapsed * 2.2) * multiplier;
			else if (FlxG.mouse.getScreenPosition().y < FlxG.height * 0.2)
				smoothY -= 420 * (elapsed * 2.2) * multiplier;

			smoothY -= FlxG.mouse.wheel * 120;
		}

		smoothY = CoolUtil.boundTo(smoothY, 700, 4500);

		camFollow.y = FlxMath.lerp(camFollow.y, smoothY, CoolUtil.boundTo(elapsed * 3.5, 0, 1));

		pointTxt.x = globalPointTxt.getGraphicMidpoint().x - 14;

		if (globalPoints >= 10)
		{
			pointTxt.x -= 22;
		}
		if (globalPoints >= 20)
		{
			pointTxt.x -= 10;
		}

		var multiplierInitial:Float = 0;

		for (mechanic in MechanicManager.mechanics.keys())
		{
			var points:Int = MechanicManager.mechanics[mechanic].points;
			if (points <= 0)
				points = 0;

			multiplierInitial += 1 * points;
		}

		multiplierInitial /= 2;

		MechanicManager.multiplier = multiplierPoints = 1 + FlxMath.roundDecimal(multiplierInitial / 100, 2);
		multiPointsDisplay = cast multiplierPoints;

		if (multiplierTxt != null)
		{
			multiplierTxt.text = '' + formatMulti(multiplierPoints) + 'X';
			multiplierTxt.x = rightBG.getGraphicMidpoint().x;
			multiplierTxt.x -= multiplierTxt.width / 2;
			multiplierTxt.x += 4;
		}
	}

	function formatMulti(num:Float):String
	{
		var conv:String = Std.string(num);

		while (conv.length < 4)
		{
			if (conv.length == 1)
				conv += '.';
			else
				conv += '0';
		}

		return conv;
	}

	override public function destroy()
	{
		for (mechanic in MechanicManager.mechanics.keys())
		{
			MechanicManager.mechanics[mechanic].spriteParent = null;
		}

		FlxG.camera.bgColor = 0;

		super.destroy();
	}

	function randomColor():FlxColor
	{
		return FlxColor.fromRGB(FlxG.random.int(165, 225), FlxG.random.int(165, 225), FlxG.random.int(165, 225), 255);
	}
}

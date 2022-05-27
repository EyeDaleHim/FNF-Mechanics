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
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.group.FlxSpriteGroup;
import MechanicPortrait.MechanicSprite;

class MechanicMenu extends MusicBeatState
{
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var blackGrid:FlxBackdrop;
	var gridBG:FlxBackdrop;
	var randomTxt:FlxText;

	var mechanicGrp:FlxSpriteGroup;

	var camFollow:FlxObject;
	var smoothY:Float = 0;

	var pointTxt:Alphabet;
	var rightBG:FlxSprite;
	var globalPointTxt:FlxSprite;
	var pointArrowL:MechanicSprite;
	var pointArrowR:MechanicSprite;
	var setButton:MechanicSprite;
	var multiplierTxt:FlxText;
	var multiplierDisplay:FlxText;

	static var globalPoints:Int = 0;
	public static var multiplierPoints:Float = 0;

	var characters:Array<String> = ["abcdefghijklmnopqrstuvwxyz", "1234567890", "|~#$%()*+-:;<=>@[]^_.,'!?"];

	var gridShader = new ColorSwap();

	override public function create()
	{
		super.create();

        FlxG.mouse.visible = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.scrollFactor.set();
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 1);

		bg = new FlxSprite();
		bg.loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.antialiasing = true;
		add(bg);

		gradient = FlxGradient.createGradientFlxSprite(Math.floor(bg.width), Math.floor(bg.height), [randomColor(), randomColor()]);
		gradient.scrollFactor.set();
		gradient.antialiasing = true;
		gradient.blend = MULTIPLY;
		add(gradient);

		randomTxt = new FlxText(2, 2, FlxG.width, "", 12);
		randomTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE);
		randomTxt.scrollFactor.set();
		randomTxt.alpha = 0.25;
		add(randomTxt);

		var typing:Bool = true;
		var tweening:Bool = false;

		new FlxTimer().start(0.1, function(tmr:FlxTimer) // 0.02, use 0.1 because 0.02 is stupidly lag
		{
			if (typing)
			{
				var value:Int = FlxG.random.int(0, characters.length);
				var char:Int = FlxG.random.int(0, characters[value].length);

				randomTxt.text += characters[value].charAt(char);

				if (randomTxt.height > FlxG.height * 1.1)
				{
					typing = false;
					tweening = true;
				}
			}
			else if (!typing && tweening)
			{
				randomTxt.alpha -= FlxG.elapsed * 2.4;
				if (randomTxt.alpha <= 0)
				{
					randomTxt.text = '';
					randomTxt.alpha = 0.25;
					tweening = false;
					new FlxTimer().start(0.4, function(twn:FlxTimer)
					{
						typing = true;
					});
				}
			}
		}, 0);

		gridBG = new FlxBackdrop(Paths.image('checker'), 0.2, 0.2, true, true);
		gridBG.scrollFactor.set(0.1, -0.1);
		gridBG.antialiasing = true;
		gridBG.useScaleHack = false;
		gridBG.alpha = 0.2;

        gridShader.hue = FlxG.random.int(-360, 360);
		gridBG.shader = gridShader.shader;
		add(gridBG);

		blackGrid = new FlxBackdrop(Paths.image('bgGrid'), 0.2, 0.2, true, true);
		blackGrid.scrollFactor.set();
		blackGrid.antialiasing = true;
		add(blackGrid);

		rightBG = new FlxSprite(FlxG.width * 0.75, 0);
		rightBG.makeGraphic(Std.int(FlxG.width * 0.25), FlxG.height, FlxColor.fromRGB(0, 0, 0));
		rightBG.alpha = 0.3;
		rightBG.scrollFactor.set();
		add(rightBG);

		mechanicGrp = new FlxSpriteGroup();
		add(mechanicGrp);

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

		pointArrowL = new MechanicSprite(0, FlxG.height * 0.15);
		pointArrowL.loadGraphic(Paths.image('mechanicArr', 'shared'));

		pointArrowL.unselectedScale = 1.4;
		pointArrowL.selectedScale = 1.3;
		pointArrowL.selectedColor = 0.8;
		pointArrowL.unselectedColor = 1;

		pointArrowL.scale.set(1.4, 1.4);
		pointArrowL.updateHitbox();
		pointArrowL.x = pointTxt.x - pointArrowL.width - 28;
		pointArrowL.scrollFactor.set();
		pointArrowL.antialiasing = true;
		add(pointArrowL);

		pointArrowR = new MechanicSprite(0, FlxG.height * 0.15);
		pointArrowR.loadGraphic(Paths.image('mechanicArr', 'shared'));

		pointArrowR.unselectedScale = 1.4;
		pointArrowR.selectedScale = 1.3;
		pointArrowR.selectedColor = 0.8;
		pointArrowR.unselectedColor = 1;

		pointArrowR.scale.set(1.4, 1.4);
		pointArrowR.updateHitbox();
		pointArrowR.x = pointTxt.x + pointArrowR.width + 16;
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

		multiplierDisplay = new FlxText(0, FlxG.height * 0.4, 0, 'MULTIPLIER:', 32);
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
		multiplierTxt.borderSize = 2;
		multiplierTxt.updateHitbox();
		multiplierTxt.scrollFactor.set();
		multiplierTxt.antialiasing = true;
		multiplierTxt.x = rightBG.getGraphicMidpoint().x - (multiplierTxt.width / 2);
		multiplierTxt.x += 4;
		add(multiplierTxt);

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
			mechanicSpr = new MechanicPortrait(mechanicPositions[i][0], mechanicPositions[i][1], mechanic.name, mechanic.image, null);
			mechanicSpr.scrollFactor.set(0, 0.4);
			mechanic.spriteParent = mechanicSpr;
			mechanicSpr.text.text = '' + mechanic.points;

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

				if (mechanic.points - 1 != -1
					|| (mechanic.points + 1 == 1 && mechanic.points == 0))
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

			add(mechanicSpr);

			i++;
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

			if (FlxG.mouse.getScreenPosition().y > FlxG.height * 0.8)
				smoothY += 420 * (elapsed * 2.2) * multiplier;
			else if (FlxG.mouse.getScreenPosition().y < FlxG.height * 0.2)
				smoothY -= 420 * (elapsed * 2.2) * multiplier;

			smoothY -= FlxG.mouse.wheel * 120;
		}
		
		smoothY = CoolUtil.boundTo(smoothY, 800, 4500);

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

		multiplierPoints = 1 + FlxMath.roundDecimal(multiplierInitial / 100, 2);

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

		super.destroy();
	}

	function randomColor():FlxColor
	{
		return FlxColor.fromRGB(FlxG.random.int(165, 225), FlxG.random.int(165, 225), FlxG.random.int(165, 225), 255);
	}
}

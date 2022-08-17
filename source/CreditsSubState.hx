package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;

class CreditsSubState extends MusicBeatSubstate
{
	public var list:Array<Dynamic> = [
		["TESTERS", true], ["Cherif", false], ["Mark_Zer0", false], ["BlueColorSin", false], ["TheConcealedCow", false], ["Maru", false], ["raltyro", false],
		["Tyler Blackbolt", false], ["stress", false], ["PAUSE MUSIC", true], ["Kevin MacLeod", false], ["TeknoAXE", false]];

	public var bg:FlxSprite;
	public var textGrp:FlxTypedGroup<Alphabet>;

	private var curSelected:Int = 1;

	public function new()
	{
		super();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		textGrp = new FlxTypedGroup<Alphabet>();
		add(textGrp);

		for (i in 0...list.length)
		{
			var menuText:Alphabet = new Alphabet(0, 140 * i, list[i][0], list[i][1], false, 0);
			menuText.scrollFactor.set();
			menuText.isMenuItem = true;
			menuText.ID = i;
            menuText.targetY = i;
			menuText.screenCenter(X);

			textGrp.add(menuText);
		}

		textGrp.members[1].alpha = 1;

		FlxTween.tween(bg, {alpha: 0.4}, 0.5, {ease: FlxEase.quadOut});

        changeSelection();
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (textGrp != null)
		{
			textGrp.forEachAlive(function(spr:Alphabet)
			{
				spr.screenCenter(X);
			});
		}

        if (controls.UI_DOWN_P)
            changeSelection(1);
        else if (controls.UI_UP_P)
            changeSelection(-1);
        else if (controls.BACK)
        {
            FlxG.state.persistentUpdate = true;
            close();
        }
	}

	private function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected += change;
			if (curSelected < 0)
				curSelected = textGrp.length - 1;
			if (curSelected >= textGrp.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (item in textGrp.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
				}
			}
		}
	}

	private function unselectableCheck(num:Int)
	{
		return list[num][1];
	}
}

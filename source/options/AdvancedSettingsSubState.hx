package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class AdvancedSettingsSubState extends BaseOptionsMenu
{
	var lastOption:String = '';

	public function new()
	{
		title = 'Advanced Settings';
		rpcTitle = 'Advanced Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Chart Caching',
			"Allows you to cache the charts once loaded, caches charts depending on the preference, this may cause conflicts with some mods.", 'chartCache',
			"string", "None", ['None', 'Mods', 'Base Game', 'All']);
		lastOption = option.getValue();
		addOption(option);

		var option:Option = new Option('Persistent Cache',
			'If checked, any assets will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
			'imagesPersist', 'string', 'Base Game', ['None', 'Mods', 'Base Game', 'All']);
		addOption(option);

		var option:Option = new Option('Safe Scripts',
			'Any scripts containing malicious functions will not be triggered, change this option if you know what you\'re doing!', 'safeScript', 'string',
			'on', ['Off', 'Warn First', 'On']);
		addOption(option);

		var option:Option = new Option('Debugger Mode', "Lets you enable the keybinds to access debug menus.", 'debugMode', 'bool',
			#if debug true #else false #end);
		addOption(option);

		super();

		var resetOption:Alphabet = new Alphabet(0, grpOptions.members[grpOptions.length - 1].y + 70, "Reset Preferences Data", false, false);
		resetOption.isMenuItem = true;
		resetOption.x += 300;
		resetOption.xAdd = 200;
		resetOption.targetY = grpOptions.members.length + 1;
		grpOptions.add(resetOption);
	}

	override public function update(elapsed:Float)
	{
		if (controls.ACCEPT && grpOptions.members[curSelected].text == "Reset Preferences Data")
			openSubState(new options.ResetSettingsSubState());

		if (controls.BACK)
		{
			if (lastOption != optionsArray[0].getValue())
			{
				Paths.clearStoredMemory();
				Paths.clearUnusedMemory();
			}
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		super.update(elapsed);
	}

	override function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length + 1)
			curSelected = 0;

		if (curSelected != optionsArray.length)
		{
			descText.text = optionsArray[curSelected].description;
			descText.screenCenter(Y);
			descText.y += 270;
		}
		else
		{
			descText.text = 'Resets your Preference Data, in the event of broken save files, this cannot be undone.';
			descText.screenCenter(Y);
			descText.y += 270;
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
			{
				text.alpha = 1;
			}
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		if (boyfriend != null)
		{
			boyfriend.visible = optionsArray[curSelected].showBoyfriend;
		}
		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}

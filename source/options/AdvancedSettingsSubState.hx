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
	var lastOption:Array<String> = ['', ''];
	var perfOpt:Option;

	public function new()
	{
		title = 'Advanced Settings';
		rpcTitle = 'Advanced Settings Menu'; // for Discord Rich Presence

		#if !mobile
		var option:Option = new Option('Performance Counter', 'Toggle through the options for your performance counter', 'performanceCounter', 'string',
			'fps-mem-peak', ['hide', 'fps', 'fps-mem', 'fps-mem-peak']);
		addOption(option);
		option.onChange = function()
		{
			onChangePerformanceCounter();
			switch (ClientPrefs.performanceCounter)
			{
				case 'hide':
					{
						option.text = 'Hide FPS';
					}
				case 'fps':
					{
						option.text = 'FPS Only';
					}
				case 'fps-mem':
					{
						option.text = 'FPS With Memory';
						@:privateAccess
						{
							for (i in 0...option.text.length)
							{
								if (option.child.members[i] != null)
								{
									if (i >= 7)
									{
										option.child.members[i].y += 40;
										option.child.members[i].x -= 280;
									}
									else
										option.child.members[i].y -= 15;
								}
							}
						}
					}
				case 'fps-mem-peak':
					{
						option.text = 'FPS With Memory Peak';
						@:privateAccess
						{
							for (i in 0...option.text.length)
							{
								if (option.child.members[i] != null)
								{
									if (i >= 7)
									{
										option.child.members[i].y += 40;
										option.child.members[i].x -= 360;
									}
									else
										option.child.members[i].y -= 15;
								}
							}
						}
					}
			}
		};

		perfOpt = option;
		#end

		var option:Option = new Option('Chart Caching',
			"Allows you to cache the charts once loaded, caches charts depending on the preference, this may cause conflicts with some mods.", 'chartCache',
			"string", "None", ['None', 'Mods', 'Base Game', 'All']);
		lastOption[0] = option.getValue();
		addOption(option);

		/*var option:Option = new Option('Persistent Cache',
				'If checked, any assets will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
				'imagesPersist', 'string', 'Base Game', ['None', 'Mods', 'Base Game', 'All']);
			lastOption[1] = option.getValue();
			addOption(option); */

		/*var option:Option = new Option('Safe Scripts',
			'Any scripts containing malicious functions will be dealt with based on this option, change this option if you know what you\'re doing!',
			'safeScript', 'string', 'on', ['Off', 'Warn First', 'On']);
		addOption(option);*/

		var option:Option = new Option('Time Pause Delay', "How many seconds the game should continue when you press \'Resume\' on the Pause Menu.", 'pauseSecond', 'float',
		1.25);
		option.scrollSpeed = 2.0;
		option.minValue = 0.0;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.displayFormat = '%vs';
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

		switch (ClientPrefs.performanceCounter)
		{
			case 'hide':
				{
					option.text = 'Hide FPS';
				}
			case 'fps':
				{
					option.text = 'FPS Only';
				}
			case 'fps-mem':
				{
					option.text = 'FPS With Memory';
					@:privateAccess
					{
						for (i in 0...option.text.length)
						{
							if (i >= 7)
							{
								option.child.members[i].y += 40;
								option.child.members[i].x -= 280;
							}
							else
								option.child.members[i].y -= 15;
						}
					}
				}
			case 'fps-mem-peak':
				{
					option.text = 'FPS With Memory Peak';
					@:privateAccess
					{
						for (i in 0...option.text.length)
						{
							if (i >= 7)
							{
								option.child.members[i].y += 40;
								option.child.members[i].x -= 360;
							}
							else
								option.child.members[i].y -= 15;
						}
					}
				}
				Main.fpsVar.fps.forceUpdateText = true;
		}
	}

	#if !mobile
	function onChangePerformanceCounter()
	{
		if (Main.fpsVar != null)
		{
			Main.fpsVar.visible = true;
			switch (ClientPrefs.performanceCounter)
			{
				case 'hide':
					Main.fpsVar.visible = false;
			}
			Main.fpsVar.fps.forceUpdateText = true;
		}
	}
	#end

	override public function update(elapsed:Float)
	{
		if (controls.ACCEPT && grpOptions.members[curSelected].text == "Reset Preferences Data")
			openSubState(new options.ResetSettingsSubState());

		if (controls.BACK)
		{
			if (lastOption[0] != optionsArray[1].getValue())
			{
				Song.cleanCache();
			}
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		super.update(elapsed);

		if (perfOpt != null)
			perfOpt.onChange();
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

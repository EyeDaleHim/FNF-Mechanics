import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

using StringTools;

class Achievements
{
	public static var achievementsStuff:Array<AchievementIdentifier> = [ //Name, Description, Achievement save tag, Hidden achievement
		{name: "Freaky on a Friday Night", description: "Play on a Friday... Night.", tag: 'friday_night_play', hidden: true},
		{name: "She Calls Me Daddy Too", description: "Beat Week 1 on Hard with no Misses.", tag: 'week1_nomiss', hidden: false},
		{name: "No More Tricks", description: "Beat Week 2 on Hard with no Misses.", tag: 'week2_nomiss', hidden: false},
		{name: "Call Me The Hitman", description: "Beat Week 3 on Hard with no Misses.", tag: 'week3_nomiss', hidden: false},
		{name: "Lady Killer", description: "Beat Week 4 on Hard with no Misses.", tag: 'week4_nomiss', hidden: false},
		{name: "Missless Christmas", description: "Beat Week 5 on Hard with no Misses.", tag: 'week5_nomiss', hidden: false},
		{name: "Highscore!!", description: "Beat Week 6 on Hard with no Misses.", tag: 'week6_nomiss', hidden: false},
		{name: "God Effing Damn It!", description: "Beat Week 7 on Hard with no Misses.", tag: 'week7_nomiss', hidden: false},
		{name: "What a Funkin' Disaster!", description: "Complete a Song with a rating lower than 20%.", tag: 'ur_bad', hidden: false},
		{name: "Perfectionist", description: "Complete a Song with a rating of 100%.", tag: 'ur_good', hidden: false},
		{name: "Challenger", description: "Complete a Song with 2 Safe Frames.", tag: 'challenger', hidden: false, specialAnim: true},
		{name: "Hardcore", description: "Beat a song with no Misses on 24/20 mode.", tag: 'hardcore', hidden: true, specialAnim: true},
		{name: "Demon", description: "Beat a Song with 100% accuracy on 24/20 mode. Well done, now stop it.", tag: 'demon', hidden: true, specialAnim: true},
		{name: "Persistent", description: "Beat a Week with no Misses on 24/20 mode. Jesus Christ...", tag: 'persistent', hidden: true, specialAnim: true},
		{name: "Resilient", description: "Beat a Week with 100% accuracy on all songs on 24/20 mode. Stop grinding!", tag: 'resilient', hidden: true, specialAnim: true},
		{name: "Roadkill Enthusiast", description: "Watch the Henchmen die over 100 times.", tag: 'roadkill_enthusiast', hidden: false},
		{name: "Oversinging Much...?", description: "Hold down a note for 10 seconds.", tag: 'oversinging', hidden: false},
		{name: "Hyperactive", description: "Finish a Song without going Idle.", tag: 'hype', hidden: false},
		{name: "Just the Two of Us", description: "Finish a Song pressing only two keys.", tag: 'two_keys', hidden: false},
		{name: "Toaster Gamer", description: "Have you tried to run the game on a toaster?", tag: 'toastie', hidden: false}
	];

	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var henchmenDeath:Int = 0;

	private static function findByName(name:String):Int
	{
		var i:Int = -1;
		while (achievementsStuff[i].name != name)
			i++;
		return i;
	}

	public static function unlockAchievement(name:String):Void
	{
		FlxG.log.add('Completed achievement "' + name + '"');
		achievementsMap.set(name, true);
		if (achievementsStuff[findByName(name)].specialAnim != null && achievementsStuff[findByName(name)].specialAnim)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			trace('special');
		}
		else
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String)
	{
		if (achievementsMap.exists(name) && achievementsMap.get(name))
		{
			return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String)
	{
		for (i in 0...achievementsStuff.length)
		{
			if (achievementsStuff[i].tag == name)
			{
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void
	{
		if (FlxG.save.data != null)
		{
			if (FlxG.save.data.achievementsMap != null)
			{
				achievementsMap = FlxG.save.data.achievementsMap;
			}
			if (henchmenDeath == 0 && FlxG.save.data.henchmenDeath != null)
			{
				henchmenDeath = FlxG.save.data.henchmenDeath;
			}
		}
	}
}

class AttachedAchievement extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var tag:String;

	public function new(x:Float = 0, y:Float = 0, name:String)
	{
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function changeAchievement(tag:String)
	{
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage()
	{
		if (Achievements.isAchievementUnlocked(tag))
		{
			loadGraphic(Paths.image('achievements/' + tag));
		}
		else
		{
			loadGraphic(Paths.image('achievements/lockedachievement'));
		}
		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievements/' + name));
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280,
			Achievements.achievementsStuff[id].name, 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[id].description, 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if (camera != null)
		{
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween)
			{
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
					startDelay: 2.5,
					onComplete: function(twn:FlxTween)
					{
						alphaTween = null;
						remove(this);
						if (onFinish != null)
							onFinish();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (alphaTween != null)
		{
			alphaTween.cancel();
		}
		super.destroy();
	}
}

// secret credits to myke
typedef AchievementIdentifier =
{
	var name:String;
	var description:String;
	var tag:String;
	var hidden:Bool;
	@:optional var specialAnim:Bool;
}
package;

import flixel.FlxG;
import MechanicPortrait.MechanicSprite;

// mport flixel.
class MechanicManager
{
	public static var mechanics:Map<String, MechanicData> = [
		'hurt_note' => new MechanicData('Hurt Note', 'A Hurt Note will decrease your HP, generated randomly throughout the chart, more frequently based on points', 'hurtnote', 0),
        'kill_note' => new MechanicData('Instakill Note', 'Kills you instantly, generated randomly through the chart', 'killnote', 1),
        'burst_note' => new MechanicData('Burst Note', 'Upon hit, prevents you from getting HP for a short interval', 'burstnote', 2),
        'fake_note' => new MechanicData('Fake Note', 'A note with a noticeable difference, they have the same effect as hitting a hurt note', 'fakenote', 3),
        'restore_note' => new MechanicData('Restore Note', 'In some rare cases, you will lose & not gain health until you lose, you must hit a Restore Note to prevent so', 'restorenote', 4),
        'sleep_note' => new MechanicData('Sleepy Note', 'If you hit too many sleepy notes, you will lose, your sleepiness will gradually reduce', 'sleepnote', 5),
        'note_random' => new MechanicData('Random Notes', 'Random Notes will scatter randomly throughout the chart', 'random2', 6),
        'drain_hp' => new MechanicData('HP Drain', 'Your HP drains over time. With a limit', 'healthdr1', 7),
        'hit_hp' => new MechanicData('HP Killer', 'Your opponent can fight back when they hit a note', 'healthdr2', 8),
        'note_speed' => new MechanicData('Random Speed', 'Each note individually will have a random speed', 'notespeed', 9),
        'dodging' => new MechanicData('Dodging', 'You will get attacked at random, you have to react more quickly depending on the points', 'dodge', 10),
        'note_change' => new MechanicData('Note Changer', 'A note will change from it\'s original position. Affects all type of notes', 'random1', 11),
        'strum_swap_enemy' => new MechanicData('Player Strum Swap', 'You and your opponent\'s strums will get swapped once in a while', 'strumswap', 12),
        'strum_swap' => new MechanicData('Strum Swap', 'Your own strums will swap each other accordingly', 'noteswap', 13),
        'mouse_follower' => new MechanicData('Mouse Follower', 'A green mouse will follow your own mouse, just don\'t let it on your own too much', 'fakemouse', 14),
        'click_icon' => new MechanicData('Icon Click', 'Your icon occasionally may reduce health expotentially over time. Click on the icon to stop it from doing so', 'clickicon', 15),
        'flashlight' => new MechanicData('Flashlight', 'The notes get harder to see the closer they are to being hit', 'flashlight', 16),
        'morale' => new MechanicData('Morale', 'Keep your morale high by playing good at the game, don\'t lose all of it or you\'ll die', 'morale', 17),
        // 'moving_strum' => new MechanicData('Freaky Strum', 'Your strums will sometimes jerk off. Keep your focus', 'freakstrum', 18),
        'limit_health' => new MechanicData('Limited Health', 'The maximum health you can get is randomized', 'healthlimit', 18),
        'typewriter' => new MechanicData('Typewriter', 'Type what is said on the screen, don\'t mess up though, gets harder the more points', 'typewriter', 19),
        'beat_timer' => new MechanicData('Beat Timer', 'Press a button accordingly to the timing! (Not the beat)', 'beattimer', 20),
        'click_circle' => new MechanicData('Click The Circles', 'Click the circles with your mouse', 'osu', 21),
        'dimension' => new MechanicData('Dimensions', 'There are now dimensions within the notes, press a button to swap to a dimension', 'dimension', 22),
        'karma' => new MechanicData('Karma', 'When losing health, a poison effect is applied', 'karma', 23)
	];

    public static var multiplier:Float = 1;
}

class MechanicData
{
	public var name:String;

	public var image:String;
	public var description:String;
	public var points:Int;
    public var ID:Int;

    public var spriteParent:MechanicPortrait;

	public function new(name:String, description:String, image:String, ID:Int = -1)
	{
		this.name = name;
		this.description = description;
		this.image = image;
        this.ID = ID;
	}

    function set_points(value:Int):Int
    {
        if (spriteParent == null)
        {
            points = value;
            return value;
        }

        points = value;
        spriteParent.text.text = '' + value;
        return value;
    }
}

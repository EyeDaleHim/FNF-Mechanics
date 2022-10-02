package;

import flixel.FlxG;
import MechanicPortrait.MechanicSprite;

// mport flixel.
class MechanicManager
{
	public static var mechanics:Map<String, MechanicData> = [
		'hurt_note' => new MechanicData('Hurt Note', 'A Hurt Note will decrease your health', 'Damage', 'hurtnote', 0),
		'kill_note' => new MechanicData('Instakill Note', 'Kills you instantly, generated randomly through the chart', 'Damage', 'killnote', 1),
		'burst_note' => new MechanicData('Burst Note', 'Upon hit, prevents you from getting health for a short interval', 'Duration', 'burstnote', 2),
		'fake_note' => new MechanicData('Fake Note', 'A note with a noticeable difference, they have the same effect as hitting a hurt note', 'Damage',
			'fakenote', 3),
		'restore_note' => new MechanicData('Restore Note',
			'In some rare cases, you will lose & not gain health until you lose, you must hit a Restore Note to prevent so', 'Damage', 'restorenote', 4),
		'sleep_note' => new MechanicData('Sleepy Note', 'Hitting a Sleepy Note will increase your sleep bar, which will diminish slowly', 'Duration',
			'sleepnote', 5),
		'swap_note' => new MechanicData('Swap Note',
			'There will be a chance that a Swap Note will replace a regular note and it will appear on your opposing enemy\'s strum instead', 'Damage',
			'swapnote', 6),
		'note_random' => new MechanicData('Random Notes', 'Random Notes will scatter randomly throughout the chart', 'Damage', 'random2', 7),
		'drain_hp' => new MechanicData('Health Drain', 'Your health drains over time. With a limit', 'Damage', 'healthdr1', 8),
		'hit_hp' => new MechanicData('Health Killer', 'Your opponent can fight back when they hit a note', 'Damage', 'healthdr2', 9),
		'note_speed' => new MechanicData('Random Speed', 'Each note individually will have a random speed', null, 'notespeed', 10),
		'dodging' => new MechanicData('Dodging', 'You will get attacked at random, you have to react more quickly depending on the points', 'Damage', 'dodge',
			11),
		'note_change' => new MechanicData('Note Changer', 'A note will change from it\'s original position. Affects all type of notes', null, 'random1', 12),
		'strum_swap' => new MechanicData('Strum Swap', 'Your own strums will swap each other accordingly', null, 'noteswap', 13),
		'mouse_follower' => new MechanicData('Mouse Follower', 'A green mouse will follow your own mouse, just don\'t let it overlap your own mouse',
			'Duration', 'fakemouse', 14),
		'click_time' => new MechanicData('Time Click',
			'A time will appear on your screen with a specific time, you should click whenever the song time matches the time', 'Attempts', 'clicktime', 15),
		'flashlight' => new MechanicData('Flashlight', 'The notes get harder to see the closer they are to being hit', null, 'flashlight', 16),
		'morale' => new MechanicData('Morale', 'Keep your morale high by playing good at the game, don\'t lose all of it or you\'ll lose', 'Lost Morale',
			'morale', 17),
		// 'moving_strum' => new MechanicData('Freaky Strum', 'Your strums will sometimes jerk off. Keep your focus', 'freakstrum', 18),
		'limit_health' => new MechanicData('Limited Maximum Health', 'The maximum health you can get is randomized', null, 'healthlimit', 18),
		'minimum_hp' => new MechanicData('Limited Minimum Health', 'The minimum health you can get is randomized', null, 'healthlimit1', 19),
		'shape_obst' => new MechanicData('Polygon Obstruction', 'Random polygon-shapes will obstruct your view on the game', null, 'shape', 20),
		'letter_placement' => new MechanicData('Letter Placement',
			'A random set of letters will be provided for you to press, failing to press them all in time will provide a health loss', 'Attempts',
			'placement', 21),
		'luck' => new MechanicData('Mechanic Luck', 'A random set of points will be provided to a random mechanic, to even going above the limit', null,
			'luck', 22),
		'karma' => new MechanicData('Karma', 'When losing health, a poison effect is applied', 'Damage', 'karma',
			23) // 'rps' => new MechanicData('Rock Paper Scissors', 'Rock Paper Scissors, win more games than your enemy for less penalty', 'rps', 22),
			// 'fake_miss' => new MechanicData('Fake Misses', 'When it\'s your turn, your character will sometimes \'miss\' despite not actually missing', 'fake_miss' 25)
	];

	public static var multiplier:Float = 1;
}

class MechanicData
{
	public var name:String;
	public var results:String;
	public var image:String;
	public var description:String;
	public var points:Int;
	public var ID:Int;

	public var spriteParent:MechanicPortrait;

	public function new(name:String, description:String, results:String, image:String, ID:Int = -1)
	{
		this.name = name;
		this.results = results;
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

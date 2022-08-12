package;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;

enum NoteTypeIterator
{
	GLOBAL;
	HITTABLE;
	OPPONENT;
}

class StrumGroups extends FlxBasic
{
	public var hittableNotes:NoteGroup;
	public var opponentNotes:NoteGroup;
	public var globalNotes:NoteGroup;

	// most of these are just references to globalNotes
	public var length(get, null):Int;
	public var members(get, null):Array<Note>;

	public function new()
	{
		super();

		hittableNotes = new NoteGroup();
		hittableNotes.parent = this;
		opponentNotes = new NoteGroup();
		opponentNotes.parent = this;
		globalNotes = new NoteGroup();
		globalNotes.parent = this;

		hittableNotes.sustains = new FlxTypedGroup<Note>();
		opponentNotes.sustains = new FlxTypedGroup<Note>();
		globalNotes.sustains = new FlxTypedGroup<Note>();
	}

	public function remove(object:Note, splice:Bool = false)
	{
		if (object.mustPress)
			hittableNotes.remove(object, splice);
		else
			opponentNotes.remove(object, splice);
		globalNotes.remove(object, splice);
	}

	public function insert(index:Int, object:Note, splice:Bool = false)
	{
		if (object.mustPress)
			hittableNotes.insert(index, object);
		else
			opponentNotes.insert(index, object);
		globalNotes.insert(index, object);
	}

	public function forEach(Function:Note->Void, Recurse:Bool = false, iterator:NoteTypeIterator = GLOBAL)
	{
		switch (iterator)
		{
			case GLOBAL:
				globalNotes.forEach(Function, Recurse);
			case HITTABLE:
				hittableNotes.forEach(Function, Recurse);
			case OPPONENT:
				opponentNotes.forEach(Function, Recurse);
		}
	}

	public function forEachAlive(Function:Note->Void, Recurse:Bool = false, iterator:NoteTypeIterator = GLOBAL)
	{
		switch (iterator)
		{
			case GLOBAL:
				globalNotes.forEachAlive(Function, Recurse);
			case HITTABLE:
				hittableNotes.forEachAlive(Function, Recurse);
			case OPPONENT:
				opponentNotes.forEachAlive(Function, Recurse);
		}
	}

	public function sort(Function:Int->Note->Note->Int, Order:Int = FlxSort.ASCENDING)
	{
		globalNotes.sort(Function, Order);
		hittableNotes.sort(Function, Order);
		opponentNotes.sort(Function, Order);
	}

	function get_length():Int
	{
		return globalNotes.length;
	}

	function get_members():Array<Note>
	{
		return globalNotes.members;
	}

	override function set_cameras(newCameras:Array<FlxCamera>)
	{
		super.set_cameras(newCameras);

		globalNotes.cameras = newCameras;
		hittableNotes.cameras = newCameras;
		opponentNotes.cameras = newCameras;

		return null;
	}
}

class NoteGroup extends FlxTypedGroup<Note>
{
	public var parent:StrumGroups;
	public var sustains:FlxTypedGroup<Note>;
}

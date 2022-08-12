package;

import flixel.FlxG;

class KeyboardMechanic
{
    public static var firstRow:String = 'qwertyuiop';
    public static var secondRow:String = 'asdfghjkl';
    public static var thirdRow:String = 'zcvbnm';

    public static function generateLetter(scatter:Float, len:Int = 4):String
    {
        var str:String = '';
        var list:Array<String> = [firstRow, secondRow, thirdRow];

        while (str.length != len)
        {
            var pointer:Int = -1;
            var chosenRow:String = FlxG.random.getObject(list);
            var rowIndex:Int = FlxG.random.int(0, chosenRow.length - 1);
 
            pointer = Math.floor(CoolUtil.boundTo(distanceFrom(rowIndex, Std.int(scatter * FlxG.random.float(0.5, 2)), {min: 0, max: chosenRow.length}, FlxG.random.float(50, 80)), 0, chosenRow.length));
            str += chosenRow.charAt(pointer);
        }
        
        return str;
    }

    private static function distanceFrom(from:Int, wander:Int, values:{min:Int, max:Int}, chance:Float):Int
    {
        var distance:Int = from;
        var mult:Int = -1;
        if (FlxG.random.bool())
            mult = 1;

        for (i in 0...Std.int(wander))
        {
            if (FlxG.random.bool(chance * 1.25))
            {
                distance += 1 * mult;
            }

            if (distance <= values.min)
            {
                mult = 1;
                distance = values.min;
            }
            else if (distance >= values.max)
            {
                mult = -1;
                distance = values.max;
            }
        }

        return distance;
    }
}
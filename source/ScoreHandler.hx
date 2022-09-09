package;

import flixel.FlxG;
import flixel.util.FlxSave;

class ScoreHandler
{
    // songScores['song'][diff][0]
    public static var songScores:Map<String, Array<Array<SongScore>>> = [];

    public static var weekScores:Map<String, Array<Array<WeekScore>>> = [];

    // The 2 variables up-top get synced to the save files.
    public static function syncSave():Void
    {
        var save:FlxSave = new FlxSave();
        save.bind('fnf-mechanics-scores', 'eyedalehim');

        if (save.data.songScores != null)
            songScores = save.data.songScores;
        if (save.data.weekScores != null)
            weekScores = save.data.weekScores;

        save.close();
    }

    // gets the song progress
    public static function getBestSong(name:String, diff:Int):SongScore
    {
        if (songScores[name] == null || songScores[name][diff] == null)
            return {name: name, diff: diff, score: 0, misses: 0, accuracy: 0.00, mechanics: [], gameplaySettings: []};

        return songScores[formatSong(name)][diff][0];
    }

    // saves the song progress
    public static function saveSong(name:String, diff:Int, info:SongScore):Array<SongScore>
    {
        if (songScores[name] == null)
            songScores[name] = [];
        
        songScores[name][diff][sortSongByPerf(name, diff, performanceRatio(info))] = info;

        var save:FlxSave = new FlxSave();
        save.bind('fnf-mechanics-scores', 'eyedalehim');
        save.data.songScores = songScores;

        save.close();

        return songScores[formatSong(name)][diff];
    }

    private static function formatSong(name:String):String
    {
        if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 1)
            return Paths.currentModDirectory + '-' + name;
        
        return name;
    }

    // Ok so, here's how the performance ratio works:
    /*
     * We start the performance ratio with a score divided by 50,000.
     * Then, we subtract it by misses divided by 4,000
     * Finally, we'll have the perforance ratio multiplied by the accuracy (0 to 1)
    */
    private static function performanceRatio(info:SongScore):Float
    {
        var PR:Float = 0.0;

        PR += info.score / 50000;
        PR -= info.misses / 4000;
        PR *= info.accuracy;

        return PR;
    }

    private static function sortSongByPerf(name:String, diff:Int, performanceCurRatio:Float):Int
    {
        if (songScores[name][diff].length > 0)
        {
            for (i in 0...songScores[name][diff].length)
            {
                if (songScores[name][diff][i] == null)
                    continue;
                
                if (performanceRatio(songScores[name][diff][i]) < performanceCurRatio)
                    return i;
            }
        }

        return 0;
    }
}

typedef WeekScore = Array<SongScore>;

typedef SongScore = 
{
    var name:String;
    var diff:Int;
    var score:Int;
    var misses:Int;
    var accuracy:Float;
    var mechanics:Array<Int>;
    var gameplaySettings:Map<String, Dynamic>;
}


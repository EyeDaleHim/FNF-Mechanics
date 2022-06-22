package;

import flixel.math.FlxMath;

class ScoreText
{
    public static function generateScore(score:Int)
    {
        return '[Score] ${score}';
    }

    public static function generateMiss(miss:Int)
    {
        return '[Misses] ${miss}';
    }

    public static function generateRating(rating:String, accuracy:Float)
    {
        if (rating == '?')
            return '[Rating] ?';
        return '[Rating] ${rating} (${CoolUtil.formatAccuracy(accuracy)}%)';
    }

    public static function generateRank(rank:Null<String>)
    {
        if (rank == null || rank == '')
            return '';

        return '[${rank}]';
    }

    public static function generateText(score:Int, miss:Int, rating:String, accuracy:Float, rank:String)
    {
        var fullText:String = '';
        var generateList:Array<String> = [generateScore(score), generateMiss(miss), generateRating(rating, accuracy), generateRank(rank)];
        for (i in 0...generateList.length)
        {
            fullText += generateList[i];
            if (i != generateList.length - 1 && generateList[i] != '')
                fullText += ' ';
        }

        return fullText;
    }
}
package;

import flixel.FlxG;
import flixel.math.FlxMath;

class AIPlayer
{
    public static var BadNoteTypes:Array<String> = ['Hurt Note', 'Kill Note', 'Burst Note', 'Sleep Note', 'Fake Note'];

    public static function GeneratePlayMap(map:Song.SwagSong, rules:AI_Rulesets)
    {
        // ok so lets set up some vars
        var AmountOfNotesHit:Int = 0;
        var SectionNumbers:Array<Int> = [];
        var NoteAIStrumTimes:Array<Array<Float>> = [];

        rules.Hand1 = {Finger1: null, Finger2: null};
        rules.Hand2 = {Finger1: null, Finger2: null};
        
        rules.Hand1.Finger1 = new Finger(0);
        rules.Hand1.Finger2 = new Finger(1);

        rules.Hand2.Finger1 = new Finger(2);
        rules.Hand2.Finger2 = new Finger(3);

        rules.Random_Section_Tolerancy = FlxG.random.int(0, 32);

        for (i in 0...map.notes.length)
        {
            SectionNumbers[i] = FlxG.random.int(0, 32);

            NoteAIStrumTimes[i] = [];
        }

        // ok now we're gonna generate the actual playmap
        for (i in 0...map.notes.length)
        {
            AmountOfNotesHit = Math.ceil(Math.max(0, AmountOfNotesHit - FlxG.random.int(4, 13)));
            
            var SectionStartTime:Float = Conductor.stepCrochet * (map.notes[i].lengthInSteps * i);

            for (j in 0...Math.floor(map.notes[i].lengthInSteps / 4))
            {
                var QuarterOfSection:Float = SectionStartTime + (SectionStartTime / j);

                var ListedNotes:Array<Dynamic> = [];
                for (note in map.notes[i].sectionNotes)
                {
                    if (note[0].strumTime > QuarterOfSection)
                        break;

                    var gottaHitNote:Bool = map.notes[i].mustHitSection;

                    if (note[1] > 3)
                    {
                        gottaHitNote = !map.notes[i].mustHitSection;
                    }

                    if (!gottaHitNote)
                        ListedNotes.push(note);
                }

                for (NoteObject in ListedNotes)
                {
                    // lets determine our strumTime for our AI
                    for (Fingers in [rules.Hand1.Finger1, rules.Hand1.Finger1, rules.Hand2.Finger1, rules.Hand2.Finger2])
                    {
                        if (Std.int(NoteObject[1] % 4) == Fingers.noteDirection)
                            Fingers.tiredness += (AmountOfNotesHit > rules.Minimum_Note_Density ? rules.Tireness_Density : rules.Tireness_Density_Before) * Math.random() * 0.895;
                    }

                    var IgnoreBadNoteTypes:Bool = !(AmountOfNotesHit > rules.Minimum_Note_Density); // if the bot is consecutively hitting notes, there's a low chance it will hit notes it's not supposed to

                    if (BadNoteTypes.indexOf(NoteObject[3]) != -1)
                    {
                        if (IgnoreBadNoteTypes)
                        {
                            NoteAIStrumTimes[i][map.notes[i].sectionNotes.indexOf(NoteObject)] = Conductor.safeZoneOffset;
                            continue;
                        }
                    }

                    var RangeFromSafety:Float = (Math.abs(AmountOfNotesHit + FlxG.random.float(-0.465, 0.465) - rules.Maximum_Note_Density));

                    if (RangeFromSafety < 0.465) // we can manage
                        RangeFromSafety /= 2;

                    RangeFromSafety *= 1 - rules.Accuracy_Tolerance;

                    if (!FlxG.random.bool(100 * (RangeFromSafety * (Math.PI - (Math.sqrt(Math.PI / 2)))))) // oh we're hitting the bad note type all right
                    {
                        NoteAIStrumTimes[i][map.notes[i].sectionNotes.indexOf(NoteObject)] = Conductor.safeZoneOffset;

                        continue;
                    }

                    var valueMult:Float = Math.random() > 0.5 ? -1.0 : 1.0;
                        
                    var randomStrum:Float = FlxMath.remapToRange(FlxMath.remapToRange(Math.random() * RangeFromSafety, 0, 1, 0.3, 0.7), -0.2, 1.2, 0, Conductor.safeZoneOffset) * valueMult;

                    if (AmountOfNotesHit > rules.Minimum_Note_Density)
                        randomStrum += (Math.random() * 10) * valueMult;
                    else if (AmountOfNotesHit > rules.Maximum_Note_Density)
                        randomStrum += (FlxMath.remapToRange(Math.random(), 0, 1, 0.3, 1.3) * 30.45) * valueMult;
                    else
                    {
                        randomStrum += (Math.random() * 10) * valueMult;
                        randomStrum /= 1 + Math.random();
                    }

                    if (SectionNumbers[i] == rules.Random_Section_Tolerancy)
                        randomStrum -= (14.6 * Math.random()) * -valueMult; 

                    NoteAIStrumTimes[i][map.notes[i].sectionNotes.indexOf(NoteObject)] = randomStrum;
                    trace(NoteAIStrumTimes[i][map.notes[i].sectionNotes.indexOf(NoteObject)]);

                    AmountOfNotesHit++;
                }
            }
        }

        return NoteAIStrumTimes;
    }
}

typedef AI_Rulesets =
{
    var Accuracy_Tolerance:Float; // 0 to 1, 0.1 means the AI is a terrible cosplayer, 1 means the AI is a god
    
    var Minimum_Note_Density:Float; // How much notes it can handle without breaking a sweat
    var Maximum_Note_Density:Float; // How much notes it can handle before the "tired-mechanism" starts

    // Random value for the AI, if a section's random value is this one, this will always benefit the AI.
    // Otherwise, just depends on the range.
    // Generated from a number between 0 to 32
    var Random_Section_Tolerancy:Int;

    var Tireness_Density_Before:Float; // How each note can make a finger tired, only when the current note amount hits the Minimum_Note_Density
    var Tireness_Density:Float; // How each note can make a finger tired, effective after 


    var Hand1:Hand; // Hand 1, Direction: 0, 1
    var Hand2:Hand; // Hand 2, Direction: 2, 3
}

typedef Hand =
{
    var Finger1:Finger;
    var Finger2:Finger;
}

class Finger
{
    public var noteDirection:Int;
    public var tiredness:Float = 1.0;

    public function new(noteDirection:Int)
    {
        this.noteDirection = noteDirection;
    }
}
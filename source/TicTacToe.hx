package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;

class TicTacToe extends FlxTypedGroup<FlxSprite>
{
	public static var wins:Int = 0;
	public static var loss:Int = 0;

	public var board:Board; // quite literally its just the 3x3 tiles in data
	public var reduceTime:Bool = true;
	public var time:Float = 0;
	public var maxTime:Float = 0;
	public var timeTxt:FlxText;
	public var bgSprite:FlxSprite;
	public var canDoAction:Bool = true;
	public var tileSprites:Array<Array<TileSprite>> = [];
	public var formerX:Float = 0;
	public var formerY:Float = 0;

	// 1% chance to get a message from these
	// also credits to some people from psych engine for messages
	public static var winMessages:Array<String> = [
		'yuro\'e mom',
		'dub so big that BF and GF from FNF came to see it',
		'Daddy Dearest\nwould be ashamed...',
		"Friday Night Funkin' - Perfect Combo",
		"Unholywanderer04 is better than you lol lo lmao loan lo l"
	];
	public static var tieMessages:Array<String> = [
		'I swear to the heavens above...',
		'Shado Merio psyco eng fail',
		'Uou have to TRY you know.',
		'One of you has to WIN dum dum',
		"I guess there's enough space for 2.",
		"Delusive ass AI"
	];
	public static var lossMessages:Array<String> = [
		'skill issue',
		'EyeDale? more like EyeFail lol lmao lol lol lol',
		'bruh moment',
		'I am in your walls.',
		"That was underwhelming.",
		'My fuckin healthhh noooooo',
		'man you really are unholy because god is not on your side',
		'this town aint big enough for the both us',
		'L so big, I gotta whoop yo ass',
		'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
		"my blind grandma could play better ngl",
		"You have to use the mouse not whatever that was"
	];

	public function new(X:Float = 0, Y:Float = 0)
	{
		super();

		this.formerX = X;
		this.formerY = Y;

		maxTime = FlxMath.remapToRange(MechanicManager.mechanics['tictactoe'].points, 1, 20, 40, 15);
		time = maxTime;

		wins = 0;
		loss = 0;

		var colors:Array<Int> = [0xFFEBE8E8, 0xFFFFFFFF];
		var curColor:Array<Array<Int>> = [[], [], []];

		board = [];

		for (i in 0...3) // set up 3x3 tile data
		{
			board[i] = [];
			for (j in 0...3)
			{
				if (i == 0 || i == 2) // yes i know
				{
					if (j == 0 || j == 2)
						curColor[i][j] = colors[0];
					else if (j == 1)
						curColor[i][j] = colors[1];
				}
				else if (i == 1)
				{
					if (j == 0 || j == 2)
						curColor[i][j] = colors[1];
					else if (j == 1)
						curColor[i][j] = colors[0];
				}
				board[i].push(0);
			}
		}

		bgSprite = new FlxSprite(formerX - 4, formerY - 4 - 20);
		var cornerRight:Array<Float> = [];

		for (row in 0...board.length)
		{
			for (col in 0...board[row].length)
			{
				var tileSprite:TileSprite = new TileSprite(formerX + (44 * row), formerY + (44 * col));
				tileSprite.makeGraphic(40, 40, curColor[row][col]);
				tileSprite.formerColor = curColor[row][col];
				tileSprite.move = new Move(row, col);
				tileSprite.scrollFactor.set();
				tileSprite.alpha = 0.3;
				tileSprite.cameras = [PlayState.instance.camOther];
				add(tileSprite);
				if (tileSprites[row] == null)
					tileSprites[row] = [];
				tileSprites[row].push(tileSprite);
				if (row == 2 && col == 2)
				{
					cornerRight = [tileSprite.width * (row + 1), tileSprite.height * (col + 1)];
				}
			}
		}

		bgSprite.makeGraphic(Std.int(cornerRight[0] + 16), Std.int(cornerRight[1] + 16 + 20), FlxColor.BLACK);
		bgSprite.scrollFactor.set();
		bgSprite.alpha = 0.6;
		bgSprite.cameras = [PlayState.instance.camOther];
		insert(0, bgSprite);

		timeTxt = new FlxText(formerX + (bgSprite.width / 2), formerY - 22, 0, "2:22", 16);
		timeTxt.scrollFactor.set();
		timeTxt.cameras = [PlayState.instance.camOther];
		add(timeTxt);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (reduceTime)
			time -= elapsed;
		time = CoolUtil.boundTo(time, 0, maxTime);

		if (timeTxt != null && bgSprite != null)
		{
			timeTxt.text = FlxStringUtil.formatTime(time, false);
			timeTxt.x = bgSprite.getGraphicMidpoint().x - (timeTxt.width / 2);
		}

		for (spr in FlxArrayUtil.flatten2DArray(tileSprites))
		{
			var mousePos = FlxG.mouse.getScreenPosition(PlayState.instance.camOther);
			if ((mousePos.x >= spr.x && mousePos.x <= spr.x + spr.width) && (mousePos.y >= spr.y && mousePos.y <= spr.y + spr.height))
				hoverOver(spr);
			else
				spr.color = FlxColor.interpolate(spr.color, spr.formerColor, CoolUtil.boundTo(FlxG.elapsed * 7.5, 0, 1));
		}
	}

	public function hoverOver(spr:TileSprite)
	{
		spr.color = FlxColor.interpolate(spr.color, FlxColor.fromRGBFloat(0.8, 0.8, 0.8, 1), CoolUtil.boundTo(FlxG.elapsed * 7.5, 0, 1));
		if (FlxG.mouse.justPressed && canDoAction)
		{
			spawnPlayer(spr);
		}
	}

	public var playerSprites:Array<FlxSprite> = [];

	public function spawnPlayer(spr:TileSprite, ?isAI:Bool = false)
	{
		if (!isAI)
		{
			canDoAction = false;
			reduceTime = false;
		}

		var newSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(isAI ? 'tictactoe_circle' : 'tictactoe_cross'));
		newSprite.scrollFactor.set();
		newSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(newSprite);
		playerSprites.push(newSprite);
		newSprite.scale.set();

		newSprite.x = spr.x;
		newSprite.y = spr.y;
		FlxTween.tween(newSprite.scale, {x: 1, y: 1}, 0.6, {ease: FlxEase.quadOut});

		board[spr.move.row][spr.move.col] = 2;

		if (!isAI)
		{
			new FlxTimer().start(1.25, function(tmr:FlxTimer)
			{
				canDoAction = true;

				var bestMoveAI:Move = TicTacToeAI.findBestMove(board);
				board[bestMoveAI.row][bestMoveAI.col] = 1;
				trace('${bestMoveAI.row} + ${bestMoveAI.col}');
				spawnPlayer(tileSprites[bestMoveAI.row][bestMoveAI.col], true);

				FlxTween.tween(this, {time: maxTime}, 0.65, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						reduceTime = true;
					}
				});

				// checkWinner();
			});
		}
	}

	public function checkWinner():Void
	{
		if (!TicTacToeAI.isMovesLeft(board))
		{
			switch (TicTacToeAI.evaluate(board))
			{
				case 0:
					{
						makeText(FlxG.random.bool(1) ? tieMessages[FlxG.random.int(0, tieMessages.length - 1)] : 'Tie!');
						clearBoard();
						trace('tie');
					}
				case 1:
					{
						loss++;
						makeText(FlxG.random.bool(1) ? winMessages[FlxG.random.int(0, winMessages.length - 1)] : 'Loss!');
						clearBoard();
						trace('loss');
					}
				case 2:
					{
						wins++;
						makeText(FlxG.random.bool(1) ? winMessages[FlxG.random.int(0, winMessages.length - 1)] : 'Win!');
						clearBoard();
						trace('won');
					}
			}
		}
	}

	public function clearBoard()
	{
		/*for (row in 0...board.length)
			{
				for (col in 0...board[row].length)
				{
					if (board[row] == null)
						board[row] = [];

					board[row][col] = -1;
					FlxTween.tween(playerSprites[row * col].scale, {x: 0, y: 0}, 0.3, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							playerSprites[row * col].kill();
							remove(playerSprites[row * col], true);
							playerSprites.remove(playerSprites[row * col]);
							playerSprites[row * col].destroy();
						}
					});
				}
		}*/
	}

	public function makeText(text:String = ''):Void
	{
	}
}

class TicTacToeAI
{
	public static var player:Int = 2;
	public static var opponent:Int = 1;

	public static function isMovesLeft(board:Board)
	{
		for (row in 0...board.length)
		{
			for (col in 0...board[row].length)
			{
				if (board[row][col] == 0) // empty square
					return true;
			}
		}

		return false;
	}

	public static function evaluate(board:Board):Int
	{
		for (row in 0...board.length)
		{
			if (board[row] == null)
				board[row] = [0, 0, 0];
			if (board[row][0] == board[row][1] && board[row][1] == board[row][2])
			{
				if (board[row][0] == 0)
					return player; // way to go! you won!
				else if (board[row][0] == 1)
					return opponent; // NOOOOOOOOOOOOOOOOOOO
			}
		}

		for (col in 0...board.length)
		{
			if (board[0][col] == board[1][col] && board[1][col] == board[2][col])
			{
				if (board[0][col] == 0)
					return player;
				else if (board[0][col] == 1)
					return opponent;
			}
		}

		if (board[0][0] == board[1][1] && board[1][1] == board[2][2])
		{
			if (board[0][0] == 0)
				return player;
			else if (board[0][0] == 1)
				return opponent;
		}

		if (board[0][2] == board[1][1] && board[1][1] == board[2][0])
		{
			if (board[0][2] == 0)
				return player;
			else if (board[0][2] == 1)
				return opponent;
		}

		return 0; // ok we can continue
	}

	public static function minimax(board:Board, depth:Int, isMax:Bool):Float
	{
		var score:Int = evaluate(board);

		if (score == 2)
			return score;

		if (score == 1)
			return score;

		if (!isMovesLeft(board))
			return 0;

		var returned:Float = 0;

		if (isMax)
		{
			var best:Float = -2;

			for (i in 0...3)
			{
				for (j in 0...3)
				{
					// cell empty?
					if (board[i][j] == 0)
					{
						board[i][j] = 2;
					}

					best = Math.max(best, minimax(board, depth + 1, !isMax));

					board[i][j] = 0;
				}
			}
			returned = best;
		}
		else
		{
			var best:Float = 2;

			for (i in 0...3)
			{
				for (j in 0...3)
				{
					if (board[i][j] == 0)
					{
						board[i][j] = 1;
					}

					best = Math.min(best, minimax(board, depth + 1, !isMax));

					board[i][j] = 0;
				}
			}
			returned = best;
		}
		return returned;
	}

	public static function findBestMove(board:Board):Move
	{
		var bestVal:Float = -2;
		var bestMove = new Move(-1, -1);

		for (i in 0...3)
		{
			for (j in 0...3)
			{
				if (board[i][j] == 0)
				{
					board[i][j] = player;

					var moveVal = minimax(board, 0, false);

					board[i][j] = 0;

					if (moveVal > bestVal)
					{
						bestMove.row = i;
						bestMove.col = j;
						bestVal = moveVal;
					}
				}
			}
		}

		return bestMove;
	}
}

class Move
{
	public var row:Int = 0;
	public var col:Int = 0;

	public function new(?row:Int = 0, ?col:Int = 0)
	{
		this.row = row;
		this.col = col;
	}
}

class TileSprite extends FlxSprite
{
	public var move:Move = null;
	public var formerColor:Int = 0;
}

typedef Board = Array<Array<Int>>;

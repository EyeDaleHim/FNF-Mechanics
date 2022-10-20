package;

import flixel.FlxG;
import haxe.io.Bytes;
import openfl.events.Event;
import udprotean.server.UDProteanClientBehavior;
import udprotean.client.UDProteanClient;

class MultiplayerHandler
{
	public static final CLIENT_ENC_KEY:Bytes = Bytes.ofString('', UTF8);

	public static var CLIENT_HANDLER:FNFClient;
	public static var SERVER_HANDLER:FNFClient;

	public static function initialize():Void
	{
		// CLIENT_HANDLER = new FNFClient("127.0.0.1", 9000);
		// SERVER_HANDLER = new FNFServer("0.0.0.0", 9000, FNFClient);

		// SERVER_HANDLER.start();
	}

	private static var __IS_PLAYSTATE:Bool = false;

	public static function update(elapsed:Float):Void
	{
		if (__IS_PLAYSTATE)
		{
		}

		SERVER_HANDLER.update();
	}
}

class FNFClient extends UDProteanClient
{
	override public function initialize():Void
	{
		super.initialize();

		trace('client initialized');
	}

	override public function onMessage(b:Bytes)
	{
		trace(b.toString());
	}
}

class FNFServer extends UDProteanClientBehavior
{
}

package;

import flixel.system.FlxAssets.FlxShader;

class MosaicEffect extends FlxShader
{
    public var shader(default, null):MosaicShader = new MosaicShader();

	public function new():Void
	{
        super();
	}
}

class MosaicShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header
    
    void main()
    {
        vec2 blocks = openfl_TextureSize / 2;
         gl_FragColor = texture2D(bitmap, floor(openfl_TextureCoordv * blocks) / blocks);
    }
    ')

    public function new()
    {
        super();
    }
}
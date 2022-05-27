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
    uniform bool small = false;
    
    void main()
    {
        vec2 blocks = openfl_TextureSize / (0.5);
        if (small)
            // fuck you
            gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
        else
            gl_FragColor = texture2D(bitmap, floor(openfl_TextureCoordv * blocks) / blocks);
    }
    ')

    public function new()
    {
        super();
    }
}
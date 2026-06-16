package legacy.shaders;

import flixel.addons.display.FlxRuntimeShader;
import animate.internal.filters.AdjustColorFilter;
import funkin.util.ReflectUtil;
import flixel.math.FlxAngle;

class ExtraDropShadowShader extends FlxRuntimeShader
{
	public var antialiasing(get, set):Bool;
	public var operation(default, set):LayerOperation = 'replace';
	public var hollowColorMatrix(get, set):Array<Float>;
	public var colorMatrix(get, set):Array<Float>;
	public var layers:Array<ExtraDropShadowLayer>;
	public var thresholdMode(get, set):ThreshMode;
	public var antialiasStages(get, set):Float;
	public var roughness(get, set):Float;
	public var threshold(get, set):Float;
	public var strength(get, set):Float;
	
	public var attachedSprite(default, set):FlxSprite = null;
	var __attachedSpriteHook:String -> Int -> Int -> Void;
	
	public var activeLayers(get, never):Int;
	
	public function copyFrom(from:ExtraDropShadowShader):ExtraDropShadowShader
	{
		for (i => layer in layers) layer.copyFrom(from.layers[i]);
		
		antialiasStages = from.antialiasStages;
		thresholdMode = from.thresholdMode;
		threshold = from.threshold;
		operation = from.operation;
		roughness = from.roughness;
		strength = from.strength;
		
		for (i in 0 ... 16)
		{
			this.data.shadowMultipliers.value[i] = from.data.shadowMultipliers.value[i];
			this.data.hollowMultipliers.value[i] = from.data.hollowMultipliers.value[i];
		}
		for (i in 0 ... 4)
		{
			this.data.shadowOffsets.value[i] = from.data.shadowOffsets.value[i];
			this.data.hollowOffsets.value[i] = from.data.hollowOffsets.value[i];
		}
		
		return this;
	}
	public function setColorMatrix(matrix:Array<Float>):ExtraDropShadowShader
	{
		colorMatrix = matrix;
		
		return this;
	}
	public function setAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowShader
	{
		return setColorMatrix(@:privateAccess AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	public function setHollowColorMatrix(matrix:Array<Float>):ExtraDropShadowShader
	{
		hollowColorMatrix = matrix;
		
		return this;
	}
	public function setHollowAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowShader
	{
		return setHollowColorMatrix(@:privateAccess animate.internal.filters.AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	
	public function addLayer(colorMatrix:Array<Float>, angle:Float = 0, distance:Float = 20, threshold:Float = .01, strength:Float = 1, roughness:Float = 1):ExtraDropShadowLayer
	{
		var rimlight:ExtraDropShadowLayer = getFreeLayer();
		
		if (rimlight == null)
		{
			trace('we outta rimlight\'s');
			return null;
		}
		
		return rimlight.setColorMatrix(colorMatrix).setAttributes(angle, distance, threshold, strength, roughness);
	}
	
	public function updateFrameInfo(frame:Null<flixel.graphics.frames.FlxFrame>):Void
	{
		if (frame == null) return;
		
		this.data.frameBounds.value = [frame.uv.left, frame.uv.top, frame.uv.right, frame.uv.bottom];
		this.data.angOffset.value = [frame.angle * FlxAngle.TO_RAD];
	}
	
	function getFreeLayer():Null<ExtraDropShadowLayer>
	{
		for (rimlight in layers)
		{
			if (!rimlight.active) return rimlight;
		}
		
		return null;
	}
	
	function set_attachedSprite(sprite:FlxSprite):FlxSprite
	{
		if (attachedSprite != null)
		{
			if (attachedSprite.shader == this) attachedSprite.shader = null;
			
			if (attachedSprite != null && attachedSprite.animation != null && attachedSprite.animation.onFrameChange != null && __attachedSpriteHook != null) attachedSprite.animation.onFrameChange.remove(__attachedSpriteHook);
		}
		
		attachedSprite = sprite;
		
		if (sprite != null)
		{
			sprite.animation.onFrameChange.add(__attachedSpriteHook);
			
			updateFrameInfo(sprite.frame);
			
			sprite.shader = super;
		}
		
		return sprite;
	}
	
	function set_operation(op:LayerOperation):LayerOperation
	{
		this.data.stack.value = [op == 'stack'];
		
		return operation = op;
	}
	
	public function new()
	{
		super(Assets.getText(Paths.frag('extraDropShadow')));
		
		__attachedSpriteHook = function(_, _, _)
		{
			if (attachedSprite == null) return;
			
			antialiasing = attachedSprite.antialiasing;
			this.data.scale.value[0] = attachedSprite.scale.x;
			this.data.scale.value[1] = attachedSprite.scale.y;
			updateFrameInfo(attachedSprite.frame);
		}
		
		this.data.shadowMultipliers.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		this.data.shadowOffsets.value = [0, 0, 0, 0];
		this.data.hollowMultipliers.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		this.data.hollowOffsets.value = [0, 0, 0, 0];
		this.data.uShadowStrength.value = [1];
		this.data.uThreshMode.value = [1];
		this.data.uThreshold.value = [0];
		this.data.uRoughness.value = [1];
		this.data.scale.value = [1, 1];
		this.data.aaStages.value = [0];
		this.data.aa.value = [true];
		
		layers = [
			for (id in 0 ... 6) {
				new ExtraDropShadowLayer(
					ReflectUtil.field(this.data, 'rimlightMultipliers$id').value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
					ReflectUtil.field(this.data, 'rimlightOffsets$id').value = [0, 0, 0, 0],
					ReflectUtil.field(this.data, 'rimlightData$id').value = [0, 0, 0, -1, 1, 0, 0, 0, 0]
				);
			}
		];
		
		operation = 'replace';
	}
	
	inline function get_colorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? this.data.shadowOffsets.value[Math.floor(i / 5)] : this.data.shadowMultipliers.value[i - Math.floor(i / 5)])];
	}
	inline function set_colorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) this.data.shadowMultipliers.value[i] = matrix[i + Math.floor(i / 4)];
		for (i in 0 ... 4) this.data.shadowOffsets.value[i] = (matrix[i * 5 + 4] / 255);
		
		return matrix;
	}
	
	inline function get_hollowColorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? this.data.hollowOffsets.value[Math.floor(i / 5)] : this.data.hollowMultipliers.value[i - Math.floor(i / 5)])];
	}
	inline function set_hollowColorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) this.data.hollowMultipliers.value[i] = matrix[i + Math.floor(i / 4)];
		for (i in 0 ... 4) this.data.hollowOffsets.value[i] = (matrix[i * 5 + 4] / 255);
		
		return matrix;
	}
	
	inline function get_activeLayers():Int
	{
		var i:Int = 0;
		for (rimlight in layers) if (rimlight.active) i ++;
		
		return i;
	}
	
	inline function get_antialiasing():Bool { return this.data.aa.value[0]; }
	inline function set_antialiasing(v:Bool):Bool { return this.data.aa.value[0] = v; }
	
	inline function get_antialiasStages():Float { return this.data.aaStages.value[0]; }
	inline function set_antialiasStages(v:Float):Float { return this.data.aaStages.value[0] = v; }
	
	inline function get_roughness():Float { return this.data.uRoughness.value[0]; }
	inline function set_roughness(v:Float):Float { return this.data.uRoughness.value[0] = v; }
	
	inline function get_threshold():Float { return this.data.uThreshold.value[0]; }
	inline function set_threshold(v:Float):Float { return this.data.uThreshold.value[0] = v; }
	
	inline function get_strength():Float { return this.data.uShadowStrength.value[0]; }
	inline function set_strength(v:Float):Float { return this.data.uShadowStrength.value[0] = v; }
	
	inline function get_thresholdMode():ThreshMode { return (this.data.uThreshMode.value[0] == 0 ? 'luminance' : 'value'); }
	inline function set_thresholdMode(v:ThreshMode):ThreshMode
	{
		this.data.uThreshMode.value[0] = (v == 'value' ? 1 : 0);
		
		return v;
	}
}

// puppy 's first private class >w<Ok sorry
private class ExtraDropShadowLayer
{
	public var active(get, set):Bool;
	
	public var angle(get, set):Float;
	public var distance(get, set):Float;
	public var threshold(get, set):Float;
	public var strength(get, set):Float;
	public var roughness(get, set):Float;
	
	public var colorMatrix(get, set):Array<Float>;
	public var multipliers:Array<Float>;
	public var offsets:Array<Float>;
	var data:Array<Float>;
	
	public function new(multipliers:Array<Float>, offsets:Array<Float>, data:Array<Float>)
	{
		this.multipliers = multipliers;
		this.offsets = offsets;
		this.data = data;
	}
	
	public function copyFrom(from:ExtraDropShadowLayer):ExtraDropShadowLayer
	{
		for (i in 0 ... 16) multipliers[i] = from.multipliers[i];
		for (i in 0 ... 4) offsets[i] = from.offsets[i];
		
		return setAttributes(from.angle, from.distance, from.threshold, from.strength, from.roughness);
	}
	public inline function setAttributes(angle:Float = 0, distance:Float = 20, threshold:Float = .01, strength:Float = 1, roughness:Float = 1):ExtraDropShadowLayer
	{
		this.angle = angle;
		this.distance = distance;
		this.threshold = threshold;
		this.strength = strength;
		this.roughness = roughness;
		
		return this;
	}
	public function setColorMatrix(matrix:Array<Float>):ExtraDropShadowLayer
	{
		colorMatrix = matrix;
		
		return this;
	}
	public function setAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowLayer
	{
		return setColorMatrix(@:privateAccess AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	
	inline function get_active():Bool { return (strength > 0); }
	inline function set_active(active:Bool):Bool
	{
		strength = (active ? Math.abs(strength) : -Math.abs(strength));
		return active;
	}
	
	inline function get_angle():Float { return (data[0] * FlxAngle.TO_DEG); }
	inline function set_angle(v:Float):Float { return data[0] = (v * FlxAngle.TO_RAD); }
	
	inline function get_distance():Float { return data[1]; }
	inline function set_distance(v:Float):Float { return data[1] = v; }
	
	inline function get_threshold():Float { return data[2]; }
	inline function set_threshold(v:Float):Float { return data[2] = v; }
	
	inline function get_strength():Float { return data[3]; }
	inline function set_strength(v:Float):Float { return data[3] = v; }
	
	inline function get_roughness():Float { return data[4]; }
	inline function set_roughness(v:Float):Float { return data[4] = v; }
	
	inline function get_colorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? (offsets[Math.floor(i / 5)] * 255) : multipliers[i - Math.floor(i / 5)])];
	}
	inline function set_colorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) multipliers[i] = (matrix[i + Math.floor(i / 4)] ?? 0);
		for (i in 0 ... 4) offsets[i] = ((matrix[i * 5 + 4] ?? 0) / 255);
		
		return matrix;
	}
}
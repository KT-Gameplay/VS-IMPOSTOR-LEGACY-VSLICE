#pragma header

uniform vec3 r;
uniform vec3 g;
uniform vec3 b;

uniform float mult;
uniform float enabled;

uniform float a_alpha;
uniform float a_flash;

		vec4 rgb(sampler2D bitmap, vec2 coord) 
		{
			vec4 color = flixel_texture2D(bitmap, coord);
			
			if (!hasTransform || color.a == 0. || mult == 0. || enabled == 0.) return color;

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult * enabled);
			
			if (color.a > 0.) return vec4(color.rgb, color.a);
			
			return vec4(0.);
		}

		void main() 
		{
			vec4 texOutput = rgb(bitmap, openfl_TextureCoordv);
			
			if (a_flash != 0.0) texOutput = mix(texOutput, vec4(1.), a_flash) * texOutput.a;

			texOutput *= a_alpha;

			gl_FragColor = texOutput;
		}
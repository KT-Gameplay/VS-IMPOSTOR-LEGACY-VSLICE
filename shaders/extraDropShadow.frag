#pragma header
		
		// cant set uniofrm arrays in openfl so i guess i just have to deal with this SUTPID shit
		uniform mat4 rimlightMultipliers0; uniform mat4 rimlightMultipliers1; uniform mat4 rimlightMultipliers2;
		uniform mat4 rimlightMultipliers3; uniform mat4 rimlightMultipliers4; uniform mat4 rimlightMultipliers5;
		
		uniform vec4 rimlightOffsets0; uniform vec4 rimlightOffsets1; uniform vec4 rimlightOffsets2;
		uniform vec4 rimlightOffsets3; uniform vec4 rimlightOffsets4; uniform vec4 rimlightOffsets5;
		
		uniform mat3 rimlightData0; uniform mat3 rimlightData1; uniform mat3 rimlightData2;
		uniform mat3 rimlightData3; uniform mat3 rimlightData4; uniform mat3 rimlightData5;
		/*
		[
		angle, 		distance, 	threshold,
		strength, 	roughness, 	idk
		idk, 		idk, 		idk
		]
		
		cant qwait for this to bite me in the butt
		*/
		
		uniform bool aa;
		uniform float aaStages;
		uniform vec2 scale;
		
		uniform float uThreshold;
		uniform float uRoughness;
		uniform float uShadowStrength;
		uniform int uThreshMode;
		uniform bool stack;
		
		uniform mat4 hollowMultipliers;
		uniform vec4 hollowOffsets;
		
		uniform mat4 shadowMultipliers;
		uniform vec4 shadowOffsets;
		
		uniform float angOffset;
		uniform vec4 frameBounds;
		
		float intensity(vec4 color) {
			return (uThreshMode == 0 ? dot(color.rgb, vec3(.2126, .7152, .0722)) : max(max(color.r, color.g), color.b));
		}
		
		float cutoff(vec4 color, float thresh, float roughness) {
			if (thresh <= 0.) return 1.;
			
			return clamp((intensity(color) - thresh) * (1. - thresh) * 4. * roughness, 0., 1.);
		}
		
		vec2 hash22(vec2 p) {
			vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
			p3 += dot(p3, p3.yzx + 33.33);
			return fract((p3.xx + p3.yz) * p3.zy);
		}
		
		float antialias(vec2 coord, float thresh, float roughness) { // form the fnf shader
			if (aaStages == 0. || !aa) return cutoff(texture2D(bitmap, coord), thresh, roughness);
			
			const int MAX_AA = 8;

			float AA_TOTAL_PASSES = (aaStages * aaStages + 1.);
			const float AA_JITTER = .5;
			
			float intensity = cutoff(texture2D(bitmap, coord), thresh, roughness);
			for (int i = 0; i < MAX_AA * MAX_AA; i++) {
				int x = (i / MAX_AA);
				int y = (i - (MAX_AA * int(i/MAX_AA)));
				
				if (float(x) >= aaStages || float(y) >= aaStages) continue;
				
				vec2 offset = (AA_JITTER * (2. * hash22(vec2(float(x), float(y))) - 1.) / openfl_TextureSize);
				intensity += cutoff(texture2D(bitmap, coord + offset), thresh, roughness);
			}
			
			return (intensity / AA_TOTAL_PASSES);
		}
		
		float getLayerIntensity(vec4 color, mat3 data) {
			float strength = data[1].x;
			
			if (strength <= 0.) return 0.;
			
			float angle = data[0].x;
			float dist = data[0].y;
			
			vec2 coord = vec2(
				openfl_TextureCoordv.x + dist * cos(angle + angOffset) / scale.x / openfl_TextureSize.x,
				openfl_TextureCoordv.y - dist * sin(angle + angOffset) / scale.y / openfl_TextureSize.y
			);
			
			if (!aa) coord = (floor(coord * openfl_TextureSize) / openfl_TextureSize);
			
			float rimIntensity = (1. - texture2D(bitmap, coord).a);
			if (frameBounds.z > 0 && (coord.x < frameBounds.x || coord.y < frameBounds.y || coord.x >= frameBounds.z || coord.y >= frameBounds.w)) rimIntensity = 1.;
			
			return (rimIntensity * strength * antialias(openfl_TextureCoordv, data[0].z, data[1].y));
		}
		
		vec4 applyLayer(vec4 tintedColor, vec4 baseColor, mat4 multipliers, vec4 offsets, float intensity) {
			if (intensity <= 0.) return tintedColor;
			
			return mix(tintedColor, clamp((stack ? tintedColor : baseColor) * multipliers + offsets, 0., 1.), intensity);
		}
		
		void main() {
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			
			if (color.a == 0.) {
				gl_FragColor = vec4(0.);
			} else {
				if (color.a > 0.) color.rgb /= color.a;
				
				if (openfl_HasColorTransform || hasColorTransform) color = clamp(color * vec4(openfl_ColorMultiplierv.rgb, 1.) + openfl_ColorOffsetv, 0., 1.);
				
				vec4 tinted = clamp(color * hollowMultipliers + hollowOffsets, 0., 1.);
				tinted = applyLayer(tinted, color, shadowMultipliers, shadowOffsets, antialias(openfl_TextureCoordv, uThreshold, uRoughness * 4.) * uShadowStrength);
				
				tinted = applyLayer(tinted, color, rimlightMultipliers5, rimlightOffsets5, getLayerIntensity(color, rimlightData5));
				tinted = applyLayer(tinted, color, rimlightMultipliers4, rimlightOffsets4, getLayerIntensity(color, rimlightData4));
				tinted = applyLayer(tinted, color, rimlightMultipliers3, rimlightOffsets3, getLayerIntensity(color, rimlightData3));
				tinted = applyLayer(tinted, color, rimlightMultipliers2, rimlightOffsets2, getLayerIntensity(color, rimlightData2));
				tinted = applyLayer(tinted, color, rimlightMultipliers1, rimlightOffsets1, getLayerIntensity(color, rimlightData1));
				tinted = applyLayer(tinted, color, rimlightMultipliers0, rimlightOffsets0, getLayerIntensity(color, rimlightData0));
				
				gl_FragColor = vec4(tinted.rgb * tinted.a * openfl_Alphav, tinted.a * openfl_Alphav);
			}
		}
////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in float vlFactor;

noperspective in vec2 texCoord;

flat in vec3 upVec, sunVec;

//Uniforms//
uniform int isEyeInWater;

uniform vec3 fogColor;
uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if defined LIGHTSHAFTS_ACTIVE || WATER_QUALITY >= 3 || defined MULTICOLORED_BLOCKLIGHT
	uniform float far, near;

	uniform mat4 gbufferProjection;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 shadowModelView;
	uniform mat4 shadowProjection;

	uniform sampler2D noisetex;
#endif

#ifdef LIGHTSHAFTS_ACTIVE
	uniform int frameCounter;

	uniform float viewWidth, viewHeight;
	uniform float blindness;
	uniform float darknessFactor;
	uniform float frameTime;
	uniform float frameTimeSmooth;

	uniform ivec2 eyeBrightness;

	uniform vec3 skyColor;

	uniform sampler2D colortex3;
	uniform sampler2DShadow shadowtex0;
	uniform sampler2DShadow shadowtex1;
	uniform sampler2D shadowcolor1;
#endif

#if WATER_QUALITY >= 3
	uniform sampler2D colortex1;
#endif

#if OVERWORLD_BEAMS_CONDITION == 0
	uniform int moonPhase;
#endif

#ifdef MULTICOLORED_BLOCKLIGHT
	#ifndef LIGHTSHAFTS_ACTIVE
		uniform float viewWidth, viewHeight;
		uniform int frameCounter;
	#endif

	uniform vec3 previousCameraPosition;

	uniform mat4 gbufferPreviousModelView;
	uniform mat4 gbufferPreviousProjection;

	uniform sampler2D colortex8;
	uniform sampler2D colortex9;
#endif

//Pipeline Constants//
//const bool colortex0MipmapEnabled = true;

#ifdef MULTICOLORED_BLOCKLIGHT
	const bool colortex9Clear = false;
#endif

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;

#ifdef LIGHTSHAFTS_ACTIVE
	float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
	float sunVisibility2 = sunVisibility * sunVisibility;
	float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
	float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
	float shadowTime = shadowTimeVar2 * shadowTimeVar2;
	float vlTime = min(abs(SdotU) - 0.05, 0.15) / 0.15;

	vec2 view = vec2(viewWidth, viewHeight);
	
	#ifdef OVERWORLD
		vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	#else
		vec3 lightVec = sunVec;
	#endif
#endif

//Common Functions//
#ifdef MULTICOLORED_BLOCKLIGHT
	float GetLinearDepth(float depth) {
    	return (2.0 * near) / (far + near - depth * (far - near));
	}

	vec2 Reprojection(vec3 pos) {
		pos = pos * 2.0 - 1.0;

		vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
		viewPosPrev /= viewPosPrev.w;
		viewPosPrev = gbufferModelViewInverse * viewPosPrev;

		vec3 cameraOffset = cameraPosition - previousCameraPosition;
		cameraOffset *= float(pos.z > 0.56);

		vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
	}

	vec2 OffsetDist(float x) {
		float n = fract(x * 16.2) * 2 * pi;
    	return vec2(cos(n), sin(n)) * x;
	}

	vec3 GetMultiColoredBlocklight(vec2 coord, float z, float dither) {
		vec2 prevCoord = Reprojection(vec3(coord, z));
		float lz = GetLinearDepth(z);

		float distScale = clamp((far - near) * lz + near, 4.0, 128.0);
		float fovScale = gbufferProjection[1][1] / 1.37;

		vec2 blurstr = vec2(1.0 / (viewWidth / viewHeight), 1.0) * fovScale / distScale;
		vec3 lightAlbedo = texture2D(colortex8, coord).rgb;
		vec3 previousColoredLight = vec3(0.0);

		float mask = clamp(2.0 - 2.0 * max(abs(prevCoord.x - 0.5), abs(prevCoord.y - 0.5)), 0.0, 1.0);

		vec2 offset = OffsetDist(dither) * blurstr;
		previousColoredLight += texture2D(colortex9, prevCoord.xy + offset).rgb;
		previousColoredLight *= previousColoredLight * mask;

		return sqrt(mix(previousColoredLight, lightAlbedo * lightAlbedo / clamp(previousColoredLight.r + previousColoredLight.g + previousColoredLight.b, 0.01, 1.0), 0.01));
	}
#endif

//Includes//
#include "/lib/atmospherics/fog/waterFog.glsl"

#if defined BLOOM_FOG && !defined MOTION_BLURRING
	#include "/lib/atmospherics/fog/bloomFog.glsl"
#endif

#ifdef LIGHTSHAFTS_ACTIVE
	#if defined END && defined END_BEAMS
		#include "/lib/atmospherics/enderBeams.glsl"
	#endif
	#include "/lib/atmospherics/volumetricLight.glsl"

	#ifdef ATM_COLOR_MULTS
		#include "/lib/colors/colorMultipliers.glsl"
	#endif
#endif

#if WATER_QUALITY >= 3
	#include "/lib/util/spaceConversion.glsl"

	#include "/lib/materials/materialMethods/refraction.glsl"
#endif

//Program//
void main() {
	vec3 color = texelFetch(colortex0, texelCoord, 0).rgb;
	float z0 = texelFetch(depthtex0, texelCoord, 0).r;
	float z1 = texelFetch(depthtex1, texelCoord, 0).r;

	#if defined LIGHTSHAFTS_ACTIVE || WATER_QUALITY >= 3 || defined BLOOM_FOG && !defined MOTION_BLURRING
		vec4 screenPos = vec4(texCoord, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;
		float lViewPos = length(viewPos.xyz);
	#endif

	#if defined LIGHTSHAFTS_ACTIVE || defined MULTICOLORED_BLOCKLIGHT
		float dither = texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 128.0).b;
		#ifdef TAA
			dither = fract(dither + 1.61803398875 * mod(float(frameCounter), 3600.0));
		#endif
		#ifdef MULTICOLORED_BLOCKLIGHT
			float lightZ = z1 >= 1.0 ? z0 : z1;
			vec3 coloredLight = GetMultiColoredBlocklight(texCoord, lightZ, dither);
		#endif
	#endif

	#if WATER_QUALITY >= 3
		DoRefraction(color, z0, z1, viewPos.xyz, lViewPos);
	#endif

	vec4 volumetricLight = vec4(0.0);

	#ifdef LIGHTSHAFTS_ACTIVE
		float vlFactorM = vlFactor;

		/* The "1.0 - translucentMult" trick is done because of the default color attachment
		value being vec3(0.0). This makes it vec3(1.0) to avoid issues especially on improved glass */
		vec3 translucentMult = 1.0 - texelFetch(colortex3, texelCoord, 0).rgb;

		vec3 nViewPos = normalize(viewPos.xyz);

		float VdotL = dot(nViewPos, lightVec);
		float VdotU = dot(nViewPos, upVec);

		vec4 screenPos1 = vec4(texCoord, z1, 1.0);
		vec4 viewPos1 = gbufferProjectionInverse * (screenPos1 * 2.0 - 1.0);
		viewPos1 /= viewPos1.w;
		float lViewPos1 = length(viewPos1.xyz);

		volumetricLight = GetVolumetricLight(vlFactorM, translucentMult, lViewPos1, nViewPos, VdotL, VdotU, texCoord, z0, z1, dither);
		
		#ifdef ATM_COLOR_MULTS
			volumetricLight.rgb *= GetAtmColorMult();
		#endif
	#endif

	/*color.rgb = vec3(lViewPos);
	if (gl_FragCoord.x > 960)
	color.rgb = vec3(GetApproxDistance(z1));
	color.rgb *= 0.02;
	color.rgb = min(color.rgb, vec3(2.0));*/
	
	if (isEyeInWater == 1) {
		if (z0 == 1.0) color.rgb = waterFogColor;

		const vec3 underwaterMult = vec3(0.80, 0.87, 0.97);
		color.rgb *= underwaterMult * 0.85;

		volumetricLight.rgb *= pow2(underwaterMult * 0.71);
	} else if (isEyeInWater == 2) {
		if (z1 == 1.0) color.rgb = fogColor * 5.0;
		
		volumetricLight.rgb *= 0.0;
	}
	
	#if TONEMAP > 0
		// convert rgb to linear:
		const vec3 a = vec3(0.055f);
		color = mix(pow((color.rgb + a)/(vec3(1.0f) + a), vec3(2.4)), color.rgb / 12.92f, lessThan(color.rgb, vec3(0.04045f)));
	#else
		color = pow(color, vec3(2.2));
	#endif
	
	#ifdef LIGHTSHAFTS_ACTIVE
		#ifndef OVERWORLD
			volumetricLight.rgb *= volumetricLight.rgb;
		#endif
		color += volumetricLight.rgb;
	#endif

	#if defined BLOOM_FOG && !defined MOTION_BLURRING
		color *= GetBloomFog(lViewPos); // Reminder: Bloom Fog moves between composite and composite2 depending on Motion Blur
	#endif
	
	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 1.0);
	
	#if LIGHTSHAFT_QUALITY > 0 && defined OVERWORLD && defined REALTIME_SHADOWS || defined END // Can't use LIGHTSHAFTS_ACTIVE on Optifine
		/* DRAWBUFFERS:04 */
		gl_FragData[1] = vec4(vlFactorM, 0.0, 0.0, 1.0);

		#ifdef MULTICOLORED_BLOCKLIGHT
			/* DRAWBUFFERS:049 */
			gl_FragData[2] = vec4(coloredLight, 1.0);
		#endif
	#elif defined MULTICOLORED_BLOCKLIGHT
		/* DRAWBUFFERS:09 */
		gl_FragData[1] = vec4(coloredLight, 1.0);
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out float vlFactor;

noperspective out vec2 texCoord;

flat out vec3 upVec, sunVec;

//Uniforms//
#if LIGHTSHAFT_BEHAVIOUR == 1 || defined END
	uniform float viewWidth, viewHeight;
	
	uniform sampler2D colortex4;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = GetSunVector();

	#if LIGHTSHAFT_BEHAVIOUR == 1 || defined END
		vlFactor = texelFetch(colortex4, ivec2(viewWidth-1, viewHeight-1), 0).r;
	#else
		#if LIGHTSHAFT_BEHAVIOUR == 2
			vlFactor = 0.0;
		#elif LIGHTSHAFT_BEHAVIOUR == 3
			vlFactor = 1.0;
		#endif
	#endif
}

#endif

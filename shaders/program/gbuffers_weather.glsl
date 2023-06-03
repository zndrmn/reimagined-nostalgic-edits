////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in vec2 lmCoord;
in vec2 texCoord;

flat in vec3 upVec, sunVec;

flat in vec4 glColor;

//Uniforms//
uniform int isEyeInWater;

uniform vec3 skyColor;
uniform vec3 fogColor;

uniform sampler2D tex;

//Pipeline Constants//

//Common Variables//
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;

//Common Functions//

//Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"
#include "/lib/colors/blocklightColors.glsl"

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord);
	color *= glColor;

	if (color.a < 0.1 || isEyeInWater == 3) discard;

	if (color.r + color.g < 1.5) {
		color.a *= RAIN_PARTICLE_TRANSPARENCY;
	} else {
		color.a *= SNOW_PARTICLE_TRANSPARENCY;
	}
	color.rgb = sqrt2(color.rgb) * (blocklightCol * lmCoord.x + ambientColor * lmCoord.y * (0.7 + 0.35 * sunFactor));

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

flat out vec2 lmCoord;
out vec2 texCoord;

flat out vec3 upVec, sunVec;

flat out vec4 glColor;

//Uniforms//

#if defined WORLD_CURVATURE
	uniform sampler2D noisetex;
	uniform mat4 gbufferModelViewInverse;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

#if defined WORLD_CURVATURE
	#include "/lib/misc/distortWorld.glsl"
#endif

//Program//
void main() {
	gl_Position = ftransform();
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmCoord  = GetLightMapCoordinates();
	glColor = gl_Color;
	
	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = GetSunVector();

	#if defined WORLD_CURVATURE
		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
		#ifdef WORLD_CURVATURE
			position.y += doWorldCurvature(position.xz);
		#endif
		gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#endif
}

#endif

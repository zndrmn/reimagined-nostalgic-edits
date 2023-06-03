//////////////////////////////////
// Complementary Base by EminGT //
//////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

flat in vec4 glColor;

//Uniforms//
uniform sampler2D tex;

//Pipeline Constants//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord);
	color.rgb *= glColor.rgb;

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

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
	glColor = gl_Color;

	#if defined WORLD_CURVATURE
		vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
		#ifdef WORLD_CURVATURE
			position.y += doWorldCurvature(position.xz);
		#endif
		gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#endif
}

#endif

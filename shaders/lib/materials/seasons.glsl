vec3 oldColor = color.rgb;	// Needed for entities

#include "/lib/materials/seasonsTime.glsl"

#if SEASONS != 2 && SEASONS != 5
	// Color Desaturation
	vec3 desaturatedColor = color.rgb;
	if (COLOR_DESATURATION > 0.0) {
		float desaturation = COLOR_DESATURATION;

		#if SEASONS == 1 || SEASONS == 4
			if (winterTime > 0) {
				// snow conditions
				#if SNOW_CONDITION != 2
					desaturation *= isSnowy; // make only appear in cold biomes
				#elif SNOW_CONDITION == 0
					desaturation *= rainFactor; // make only appear in rain
				#endif
			}
		#endif

		desaturatedColor = clamp(mix(color.rgb, color.rgb * (GetLuminance(color.rgb) / color.rgb * 0.99), clamp01(desaturation - lmCoord.x)), 0.0, 1.0);
	}

	#ifndef GBUFFERS_ENTITIES
		// specific materials
		float specificMaterialIntensity = 0.0;
		if (mat == 10000 || mat == 10004 || mat == 10020 || mat == 10348 || mat == 10628 || mat == 10472) specificMaterialIntensity = mix(1.0, 0.0, (color.r + color.g + color.b) * 0.3); // vegetation check
		if (mat == 10492 || mat == 10006) specificMaterialIntensity = mix(1.0, 0.0, (color.r + color.g + color.b) * 0.1 - 1.0); // fungus and mushroom
		if (mat == 10005 && color.g * 1.5 > color.r + color.b) specificMaterialIntensity = mix(1.0, 0.0, 1 / (color.g * color.g) * 0.01); //wither rose
		if (mat == 10008) specificMaterialIntensity = mix(1.0, 0.0, 1 / (color.g * color.g) * 0.033); //leaves
		if (mat == 10016 || mat == 10060 || mat == 10017) specificMaterialIntensity = mix(1.0, 0.0, 1 / (color.g * color.g) * 0.09); // sugar cane, bamboo, propagule
		if (mat == 10012) specificMaterialIntensity = mix(1.0, 0.0, 1 / (color.g * color.g) * 0.04); // vine
		if ((mat == 10132 && glColor.b < 0.999) || (mat == 10129 && color.b + color.g < color.r * 2.0 && color.b > 0.3 && color.g < 0.45) || (mat == 10492 && color.r > 0.52 && color.b < 0.30 && color.g > 0.41 && color.g + color.b * 0.95 > color.r * 1.2)) {
			specificMaterialIntensity = mix(0.0, 1.0, pow(midUV.y, 3.0));
			#if defined SSS_SEASON_SNOW && (SEASONS == 1 || SEASONS == 4)
				#if SNOW_CONDITION == 0
					if (rainFactor > 0 && isSnowy > 0) subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true; // SSS
				#elif SNOW_CONDITION == 1
					if (isSnowy > 0) subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
				#else
					subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
				#endif
			#endif
		} // add to the side of grass, mycelium, path blocks; in that order. Use midUV to increase transparency the the further down the block it goes
		if (mat == 10132 && glColor.b < 0.999) specificMaterialIntensity += abs(color.g - color.g * 0.5); // mute the grass colors a bit
	#endif
#endif

#if SEASONS == 1 || SEASONS == 2
	vec3 summerColor = color.rgb;
#endif

#if SEASONS == 1 || SEASONS == 3
	vec3 autumnColor;

	if (autumnTime > 0) {
		autumnColor = mix(color.rgb, desaturatedColor, 0.5);

		#ifndef GBUFFERS_ENTITIES
			autumnColor = mix(autumnColor, autumnColor * vec3(1.0, 0.7, 0.5), specificMaterialIntensity);
		#endif
	}
#endif

#if SEASONS == 1 || SEASONS == 5
	vec3 springColor = color.rgb;
#endif

#if SEASONS == 1 || SEASONS == 4
	vec3 winterColor;

	if (winterTime > 0) {
		winterColor = desaturatedColor;

		#ifdef GBUFFERS_ENTITIES
			oldColor = mix(color.rgb, winterColor, winterTime);
		#else
			float winterAlpha = color.a;
			float snowVariable;
			float upCheck = abs(clamp01(dot(normal, upVec)));	// normal check for top surfaces

			snowVariable = specificMaterialIntensity;
			if (upCheck > 0.99) snowVariable = 0.0;
			snowVariable += upCheck;

			if (snowVariable > 0.001) {
				vec3 snowColor = vec3(0.9713, 0.9691, 0.9891);

				// snow noise
				vec3 worldPos = playerPos + cameraPosition;

				#if SNOW_SIZE > 0
					int snowSize = SNOW_SIZE;
				#else
					int snowSize = pixelTexSize.x + 1;
				#endif
				float snowNoise = float(hash33(floor(mod(worldPos, vec3(100.0)) * snowSize + 0.03) * snowSize)) * 0.25; // pixel-locked procedural noise
			
				snowColor *= 1.1;
				snowColor += 0.13 * snowNoise * SNOW_NOISE_INTENSITY; // make the noise less noticeable & configurable with option

				float snowRemoveNoise1 = 1.0 - texture2D(noisetex, 0.0005 * (worldPos.xz + worldPos.y)).r;
				float snowRemoveNoise2 = 1.0 - texture2D(noisetex, 0.005 * (worldPos.xz + worldPos.y)).r;
				float snowRemoveNoise3 = texture2D(noisetex, 0.02 * (worldPos.xz + worldPos.y)).r;
				snowVariable *= clamp01(2.0 * snowRemoveNoise1 + 0.70 * snowRemoveNoise2 + 0.2 * snowRemoveNoise3);

				// light check
				snowVariable = clamp01(snowVariable); // to prevent stuff breaking, like the fucking bamboo sapling!!!!
				snowVariable *= (1.0 - pow(lmCoord.x, 1.0 / MELTING_RADIUS * 2.5) * 4.3) * pow(lmCoord.y, 14.0); // first part to turn off at light sources, second part to turn off if under blocks
				snowVariable = clamp(snowVariable, 0.0, SNOW_TRANSPARENCY * 0.1 + 0.8); // to prevent artifacts near light sources

				// snow conditions
				#if SNOW_CONDITION != 2
					snowVariable *= isSnowy; // make only appear in cold biomes
				#endif
				#if SNOW_CONDITION == 0
					snowVariable *= rainFactor; // make only appear in rain
				#endif

				#ifdef IPBR
					smoothnessG = mix(smoothnessG, 0.45 + 0.1 * snowNoise, snowVariable * IPBRMult * winterTime);
					highlightMult = mix(highlightMult, 2.3 - subsurfaceMode * 0.1, snowVariable * IPBRMult * winterTime);
				#endif

				#ifdef SSS_SEASON_SNOW
					#if SNOW_CONDITION == 0
						if (upCheck > 0.99 && rainFactor > 0 && isSnowy > 0) subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
					#elif SNOW_CONDITION == 1
						if (upCheck > 0.99 && isSnowy > 0) subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
					#else
						if (upCheck > 0.99) subsurfaceMode = 1, noSmoothLighting = true, noDirectionalShading = true;
					#endif
				#endif

				#ifdef GBUFFERS_TERRAIN
					if (dot(normal, upVec) > 0.99) {
						#if SNOW_CONDITION == 0
							emission = mix(emission, emission * snowEmission, rainFactor * isSnowy * winterTime); // make only appear in rain
						#elif SNOW_CONDITION == 1
							emission = mix(emission, emission * snowEmission, isSnowy * winterTime); // make only appear in cold biomes
						#else
							emission = mix(emission, emission * snowEmission, winterTime);
						#endif
					}
					smoothnessD = mix(smoothnessD, 0.0, snowVariable * winterTime);
				#endif

				#ifdef GBUFFERS_WATER
					if (dot(normal, upVec) > 0.99) {
						#if SNOW_CONDITION == 0
							snowTransparentOverwrite = mix(snowTransparentOverwrite, snowAlpha, rainFactor * isSnowy * winterTime);
						#elif SNOW_CONDITION == 1
							snowTransparentOverwrite = mix(snowTransparentOverwrite, snowAlpha, isSnowy * winterTime);
						#else
							snowTransparentOverwrite = mix(1.0, snowAlpha, winterTime);
						#endif		
					}
					fresnel = mix(fresnel, 0.01, snowVariable * snowFresnelMult * winterTime);
				#endif

				// final mix
				winterColor = mix(winterColor, snowColor, snowVariable * snowIntensity);
				winterAlpha = mix(color.a, 1.0, clamp(snowTransparentOverwrite * snowVariable, 0.0, 1.0));
				color.a = mix(color.a, winterAlpha, winterTime);
			}
		#endif
	}
#endif

#if SEASONS == 1
	vec3 summerToAutumn = mix(summerColor, autumnColor, summer);
	vec3 autumnToWinter = mix(summerToAutumn, winterColor, autumn);	
	vec3 winterToSpring = mix(autumnToWinter, springColor, winter);
	vec3 springToSummer = mix(winterToSpring, summerColor, spring);

	#ifndef GBUFFERS_ENTITIES	
		color.rgb = springToSummer;
	#endif

#elif SEASONS == 2
	color.rgb = summerColor;

#elif SEASONS == 3
	color.rgb = autumnColor;

#elif SEASONS == 4
	color.rgb = winterColor;

#elif SEASONS == 5
	color.rgb = springColor;
#endif

#ifdef GBUFFERS_ENTITIES
	color.rgb = oldColor;
#endif
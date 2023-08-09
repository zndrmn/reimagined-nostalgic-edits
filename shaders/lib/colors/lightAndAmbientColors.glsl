#ifndef INCLUDE_LIGHT_AND_AMBIENT_COLORS
#define INCLUDE_LIGHT_AND_AMBIENT_COLORS

#if defined OVERWORLD
    #ifndef COMPOSITE
        vec3 noonClearLightColor = vec3(0.67, 0.55, 0.5) * 1.6; //ground and cloud color
    #else
        vec3 noonClearLightColor = vec3(0.4, 0.7, 1.4); //light shaft color
    #endif
    vec3 noonClearAmbientColor = pow(skyColor, vec3(0.55)) * 0.85;


    #ifndef COMPOSITE
        vec3 sunsetClearLightColor = pow(vec3(0.6, 0.41, 0.24), vec3(1.5 + invNoonFactor)) * 4.5; //ground and cloud color
    #else
        vec3 sunsetClearLightColor = pow(vec3(0.6, 0.40, 0.24), vec3(1.5 + invNoonFactor)) * 6.4; //light shaft color
    #endif
    vec3 sunsetClearAmbientColor   = noonClearAmbientColor * vec3(1.0, 0.8, 0.7);


    #if !defined COMPOSITE && !defined DEFERRED1
        vec3 nightClearLightColor = vec3(0.08, 0.12, 0.16) * (1.1 + vsBrightness * 1.6); //ground color
    #elif defined DEFERRED1
        vec3 nightClearLightColor = vec3(0.15, 0.19, 0.29); //cloud color
    #else
        vec3 nightClearLightColor = vec3(0.02, 0.15, 0.64); //light shaft color
    #endif
    vec3 nightClearAmbientColor   = vec3(0.11, 0.12, 0.18) * (0.48 + vsBrightness * 0.62);


    vec3 dayRainLightColor   = vec3(0.48, 0.52, 0.54) * (0.28 + vsBrightness * 0.15); //sun light color
    #ifdef RAIN_ATMOSPHERE //ground color
        vec3 dayRainAmbientColor = vec3(0.49, 0.52, 0.55) * (0.25 + vsBrightness) * mix(0.9, 7.0 * float(skyColor), float(skyColor) * 0.5);
    #else
        vec3 dayRainAmbientColor = vec3(0.49, 0.52, 0.55) * (0.25 + vsBrightness);
    #endif


    vec3 nightRainLightColor   = vec3(0.10, 0.10, 0.11) / 2.88 * (0.38 + vsBrightness); //moon light color
    #ifdef RAIN_ATMOSPHERE //ground color
        vec3 nightRainAmbientColor = vec3(0.09, 0.11, 0.12) / 1.38 * (0.41 + vsBrightness * 0.5) * mix(0.9, 31.0 * float(skyColor), float(skyColor) * 0.5);
    #else
        vec3 nightRainAmbientColor = vec3(0.09, 0.11, 0.12) / 1.38 * (0.41 + vsBrightness * 0.5);
    #endif


    #ifndef COMPOSITE
        float noonFactorDM = noonFactor; //ground and cloud factor
    #else
        float noonFactorDM = noonFactor * noonFactor; //light shaft factor
    #endif
    vec3 dayLightColor   = mix(sunsetClearLightColor, noonClearLightColor, noonFactorDM);
    vec3 dayAmbientColor = mix(sunsetClearAmbientColor, noonClearAmbientColor, noonFactorDM);

    vec3 clearLightColor   = mix(nightClearLightColor, dayLightColor, sunVisibility2);
    vec3 clearAmbientColor = mix(nightClearAmbientColor, dayAmbientColor, sunVisibility2);

    vec3 rainLightColor   = mix(nightRainLightColor, dayRainLightColor, sunVisibility2) * 2.5;
    vec3 rainAmbientColor = mix(nightRainAmbientColor, dayRainAmbientColor, sunVisibility2);

    vec3 lightColor   = mix(clearLightColor, rainLightColor, rainFactor);
    vec3 ambientColor = mix(clearAmbientColor, rainAmbientColor, rainFactor);
#elif defined NETHER
    vec3 netherColor  = max(normalize(sqrt(fogColor)), vec3(0.0));
    vec3 lightColor   = vec3(0.0);
    vec3 ambientColor = netherColor * (0.44 + 0.22 * vsBrightness);
#elif defined END
    vec3 endLightColor = vec3(0.68, 0.51, 1.07);
    float endLightBalancer = 0.2 * vsBrightness;
    vec3 lightColor   = endLightColor * (0.35 - endLightBalancer);
    vec3 ambientCol   = endLightColor * (0.2 + endLightBalancer);
    vec3 ambientColor = mix(ambientCol, vec3(255.0, 255.0, 255.0) / 255 * 1.0, 0.00);
    vec3 endColorBeam = mix(ambientCol, vec3(E_BEAM_R, E_BEAM_G, E_BEAM_B) / 255, E_BEAMS_AMBIENT_INFLUENCE);
#endif

#endif
#ifndef INCLUDE_SKY_COLORS
#define INCLUDE_SKY_COLORS

#ifdef OVERWORLD
    vec3 skyColorSqrt = sqrt(skyColor);

    vec3 noonUpSkyColor     = vec3(0.28, 0.50, 0.89);
    vec3 noonMiddleSkyColor = vec3(0.66, 0.84, 0.98) * 1.01;
    vec3 noonDownSkyColor   = noonMiddleSkyColor / 1.2;

    // sunset middle sky color brightness makes sunset -> night super bright, lowering the overall sunset brightess somehow might make it look natural
    // 1: og + new     2: new     3: og

    //vec3 sunsetUpSkyColor     = skyColor * vec3(1.76, 0.72, 0.54) * 1.13;
    //vec3 sunsetMiddleSkyColor = vec3(0.82, 0.61, 0.72);
    //vec3 sunsetDownSkyColor   = vec3(0.94, 0.56, 0.48);

    //vec3 sunsetUpSkyColor     = skyColor * vec3(1.76, 0.72, 0.54) * 1.13;
    //vec3 sunsetMiddleSkyColor = skyColor * vec3(0.82, 0.80, 0.70);
    //vec3 sunsetDownSkyColor   = vec3(0.94, 0.56, 0.48);

    vec3 sunsetUpSkyColor     = pow(skyColor, vec3(0.5)) * vec3(0.97, 0.68, 0.60);
    vec3 sunsetMiddleSkyColor = vec3(0.82, 0.61, 0.72);
    vec3 sunsetDownSkyColor   = vec3(0.94, 0.56, 0.48);

    vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2)         
                           * mix(vec3(1.1), vec3(0.7, 0.75, 0.9) * 0.4, rainFactor);
    vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2)
                           * mix(vec3(1.0), vec3(0.6, 0.65, 0.7) * 0.4, rainFactor);
    vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor * 0.5, invNoonFactor2);

    //vec3 rainNC = vec3(0.012, 0.018, 0.036);
    //vec3 nightColFactor      = mix(vec3(0.07, 0.14, 0.24) + skyColor, rainNC + 20.0 * rainNC * skyColor, rainFactor);
    //vec3 nightUpSkyColor     = pow(nightColFactor, vec3(0.90)) * 0.4;
    //vec3 nightMiddleSkyColor = sqrt(nightUpSkyColor) * 0.7;
    //vec3 nightDownSkyColor   = nightUpSkyColor * 1.3;

    vec3 rainNC = vec3(0.20, 0.12, 0.10) / 1.0;
    vec3 nightColFactor      = mix(vec3(0.0, 0.20, 0.46) + skyColor, rainNC + 20.0 * rainNC * skyColor, rainFactor);
    //vec3 nightUpSkyColor     = nightColFactor / 2.9;
    //vec3 nightUpSkyColor     = mix(nightColFactor, vec3(0.02, 0.25, 0.48), vec3(0.0)) / 2.1;
    vec3 nightUpSkyColor     = nightColFactor * vec3(0.0, 0.45, 0.32);
    vec3 nightMiddleSkyColor = nightColFactor * vec3(0.0, 0.38, 0.21);
    vec3 nightDownSkyColor   = nightMiddleSkyColor;

#elif defined NETHER
    vec3 netherSkyColor = pow(fogColor, vec3(0.6, 0.75, 0.75));
#elif defined END
    vec3 endSkyColor = vec3(42.3375, 26.775, 65.375) / 255.0 * 1.00;
#endif

#endif
#ifndef INCLUDE_SKY_COLORS
#define INCLUDE_SKY_COLORS

#ifdef OVERWORLD
    vec3 skyColorSqrt = sqrt(skyColor);

    vec3 noonUpSkyColor     = vec3(0.28, 0.50, 0.89);
    vec3 noonMiddleSkyColor = vec3(0.66, 0.84, 0.98) * 1.01;
    vec3 noonDownSkyColor   = noonMiddleSkyColor / 1.2;

    vec3 sunsetUpSkyColor     = pow(skyColor, vec3(0.5)) * vec3(0.97, 0.68, 0.60);
    vec3 sunsetMiddleSkyColor = vec3(0.82, 0.61, 0.72);
    vec3 sunsetDownSkyColor   = vec3(0.94, 0.56, 0.48);

    vec3 dayUpSkyColor     = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2)         
                           * mix(vec3(1.1), vec3(0.7, 0.75, 0.9) * 0.4, rainFactor);
    vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2)
                           * mix(vec3(1.0), vec3(0.6, 0.65, 0.7) * 0.4, rainFactor);
    vec3 dayDownSkyColor   = mix(noonDownSkyColor, sunsetDownSkyColor * 0.5, invNoonFactor2);

    vec3 rainNC = vec3(0.20, 0.12, 0.10) / 1.4;
    vec3 nightColFactor      = mix(vec3(0.10, 0.20, 0.36) + skyColor, rainNC + 20.0 * rainNC * skyColor, rainFactor);
    vec3 nightUpSkyColor     = nightColFactor / 2.9;
    vec3 nightMiddleSkyColor = mix(nightUpSkyColor, vec3(0.10, 0.29, 0.32), vec3(0.08, 0.25, 0.38) / 2.7);
    vec3 nightDownSkyColor   = nightMiddleSkyColor;

#elif defined NETHER
    vec3 netherSkyColor = pow(fogColor, vec3(0.6, 0.75, 0.75));
#elif defined END
    vec3 endSkyColor = vec3(42.3375, 26.775, 65.375) / 255.0 * 1.00;
#endif

#endif
float CLOUD_AMOUNT = 10.5;
float CLOUD_THICKNESS = 0.5;
float stretchFactor = 2.5;
float coordFactor = 0.009375;

float CloudNoise(vec2 coord) {
    float wind = syncedTime * 0.007;
    float noise = texture2D(noisetex, coord*0.5    + vec2(wind * 0.25, 0)).r * 7.0;
          noise+= texture2D(noisetex, coord*0.25   + vec2(wind * 0.15, 0)).r * 12.0;
          noise+= texture2D(noisetex, coord*0.125  + vec2(wind * 0.05, 0)).r * 12.0;
          noise+= texture2D(noisetex, coord*0.0625 + vec2(wind * 0.05, 0)).r * 24.0;
    return noise * 0.34;
}

float CloudCoverage(float noise, float coverage, float VdotU, float VdotS) {
    float sunMoonFactor = pow2(pow2(abs(VdotS)));
    float noiseCoverage = pow2(coverage) + CLOUD_AMOUNT
                        * (1.0 + sunMoonFactor * 0.175) 
                        * (1.0 + VdotU * 0.365 * (1.0 - rainFactor * 2.7))
                        - 2.5;
    return max(noise - noiseCoverage, 0.0);
}

vec4 DrawCloud(vec3 viewPos, float dither, float VdotS, float VdotU) {
    float cloudGradient = 0.0;
    float gradientMix = dither * 0.1667;

    float cloudHeight = 15.0 * pow2(max(1.11 - 0.0015 * cameraPosition.y, 0.0));

    vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    wpos /= (abs(wpos.y) + length(wpos.xz));

    float r = wpos.x * cos(frameTimeCounter * 0.1) - wpos.z * sin(frameTimeCounter * 0.01) + frameTimeCounter * 0.01;
    vec3 rainbowColor = vec3(0.5) + vec3(0.5) * cos(6.28318 * (vec3(0.1,0.1,0.1) * rainbowCloudDistribution * 2.0 * r + vec3(0.0,0.33,0.67)));        // Copyright © 2015 Inigo Quilez Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    float scatter = max0(pow2(VdotS));
    float dayNightFogBlend = pow(1.0 - nightFactor, 4.0 - VdotS - 3.0 * sunVisibility2);
    vec3 cloudRainColor = mix(nightMiddleSkyColor, dayUpSkyColor * 3.5, sunFactor);
    vec3 cloudClearAmbient = mix(nightClearAmbientColor * 0.3, 0.9 * dayAmbientColor, dayNightFogBlend);
    vec3 cloudClearLight = mix(nightClearLightColor * (1.7 + scatter), (0.9 + 0.4 * noonFactor + scatter) * dayLightColor, pow2(dayNightFogBlend));

    #if RAINBOW_CLOUD != 0
        vec3 cloudAmbientColor = mix(cloudClearAmbient, cloudRainColor * 0.3, rainFactor) * rainbowColor;
        vec3 cloudLightColor   = mix(cloudClearLight, cloudRainColor * (1.0 + scatter), rainFactor) * rainbowColor;
    #else
        vec3 cloudAmbientColor = mix(cloudClearAmbient, cloudRainColor * 0.3, rainFactor);
        vec3 cloudLightColor   = mix(cloudClearLight, cloudRainColor * (1.0 + scatter), rainFactor);
    #endif

    vec4 clouds = vec4(0.0);
    if (VdotU > 0.025) {
        vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
        for(int i = 0; i < 5; i++) {
            vec2 planeCoord = wpos.xz * ((cloudHeight + (i + dither) * stretchFactor) / wpos.y) * 0.0085;
            vec2 coord = cameraPosition.xz * 0.00025 + planeCoord;
            
            float ang1 = (i + syncedTime * 0.025) * 2.391;
            float ang2 = ang1 + 2.391;
            coord += mix(vec2(cos(ang1), sin(ang1)), vec2(cos(ang2), sin(ang2)), dither * 0.25 + 0.75) * coordFactor;
            
            float coverage = float(i - 3.0 + dither) * 0.725;
            
            float noise = CloudNoise(coord);
                  noise = CloudCoverage(noise, coverage, VdotU, VdotS) * CLOUD_THICKNESS;
                  noise = noise / sqrt(noise * noise + 1.0);
            
            cloudGradient = mix(cloudGradient,
                                mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
                                noise * (1.0 - clouds.a));
            
            clouds.a += max(noise - clouds.a, 0.0);
            gradientMix += 0.2;
        }

        clouds.rgb = cloudAmbientColor + cloudLightColor * cloudGradient;

        clouds.a *= pow2(pow2(1.0 - exp(- 10.0 * VdotU)));
    }

    return clouds;
}
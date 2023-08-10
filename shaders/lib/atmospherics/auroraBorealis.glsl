float GetAuroraVisibility(in float VdotU) {
    float visibility = sqrt1(clamp01(VdotU * (AURORA_DRAW_DISTANCE * 1.125 + 0.75) - 0.225)) - sunVisibility - rainFactor;
    visibility *= 1.0 - VdotU * 0.9;

    #if AURORA_CONDITION == 1 || AURORA_CONDITION == 3
        visibility -= moonPhase;
    #endif
    #if AURORA_CONDITION == 2 || AURORA_CONDITION == 3
        visibility *= isSnowy;
    #endif
    #if AURORA_CONDITION == 4
        visibility = max(visibility * isSnowy, visibility - moonPhase);
    #endif

    return visibility;
}

void GetAuroraColor(in vec2 wpos, out vec3 auroraUp, out vec3 auroraDown) {
    #ifdef RGB_AURORA
        auroraUp = getRainbowColor(wpos, 0.06);
        auroraDown = getRainbowColor(wpos, 0.05);
    #elif AURORA_COLOR_PRESET == 0
        auroraUp = vec3(AURORA_UP_R, AURORA_UP_G, AURORA_UP_B);
        auroraDown = vec3(AURORA_DOWN_R, AURORA_DOWN_G, AURORA_DOWN_B);
    #else
        vec3 auroraUpA[] = vec3[](
            vec3(112.0, 36.0, 192.0), // [1] Complementary Reimagined
            vec3(112.0, 36.0, 192.0), // [2] Complementary Reimagined
            vec3(112.0, 80.0, 255.0), // [3] Complementary Legacy
            vec3(64.0, 255.0, 255.0), // [4] Euphoria Patches
            vec3(24.0, 255.0, 140.0), // [5] Nostalgic Edits
            vec3(164.0, 12.0, 76.0),  // [6] Galactic Lights
            vec3(132.0, 0.0, 200.0)   // [7] Mythical Lights
        );
        vec3 auroraDownA[] = vec3[](
            vec3(96.0, 255.0, 192.0), // [1] Complementary Reimagined
            vec3(96.0, 255.0, 192.0), // [2] Complementary Reimagined
            vec3(80.0, 255.0, 180.0), // [3] Complementary Legacy
            vec3(128.0, 64.0, 128.0), // [4] Euphoria Patches
            vec3(108.0, 72.0, 255.0), // [5] Nostalgic Edits
            vec3(124.0, 64.0, 255.0), // [6] Galactic Lights
            vec3(56.0, 168.0, 255.0)  // [7] Mythical Lights
        );
        #if AURORA_COLOR_PRESET > 1
            int p = AURORA_COLOR_PRESET-1;
        #else
            int p = worldDay % 112 / 8; // number of presets multiplied by 8 is the first number, preset number listed above
        #endif
        auroraUp = auroraUpA[p];
        auroraDown = auroraDownA[p];
    #endif

    auroraUp *= (AURORA_UP_I * 0.093 + 3.1) / GetLuminance(auroraUp);
    auroraDown *= (AURORA_DOWN_I * 0.245 + 8.15) / GetLuminance(auroraDown);
}

void AuroraAmbientColor(inout vec3 color, in vec3 viewPos) {
    float visibility = GetAuroraVisibility(0.5);
    if (visibility > 0) {
        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        wpos.xz /= (abs(wpos.y) + length(wpos.xz));

        vec3 auroraUp, auroraDown;
        GetAuroraColor(wpos.xz, auroraUp, auroraDown);

        vec3 auroraColor = mix(auroraUp, auroraDown, 0.8);
        #ifdef DEFERRED1
            auroraColor *= 0.3;
            visibility *= AURORA_CLOUD_INFLUENCE_INTENSITY;
        #elif defined GBUFFERS_CLOUDS
            auroraColor *= 0.6;
            visibility *= AURORA_CLOUD_INFLUENCE_INTENSITY;
        #else
            auroraColor *= 0.05;
            visibility *= AURORA_TERRAIN_INFLUENCE_INTENSITY;
        #endif
        color *= mix(vec3(1.0), auroraColor, visibility);
    }
}

vec3 GetAuroraBorealis(vec3 viewPos, float VdotU, float dither) {
    float visibility = GetAuroraVisibility(VdotU);

    if (visibility > 0.0) {
        if (max(blindness, darknessFactor) > 0.1) return vec3(0.0);

        vec3 aurora = vec3(0.0);

        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        wpos.xz /= wpos.y;
        vec2 cameraPositionM = cameraPosition.xz * 0.0075;
        cameraPositionM.x += syncedTime * 0.04;

        int sampleCount = 25;
        int sampleCountP = sampleCount + 5;
        float ditherM = dither + 5.0;
        float auroraAnimate = frameTimeCounter * 0.001;

        vec3 auroraUp, auroraDown;
        GetAuroraColor(wpos.xz, auroraUp, auroraDown);

        for (int i = 0; i < sampleCount; i++) {
            float current = pow2((i + ditherM) / sampleCountP);

            vec2 planePos = wpos.xz * (AURORA_SIZE * 0.6 + 0.4 + current) * 11.0 + cameraPositionM;
            #if AURORA_STYLE == 1
                planePos = floor(planePos) * 0.0007;

                float noise = texture2D(noisetex, planePos).b;
                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));

                noise *= pow1_5(texture2D(noisetex, planePos * 100.0 + auroraAnimate).b);
            #else
                planePos *= 0.0007;

                float noise = texture2D(noisetex, planePos).r;
                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));

                noise *= texture2D(noisetex, planePos * 3.0 + auroraAnimate).b;
                noise *= texture2D(noisetex, planePos * 5.0 - auroraAnimate).b;
            #endif

            float currentM = 1.0 - current;

            aurora += noise * currentM * mix(auroraUp, auroraDown, pow2(pow2(currentM)));
        }

        #if AURORA_STYLE == 1
            aurora *= 1.3;
        #else
            aurora *= 1.8;
        #endif

        return aurora * visibility / sampleCount;
    }

    return vec3(0.0);
}

//    if (visibility > 0.0) {
//	    if (max(blindness, darknessFactor) > 0.1) return vec3(0.0);
//
//        vec3 aurora = vec3(0.0);
//
//        vec3 wpos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
//             wpos.xz /= wpos.y;
//        vec2 cameraPositionM = cameraPosition.xz * 0.0075;
//        cameraPositionM.x += syncedTime * 0.04;
//
//        int sampleCount = 25;
//        int sampleCountP = sampleCount + 5;
//        float ditherM = dither + 5.0;
//        float auroraAnimate = frameTimeCounter * 0.001;
//
//        #ifdef RGB_AURORA
//            float r = wpos.x * cos(frameTimeCounter * 0.1) - wpos.z * sin(frameTimeCounter * 0.01) + frameTimeCounter * 0.01;
//            vec3 auroraUp = vec3(0.5,0.5,0.5) + vec3(0.5,0.5,0.5) * cos(6.28318 * (vec3(0.1,0.1,0.1) * r + vec3(0.0,0.33,0.67)));        // Copyright © 2015 Inigo Quilez
//            vec3 auroraDown = vec3(0.5,0.5,0.5) + vec3(0.5,0.5,0.5) * cos(6.28318 * (vec3(0.15,0.15,0.15) * r + vec3(0.0,0.33,0.67)));   // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//        #elif AURORA_COLOR_PRESET == 0
//            vec3 auroraUp = vec3(AURORA_UP_R, AURORA_UP_G, AURORA_UP_B);
//            vec3 auroraDown = vec3(AURORA_DOWN_R, AURORA_DOWN_G, AURORA_DOWN_B);
//        #else
//            vec3 auroraUpA[] = vec3[](
//                vec3(112.0, 36.0, 192.0), // [0] Monthly Reserved
//                vec3(112.0, 36.0, 192.0), // [2] Complementary Reimagined
//                vec3(112.0, 80.0, 255.0), // [3] Complementary Legacy
//                vec3(64.0, 255.0, 255.0), // [4] Euphoria Patches
//                vec3(24.0, 255.0, 140.0), // [5] Nostalgic Edits
//                vec3(164.0, 12.0, 76.0),  // [6] Galactic Lights
//                vec3(132.0, 0.0, 200.0)   // [7] Mythical Lights
//                //vec3(255.0, 88.0, 188.0), // [8] Amethyst Lights
//                //vec3(76.0, 204.0, 220.0)  // [9] Malachite Lights
//            );
//            vec3 auroraDownA[] = vec3[](
//                vec3(96.0, 255.0, 192.0), // [0] Monthly Reserved
//                vec3(96.0, 255.0, 192.0), // [2] Complementary Reimagined
//                vec3(80.0, 255.0, 180.0), // [3] Complementary Legacy
//                vec3(128.0, 64.0, 128.0), // [4] Euphoria Patches
//                vec3(108.0, 72.0, 255.0), // [5] Nostalgic Edits
//                vec3(124.0, 64.0, 255.0), // [6] Galactic Lights
//                vec3(56.0, 168.0, 255.0)  // [7] Mythical Lights
//                //vec3(104.0, 72.0, 192.0), // [8] Amethyst Lights
//                //vec3(0.0, 255.0, 176.0)   // [9] Malachite Lights
//            );
//            #if AURORA_COLOR_PRESET > 1
//                int p = AURORA_COLOR_PRESET-1;
//            #else
//                int p = worldDay % 72 / 8;
//            #endif
//            vec3 auroraUp = auroraUpA[p];
//            vec3 auroraDown = auroraDownA[p];
//        #endif
//
//        auroraUp *= (AURORA_UP_I * 0.093 + 3.1) / GetLuminance(auroraUp);
//        auroraDown *= (AURORA_DOWN_I * 0.245 + 8.15) / GetLuminance(auroraDown);
//
//        for (int i = 0; i < sampleCount; i++) {
//            float current = pow2((i + ditherM) / sampleCountP);
//
//            vec2 planePos = wpos.xz * (AURORA_SIZE * 0.6 + 0.4 + current) * 11.0 + cameraPositionM;
//            #if AURORA_STYLE == 1
//                planePos = floor(planePos) * 0.0007;
//
//                float noise = texture2D(noisetex, planePos).b;
//                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));
//
//                noise *= pow1_5(texture2D(noisetex, planePos * 100.0 + auroraAnimate).b);
//            #else
//                planePos *= 0.0007;
//
//                float noise = texture2D(noisetex, planePos).r;
//                noise = pow2(pow2(pow2(pow2(1.0 - 2.0 * abs(noise - 0.5)))));
//
//                noise *= texture2D(noisetex, planePos * 3.0 + auroraAnimate).b;
//                noise *= texture2D(noisetex, planePos * 5.0 - auroraAnimate).b;
//            #endif
//
//            float currentM = 1.0 - current;
//
//            aurora += noise * currentM * mix(auroraUp, auroraDown, pow2(pow2(currentM)));
//        }
//
//        #if AURORA_STYLE == 1
//            aurora *= 1.3;
//        #else
//            aurora *= 1.8;
//        #endif
//
//        return aurora * visibility / sampleCount;
//    }
//
//    return vec3(0.0);
//}
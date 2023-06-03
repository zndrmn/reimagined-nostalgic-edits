#ifndef INCLUDE_CAVE_FACTOR
#define INCLUDE_CAVE_FACTOR
    float GetCaveFactor() {
        return clamp(1.0 - cameraPosition.y / 60.0, 0.0, 1.0 - eyeBrightnessM);
    }

    vec3 caveFogColorRaw = vec3(33.15, 33.15, 38.25) / 255 *  .00;
    #if MINIMUM_LIGHT_MODE <= 1
        vec3 caveFogColor = caveFogColorRaw * 0.7;
    #elif MINIMUM_LIGHT_MODE == 2
        vec3 caveFogColor = caveFogColorRaw * (0.7 + 0.3 * vsBrightness); // Default
    #elif MINIMUM_LIGHT_MODE >= 3
        vec3 caveFogColor = caveFogColorRaw;
    #endif
#endif

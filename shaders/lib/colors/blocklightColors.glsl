#if BLOCKLIGHT_PROFILE == 0
    #if BLOCKLIGHT_COLOR_MODE == 9
        vec3 blocklightCol = vec3(0.40, 0.32, 0.29) * BLOCKLIGHT_I;
    #elif BLOCKLIGHT_COLOR_MODE == 10
        vec3 blocklightCol = vec3(0.43, 0.32, 0.26) * BLOCKLIGHT_I;
    #elif BLOCKLIGHT_COLOR_MODE == 11
        vec3 blocklightCol = vec3(0.44, 0.31, 0.22) * BLOCKLIGHT_I;
    #endif
#else
    vec3 blocklightCol = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * BLOCKLIGHT_I * (1/255.0);
#endif

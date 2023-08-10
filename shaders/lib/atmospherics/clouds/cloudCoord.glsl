#ifdef DEFERRED1
    const float cloudRoundness = 0.125; // for clouds 0.125
#else
    const float cloudRoundness = 0.35; // for cloud shadows
#endif

#ifdef FASTER_RAIN_CLOUDS
    uniform float rainStrength;
#endif

vec2 GetRoundedCloudCoord(vec2 pos) { // Thanks to SixthSurge
    vec2 coord = pos.xy + 0.5;
    vec2 signCoord = sign(coord);
    coord = abs(coord) + 1.0;
    vec2 i, f = modf(coord, i);
    f = smoothstep(0.5 - cloudRoundness, 0.5 + cloudRoundness, f);
    coord = i + f;
    return (coord - 0.5) * signCoord / 256.0;
}

vec3 ModifyTracePos(vec3 tracePos, float cloudAltitude) {
    #if CLOUD_DIRECTION == 2
        tracePos.xz = tracePos.zx;
    #endif

    #ifdef FASTER_RAIN_CLOUDS
        const float rainSpeedMultiplier = 7.0;
        float dryPos = syncedTime * CLOUD_SPEED;
        float wetPos = dryPos * (rainSpeedMultiplier * rainFactor + 1.0);

        int rainPhase = int(rainStrength > rainFactor) * 2 - 1;    // determines whether the rain begins or ends
        float rainOffset = max0(mod((wetPos - dryPos) * rainPhase, 5120 * rainFactor)) * rainPhase;

        tracePos.x += dryPos + rainOffset;
    #else
        tracePos.x += syncedTime * CLOUD_SPEED;
    #endif
    
    tracePos.z += cloudAltitude * 64.0;

    tracePos.xz *= CLOUD_WIDTH;
    return tracePos.xyz;
}
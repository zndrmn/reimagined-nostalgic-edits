float factor = pow2(pow2(color.r));

#ifdef OBSIDIAN_ENDSTONE
    smoothnessG = min1(factor * 0.9 - 0.07);
    emission = pow(float(color.g - color.b), 2.738) * 21.7 * (-1.0);
#else
    smoothnessG = factor * 0.65;
#endif
smoothnessD = smoothnessG;

#ifdef COATED_TEXTURES
    noiseFactor = 0.66;
#endif
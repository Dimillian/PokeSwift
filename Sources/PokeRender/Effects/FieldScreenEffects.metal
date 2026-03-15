#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

namespace {

constant float3 kDMGAuthenticDarkest = float3(27.0 / 255.0, 42.0 / 255.0, 9.0 / 255.0);
constant float3 kDMGAuthenticDark = float3(14.0 / 255.0, 69.0 / 255.0, 11.0 / 255.0);
constant float3 kDMGAuthenticLight = float3(73.0 / 255.0, 107.0 / 255.0, 34.0 / 255.0);
constant float3 kDMGAuthenticLightest = float3(154.0 / 255.0, 158.0 / 255.0, 63.0 / 255.0);

constant float3 kDMGTintedDarkest = float3(22.0 / 255.0, 47.0 / 255.0, 17.0 / 255.0);
constant float3 kDMGTintedDark = float3(52.0 / 255.0, 89.0 / 255.0, 34.0 / 255.0);
constant float3 kDMGTintedLight = float3(118.0 / 255.0, 147.0 / 255.0, 60.0 / 255.0);
constant float3 kDMGTintedLightest = float3(175.0 / 255.0, 186.0 / 255.0, 104.0 / 255.0);

float3 rawPalette(float luminance) {
    return float3(luminance);
}

float3 authenticPalette(float luminance) {
    if (luminance < 0.25) {
        return kDMGAuthenticDarkest;
    } else if (luminance < 0.5) {
        return kDMGAuthenticDark;
    } else if (luminance < 0.75) {
        return kDMGAuthenticLight;
    }
    return kDMGAuthenticLightest;
}

float3 tintedPalette(float luminance) {
    float t = clamp(pow(luminance, 0.94), 0.0, 1.0);
    float lowMix = smoothstep(0.0, 0.38, t);
    float highMix = smoothstep(0.38, 1.0, t);
    float3 lowBand = mix(kDMGTintedDarkest, kDMGTintedDark, lowMix);
    float3 highBand = mix(kDMGTintedLight, kDMGTintedLightest, highMix);
    return mix(lowBand, highBand, smoothstep(0.22, 0.78, t));
}

float3 paletteForPreset(float luminance, float preset) {
    if (preset < 0.5) {
        return rawPalette(luminance);
    } else if (preset < 1.5) {
        return authenticPalette(luminance);
    }
    return tintedPalette(luminance);
}

float cellInteriorMask(float2 cellFraction) {
    float2 aperture = abs(cellFraction) / float2(0.48, 0.42);
    float edgeDistance = max(aperture.x, aperture.y);
    return 1.0 - smoothstep(0.62, 1.0, edgeDistance);
}

float gapMask(float2 cellFraction) {
    float edgeDistance = max(abs(cellFraction.x), abs(cellFraction.y));
    return 1.0 - smoothstep(0.34, 0.5, edgeDistance);
}

float3 applyLCDCell(float3 baseColor, float2 cellFraction, float preset) {
    float aperture = cellInteriorMask(cellFraction);
    float interior = gapMask(cellFraction);
    float highlight = smoothstep(-0.45, -0.08, -(cellFraction.x + cellFraction.y)) * aperture;
    float shadow = smoothstep(0.08, 0.45, cellFraction.x + cellFraction.y) * aperture;

    float bodyStrength;
    float gapStrength;
    float highlightStrength;
    float shadowStrength;
    float3 highlightColor;
    float3 shadowColor;

    if (preset < 0.5) {
        bodyStrength = 0.9;
        gapStrength = 0.74;
        highlightStrength = 0.028;
        shadowStrength = 0.06;
        highlightColor = float3(0.9);
        shadowColor = float3(0.1);
    } else if (preset < 1.5) {
        bodyStrength = 0.9;
        gapStrength = 0.74;
        highlightStrength = 0.035;
        shadowStrength = 0.065;
        highlightColor = float3(0.78, 0.88, 0.68);
        shadowColor = float3(0.05, 0.11, 0.04);
    } else {
        bodyStrength = 0.87;
        gapStrength = 0.78;
        highlightStrength = 0.05;
        shadowStrength = 0.08;
        highlightColor = float3(0.78, 0.88, 0.68);
        shadowColor = float3(0.05, 0.11, 0.04);
    }

    float3 shaded = baseColor;
    shaded *= mix(gapStrength, bodyStrength, interior);
    shaded *= mix(0.92, 1.0, aperture);
    shaded += highlightColor * highlight * highlightStrength;
    shaded -= shadowColor * shadow * shadowStrength;

    // Mild static directional softness to hint at LCD persistence without temporal feedback.
    shaded *= 1.0 - (smoothstep(0.18, 0.5, abs(cellFraction.y)) * 0.025);
    return shaded;
}

float3 applyTintedReflection(float3 baseColor, float2 uv) {
    float diagonal = (uv.x * 0.82) + ((1.0 - uv.y) * 0.58);
    float primaryBand = exp(-pow((diagonal - 0.52) / 0.17, 2.0)) * 0.07;
    float topSheen = exp(-pow((uv.y - 0.08) / 0.055, 2.0)) * (1.0 - (uv.x * 0.45)) * 0.022;

    float edgeDistance = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
    float vignette = smoothstep(0.0, 0.22, edgeDistance);
    float edgeShade = mix(0.95, 1.0, vignette);
    float panelVariation = 0.992 + (uv.y * 0.012) - (uv.x * 0.008);

    float3 glassTint = float3(0.95, 0.94, 0.84);
    float reflection = primaryBand + topSheen;
    return (baseColor * edgeShade * panelVariation) + (glassTint * reflection);
}

float2 safeNormalize(float2 value) {
    float lengthSquared = max(dot(value, value), 1e-6);
    return value * rsqrt(lengthSquared);
}

float2 spiralIntroSampleUV(float2 uv, float progress, float amount, float2 aspectScale) {
    float2 centered = (uv - 0.5) * aspectScale;
    float radius = length(centered);
    float angle = atan2(centered.y, centered.x);
    float falloff = pow(max(0.0, 1.0 - (radius * 1.18)), 2.0);
    float turbulence = sin((radius * 32.0) - (progress * 19.0));
    float swirl = amount * pow(1.0 - progress, 0.72) * (2.6 + (turbulence * 0.35)) * falloff;
    float pinch = amount * (1.0 - progress) * 0.16 * falloff;

    angle += swirl;
    radius = max(0.0, radius * (1.0 - pinch));

    float2 warped = float2(cos(angle), sin(angle)) * radius;
    warped += safeNormalize(centered + float2(1e-4)) * (turbulence * 0.015 * amount * (1.0 - progress) * falloff);
    return clamp((warped / aspectScale) + 0.5, 0.0, 1.0);
}

float spiralIntroMask(float2 uv, float progress, float amount, float2 aspectScale) {
    float2 centered = (uv - 0.5) * aspectScale;
    float radius = length(centered);
    float angle = atan2(centered.y, centered.x);
    float arms = (angle * 3.6) + (radius * 24.0) - (progress * 18.0);
    float pinwheel = 0.5 + (0.5 * sin(arms));
    float reveal = smoothstep(-0.12, 0.68, (progress * 1.9) - (radius * 0.55) + (pinwheel * 0.46));
    return mix(1.0, reveal, amount);
}

} // namespace

[[ stitchable ]] half4 fieldScreenEffect(
    float2 position,
    half4 currentColor,
    float viewportWidth,
    float viewportHeight,
    float pixelScale,
    float preset,
    float hdrBoost
) {
    if (currentColor.a <= 0.0h) {
        return currentColor;
    }

    float2 safeViewport = max(float2(viewportWidth, viewportHeight), float2(1.0));
    float safeScale = max(pixelScale, 1.0);
    float3 sourceColor = float3(currentColor.rgb);
    float luminance = clamp(dot(sourceColor, float3(0.299, 0.587, 0.114)), 0.0, 1.0);
    float3 shaded = paletteForPreset(luminance, preset);

    float2 cellFraction = fract(position / safeScale) - 0.5;
    shaded = applyLCDCell(shaded, cellFraction, preset);

    if (preset >= 1.5) {
        shaded = applyTintedReflection(shaded, clamp(position / safeViewport, 0.0, 1.0));
    }

    if (hdrBoost > 0.001) {
        float emissiveWeight = hdrBoost * smoothstep(0.5, 1.0, luminance);
        shaded *= 1.0 + (emissiveWeight * 1.4);
    }

    return half4(half3(max(shaded, 0.0)), currentColor.a);
}

[[ stitchable ]] half4 battleScreenEffect(
    float2 position,
    SwiftUI::Layer layer,
    float viewportWidth,
    float viewportHeight,
    float pixelScale,
    float preset,
    float introStyle,
    float introProgress,
    float introAmount,
    float hdrBoost
) {
    float2 safeViewport = max(float2(viewportWidth, viewportHeight), float2(1.0));
    float2 uv = clamp(position / safeViewport, 0.0, 1.0);
    float safeScale = max(pixelScale, 1.0);
    float2 aspectScale = float2(max(safeViewport.x / safeViewport.y, 1.0), 1.0);
    float transitionPhase = clamp(introProgress, 0.0, 1.0);
    float effectAmount = introAmount * (introStyle > 1.5 ? 1.0 : 0.76);

    float2 sampleUV = uv;
    float introMask = 1.0;

    if (effectAmount > 0.001 && introStyle > 0.5) {
        sampleUV = spiralIntroSampleUV(uv, transitionPhase, effectAmount, aspectScale);
        introMask = spiralIntroMask(uv, transitionPhase, effectAmount, aspectScale);
    }

    half4 sampledColor = layer.sample(sampleUV * safeViewport);
    if (sampledColor.a <= 0.0h) {
        return sampledColor;
    }

    float2 cellFraction = fract(position / safeScale) - 0.5;
    float3 sourceColor = float3(sampledColor.rgb);
    float luminance = clamp(dot(sourceColor, float3(0.299, 0.587, 0.114)), 0.0, 1.0);
    float3 shaded = paletteForPreset(luminance, preset);

    shaded = applyLCDCell(shaded, cellFraction, preset);

    if (preset >= 1.5) {
        shaded = applyTintedReflection(shaded, uv);
    }

    shaded *= introMask;

    if (effectAmount > 0.001) {
        float edgeGlow = (1.0 - introMask) * (0.12 + (0.1 * (1.0 - transitionPhase)));
        shaded += float3(0.18, 0.21, 0.14) * edgeGlow * effectAmount;
    }

    if (hdrBoost > 0.001) {
        float emissiveWeight = hdrBoost * smoothstep(0.52, 1.0, luminance);
        shaded *= 1.0 + (emissiveWeight * 1.2);
    }

    return half4(half3(max(shaded, 0.0)), sampledColor.a);
}

[[ stitchable ]] half4 battleTransitionEffect(
    float2 position,
    SwiftUI::Layer layer,
    float viewportWidth,
    float viewportHeight,
    float introStyle,
    float introProgress,
    float introAmount
) {
    float2 safeViewport = max(float2(viewportWidth, viewportHeight), float2(1.0));
    float2 uv = clamp(position / safeViewport, 0.0, 1.0);
    float2 aspectScale = float2(max(safeViewport.x / safeViewport.y, 1.0), 1.0);
    float transitionPhase = clamp(introProgress, 0.0, 1.0);
    float effectAmount = introAmount * (introStyle > 1.5 ? 1.0 : 0.76);

    float2 sampleUV = uv;
    float introMask = 1.0;

    if (effectAmount > 0.001 && introStyle > 0.5) {
        sampleUV = spiralIntroSampleUV(uv, transitionPhase, effectAmount, aspectScale);
        introMask = spiralIntroMask(uv, transitionPhase, effectAmount, aspectScale);
    }

    half4 sampledColor = layer.sample(sampleUV * safeViewport);
    if (sampledColor.a <= 0.0h) {
        return sampledColor;
    }

    float3 shaded = float3(sampledColor.rgb);
    shaded *= introMask;

    if (effectAmount > 0.001) {
        float edgeGlow = (1.0 - introMask) * (0.08 + (0.08 * (1.0 - transitionPhase)));
        shaded += float3(0.16, 0.18, 0.14) * edgeGlow * effectAmount;
    }

    return half4(half3(max(shaded, 0.0)), sampledColor.a);
}

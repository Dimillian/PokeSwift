#include <metal_stdlib>
using namespace metal;

namespace {

constant float3 kDMGDarkest = float3(15.0 / 255.0, 56.0 / 255.0, 15.0 / 255.0);
constant float3 kDMGDark = float3(48.0 / 255.0, 98.0 / 255.0, 48.0 / 255.0);
constant float3 kDMGLight = float3(139.0 / 255.0, 172.0 / 255.0, 15.0 / 255.0);
constant float3 kDMGLightest = float3(155.0 / 255.0, 188.0 / 255.0, 15.0 / 255.0);

float3 authenticPalette(float luminance) {
    if (luminance < 0.25) {
        return kDMGDarkest;
    } else if (luminance < 0.5) {
        return kDMGDark;
    } else if (luminance < 0.75) {
        return kDMGLight;
    }
    return kDMGLightest;
}

float3 tintedPalette(float luminance) {
    float t = clamp(pow(luminance, 0.92), 0.0, 1.0);
    float lowMix = smoothstep(0.0, 0.38, t);
    float highMix = smoothstep(0.38, 1.0, t);
    float3 lowBand = mix(kDMGDarkest, kDMGDark, lowMix);
    float3 highBand = mix(kDMGLight, kDMGLightest, highMix);
    return mix(lowBand, highBand, smoothstep(0.22, 0.78, t));
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

    float bodyStrength = preset < 1.5 ? 0.9 : 0.87;
    float gapStrength = preset < 1.5 ? 0.74 : 0.78;
    float highlightStrength = preset < 1.5 ? 0.035 : 0.05;
    float shadowStrength = preset < 1.5 ? 0.065 : 0.08;

    float3 shaded = baseColor;
    shaded *= mix(gapStrength, bodyStrength, interior);
    shaded *= mix(0.92, 1.0, aperture);
    shaded += float3(0.78, 0.88, 0.68) * highlight * highlightStrength;
    shaded -= float3(0.05, 0.11, 0.04) * shadow * shadowStrength;

    // Mild static directional softness to hint at LCD persistence without temporal feedback.
    shaded *= 1.0 - (smoothstep(0.18, 0.5, abs(cellFraction.y)) * 0.025);
    return shaded;
}

float3 applyTintedReflection(float3 baseColor, float2 uv) {
    float diagonal = (uv.x * 0.82) + ((1.0 - uv.y) * 0.58);
    float primaryBand = exp(-pow((diagonal - 0.52) / 0.17, 2.0)) * 0.09;
    float topSheen = exp(-pow((uv.y - 0.08) / 0.055, 2.0)) * (1.0 - (uv.x * 0.45)) * 0.03;

    float edgeDistance = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
    float vignette = smoothstep(0.0, 0.22, edgeDistance);
    float edgeShade = mix(0.93, 1.0, vignette);
    float panelVariation = 0.985 + (uv.y * 0.02) - (uv.x * 0.012);

    float3 glassTint = float3(0.96, 1.0, 0.9);
    float reflection = primaryBand + topSheen;
    return (baseColor * edgeShade * panelVariation) + (glassTint * reflection);
}

} // namespace

[[ stitchable ]] half4 fieldScreenEffect(
    float2 position,
    half4 currentColor,
    float viewportWidth,
    float viewportHeight,
    float pixelScale,
    float preset
) {
    if (preset < 0.5 || currentColor.a <= 0.0h) {
        return currentColor;
    }

    float2 safeViewport = max(float2(viewportWidth, viewportHeight), float2(1.0));
    float safeScale = max(pixelScale, 1.0);
    float3 sourceColor = float3(currentColor.rgb);
    float luminance = clamp(dot(sourceColor, float3(0.299, 0.587, 0.114)), 0.0, 1.0);
    float3 paletteColor = preset < 1.5 ? authenticPalette(luminance) : tintedPalette(luminance);

    float2 cellFraction = fract(position / safeScale) - 0.5;
    float3 shaded = applyLCDCell(paletteColor, cellFraction, preset);

    if (preset >= 1.5) {
        shaded = applyTintedReflection(shaded, clamp(position / safeViewport, 0.0, 1.0));
    }

    return half4(half3(clamp(shaded, 0.0, 1.0)), currentColor.a);
}

[[ stitchable ]] half4 battleScreenEffect(
    float2 position,
    half4 currentColor,
    float pixelScale
) {
    if (currentColor.a <= 0.0h) {
        return currentColor;
    }

    float safeScale = max(pixelScale, 1.0);
    float2 cellFraction = fract(position / safeScale) - 0.5;
    float aperture = cellInteriorMask(cellFraction);
    float interior = gapMask(cellFraction);

    float3 sourceColor = float3(currentColor.rgb);
    float3 shaded = sourceColor;
    shaded *= mix(0.9, 0.985, interior);
    shaded *= mix(0.96, 1.0, aperture);

    return half4(half3(clamp(shaded, 0.0, 1.0)), currentColor.a);
}

#define LIGHTSTRUCTS_FXH 1

struct PointLightProp
{
    float4 LightCol;
    float3 Position;
    float3 ShadowMapCenter;
    float Range;
    float RangePow;
    float LightStrength;
    float KnowShadows; // > 0.5
    float Penumbra;
    // NoF = 15
    // Size = 60
};

struct SpotLightProp
{
    float4x4 lProjection;
    float4x4 lView;
    float4 LightCol;
    float3 Position; // Source
    float Range; // Distance
    float RangePow; // Fade
    float LightStrength;
    float TexID;
    float KnowShadows; // > 0.5
    float Penumbra;
    // NoF = 45
    // Size = 180
};

struct SunLightProp
{
    float4x4 ShadowMapView;
    float4 LightCol;
    float3 Direction; // Source
    float LightStrength;
    float KnowShadows; // > 0.5
    float Penumbra;
    // NoF = 26
    // Size = 104
};
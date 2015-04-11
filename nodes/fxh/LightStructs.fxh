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
    float MapID;
    // NoF = 16
    // Size = 64
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
    float MapID;
    // NoF = 46
    // Size = 184
};

struct SunLightProp
{
    float4x4 ShadowMapView;
    float4 LightCol;
    float3 Direction; // Source
    float LightStrength;
    float KnowShadows; // > 0.5
    float Penumbra;
    float MapID;
    // NoF = 27
    // Size = 108
};
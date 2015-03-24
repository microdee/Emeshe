#define LIGHTUTILS_FXH 1

// define DOSHADOWS in vvvv for shadows

#if !defined(LIGHTSTRUCTS_FXH)
    #include "../fxh/LightStructs.fxh"
#endif

struct Components
{
	float3 Ambient;
	float3 Diffuse;
	float3 Specular;
	float3 SSS;
	float3 Rim;
};

StructuredBuffer<PointLightProp> pointlightprop <string uiname="Pointlight Buffer";>;
StructuredBuffer<SpotLightProp> spotlightprop <string uiname="Spotlight Buffer";>;
StructuredBuffer<float> MaskID;
bool UseMask = false;
bool ZeroBypass = false;
Texture2DArray SpotTexArray;
StructuredBuffer<SunLightProp> sunlightprop <string uiname="Sunlight Buffer";>;

SamplerState SpotSampler <bool visible=false;string uiname="Spotlight Sampler";>
{
    Filter=MIN_MAG_MIP_LINEAR;
    AddressU=CLAMP;
    AddressV=CLAMP;
};

SamplerState MapSampler <string uiname="Map Sampler";>
{
    Filter=MIN_MAG_MIP_LINEAR;
    AddressU=CLAMP;
    AddressV=CLAMP;
};

float lEpsilon : IMMUTABLE = 0.001;
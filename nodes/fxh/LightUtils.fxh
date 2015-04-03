#define LIGHTUTILS_FXH 1

// define DOSHADOWS in vvvv for shadows

#if !defined(LIGHTSTRUCTS_FXH)
#include "../fxh/LightStructs.fxh"
#endif
#if !defined(POISSONDISC_FXH)
#include "../fxh/PoissonDisc.fxh"
#endif
#if !defined(PANOTOOLS_FXH)
#include "../fxh/PanoTools.fxh"
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

#if !defined(PI)
    #define PI 3.14159265358979
#endif

#if !defined(DISCSAMPLES)
    #define DISCSAMPLES 32
#endif

float lEpsilon : IMMUTABLE = 0.001;
float2 ShadNoise = 0;

// define DOSHADOWS in vvvv to turn on shadows

float rand(float2 co)
{
  return frac(sin(dot(co.xy ,float2(12.9898,78.233))+ShadNoise.y) * 43758.5453);
}

float PointShadows(
    SamplerState ss,
    Texture2DArray maps,
    float slice,
    float3 lpos,
    float3 cwpos,
    float bias,
    float penumbra)
{
    float res = 1;
    float sampcount = DISCSAMPLES + 1;
    float3 ldir = normalize(cwpos-lpos);
    float4 centerpos = maps.SampleLevel(ss, float3(DirToUV(ldir), slice), 0);
    float centerrd = distance(cwpos, lpos);
    float centerd = distance(cwpos, centerpos.xyz);
    float centerhd = centerpos.a;
    //if(abs(centerrd-centerhd) > bias) res -= 1/sampcount;
    if((length(centerpos.xyz) > 0.0001) && (centerd > bias)) res -= 1/sampcount;
    
    for(float i=0; i<DISCSAMPLES; i++)
    {
        float tt = (i/DISCSAMPLES) * PI * 2;
        float3 pdiscray = PoissonDiscDir(ldir, tt, penumbra);
        float4 pcurrpos = maps.SampleLevel(ss, float3(DirToUV(pdiscray), slice), 0);
    	if(length(pcurrpos.xyz) > 0.0001)
    	{
	        float currd = distance(cwpos, pcurrpos.xyz);
    		float noise = 1 - rand(cwpos.xy + tt) * ShadNoise.x;
	        float3 discray = PoissonDiscDir(ldir, tt, penumbra * saturate(currd*4) * noise);
	        float4 currpos = maps.SampleLevel(ss, float3(DirToUV(discray), slice), 0);
    		
	        float3 clpos = discray * centerrd;
	        float currrd = distance(cwpos, clpos);
	        float currhd = distance(currpos.xyz, clpos);
	        if(abs(currrd-currhd) > bias) res -= 1/sampcount;
	        //if(currd > bias) res -= 1/sampcount;
    	}
    }
    return res;
}
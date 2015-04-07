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

SamplerState ShadSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = MIRROR;
};

#if !defined(PI)
    #define PI 3.14159265358979
#endif

#if !defined(DISCSAMPLES)
    #define DISCSAMPLES 32
#endif
#if !defined(SEARCH_DISCSAMPLES)
    #define SEARCH_DISCSAMPLES 16
#endif

float lEpsilon : IMMUTABLE = 0.001;
float2 ShadNoise = 0;
float ShadGamma = 1;
float ShadSoftOffs = 0;

float rand(float2 co)
{
	return frac(sin(dot(co.xy ,float2(12.9898,78.233))+ShadNoise.y) * 43758.5453);
}
float PenumbraSize(float zReceiver, float zBlocker) //Parallel plane estimation
{
	return (zReceiver - zBlocker) / zBlocker;
}

float PointShadows(
    Texture2DArray maps,
    float slice,
    float3 lpos,
	float lrange,
    float3 cwpos,
    float bias,
    float penumbra)
{
    float3 ldir = normalize(cwpos-lpos);
	//float4 centerpos = maps.SampleLevel(ShadSampler, float3(DirToUV(ldir), slice), 0);
	float centerld = distance(cwpos, lpos);
	//if(abs(centerpos.a - centerld) < bias) return 1;
	float numBlocks = 0;
	float sumBlocks = 0;
    
    for(float i=0; i<SEARCH_DISCSAMPLES; i++)
    {
        float tt = (i/SEARCH_DISCSAMPLES) * PI * 2;
		//float noise = 1 - rand(cwpos.xy + tt) * ShadNoise.x;
        float3 discray = PoissonDiscDir(ldir, tt, penumbra);
        float4 currpos = maps.SampleLevel(ShadSampler, float3(DirToUV(discray), slice), 0);
    	
    	if ( abs(currpos.a - centerld) > bias )
    	{
			sumBlocks += currpos.a;
			numBlocks++;
		}
    }
	if(numBlocks == 0) return 1;
	
	float avgBld = sumBlocks / numBlocks;
	float vpenumbra = PenumbraSize(centerld/lrange, avgBld/lrange) * penumbra + ShadSoftOffs;
    float res = 1;
	
    for(float i=0; i<DISCSAMPLES; i++)
    {
        float tt = (i/DISCSAMPLES) * PI * 2;
		float noise = 1 - rand(cwpos.xy + tt) * ShadNoise.x;
        float3 discray = PoissonDiscDir(ldir, tt, vpenumbra * noise);
        float4 currpos = maps.SampleLevel(ShadSampler, float3(DirToUV(discray), slice), 0);
    	
    	float dbias = (centerld > 1) ? pow(centerld,0.25) : pow(centerld,4);
    	if ( abs(currpos.a - centerld) > (bias * dbias) )
    	{
			res = res - 1.0/DISCSAMPLES;
		}
    }
	
    return saturate(pow(smoothstep(0,1,res),ShadGamma));
}
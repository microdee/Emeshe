#define DISCSAMPLE_FXH 1

#if !defined(POISSONDISC_FXH)
#include "../fxh/PoissonDisc.fxh"
#endif
#if !defined(PANOTOOLS_FXH)
#include "../fxh/PanoTools.fxh"
#endif

#if !defined(PI)
	#define PI 3.14159265358979
#endif

#if !defined(DISCSAMPLES)
	#define DISCSAMPLES 16
#endif

float4 DiscSample(
		Texture2DArray envtex,
		SamplerState ss,
		float3 dir,
		float blur,
		float slice,
		float maxmiplevel)
{
	float4 col = envtex.SampleLevel(ss, float3(DirToUV(dir), slice), 0);
	if(blur < 0.0001)
		return col;
	else
	{
		col = 0;
		float sampcount = DISCSAMPLES;
		for(float i=0; i<DISCSAMPLES; i++)
		{
			float tt = (i/sampcount) * PI * 2;
			float3 discray = PoissonDiscDir(dir, tt, blur);
			float lod = lerp(0, maxmiplevel, pow(blur, 0.25));
			col += envtex.SampleLevel(ss, float3(DirToUV(discray), slice), lod) / sampcount;
		}
		return col;
	}
}

float4 DiscSample(
		Texture2DArray envtex,
		SamplerState ss,
		float3 dir,
		float blur,
		float slice)
{
	float4 col = envtex.SampleLevel(ss, float3(DirToUV(dir), slice), 0);
	if(blur < 0.0001)
		return col;
	else
	{
		col = 0;
		float sampcount = DISCSAMPLES;
		for(float i=0; i<DISCSAMPLES; i++)
		{
			float tt = (i/sampcount) * PI * 2;
			float3 discray = PoissonDiscDir(dir, tt, blur);
			col += envtex.SampleLevel(ss, float3(DirToUV(discray), slice), 0) / sampcount;
		}
		return col;
	}
}


#define MREFORWARD_FXH 1

#if !defined(POWS_FXH)
#include "../fxh/pows.fxh"
#endif
#if !defined(BITWISE_FXH)
#include "../fxh/bitwise.fxh"
#endif
#if !defined(INSTANCEPARAMS_FXH)
#include "../fxh/InstanceParams.fxh"
#endif

/*
	optional defines:
	HAS_TEXCOORD
	HAS_GEOMVELOCITY
	HAS_NORMALMAP
	WRITEDEPTH
	TRIPLANAR
	IID_FROM_GEOM
	INSTANCING
	ALPHATEST
*/

struct VSin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	#if defined(HAS_TEXCOORD)
		float2 TexCd: TEXCOORD0;
	#endif
	#if defined(HAS_NORMALMAP)
		float3 Tangent : TANGENT;
		float3 Binormal : BINORMAL;
	#endif
	#if defined(HAS_GEOMVELOCITY)
		float4 velocity : COLOR0;
	#endif
	uint vid : SV_VertexID;
	uint iid : SV_InstanceID;
};

struct PSin
{
    float4 PosWVP: SV_Position;
    float4 PosP: PROJECTEDPOS;
    float4 PosV: VIEWPOS;
	float4 TexCd: TEXCOORD0;
    float3 NormV: NORMAL;
    float3 NormW: WORLDNORMAL;
    nointerpolation float ii: INSTANCEID;
	float4 velocity : COLOR0;
	#if defined(HAS_NORMALMAP)
		float3 Tangent : TANGENT;
		float3 Binormal : BINORMAL;
	#endif
};

struct PSinProp
{
    float4 PosWVP: SV_Position;
    float4 PosW: WORLDPOSITION;
    float3 NormW: WORLDNORMAL;
	float4 TexCd: TEXCOORD0;
    nointerpolation float ii: INSTANCEID;
};

struct PSOut
{
	float4 color : SV_Target0; // rgb: col; a: MatID
	float4 normalV : SV_Target1; // rgb: norm; a: ObjID
	float4 veluv : SV_Target2; // rg: velocity; ba: UV
	#if defined(WRITEDEPTH)
		float depth : SV_Depth;
	#endif
};

SamplerState Sampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = MIRROR;
};

float2 TriPlanar(float3 pos, float3 norm, float tpow)
{
	float2 uvxy = pos.xy;
	float2 uvxz = pos.xz;
	float2 uvyz = pos.yz;
	float3 uxy = {0,0,1};
	float3 uxz = {0,1,0};
	float3 uyz = {1,0,0};
	float3 d = 0;
	d.x = abs(dot(norm, uxy));
	d.y = abs(dot(norm, uxz));
	d.z = abs(dot(norm, uyz));
	d /= (d.x+d.y+d.z).xxx;
	d = pows(d,tpow);
	d /= (d.x+d.y+d.z).xxx;
	float2 uv = uvxy*d.x + uvxz*d.y + uvyz*d.z;
	return uv;
}
float4 TriPlanarSample(Texture2D tex, SamplerState s0, float3 pos, float3 norm, float tpow)
{
	float2 uvxy = pos.xy;
	float2 uvxz = pos.xz;
	float2 uvyz = pos.yz;
	float4 colxy = tex.Sample(s0, uvxy);
	float4 colxz = tex.Sample(s0, uvxz);
	float4 colyz = tex.Sample(s0, uvyz);
	float3 uxy = {0,0,1};
	float3 uxz = {0,1,0};
	float3 uyz = {1,0,0};
	float3 d = 0;
	d.x = abs(dot(norm, uxy));
	d.y = abs(dot(norm, uxz));
	d.z = abs(dot(norm, uyz));
	d /= (d.x+d.y+d.z).xxx;
	d = pows(d,tpow);
	d /= (d.x+d.y+d.z).xxx;
	float4 col = colxy*d.xxxx + colxz*d.yyyy + colyz*d.zzzz;
	return col;
}
float4 TriPlanarSampleLevel(Texture2D tex, SamplerState s0, float3 pos, float3 norm, float tpow, float LOD)
{
	float2 uvxy = pos.xy;
	float2 uvxz = pos.xz;
	float2 uvyz = pos.yz;
	float4 colxy = tex.SampleLevel(s0, uvxy, LOD);
	float4 colxz = tex.SampleLevel(s0, uvxz, LOD);
	float4 colyz = tex.SampleLevel(s0, uvyz, LOD);
	float3 uxy = {0,0,1};
	float3 uxz = {0,1,0};
	float3 uyz = {1,0,0};
	float3 d = 0;
	d.x = abs(dot(norm, uxy));
	d.y = abs(dot(norm, uxz));
	d.z = abs(dot(norm, uyz));
	d /= (d.x+d.y+d.z).xxx;
	d = pows(d,tpow);
	d /= (d.x+d.y+d.z).xxx;
	float4 col = colxy*d.xxxx + colxz*d.yyyy + colyz*d.zzzz;
	return col;
}

#define MRE_FXH 1

#if !defined(POWS_FXH)
#include "../fxh/pows.fxh"
#endif
#if !defined(BITWISE_FXH)
#include "../fxh/bitwise.fxh"
#endif
#if !defined(DEPTHRECONSTRUCT_FXH)
#include "../fxh/depthreconstruct.fxh"
#endif

Texture2D Color : MRE_COLOR;
Texture2D Normals : MRE_NORMALS;
Texture2D Velocity : MRE_VELUV;
Texture2D<float> Depth : MRE_DEPTH;
Texture2D<uint4> Stencil : MRE_STENCIL;

float4x4 CamView : CAM_VIEW;
float4x4 CamViewInv : CAM_VIEWINV;
float4x4 CamProj : CAM_PROJ;
float4x4 CamProjInv : CAM_PROJINV;
float3 CamPos : CAM_POSITION;

float DepthMode : MRE_DEPTHMODE;
float3 NearFarPow : NEARFARDEPTHPOW;

float2 GetUV(SamplerState SS, float2 uv)
{
	return Velocity.SampleLevel(SS, uv, 0).zw;
}
uint GetMatID(SamplerState SS, float2 uv)
{
	return (uint)Color.SampleLevel(SS, uv, 0).a;
}
float GetObjID(SamplerState SS, float2 uv)
{
	return Normals.SampleLevel(SS, uv, 0).a;
}
float GetStencil(float2 R, float2 uv)
{
	return Stencil.Load(int3(uv * R, 0)).g;
}
/*
float3 GetViewPos(SamplerState SS, float2 uv)
{
	float3 d = ViewPos.SampleLevel(SS, uv, 0).rgb;
	return d;
}
*/
float3 GetViewPos(SamplerState SS, float2 uv)
{
	float d = Depth.SampleLevel(SS, uv, 0);
	if(DepthMode == 1)
		return UVDtoVIEW(uv, d, NearFarPow, CamProj, CamProjInv);
	else
		return UVZtoVIEW(uv, d, CamProj, CamProjInv);
}
float3 LoadViewPos(float2 RR, float2 uv)
{
	float d = Depth.Load(int3(uv*RR,0));
	if(DepthMode == 1)
		return UVDtoVIEW(uv, d, NearFarPow, CamProj, CamProjInv);
	else
		return UVZtoVIEW(uv, d, CamProj, CamProjInv);
}
float3 GetWorldPos(SamplerState SS, float2 uv)
{
	return mul(float4(GetViewPos(SS, uv), 1), CamViewInv).xyz;
}
/*
float3 CalculateWorldPos(SamplerState SS, float2 uv)
{
	float d = Depth.SampleLevel(SS, uv, 0).r;
	if(DepthMode == 1)
		return UVDtoWORLD(uv, d, NearFarPow, CamViewInv, CamProj, CamProjInv);
	else
		return UVZtoWORLD(uv, d, CamViewInv, CamProj, CamProjInv);
}
*/
float3 GetWorldNormal(SamplerState SS, float2 uv)
{
	return normalize(mul(float4(Normals.SampleLevel(SS, uv, 0).rgb, 0), CamViewInv).xyz);
}
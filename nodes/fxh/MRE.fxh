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
Texture2D ViewPos : MRE_VIEWPOS;
Texture2D Normals : MRE_NORMALS;
Texture2D Velocity : MRE_VELOCITY;
Texture2D<uint4> MatProp : MRE_MATERIAL;
Texture2D Depth : MRE_DEPTH;
Texture2D<uint4> Stencil : MRE_STENCIL;

float4x4 CamView : CAM_VIEW;
float4x4 CamViewInv : CAM_VIEWINV;
float4x4 CamProj : CAM_PROJ;
float4x4 CamProjInv : CAM_PROJINV;
float3 CamPos : CAM_POSITION;

float DepthMode : MRE_DEPTHMODE;
float ObjIDMode : MRE_OBJIDMODE;
float3 NearFarPow : NEARFARDEPTHPOW;

float2 GetUV(float2 uv, float2 R)
{
	uint2 p0 = MatProp.Load(int3(uv * R, 0)).xy;
	float2 ret = f16tof32(p0);
	return ret;
}
uint GetMatID(float2 uv, float2 R)
{
	return MatProp.Load(int3(uv * R, 0)).z;
}
uint2 GetObjID(float2 uv, float2 R)
{
	uint p0 = MatProp.Load(int3(uv * R, 0)).w;
	if(ObjIDMode == 1) return SplitHalf(p0);
	else return uint2(p0, p0);
}
float GetStencil(float2 uv, float2 R)
{
	return Stencil.Load(int3(uv * R, 0)).g;
}

float3 GetViewPos(SamplerState s0, float2 uv)
{
	float3 d = ViewPos.SampleLevel(s0, uv, 0).rgb;
	return d;
}
float3 CalculateViewPos(SamplerState s0, float2 uv)
{
	float d = Depth.SampleLevel(s0, uv, 0).r;
	if(DepthMode == 1)
		return UVDtoVIEW(uv, d, NearFarPow, CamProj, CamProjInv);
	else
		return UVZtoVIEW(uv, d, CamProj, CamProjInv);
}
float3 GetWorldPos(SamplerState s0, float2 uv)
{
	return mul(float4(GetViewPos(s0, uv), 1), CamViewInv).xyz;
}
float3 CalculateWorldPos(SamplerState s0, float2 uv)
{
	float d = Depth.SampleLevel(s0, uv, 0).r;
	if(DepthMode == 1)
		return UVDtoWORLD(uv, d, NearFarPow, CamViewInv, CamProj, CamProjInv);
	else
		return UVZtoWORLD(uv, d, CamViewInv, CamProj, CamProjInv);
}
float3 GetWorldNormal(SamplerState s0, float2 uv)
{
	return normalize(mul(float4(Normals.SampleLevel(s0, uv, 0).rgb, 0), CamViewInv).xyz);
}
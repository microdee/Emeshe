#define DEPTHRECONSTRUCT_FXH 1
#define IS_ORTHO(P) (round(P._34)==0&&round(P._44)==1)

float2 UVtoSCREEN(float2 UV)
{
	return (UV.xy*2-1)*float2(1,-1);
}
float3 UVtoEYEV(float2 UV, float4x4 tPI)
{
	return normalize(float3(mul(float4((UV.xy*2-1)*float2(1,-1),0,1),tPI).xy,1));
}
float3 UVtoEYEW(float2 UV, float4x4 tVI, float4x4 tPI)
{
	return normalize(mul(float4(UVtoEYEV(UV, tPI), 1), tVI).xyz);
}
float2 EYEWtoUV(float3 Eye, float4x4 tV, float4x4 tP)
{
	float4 p=mul(float4(mul(Eye,(float3x3)tV),0),tP);
	return (p.xy/p.w)*float2(1,-1)*.5+.5;
}
float3 CAMPOS(float4x4 tVI)
{
	return tVI[3].xyz;
}
float3 UVZtoVIEW(float2 UV, float z, float4x4 tP, float4x4 tPI)
{
	if(IS_ORTHO(tP))return mul(float4(UV.x*2-1,1-2*UV.y,z,1.0),tPI).xyz;
	float4 p=mul(float4(UV.x*2-1,1-2*UV.y,0,1.0),tPI);
	float ld = tP._43 / (z - tP._33);
	p.xyz=float3(p.xy*ld,ld);
	return p.xyz; 
}

float3 UVZtoWORLD(float2 UV, float z, float4x4 tVI, float4x4 tP, float4x4 tPI){
	return mul(float4(UVZtoVIEW(UV, z, tP, tPI),1), tVI).xyz; 
}

float LinearDepth(float z, float4x4 tP)
{
	return tP._43 / (z - tP._33);
}
float2 WORLDtoUV(float3 PosW, float4x4 tV, float4x4 tP)
{
	float4 p=mul(float4(mul(float4(PosW.xyz,1),tV).xyz,1),tP);
	return (p.xy/p.w)*float2(1,-1)*.5+.5;
}

float3 RayOriginW(float2 UV, float4x4 tP, float4x4 tPI, float4x4 tVI)
{
	if(!IS_ORTHO(tP))return tVI[3].xyz;
	return mul(mul(float4(UV.x*2-1,1-2*UV.y,0,1.0),tPI),tVI).xyz;
}
float3 RayDirectionW(float2 UV, float4x4 tP, float4x4 tPI, float4x4 tVI)
{
	if(IS_ORTHO(tP))return mul(float3(0,0,1),(float3x3)tVI);
	return normalize(mul(float4(mul(float4((UV.xy*2-1)*float2(1,-1),0,1),tPI).xy,1,0),tVI).xyz);
}
float3 RayDirectionV(float2 UV, float4x4 tP, float4x4 tPI)
{
	if(IS_ORTHO(tP))return float3(0,0,1);
	return normalize(float3(mul(float4((UV.xy*2-1)*float2(1,-1),0,1),tPI).xy,1));
}
float RayLength(float2 UV, float z, float4x4 tP, float4x4 tPI, float4x4 tVI)
{
	return length(UVZtoWORLD(UV, z, tP, tPI, tVI).xyz-RayOriginW(UV, tP, tPI, tVI));
}

float3 UVDtoVIEW(float2 UV, float d, float3 NearFarPow, float4x4 tP, float4x4 tPI)
{
	float dd = pow(d,1/NearFarPow.z) * abs(NearFarPow.y - NearFarPow.x) + NearFarPow.x;
	return RayDirectionV(UV, tP, tPI) * dd;
}

float3 UVDtoWORLD(float2 UV, float d, float3 NearFarPow, float4x4 tVI, float4x4 tP, float4x4 tPI)
{
	return mul(float4(UVDtoVIEW(UV, d, NearFarPow, tP, tPI),1), tVI).xyz;
}
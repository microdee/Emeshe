
#import "pows.fxh"
struct sDeferredBase
{
	float4x4 tW;
	float4x4 ptW;
	float4x4 tTex;
	float DiffAmount;
	float4 DiffCol;
	float VelocityGain;
	float BumpAmount;
	float DispAmount;
	float pDispAmount;
	uint MatID;
	int ObjID0;
	int ObjID1;
	int ObjID2;
};

struct PSOut
{
	float4 color : SV_Target0;
	// RGBA
	float4 normalW : SV_Target1;
	//XYZ(1)
	float4 velocity : SV_Target2;
	// XYZ(A)
	float4 matprop : SV_Target4;
	// UV MatID OID
	float position : SV_Depth;
};

struct PSProp
{
	float4 positionW : SV_Target;
	//XYZ(1)
	float CamDistance : SV_Depth;
	//XYZ(1)
};

SamplerState Sampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = MIRROR;
};

float2 TriPlanar(float3 pos, float3 norm, float4x4 tT, float tpow)
{
	float3 post = mul(float4(pos,1),tT).xyz;
	float2 uvxy = post.xy;
	float2 uvxz = post.xz;
	float2 uvyz = post.yz;
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
float4 TriPlanarSample(Texture2D tex, SamplerState s0, float3 pos, float3 norm, float4x4 tT, float tpow)
{
	float3 post = mul(float4(pos,1),tT).xyz;
	float2 uvxy = post.xy;
	float2 uvxz = post.xz;
	float2 uvyz = post.yz;
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
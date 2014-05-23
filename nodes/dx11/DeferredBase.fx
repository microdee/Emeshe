//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

// conemapping constants:
#define NUM_ITERATIONS 16
#define NUM_ITERATIONS_RELIEF1 11
#define NUM_ITERATIONS_RELIEF2 5
//

Texture2D EmTex;
Texture2D DiffTex;
Texture2D SpecTex;
Texture2D ThickTex;
Texture2D BumpTex;
Texture2D NormTex;
Texture2D DispTex;
Texture2D pDispTex;
Texture2D DispNormTex;
Texture2D RefTex;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

#include "DeferredBaseStruct.fxh"

StructuredBuffer<DeferredBase> sbDeferredBase;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tW : WORLD;
	float4x4 ptW; // previous frame world transform per draw call
	float4x4 tV : VIEW;
	float4x4 tVI : VIEWINVERSE;
	float4x4 ptV : PREVIOUSVIEW;
	float4x4 tP : PROJECTION;
	float4x4 ptP : PREVIOUSPROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float4x4 NormTr;
	float gVelocityGain = 1;
	float GIAmount = 1;
	bool DEPTH_BIAS = false;
	bool BORDER_CLAMP = false;
	bool isPTxCd = false;
	float alphatest = 0.5;
	float utilalpha = 0;
	float bumpOffset = 0;
	float posDepth = 0;
	float displaceOffset = 0;
	bool IsWorld;
	float4x4 NormalMapTrB;
	float4x4 NormalMapTrD;
};

#include "..\conemapping.fxh"

struct VSin
{
	uint ii : SV_InstanceID;
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;	
	float4 TexCd: TEXCOORD0;
    float4 PosWVPps: TEXCOORD1;
    float4 PosW: TEXCOORD2;
    float4 PosWV: COLOR0;
    float3 NormWV: NORMAL;
    float3 NormW: TEXCOORD4;
	float3 eyeVec: TEXCOORD5;
    float4 vel : TEXCOORD6;
	uint psii: TEXCOORD7;
};

vs2ps VS(VSin In)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	if(isPTxCd) Out.TexCd = mul(In.PosO, sbDeferredBase[In.ii].tTex);
	else Out.TexCd = mul(float4(In.TexCd,0,1), sbDeferredBase[In.ii].tTex);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float4 pdispPos = In.PosO;
	
	if(sbDeferredBase[In.ii].DispAmount!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * sbDeferredBase[In.ii].DispAmount;
		dispPos.w = 1;
		pdispPos += (pDispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r * float4(In.NormO,1) + displaceOffset) * sbDeferredBase[In.ii].pDispAmount;
		pdispPos.w = 1;
		float3 normdir = dnormalmap*-(-1/(sbDeferredBase[In.ii].DispAmount+1)+1);
		dispNorm += normdir;
		//dispBinorm -= normdir;
		//dispTang -= normdir;
	}
	
	float4x4 w = mul(sbDeferredBase[In.ii].tW, tW);
    Out.PosW = mul(dispPos, w);
    Out.PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(Out.PosWV, tP);
    Out.PosWVPps = Out.PosWVP;
	
	float3 npos = Out.PosWV.xyz;
	float4x4 ptWVP = mul(sbDeferredBase[In.ii].ptW, ptW);
	ptWVP = mul(ptWVP, ptV);
	//ptWVP = mul(ptWVP, ptP);
	float3 pnpos = mul(pdispPos, ptWVP).xyz;
	Out.vel.rgb = ((npos - pnpos) * gVelocityGain * sbDeferredBase[In.ii].VelocityGain);
	Out.vel.rgb *= min(3,2/(pnpos.z));
	Out.vel.a = 1;
	
    //normal in view space
	float4x4 tWV = mul(w, tV);
    Out.NormWV = normalize(mul(dispNorm, tWV).xyz);
    Out.NormW = normalize(mul(dispNorm, w).xyz);
	
    //float3x3 tangentMap = float3x3(dispTang, dispBinorm, dispNorm);
    //tangentMap = mul(tangentMap, tW);
	float3 eyeVec = Out.PosWV.xyz - mul(float4(0,0,0,1), tVI).xyz;	
	//Out.eyeVec = mul(tangentMap, eyeVec);
	Out.eyeVec = eyeVec;
	
	Out.psii = In.ii;
	
    return Out;
}



struct PSOut
{
	float4 color : SV_Target0;
	// RGBA
	float4 position : SV_Target1;
	//XYZ(1)
	float4 velocity : SV_Target2;
	// XYZ(A)
	float4 matpropA : SV_Target3;
	//SpecMap ThickMap MatID (1)
	float4 matpropB : SV_Target4;
	// OID0 OID2 EmissionMap (1)
};

PSOut PS_Tex(vs2ps In): SV_Target
{
	PSOut Out = (PSOut)0;
	float3 normb = In.NormWV;
	float3 normWb = In.NormW;
	float2 itexcd = In.TexCd.xy;
	itexcd.x *= -1;
	float2 uvb = float2(0,0);
	if(sbDeferredBase[In.psii].BumpAmount != 0)
	{
		uvb = cone(In.TexCd.xy, In.eyeVec, BumpTex, g_samLinear, bumpOffset, sbDeferredBase[In.psii].BumpAmount * posDepth);
		if (BORDER_CLAMP)
		{
			if (uvb.x < 0.0) discard;
			if (uvb.x > sbDeferredBase[In.psii].tTex[0].x) discard;
			if (uvb.y < 0.0) discard;
			if (uvb.y > sbDeferredBase[In.psii].tTex[1].y) discard;
		}
	}
	else uvb = In.TexCd.xy;
	
	float depth = sbDeferredBase[In.psii].BumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	float ndepth = -1/(sbDeferredBase[In.psii].BumpAmount+1)+1;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normb += ((2 * normalmap) - 1.0)*-ndepth;
	float3 posWb = In.PosW;
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	float3 posb = In.PosWV;
	if(depth!=0) posb += In.NormWV * mdepth * (-1*pow(depth,.5));
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * sbDeferredBase[In.psii].DiffCol.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb * sbDeferredBase[In.psii].DiffCol.rgb * sbDeferredBase[In.psii].DiffAmount;
	Out.color.rgb = diffcol;
	Out.color.a = alphat;
	
	Out.position.xyz = posb;
	Out.position.a = alphat;
	
	Out.velocity.rgb = In.vel + .5;
	Out.velocity.a = alphat + utilalpha;
	
	//Out.emission.rgb = EmTex.Sample( g_samLinear, uvb).rgb * sbDeferredBase[In.psii].EmCol.rgb * sbDeferredBase[In.psii].EmAmount;
	//Out.emission.a = alphat;
	
	Out.matpropA.r = SpecTex.Sample(g_samLinear, uvb).r;
	Out.matpropA.g = ThickTex.Sample(g_samLinear, uvb).r;
	Out.matpropA.b = sbDeferredBase[In.psii].MatID;
	Out.matpropA.a = 1;
	
	Out.matpropB.rg = sbDeferredBase[In.psii].ObjectID.xy;
	Out.matpropB.b = EmTex.Sample( g_samLinear, uvb).r;
	Out.matpropB.a = 1;
	
    return Out;
}


struct PSOutUtil
{
	float4 color : SV_Target0;
	float4 position : SV_Target1;
	float4 normal : SV_Target2;
};




technique10 DeferredBaseT
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Tex() ) );
	}
}





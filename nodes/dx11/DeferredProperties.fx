//@author: microdee

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

// conemapping constants:
#define NUM_ITERATIONS 16
#define NUM_ITERATIONS_RELIEF1 11
#define NUM_ITERATIONS_RELIEF2 5
//
Texture2D DiffTex;
Texture2D BumpTex;
Texture2D NormTex;
Texture2D DispTex;
Texture2D DispNormTex;
StructuredBuffer<sDeferredBase> InstancedParams;

float3 campos : POINTLIGHTPOSITION;

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tW : WORLD;
	float4x4 tV : VIEW;
	float4x4 tVI : VIEWINVERSE;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float4x4 NormTr;
	float4x4 tTex;
	float4 FDiffColor;
	bool isPTxCd = false;
	float alphatest = 0.5;
	float FBumpAmount = 0;
	float FDispAmount = 0;
	float bumpOffset = 0;
	float posDepth = 0;
	float displaceOffset = 0;
	float4x4 NormalMapTrB;
	float4x4 NormalMapTrD;
	bool InstanceFromGeomFX = false;
};

struct VSin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	uint vid : SV_VertexID;
};
struct VSinst
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	float4 velocity : COLOR0;
	uint vid : SV_VertexID;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
    float3 NormW: NORMAL;
};
struct vs2psinst
{
    float4 PosWVP: SV_POSITION;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
    float3 NormW: NORMAL;
    nointerpolation float ii: TEXCOORD2;
};


vs2ps VS(VSin In)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	if(isPTxCd) Out.TexCd = mul(In.PosO, tTex);
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	
	if(FDispAmount!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * FDispAmount;
		dispPos.w = 1;
		float3 normdir = dnormalmap*-(-1/(FDispAmount+1)+1);
		dispNorm += normdir;
	}
	
	float4x4 w = tW;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
    Out.PosW = mul(dispPos, w);
    float4 PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(PosWV, tP);
	
    return Out;
}
vs2psinst VSInst(VSinst In)
{
    //inititalize all fields of output struct with 0
    vs2psinst Out = (vs2psinst)0;
	float ii = In.velocity.w;
	Out.ii = ii;
	
	float4x4 tT = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	if(isPTxCd) Out.TexCd = mul(In.PosO, tT);
	else Out.TexCd = mul(float4(In.TexCd,0,1), tT);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float dispam = (InstanceFromGeomFX) ? InstancedParams[ii].DispAmount*FDispAmount : FDispAmount;
	
	if(FDispAmount!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * dispam;
		dispPos.w = 1;
		float3 normdir = dnormalmap*-(-1/(FDispAmount+1)+1);
		dispNorm += normdir;
	}
	
	float4x4 w = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tW,tW) : tW;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
    Out.PosW = mul(dispPos, w);
    float4 PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(PosWV, tP);
	
    return Out;
}

struct PSOut
{
	float4 positionW : SV_Target0;
	//XYZ(1)
	float4 normalW : SV_Target1;
	//XYZ(1)
	float4 CamDistance : SV_Target2;
	//XYZ(1)
};


PSOut PS_Tex(vs2ps In)
{	
	float3 posWb = In.PosW.xyz;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 itexcd = In.TexCd.xy;
	itexcd.x *= -1;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	float ndepth = -1/(FBumpAmount+1)+1;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normWb += ((2 * normalmap) - 1.0)*-ndepth;
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
	Out.positionW.xyz = posWb;
	Out.positionW.a = alphat;
	
	Out.CamDistance.xyz = length(posWb-campos);
	Out.CamDistance.a = 0;
	
    return Out;
}

PSOut PS_Inst(vs2psinst In)
{	
	float ii = In.ii;
	float3 posWb = In.PosW.xyz;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 itexcd = In.TexCd.xy;
	itexcd.x *= -1;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float bmpam = (InstanceFromGeomFX) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	float ndepth = -1/(FBumpAmount+1)+1;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normWb += ((2 * normalmap) - 1.0)*-ndepth;
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
	Out.positionW.xyz = posWb;
	Out.positionW.a = alphat;
	
	Out.CamDistance.xyz = length(posWb-campos);
	Out.CamDistance.a = 0;
	
    return Out;
}
technique10 DeferredProp
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}

technique10 DeferredPropInstanced
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VSInst() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Inst() ) );
	}
}

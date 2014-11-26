//@author: microdee

#import "MREForward.fxh"

//
Texture2D DiffTex;
Texture2D BumpTex;
StructuredBuffer<sDeferredBase> InstancedParams;
bool DistanceToPoint = false;
float3 CamPos : CAMPOS;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tW : WORLD;
	float4x4 tV : VIEW;
	float4x4 tVI : VIEWINVERSE;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float4x4 NormTr;
	float4x4 tTex;
	float4 FDiffColor <bool color=true;> = 1;
	bool isTriPlanar = false;
	float TriPlanarPow = 1;
	float alphatest = 0.5;
	float FBumpAmount = 0;
	float bumpOffset = 0;
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
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	
	float4x4 w = tW;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
    Out.PosW = mul(dispPos, w);
	
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
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
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tT);
	
	float4x4 w = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tW,tW) : tW;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
    Out.PosW = mul(dispPos, w);
    float4 PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(PosWV, tP);
	
    return Out;
}

PSProp PS_Tex(vs2ps In)
{	
	float3 posWb = In.PosW.xyz;

	PSProp Out = (PSProp)0;
	float3 normWb = In.NormW;
	float2 itexcd = In.TexCd.xy;
	itexcd.x *= -1;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(Sampler, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, Sampler, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( Sampler, uvb).a * FDiffColor.a;
	if(isTriPlanar) alphatt = TriPlanarSample(DiffTex, Sampler, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow) * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
	Out.positionW.xyz = posWb;
	Out.positionW.a = alphat;
	
	float4 posout = mul(float4(posWb,1),tVP);
	
	if(DistanceToPoint) Out.CamDistance = length(posWb-CamPos)/posout.w;
	else Out.CamDistance = posout.z/posout.w;
	
    return Out;
}

PSProp PS_Inst(vs2psinst In)
{	
	float ii = In.ii;
	float3 posWb = In.PosW.xyz;

	PSProp Out = (PSProp)0;
	float3 normWb = In.NormW;
	float2 itexcd = In.TexCd.xy;
	itexcd.x *= -1;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	float4x4 tT = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float bmpam = (InstanceFromGeomFX) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = BumpTex.Sample(Sampler, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, Sampler, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( Sampler, uvb).a * FDiffColor.a;
	if(isTriPlanar) alphatt = TriPlanarSample(DiffTex, Sampler, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow) * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
	Out.positionW.xyz = posWb;
	Out.positionW.a = alphat;
	
	float4 posout = mul(float4(posWb,1),tVP);
	
	Out.CamDistance = posout.z/posout.w;
	
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

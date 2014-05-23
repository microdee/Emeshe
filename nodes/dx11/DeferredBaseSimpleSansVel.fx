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
	bool UsePreviousGeometry = false;
	float4x4 NormTr;
	float4x4 tTex;
	float FDiffAmount = 1;
	float4 FDiffColor = 1;
	float gVelocityGain = 1;
	float GIAmount = 1;
	bool DEPTH_BIAS = false;
	bool BORDER_CLAMP = false;
	bool isPTxCd = false;
	float alphatest = 0.5;
	float utilalpha = 0;
	float FBumpAmount = 0;
	float FDispAmount = 0;
	float FpDispAmount = 0;
	float bumpOffset = 0;
	float posDepth = 0;
	float displaceOffset = 0;
	bool IsWorld;
	float4x4 NormalMapTrB;
	float4x4 NormalMapTrD;
	int MatID = 0;
	int3 ObjID = 0;
	float SmoothNormVal = 0;
	float SmoothNormPow = 2;
};

struct VSin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	uint vid : SV_VertexID;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;	
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
    float4 PosWV: TEXCOORD2;
    float3 NormWV: NORMAL;
    float3 NormW: TEXCOORD3;
	float4 triPos0 : TEXCOORD4;
	float3 triPos1 : TEXCOORD5;
	float3 triPos2 : TEXCOORD6;
    float4 vel : COLOR0;
};

vs2ps VS(VSin In)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	if(isPTxCd) Out.TexCd = mul(In.PosO, tTex);
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float4 pdispPos = In.PosO;
	
	if(FDispAmount!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * FDispAmount;
		dispPos.w = 1;
		pdispPos += (pDispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r * float4(In.NormO,1) + displaceOffset) * FpDispAmount;
		pdispPos.w = 1;
		float3 normdir = dnormalmap*-(-1/(FDispAmount+1)+1);
		dispNorm += normdir;
		//dispBinorm -= normdir;
		//dispTang -= normdir;
	}
	
	float4x4 w = tW;
    Out.PosW = mul(dispPos, w);
    Out.PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(Out.PosWV, tP);
	
	float3 npos = Out.PosWV.xyz;
	float4x4 ptWV = ptW;
	ptWV = mul(ptWV, ptV);
	//ptWVP = mul(ptWVP, ptP);
	float3 pnpos = mul(pdispPos, ptWV).xyz;
	Out.vel.rgb = ((npos - pnpos) * gVelocityGain);
	Out.vel.rgb *= min(3,2/(pnpos.z));
	Out.vel.rgb += 0.5;
	Out.vel.a = 1;
	
    //normal in view space
	float4x4 tWV = mul(w, tV);
    Out.NormWV = normalize(mul(dispNorm, tWV).xyz);
    Out.NormW = normalize(mul(dispNorm, w).xyz);
	/*
    //float3x3 tangentMap = float3x3(dispTang, dispBinorm, dispNorm);
    //tangentMap = mul(tangentMap, tW);
	float3 eyeVec = Out.PosWV.xyz - mul(float4(0,0,0,1), tVI).xyz;	
	//Out.eyeVec = mul(tangentMap, eyeVec);
	Out.eyeVec = eyeVec;
	*/
    return Out;
}

[maxvertexcount(3)]
void GS(triangle vs2ps input[3], inout TriangleStream<vs2ps> gsout)
{
	vs2ps o;
	
	for(uint i = 0; i<3; i++)
	{
		o = input[i];
		o.triPos0.xyz = input[0].PosW.xyz;
		o.triPos1 = input[1].PosW.xyz;
		o.triPos2 = input[2].PosW.xyz;
		gsout.Append(o);
	}
	
	gsout.RestartStrip();
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
	uvb = In.TexCd.xy;
	
	float3 tripos0 = In.triPos0-In.PosW;
	float3 tripos1 = In.triPos1-In.PosW;
	float3 tripos2 = In.triPos2-In.PosW;
	float3 dFromVerts = float3(0,0,0);
	dFromVerts.x = length(tripos0);
	dFromVerts.y = length(tripos1);
	dFromVerts.z = length(tripos2);
	float combinedDist = pow(abs(min(dFromVerts.x, min(dFromVerts.y, dFromVerts.z)) * SmoothNormVal),SmoothNormPow)*sign(SmoothNormVal);
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	float3 posWb = In.PosW + combinedDist * normWb;
	float3 posb = In.PosWV + combinedDist * normb;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	float ndepth = -1/(FBumpAmount+1)+1;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normb += ((2 * normalmap) - 1.0)*-ndepth;
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	if(depth!=0) posb += In.NormWV * mdepth * (-1*pow(depth,.5));
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb * FDiffColor.rgb * FDiffAmount;
    //float3 diffcol = combinedDist*10;
	Out.color.rgb = diffcol;
	Out.color.a = alphat;
	
	Out.position.xyz = posb;
	Out.position.a = alphat;
	
	Out.velocity.rgb = In.vel;
	Out.velocity.a = alphat + utilalpha;
	
	//Out.emission.rgb = EmTex.Sample( g_samLinear, uvb).rgb * sbDeferredBase[In.psii].EmCol.rgb * sbDeferredBase[In.psii].EmAmount;
	//Out.emission.a = alphat;
	
	Out.matpropA.r = SpecTex.Sample(g_samLinear, uvb).r;
	Out.matpropA.g = ThickTex.Sample(g_samLinear, uvb).r;
	Out.matpropA.b = MatID;
	Out.matpropA.a = 1;
	
	Out.matpropB.rg = ObjID.xy;
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




technique10 DeferredBase
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		//SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}



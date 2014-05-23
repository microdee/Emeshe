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
StructuredBuffer<sDeferredBase> InstancedParams;

SamplerState g_samLinear
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
	float4x4 tWV : WORLDVIEW;
	bool UsePreviousGeometry = true;
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
	bool InstanceFromGeomFX = false;
	bool3 NormMapProp = bool3(false, false, true);
};

struct VSgvin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	float4 velocity : COLOR0;
	uint vid : SV_VertexID;
};

struct VSin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	uint vid : SV_VertexID;
};

struct vs2gs
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
	float3 ViewDir: TEXCOORD3;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
};
struct vs2gsi
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
	float3 ViewDir: TEXCOORD3;
    nointerpolation float ii: TEXCOORD2;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
};
/*
struct gs2ps
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
    float3 NormW: NORMAL;
	float4 triPos0 : TEXCOORD2;
	float4 triPos1 : TEXCOORD3;
	float4 triPos2 : TEXCOORD4;
	float3 triNorm0 : TEXCOORD5;
	float3 triNorm1 : TEXCOORD6;
	float3 triNorm2 : TEXCOORD7;
    float4 vel : COLOR0;
};*/

vs2gsi VSgv(VSgvin In)
{
    // inititalize
    vs2gsi Out = (vs2gsi)0;
	// get Instance ID from GeomFX
	float ii = In.velocity.w;
	Out.ii = ii;
	
	// TexCoords
	float4x4 tT = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	if(isPTxCd) Out.TexCd = mul(In.PosO, tT);
	else Out.TexCd = mul(float4(In.TexCd,0,1), tT);
	
	float4x4 w = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tW,tW) : tW;
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
    float3 fViewDirV = -normalize(mul(mul(float4(dispPos.xyz,1),w),tV));
	//float4 pdispPos = In.PosO;
	
	float4 pdispPos = float4(In.velocity.xyz,1);
	float dispam = (InstanceFromGeomFX) ? InstancedParams[ii].DispAmount*FDispAmount : FDispAmount;
	float pdispam = (InstanceFromGeomFX) ? InstancedParams[ii].pDispAmount*FpDispAmount : FpDispAmount;
	// displacement
	if(dispam!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * dispam;
		dispPos.w = 1;
		pdispPos += (pDispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r * float4(In.NormO,1) + displaceOffset) * pdispam;
		pdispPos.w = 1;
		//dispNorm = lerp(dispNorm, perturb_normal(dispNorm, fViewDirV, Out.TexCd.xy, dnormalmap, NormMapProp), dispam);
	}
	
    Out.NormW = normalize(mul(dispNorm, w).xyz);
    Out.PosW = mul(dispPos, w);
    float4 PosWV = mul(Out.PosW, tV);
	Out.ViewDir = normalize(mul(float4(0,0,0,1),tVI)-Out.PosW);
    Out.PosWVP = mul(PosWV, tP);
	
	// velocity
	float4x4 pw = (InstanceFromGeomFX) ? mul(InstancedParams[ii].ptW,ptW) : ptW;
	float3 npos = PosWV.xyz;
	float4x4 ptWV = pw;
	ptWV = mul(ptWV, ptV);
	float3 pnpos = mul(pdispPos, ptWV).xyz;
	Out.vel.rgb = ((npos - pnpos) * gVelocityGain);
	Out.vel.rgb += 0.5;
	Out.vel.a = 1;
	
    return Out;
}
vs2gs VS(VSin In)
{
    //inititalize all fields of output struct with 0
    vs2gs Out = (vs2gs)0;
	
	if(isPTxCd) Out.TexCd = mul(In.PosO, tTex);
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float4 pdispPos = In.PosO;
    float3 fViewDirV = -normalize(mul(mul(float4(dispPos.xyz,1),tW),tV));
	
	float dispam = FDispAmount;
	float pdispam = FpDispAmount;
	
	if(FDispAmount!=0)
	{
		float3 dnormalmap = mul(DispNormTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0), NormalMapTrB).xyz;
		dispPos += (DispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r + displaceOffset) * float4(In.NormO,1) * dispam;
		dispPos.w = 1;
		pdispPos += (pDispTex.SampleLevel(g_samLinear, Out.TexCd.xy, 0).r * float4(In.NormO,1) + displaceOffset) * pdispam;
		pdispPos.w = 1;
		//dispNorm = lerp(dispNorm, perturb_normal(dispNorm, fViewDirV, Out.TexCd.xy, dnormalmap, NormMapProp), dispam);
	}
	
	float4x4 w = tW;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
	
    Out.PosW = mul(dispPos, w);
    float4 PosWV = mul(Out.PosW, tV);
	Out.ViewDir = normalize(mul(float4(0,0,0,1),tVI)-Out.PosW);
    Out.PosWVP = mul(PosWV, tP);
	//Out.PosW -= float4(Out.NormW*SmoothNormVal,0);
	
	float3 npos = PosWV.xyz;
	float4x4 ptWV = ptW;
	ptWV = mul(ptWV, ptV);
	//ptWVP = mul(ptWVP, ptP);
	float3 pnpos = mul(pdispPos, ptWV).xyz;
	Out.vel.rgb = ((npos - pnpos) * gVelocityGain);
	//Out.vel.rgb *= min(3,2/(pnpos.z));
	Out.vel.rgb += 0.5;
	Out.vel.a = 1;
	
    return Out;
}
/*
[maxvertexcount(3)]
void GS(triangle vs2gs input[3], inout TriangleStream<gs2ps> gsout)
{
	gs2ps o;
	
	for(uint i = 0; i<3; i++)
	{
		o.PosWVP = input[i].PosWVP;
		o.PosW = input[i].PosW;
		o.NormW = input[i].NormW;
		o.TexCd = input[i].TexCd;
		o.vel = input[i].vel;
		o.triPos0.xyz = input[0].PosW.xyz+input[0].NormW*SmoothNormVal;
		o.triPos1.xyz = input[1].PosW.xyz+input[1].NormW*SmoothNormVal;
		o.triPos2.xyz = input[2].PosW.xyz+input[2].NormW*SmoothNormVal;
		o.triNorm0 = input[0].NormW;
		o.triNorm1 = input[1].NormW;
		o.triNorm2 = input[2].NormW;
		float3 c1 = cross(input[0].PosW.xyz-input[1].PosW.xyz, input[0].PosW.xyz-input[2].PosW.xyz);
		o.triPos0.w = c1.x;
		o.triPos1.w = c1.y;
		o.triPos2.w = c1.z;
		
		gsout.Append(o);
	}
	
	gsout.RestartStrip();
}*/

float3x3 cotangent_frame( float3 N, float3 p, float2 uv )
{
    // get edge vectors of the pixel triangle
    float3 dp1 = ddx( p );
    float3 dp2 = ddy( p );
    float2 duv1 = ddx( uv );
    float2 duv2 = ddy( uv );
 
    // solve the linear system
    float3 dp2perp = cross( dp2, N );
    float3 dp1perp = cross( N, dp1 );
    float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
 
    // construct a scale-invariant frame 
    float invmax = rsqrt( max( dot(T,T), dot(B,B) ) );
    return float3x3( T * invmax, B * invmax, N );
}

float3 perturb_normal( float3 N, float3 V, float2 texcoord, float3 inmap, bool3 u_2ch_gu)
{
    // assume N, the interpolated vertex normal and 
    // V, the view vector (vertex to eye)
	float3 map = inmap;
    if(u_2ch_gu.x) map = map * 255/127 - 128/127;
    if(u_2ch_gu.y) map.z = sqrt( 1. - dot( map.xy, map.xy ) );
    if(u_2ch_gu.z) map.y = -map.y;
    float3x3 TBN = cotangent_frame( N, -V, texcoord );
    return normalize( mul(map,TBN) );
}

struct PSOut
{
	float4 color : SV_Target0;
	// RGBA
	float4 normalW : SV_Target1;
	//XYZ(1)
	float4 velocity : SV_Target2;
	// XYZ(A)
	float4 maps : SV_Target3;
	//SpecMap ThickMap EmissionMap (1)
	float4 matprop : SV_Target4;
	// OID0 OID2 MatID (1)
	float position : SV_Depth;
};


PSOut PS_Tex(vs2gs In)
{
	
	float3 posWb = In.PosW.xyz;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normWb = lerp(normWb, perturb_normal(normWb, In.ViewDir, uvb, normalmap, NormMapProp), depth*100);
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
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb * FDiffColor.rgb * FDiffAmount;
    //float3 diffcol = combinedDist*10;
	Out.color.rgb = diffcol;
	Out.color.a = alphat;
	
	float4 posout = mul(float4(posWb,1),tVP);
	Out.position = posout.z/posout.w;
	
	Out.velocity.rgb = In.vel.xyz-.5;
	Out.velocity.rgb *= min(3,2/mul(float4(posWb,1),tV).z);
	Out.velocity.rgb +=.5;
	Out.velocity.a = alphat + utilalpha;
	
	Out.maps.r = SpecTex.Sample(g_samLinear, uvb).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	Out.maps.a = 1;
	
	Out.matprop.rg = ObjID.xy;
	Out.matprop.b = MatID;
	Out.matprop.a = 1;
	
    return Out;
}

PSOut PS_Inst(vs2gsi In)
{
	float ii = In.ii;
	float3 posWb = In.PosW.xyz;
	float3 V = In.ViewDir;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 uvb = float2(0,0);
	uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	float bmpam = (InstanceFromGeomFX) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	
	float3 normalmap = mul(NormTex.Sample(g_samLinear,uvb), NormalMapTrB).xyz;
	if(depth!=0) normWb = lerp(normWb, normalize(perturb_normal(normWb, V, uvb, normalmap, NormMapProp)), depth*100);
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
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb;
	if(InstanceFromGeomFX)
	{
    	diffcol *= FDiffColor.rgb * FDiffAmount * InstancedParams[ii].DiffAmount * InstancedParams[ii].DiffCol;
	}
	else
	{
		diffcol *= FDiffColor.rgb * FDiffAmount;
	}
    //float3 diffcol = combinedDist*10;
	Out.color.rgb = diffcol;
	Out.color.a = alphat;
	
	float4 posout = mul(float4(posWb,1),tVP);
	Out.position = posout.z/posout.w;
	
	Out.velocity.rgb = In.vel.xyz-.5;
	Out.velocity.rgb *= min(3,2/mul(float4(posWb,1),tV).z);
	Out.velocity.rgb +=.5;
	Out.velocity.a = alphat + utilalpha;
	
	Out.maps.r = SpecTex.Sample(g_samLinear, uvb).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	
	Out.maps.a = 1;
	
	if(InstanceFromGeomFX)
	{
		Out.matprop.rg = float2(InstancedParams[ii].ObjID0,InstancedParams[ii].ObjID1);
		Out.matprop.b = InstancedParams[ii].MatID;
	}
	else
	{
		Out.matprop.rg = ObjID.xy;
		Out.matprop.b = MatID;
	}
	Out.matprop.a = 1;
	
    return Out;
}

technique10 DeferredBase
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Tex() ) );
	}
}
/*
technique10 DeferredBaseInstanced
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}*/

technique10 DeferredBaseGeomVel
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VSgv() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Inst() ) );
	}
}
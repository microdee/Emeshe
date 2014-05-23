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
Texture2D RefTex;
StructuredBuffer<sDeferredBase> InstancedParams;

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = MIRROR;
    AddressV = MIRROR;
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
	float4x4 NormTr;
	float4x4 tTex;
	float FDiffAmount = 1;
	float4 FDiffColor <bool color=true;> = 1;
	float gVelocityGain = 1;
	bool isTriPlanar = false;
	float TriPlanarPow = 1;
	float alphatest = 0.5;
	float utilalpha = 0;
	float FBumpAmount = 0;
	float bumpOffset = 0;
	int MatID = 0;
	int3 ObjID = 0;
	bool InstanceFromGeomFX = false;
	bool Instancing = false;
};

struct VSgvin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	float4 velocity : COLOR0;
	uint vid : SV_VertexID;
	uint iid : SV_InstanceID;
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
	float3 NormO: TEXCOORD2;
    float4 PosW: TEXCOORD1;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
};
struct vs2gsi
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: TEXCOORD1;
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
	d = pow(d,tpow);
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
	d = pow(d,tpow);
	d /= (d.x+d.y+d.z).xxx;
	float4 col = colxy*d.xxxx + colxz*d.yyyy + colyz*d.zzzz;
	return col;
}
vs2gsi VSgv(VSgvin In)
{
    // inititalize
    vs2gsi Out = (vs2gsi)0;
	// get Instance ID from GeomFX
	float ii = (Instancing) ? In.iid : In.velocity.w;
	Out.ii = ii;
	
	// TexCoords
	float4x4 tT = (InstanceFromGeomFX || Instancing) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	float4x4 w = (InstanceFromGeomFX || Instancing) ? mul(InstancedParams[ii].tW,tW) : tW;
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
    float3 fViewDirV = -normalize(mul(mul(float4(dispPos.xyz,1),w),tV));
	//float4 pdispPos = In.PosO;
	
	float4 pdispPos = float4(In.velocity.xyz,1);
	
    Out.NormW = normalize(mul(dispNorm, w).xyz);
	
    Out.PosW = mul(dispPos, w);
	
	//if(isTriPlanar) Out.TexCd = float4(TriPlanar(dispPos.xyz, dispNorm, tT, TriPlanarPow),0,1);
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tT);
	
    float4 PosWV = mul(Out.PosW, tV);
    Out.PosWVP = mul(PosWV, tP);
	
	// velocity
	float4x4 pw = (InstanceFromGeomFX|| Instancing) ? mul(InstancedParams[ii].ptW,ptW) : ptW;
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
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float4 pdispPos = In.PosO;
    float3 fViewDirV = -normalize(mul(mul(float4(dispPos.xyz,1),tW),tV));
	
	float4x4 w = tW;
	Out.NormO = dispNorm;
    Out.NormW = normalize(mul(dispNorm, w).xyz);
	
    Out.PosW = mul(dispPos, w);
	
	//if(isTriPlanar) Out.TexCd = float4(TriPlanar(dispPos.xyz, dispNorm, tTex, TriPlanarPow),0,1);
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
    float4 PosWV = mul(Out.PosW, tV);
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
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tTex, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * -1*depth;
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	if(isTriPlanar) alphatt = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).a * FDiffColor.a;
	alphat = alphatt;
	if(alphat < (1-alphatest)) discard;
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb * FDiffColor.rgb * FDiffAmount;
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).rgb * FDiffColor.rgb * FDiffAmount;
    //float3 diffcol = combinedDist*10;
	Out.color.rgb = diffcol;
	Out.color.a = 1;
	
	float4 posout = mul(float4(posWb,1),tVP);
	Out.position = posout.z/posout.w;
	
	Out.velocity.rgb = In.vel.xyz-.5;
	Out.velocity.rgb *= min(3,2/mul(float4(posWb,1),tV).z);
	Out.velocity.rgb +=.5;
	Out.velocity.a = alphat + utilalpha;
	
	Out.maps.r = SpecTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormO, tTex, TriPlanarPow).r;
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

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 uvb = float2(0,0);
	
	float4x4 tT = (InstanceFromGeomFX|| Instancing) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tT, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	float bmpam = (InstanceFromGeomFX|| Instancing) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * -1*depth;
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
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).rgb;
	if(InstanceFromGeomFX|| Instancing)
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
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.a = 1;
	
	Out.maps.a = 1;
	
	if(InstanceFromGeomFX|| Instancing)
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
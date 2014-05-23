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
	float CurveAmount = 1;
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
    float4 PosW: POSITION1;
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
	float ii = In.velocity.w;
	Out.ii = ii;
	
	// TexCoords
	float4x4 tT = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	float4x4 w = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tW,tW) : tW;
	
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
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	float4 pdispPos = In.PosO;
    float3 fViewDirV = -normalize(mul(mul(float4(dispPos.xyz,1),tW),tV));
	
	float4x4 w = tW;
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

struct gs2ps
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: POSITION1;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
	
	float4 triPos0 : TPOS0;
	float4 triPos1 : TPOS1;
	float4 triPos2 : TPOS2;
	float3 triNorm0 : TNORM0;
	float3 triNorm1 : TNORM1;
	float3 triNorm2 : TNORM2;
	
    float3 f3B210 : POSITION2;
    float3 f3B120 : POSITION3;
    float3 f3B021 : POSITION4;
    float3 f3B012 : POSITION5;
    float3 f3B102 : POSITION6;
    float3 f3B201 : POSITION7;
    float3 f3B111 : CENTER;
    float3 f3N110 : NORMAL2;
    float3 f3N011 : NORMAL3;
    float3 f3N101 : NORMAL4;
};

struct gs2psi
{
    float4 PosWVP: SV_Position;
	float4 TexCd: TEXCOORD0;
    float4 PosW: POSITION1;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
    nointerpolation float ii : TEXCOORD1;
	
	float4 triPos0 : TPOS0;
	float4 triPos1 : TPOS1;
	float4 triPos2 : TPOS2;
	float3 triNorm0 : TNORM0;
	float3 triNorm1 : TNORM1;
	float3 triNorm2 : TNORM2;
	
    float3 f3B210 : POSITION2;
    float3 f3B120 : POSITION3;
    float3 f3B021 : POSITION4;
    float3 f3B012 : POSITION5;
    float3 f3B102 : POSITION6;
    float3 f3B201 : POSITION7;
    float3 f3B111 : CENTER;
    float3 f3N110 : NORMAL2;
    float3 f3N011 : NORMAL3;
    float3 f3N101 : NORMAL4;
};

[maxvertexcount(3)]
void GS(triangle vs2gs input[3], inout TriangleStream<gs2ps> gsout)
{
	gs2ps o;
	
	o.triPos0.xyz = input[0].PosW.xyz;
	o.triPos1.xyz = input[1].PosW.xyz;
	o.triPos2.xyz = input[2].PosW.xyz;
	o.triNorm0 = input[0].NormW;
	o.triNorm1 = input[1].NormW;
	o.triNorm2 = input[2].NormW;
	float3 c1 = cross(input[0].PosW.xyz-input[1].PosW.xyz, input[0].PosW.xyz-input[2].PosW.xyz);
	o.triPos0.w = c1.x;
	o.triPos1.w = c1.y;
	o.triPos2.w = c1.z;
		
    float3 f3B003 = input[0].PosW.xyz;
    float3 f3B030 = input[1].PosW.xyz;
    float3 f3B300 = input[2].PosW.xyz;
    // And Normals
    float3 f3N002 = input[0].NormW;
    float3 f3N020 = input[1].NormW;
    float3 f3N200 = input[2].NormW;

    o.f3B210 = ( ( 2.0f * f3B003 ) + f3B030 - ( dot( ( f3B030 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;
    o.f3B120 = ( ( 2.0f * f3B030 ) + f3B003 - ( dot( ( f3B003 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    o.f3B021 = ( ( 2.0f * f3B030 ) + f3B300 - ( dot( ( f3B300 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    o.f3B012 = ( ( 2.0f * f3B300 ) + f3B030 - ( dot( ( f3B030 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    o.f3B102 = ( ( 2.0f * f3B300 ) + f3B003 - ( dot( ( f3B003 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    o.f3B201 = ( ( 2.0f * f3B003 ) + f3B300 - ( dot( ( f3B300 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;

    float3 f3E = ( o.f3B210 + o.f3B120 + o.f3B021 + o.f3B012 + o.f3B102 + o.f3B201 ) / 6.0f;
    float3 f3V = ( f3B003 + f3B030 + f3B300 ) / 3.0f;
    o.f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
    
    float fV12 = 2.0f * dot( f3B030 - f3B003, f3N002 + f3N020 ) / dot( f3B030 - f3B003, f3B030 - f3B003 );
    o.f3N110 = normalize( f3N002 + f3N020 - fV12 * ( f3B030 - f3B003 ) );
    float fV23 = 2.0f * dot( f3B300 - f3B030, f3N020 + f3N200 ) / dot( f3B300 - f3B030, f3B300 - f3B030 );
    o.f3N011 = normalize( f3N020 + f3N200 - fV23 * ( f3B300 - f3B030 ) );
    float fV31 = 2.0f * dot( f3B003 - f3B300, f3N200 + f3N002 ) / dot( f3B003 - f3B300, f3B003 - f3B300 );
    o.f3N101 = normalize( f3N200 + f3N002 - fV31 * ( f3B003 - f3B300 ) );
	
	for(uint i = 0; i<3; i++)
	{
		o.PosWVP = input[i].PosWVP;
		o.PosW = input[i].PosW;
		o.NormW = input[i].NormW;
		o.TexCd = input[i].TexCd;
		o.vel = input[i].vel;
		
		gsout.Append(o);
	}
	
	gsout.RestartStrip();
}

[maxvertexcount(3)]
void GSgv(triangle vs2gsi input[3], inout TriangleStream<gs2psi> gsout)
{
	gs2psi o;
	
	o.triPos0.xyz = input[0].PosW.xyz;
	o.triPos1.xyz = input[1].PosW.xyz;
	o.triPos2.xyz = input[2].PosW.xyz;
	o.triNorm0 = input[0].NormW;
	o.triNorm1 = input[1].NormW;
	o.triNorm2 = input[2].NormW;
	float3 c1 = cross(input[0].PosW.xyz-input[1].PosW.xyz, input[0].PosW.xyz-input[2].PosW.xyz);
	o.triPos0.w = c1.x;
	o.triPos1.w = c1.y;
	o.triPos2.w = c1.z;
		
    float3 f3B003 = input[0].PosW.xyz;
    float3 f3B030 = input[1].PosW.xyz;
    float3 f3B300 = input[2].PosW.xyz;
    // And Normals
    float3 f3N002 = input[0].NormW;
    float3 f3N020 = input[1].NormW;
    float3 f3N200 = input[2].NormW;

    o.f3B210 = ( ( 2.0f * f3B003 ) + f3B030 - ( dot( ( f3B030 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;
    o.f3B120 = ( ( 2.0f * f3B030 ) + f3B003 - ( dot( ( f3B003 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    o.f3B021 = ( ( 2.0f * f3B030 ) + f3B300 - ( dot( ( f3B300 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    o.f3B012 = ( ( 2.0f * f3B300 ) + f3B030 - ( dot( ( f3B030 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    o.f3B102 = ( ( 2.0f * f3B300 ) + f3B003 - ( dot( ( f3B003 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    o.f3B201 = ( ( 2.0f * f3B003 ) + f3B300 - ( dot( ( f3B300 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;

    float3 f3E = ( o.f3B210 + o.f3B120 + o.f3B021 + o.f3B012 + o.f3B102 + o.f3B201 ) / 6.0f;
    float3 f3V = ( f3B003 + f3B030 + f3B300 ) / 3.0f;
    o.f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
    
    float fV12 = 2.0f * dot( f3B030 - f3B003, f3N002 + f3N020 ) / dot( f3B030 - f3B003, f3B030 - f3B003 );
    o.f3N110 = normalize( f3N002 + f3N020 - fV12 * ( f3B030 - f3B003 ) );
    float fV23 = 2.0f * dot( f3B300 - f3B030, f3N020 + f3N200 ) / dot( f3B300 - f3B030, f3B300 - f3B030 );
    o.f3N011 = normalize( f3N020 + f3N200 - fV23 * ( f3B300 - f3B030 ) );
    float fV31 = 2.0f * dot( f3B003 - f3B300, f3N200 + f3N002 ) / dot( f3B003 - f3B300, f3B003 - f3B300 );
    o.f3N101 = normalize( f3N200 + f3N002 - fV31 * ( f3B003 - f3B300 ) );
	
	o.ii = input[0].ii;
	
	for(uint i = 0; i<3; i++)
	{
		o.PosWVP = input[i].PosWVP;
		o.PosW = input[i].PosW;
		o.NormW = input[i].NormW;
		o.TexCd = input[i].TexCd;
		o.vel = input[i].vel;
		
		gsout.Append(o);
	}
	
	gsout.RestartStrip();
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

void CurvedTrianglePS(out float3 outpos, out float3 outnorm, float3 cpos, float4 tripos[3], float3 trinorm[3], float3 ctrlpos[7], float3 ctrlnorm[3])
{
	float3 triPos[3];
	triPos[0] = tripos[0].xyz-cpos;
	triPos[1] = tripos[1].xyz-cpos;
	triPos[2] = tripos[2].xyz-cpos;
	float3 va = float3(tripos[0].w, tripos[1].w, tripos[2].w);
	
	float3 BaryArea[3];
	for(uint i=0; i<3; i++)
	{
		BaryArea[i] = cross(triPos[(i+1)%3],triPos[(i+2)%3]);
	}
	float3 Barycentric = 0;
	for(uint i=0; i<3; i++)
	{
		Barycentric[i] = length(BaryArea[i])/length(va) * sign(dot(va, BaryArea[i]));
	}
	
    float3 f3B210 = ctrlpos[0];
    float3 f3B120 = ctrlpos[1];
    float3 f3B021 = ctrlpos[2];
    float3 f3B012 = ctrlpos[3];
    float3 f3B102 = ctrlpos[4];
    float3 f3B201 = ctrlpos[5];
    float3 f3B111 = ctrlpos[6];
    float3 f3N110 = ctrlnorm[0];
    float3 f3N011 = ctrlnorm[1];
    float3 f3N101 = ctrlnorm[2];
	
    float fU = Barycentric.x;
    float fV = Barycentric.y;
    float fW = Barycentric.z;
	
    float fUU = fU * fU;
    float fVV = fV * fV;
    float fWW = fW * fW;
    float fUU3 = fUU * 3.0f;
    float fVV3 = fVV * 3.0f;
    float fWW3 = fWW * 3.0f;
	
    float3 f3Position = tripos[0].xyz * fWW * fW +
                        tripos[1].xyz * fUU * fU +
                        tripos[2].xyz * fVV * fV +
                        f3B210 * fWW3 * fU +
                        f3B120 * fW * fUU3 +
                        f3B201 * fWW3 * fV +
                        f3B021 * fUU3 * fV +
                        f3B102 * fW * fVV3 +
                        f3B012 * fU * fVV3 +
                        f3B111 * 6.0f * fW * fU * fV;
        
    float3 f3Normal =   trinorm[0] * fWW +
                        trinorm[1] * fUU +
                        trinorm[2] * fVV +
                        f3N110 * fW * fU +
                        f3N011 * fU * fV +
                        f3N101 * fW * fV;
    
    float3 oPosition = cpos;
        
    float3 oNormal =   trinorm[0] * fWW +
                        trinorm[1] * fUU +
                        trinorm[2] * fVV;
    outpos = lerp(oPosition,f3Position,CurveAmount);
    outnorm = normalize(lerp(oNormal,f3Normal,CurveAmount));
}

PSOut PS_Tex(gs2ps In)
{
	
	float3 posWb;
	float3 normWb;
	float3 ctrlp[7];
	ctrlp[0] = In.f3B210;
	ctrlp[1] = In.f3B120;
	ctrlp[2] = In.f3B021;
	ctrlp[3] = In.f3B012;
	ctrlp[4] = In.f3B102;
	ctrlp[5] = In.f3B201;
	ctrlp[6] = In.f3B111;
	
	float3 ctrln[3];
	ctrln[0] = In.f3N110;
	ctrln[1] = In.f3N011;
	ctrln[2] = In.f3N101;
	
	float4 inpos[3];
	float3 innorm[3];
	inpos[0] = In.triPos0;
	inpos[1] = In.triPos1;
	inpos[2] = In.triPos2;
	innorm[0] = In.triNorm0;
	innorm[1] = In.triNorm1;
	innorm[2] = In.triNorm2;

	CurvedTrianglePS(posWb, normWb, In.PosW, inpos, innorm, ctrlp, ctrln);
	
	PSOut Out = (PSOut)0;
	float2 uvb = float2(0,0);
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tTex, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float depth = FBumpAmount;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pow(depth,.5));
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	if(isTriPlanar) alphatt = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow) * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
    float3 diffcol = DiffTex.Sample( g_samLinear, uvb).rgb * FDiffColor.rgb * FDiffAmount;
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).rgb * FDiffColor.rgb * FDiffAmount;
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
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormW, tTex, TriPlanarPow).r;
	Out.maps.a = 1;
	
	Out.matprop.rg = ObjID.xy;
	Out.matprop.b = MatID;
	Out.matprop.a = 1;
	
    return Out;
}

PSOut PS_Inst(gs2psi In)
{
	float ii = In.ii;
	
	float3 posWb;
	float3 normWb;
	float3 ctrlp[7];
	ctrlp[0] = In.f3B210;
	ctrlp[1] = In.f3B120;
	ctrlp[2] = In.f3B021;
	ctrlp[3] = In.f3B012;
	ctrlp[4] = In.f3B102;
	ctrlp[5] = In.f3B201;
	ctrlp[6] = In.f3B111;
	
	float3 ctrln[3];
	ctrln[0] = In.f3N110;
	ctrln[1] = In.f3N011;
	ctrln[2] = In.f3N101;
	
	float4 inpos[3];
	float3 innorm[3];
	inpos[0] = In.triPos0;
	inpos[1] = In.triPos1;
	inpos[2] = In.triPos2;
	innorm[0] = In.triNorm0;
	innorm[1] = In.triNorm1;
	innorm[2] = In.triNorm2;

	CurvedTrianglePS(posWb, normWb, In.PosW, inpos, innorm, ctrlp, ctrln);

	PSOut Out = (PSOut)0;
	float2 uvb = float2(0,0);
	
	float4x4 tT = (InstanceFromGeomFX) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tT, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	float bmpam = (InstanceFromGeomFX) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	
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
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).rgb;
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
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	Out.maps.a = 1;
	
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
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
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
		SetGeometryShader( CompileShader( gs_5_0, GSgv() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Inst() ) );
	}
}
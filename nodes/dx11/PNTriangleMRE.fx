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
	float4x4 tV : VIEW;
	float4x4 tVI : VIEWINVERSE;
	float4x4 ptV : PREVIOUSVIEW;
	float4x4 tP : PROJECTION;
	float4x4 ptP : PREVIOUSPROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tWV : WORLDVIEW;
	float4x4 NormTr;
	float gVelocityGain = 1;
	bool isTriPlanar = false;
	float TriPlanarPow = 1;
	float utilalpha = 0;
	bool InstanceFromGeomFX = false;
	bool UseInstanceID = false;
};

cbuffer cbPerObject : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 ptW; // previous frame world transform per draw call
	float4x4 tTex;
	float alphatest = 0.5;
	float FDiffAmount = 1;
	float4 FDiffColor <bool color=true;> = 1;
	float FBumpAmount = 0;
	float bumpOffset = 0;
	int MatID = 0;
	int3 ObjID = 0;
	float CurveAmount = 1;
	float pCurveAmount = 1;
	float Factor = 1;
};

/////////////////////////
//////// Structs ////////
/////////////////////////

float pows(float a, float b)
{
	return pow(abs(a),b)*sign(a);
}

struct VSgvin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	float4 velocity : COLOR0;
	uint iid : SV_InstanceID;
	uint vid : SV_VertexID;
};

struct VSin
{
	float4 PosO : POSITION;
	float3 NormO : NORMAL;
	float2 TexCd : TEXCOORD0;
	uint iid : SV_InstanceID;
	uint vid : SV_VertexID;
};

struct vs2hs
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    float3 NormW: NORMAL;
	uint ii : INSTANCEID;
};
struct vs2hsi
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    nointerpolation float ii: TEXCOORD1;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
};
struct hsconst
{
    float fTessFactor[3]    : SV_TessFactor ;
    float fInsideTessFactor : SV_InsideTessFactor ;
    float3 f3B210    : POSITION3 ;
    float3 f3B120    : POSITION4 ;
    float3 f3B021    : POSITION5 ;
    float3 f3B012    : POSITION6 ;
    float3 f3B102    : POSITION7 ;
    float3 f3B201    : POSITION8 ;
    float3 f3B111    : CENTER ;
    float3 f3N110    : NORMAL3 ;
    float3 f3N011    : NORMAL4 ;
    float3 f3N101    : NORMAL5 ;
};
struct hs2ds
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    float3 NormW: NORMAL;
	uint ii : INSTANCEID;
};
struct hs2dsi
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    nointerpolation float ii: TEXCOORD1;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
};
struct ds2ps
{
    float4 PosWVP: SV_POSITION;
    float4 PosW: TEXCOORD2;
	float4 TexCd: TEXCOORD0;
    float3 NormW: NORMAL;
    float4 vel : COLOR0;
    nointerpolation float ii: TEXCOORD1;
};
struct ds2psi
{
    float4 PosWVP: SV_POSITION;
    float4 PosW: TEXCOORD2;
	float4 TexCd: TEXCOORD0;
    nointerpolation float ii: TEXCOORD1;
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

////////////////////
//////// VS ////////
////////////////////

vs2hs VS(VSin In)
{
    //inititalize all fields of output struct with 0
    vs2hs Out = (vs2hs)0;
	Out.ii = In.iid;
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	
    Out.NormW = normalize(dispNorm);
	
    Out.PosW = dispPos;
	
	//if(isTriPlanar) Out.TexCd = float4(TriPlanar(dispPos.xyz, dispNorm, tTex, TriPlanarPow),0,1);
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
    return Out;
}

vs2hsi VSi(VSgvin In)
{
    //inititalize all fields of output struct with 0
    vs2hsi Out = (vs2hsi)0;
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO;
	
    Out.NormW = normalize(dispNorm);
	
    Out.PosW = dispPos;
	Out.vel = float4(In.velocity.xyz,1);
	if (UseInstanceID) Out.ii = In.iid;
	else Out.ii = In.velocity.w;
	
	//if(isTriPlanar) Out.TexCd = float4(TriPlanar(dispPos.xyz, dispNorm, tTex, TriPlanarPow),0,1);
	if(isTriPlanar) Out.TexCd = dispPos;
	else Out.TexCd = mul(float4(In.TexCd,0,1), tTex);
	
    return Out;
}

/////////////////////
//////// HSC ////////
/////////////////////

hsconst HSC( InputPatch<vs2hs, 3> I )
{
    hsconst O = (hsconst)0;
	O.fTessFactor[0] = Factor;    
    O.fTessFactor[1] = Factor;    
    O.fTessFactor[2] = Factor;   
    O.fInsideTessFactor = ( O.fTessFactor[0] + O.fTessFactor[1] + O.fTessFactor[2] ) / 3.0f;  
		
    float3 f3B003 = I[0].PosW;
    float3 f3B030 = I[1].PosW;
    float3 f3B300 = I[2].PosW;
    // And Normals
    float3 f3N002 = I[0].NormW;
    float3 f3N020 = I[1].NormW;
    float3 f3N200 = I[2].NormW;

	O.f3B210 = ( ( 2.0f * f3B003 ) + f3B030 - ( dot( ( f3B030 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;
	O.f3B120 = ( ( 2.0f * f3B030 ) + f3B003 - ( dot( ( f3B003 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    O.f3B021 = ( ( 2.0f * f3B030 ) + f3B300 - ( dot( ( f3B300 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    O.f3B012 = ( ( 2.0f * f3B300 ) + f3B030 - ( dot( ( f3B030 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    O.f3B102 = ( ( 2.0f * f3B300 ) + f3B003 - ( dot( ( f3B003 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    O.f3B201 = ( ( 2.0f * f3B003 ) + f3B300 - ( dot( ( f3B300 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;

    float3 f3E = ( O.f3B210 + O.f3B120 + O.f3B021 + O.f3B012 + O.f3B102 + O.f3B201 ) / 6.0f;
    float3 f3V = ( f3B003 + f3B030 + f3B300 ) / 3.0f;
    O.f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
    
    float fV12 = 2.0f * dot( f3B030 - f3B003, f3N002 + f3N020 ) / dot( f3B030 - f3B003, f3B030 - f3B003 );
    O.f3N110 = normalize( f3N002 + f3N020 - fV12 * ( f3B030 - f3B003 ) );
    float fV23 = 2.0f * dot( f3B300 - f3B030, f3N020 + f3N200 ) / dot( f3B300 - f3B030, f3B300 - f3B030 );
    O.f3N011 = normalize( f3N020 + f3N200 - fV23 * ( f3B300 - f3B030 ) );
    float fV31 = 2.0f * dot( f3B003 - f3B300, f3N200 + f3N002 ) / dot( f3B003 - f3B300, f3B003 - f3B300 );
    O.f3N101 = normalize( f3N200 + f3N002 - fV31 * ( f3B003 - f3B300 ) );
    return O;
}

hsconst HSCi( InputPatch<vs2hsi, 3> I )
{
    hsconst O = (hsconst)0;
	O.fTessFactor[0] = Factor;    
    O.fTessFactor[1] = Factor;    
    O.fTessFactor[2] = Factor;   
    O.fInsideTessFactor = ( O.fTessFactor[0] + O.fTessFactor[1] + O.fTessFactor[2] ) / 3.0f;  
		
    float3 f3B003 = I[0].PosW;
    float3 f3B030 = I[1].PosW;
    float3 f3B300 = I[2].PosW;
    // And Normals
    float3 f3N002 = I[0].NormW;
    float3 f3N020 = I[1].NormW;
    float3 f3N200 = I[2].NormW;

	O.f3B210 = ( ( 2.0f * f3B003 ) + f3B030 - ( dot( ( f3B030 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;
	O.f3B120 = ( ( 2.0f * f3B030 ) + f3B003 - ( dot( ( f3B003 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    O.f3B021 = ( ( 2.0f * f3B030 ) + f3B300 - ( dot( ( f3B300 - f3B030 ), f3N020 ) * f3N020 ) ) / 3.0f;
    O.f3B012 = ( ( 2.0f * f3B300 ) + f3B030 - ( dot( ( f3B030 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    O.f3B102 = ( ( 2.0f * f3B300 ) + f3B003 - ( dot( ( f3B003 - f3B300 ), f3N200 ) * f3N200 ) ) / 3.0f;
    O.f3B201 = ( ( 2.0f * f3B003 ) + f3B300 - ( dot( ( f3B300 - f3B003 ), f3N002 ) * f3N002 ) ) / 3.0f;

    float3 f3E = ( O.f3B210 + O.f3B120 + O.f3B021 + O.f3B012 + O.f3B102 + O.f3B201 ) / 6.0f;
    float3 f3V = ( f3B003 + f3B030 + f3B300 ) / 3.0f;
    O.f3B111 = f3E + ( ( f3E - f3V ) / 2.0f );
    
    float fV12 = 2.0f * dot( f3B030 - f3B003, f3N002 + f3N020 ) / dot( f3B030 - f3B003, f3B030 - f3B003 );
    O.f3N110 = normalize( f3N002 + f3N020 - fV12 * ( f3B030 - f3B003 ) );
    float fV23 = 2.0f * dot( f3B300 - f3B030, f3N020 + f3N200 ) / dot( f3B300 - f3B030, f3B300 - f3B030 );
    O.f3N011 = normalize( f3N020 + f3N200 - fV23 * ( f3B300 - f3B030 ) );
    float fV31 = 2.0f * dot( f3B003 - f3B300, f3N200 + f3N002 ) / dot( f3B003 - f3B300, f3B003 - f3B300 );
    O.f3N101 = normalize( f3N200 + f3N002 - fV31 * ( f3B003 - f3B300 ) );
    return O;
}

////////////////////
//////// HS ////////
////////////////////

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HSC")]
[outputcontrolpoints(3)]
hs2ds HS( InputPatch<vs2hs, 3> I, uint uCPID : SV_OutputControlPointID )
{
    hs2ds O = (hs2ds)0;
    O.PosW = I[uCPID].PosW;
    O.NormW = I[uCPID].NormW; 
	O.TexCd = I[uCPID].TexCd;
	O.ii = I[uCPID].ii;
	
    return O;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HSCi")]
[outputcontrolpoints(3)]
hs2dsi HSi( InputPatch<vs2hsi, 3> I, uint uCPID : SV_OutputControlPointID )
{
    hs2dsi O = (hs2dsi)0;
    O.PosW = I[uCPID].PosW;
    O.NormW = I[uCPID].NormW; 
	O.TexCd = I[uCPID].TexCd;
	O.vel = I[uCPID].vel;
	O.ii = I[uCPID].ii;
	
    return O;
}

////////////////////
//////// DS ////////
////////////////////

[domain("tri")]
ds2ps DS( hsconst HSConstantData, const OutputPatch<hs2ds, 3> I, float3 f3BarycentricCoords : SV_DomainLocation )
{
    ds2ps O = (ds2ps)0;

	float ii = I[0].ii;
	O.ii = ii;
	
	float4x4 tT = (UseInstanceID) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	float4x4 w = (UseInstanceID) ? mul(InstancedParams[ii].tW,tW) : tW;
	
    float fU = f3BarycentricCoords.x;
    float fV = f3BarycentricCoords.y;
    float fW = f3BarycentricCoords.z;

    float fUU = fU * fU;
    float fVV = fV * fV;
    float fWW = fW * fW;
    float fUU3 = fUU * 3.0f;
    float fVV3 = fVV * 3.0f;
    float fWW3 = fWW * 3.0f;
    
    float3 f3Position = I[0].PosW.xyz * fWW * fW +
                        I[1].PosW.xyz * fUU * fU +
                        I[2].PosW.xyz * fVV * fV +
                        HSConstantData.f3B210 * fWW3 * fU +
                        HSConstantData.f3B120 * fW * fUU3 +
                        HSConstantData.f3B201 * fWW3 * fV +
                        HSConstantData.f3B021 * fUU3 * fV +
                        HSConstantData.f3B102 * fW * fVV3 +
                        HSConstantData.f3B012 * fU * fVV3 +
                        HSConstantData.f3B111 * 6.0f * fW * fU * fV;
	    
    float3 f3Normal =   I[0].NormW * fWW +
                        I[1].NormW * fUU +
                        I[2].NormW * fVV +
                        HSConstantData.f3N110 * fW * fU +
                        HSConstantData.f3N011 * fU * fV +
                        HSConstantData.f3N101 * fW * fV;
	
    float3 oPosition = I[0].PosW.xyz * fW +
                        I[1].PosW.xyz * fU +
                        I[2].PosW.xyz * fV;
	    
    float3 oNormal =   I[0].NormW * fWW +
                        I[1].NormW * fUU +
                        I[2].NormW * fVV;
	float3 pf3p = f3Position;
	f3Position = lerp(oPosition,f3Position,CurveAmount);
	float3 pf3Position = lerp(oPosition,pf3p,pCurveAmount);
	f3Normal = lerp(oNormal,f3Normal,CurveAmount);
	
    // Normalize the interpolated normal    
    f3Normal = normalize( -f3Normal );
	
	float3 dispPos = f3Position;
	float3 dispNorm = f3Normal;
	float3 pdispPos = pf3Position;

    O.PosW = mul(float4(dispPos,1), w);
    float4 PosWV = mul(O.PosW, tV);
	O.NormW = -normalize(mul(dispNorm, w).xyz);
    O.PosWVP = mul(PosWV, tP);
	
	O.TexCd = I[0].TexCd * fW + I[1].TexCd * fU + I[2].TexCd * fV;
	if(isTriPlanar) O.TexCd = float4(dispPos,1);
	
	float4x4 pw = (UseInstanceID) ? mul(InstancedParams[ii].ptW,ptW) : ptW;
	float3 npos = PosWV.xyz;
	float4x4 ptWV = pw;
	ptWV = mul(ptWV, ptV);
	float3 pnpos = mul(float4(pdispPos,1), ptWV).xyz;
	O.vel.rgb = ((npos - pnpos) * gVelocityGain);
	O.vel.rgb += 0.5;
	O.vel.a = 1;
   
    return O;
}

[domain("tri")]
ds2psi DSi( hsconst HSConstantData, const OutputPatch<hs2dsi, 3> I, float3 f3BarycentricCoords : SV_DomainLocation )
{
    ds2psi O = (ds2psi)0;
	
	float ii = I[0].ii;
	O.ii = ii;
	
	// TexCoords
	float4x4 tT = (InstanceFromGeomFX || UseInstanceID) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	float4x4 w = (InstanceFromGeomFX || UseInstanceID) ? mul(InstancedParams[ii].tW,tW) : tW;

    float fU = f3BarycentricCoords.x;
    float fV = f3BarycentricCoords.y;
    float fW = f3BarycentricCoords.z;

    float fUU = fU * fU;
    float fVV = fV * fV;
    float fWW = fW * fW;
    float fUU3 = fUU * 3.0f;
    float fVV3 = fVV * 3.0f;
    float fWW3 = fWW * 3.0f;
    
    float3 f3Position = I[0].PosW.xyz * fWW * fW +
                        I[1].PosW.xyz * fUU * fU +
                        I[2].PosW.xyz * fVV * fV +
                        HSConstantData.f3B210 * fWW3 * fU +
                        HSConstantData.f3B120 * fW * fUU3 +
                        HSConstantData.f3B201 * fWW3 * fV +
                        HSConstantData.f3B021 * fUU3 * fV +
                        HSConstantData.f3B102 * fW * fVV3 +
                        HSConstantData.f3B012 * fU * fVV3 +
                        HSConstantData.f3B111 * 6.0f * fW * fU * fV;
	
    float3 pf3Position = I[0].vel.xyz * fWW * fW +
                        I[1].vel.xyz * fUU * fU +
                        I[2].vel.xyz * fVV * fV +
                        HSConstantData.f3B210 * fWW3 * fU +
                        HSConstantData.f3B120 * fW * fUU3 +
                        HSConstantData.f3B201 * fWW3 * fV +
                        HSConstantData.f3B021 * fUU3 * fV +
                        HSConstantData.f3B102 * fW * fVV3 +
                        HSConstantData.f3B012 * fU * fVV3 +
                        HSConstantData.f3B111 * 6.0f * fW * fU * fV;
	    
    float3 f3Normal =   I[0].NormW * fWW +
                        I[1].NormW * fUU +
                        I[2].NormW * fVV +
                        HSConstantData.f3N110 * fW * fU +
                        HSConstantData.f3N011 * fU * fV +
                        HSConstantData.f3N101 * fW * fV;
	
    float3 oPosition = I[0].PosW.xyz * fW +
                        I[1].PosW.xyz * fU +
                        I[2].PosW.xyz * fV;
    float3 poPosition = I[0].vel.xyz * fW +
                        I[1].vel.xyz * fU +
                        I[2].vel.xyz * fV;
	    
    float3 oNormal =   I[0].NormW * fWW +
                        I[1].NormW * fUU +
                        I[2].NormW * fVV;
	pf3Position = lerp(poPosition,pf3Position,pCurveAmount);
	f3Position = lerp(oPosition,f3Position,CurveAmount);
	f3Normal = lerp(oNormal,f3Normal,CurveAmount);
	
    // Normalize the interpolated normal    
    f3Normal = normalize( -f3Normal );
	
	float3 dispPos = f3Position;
	float3 dispNorm = f3Normal;
	float3 pdispPos = pf3Position;

    O.PosW = mul(float4(dispPos,1), w);
    float4 PosWV = mul(O.PosW, tV);
	O.NormW = -normalize(mul(dispNorm, w).xyz);
    O.PosWVP = mul(PosWV, tP);
	
	O.TexCd = I[0].TexCd * fW + I[1].TexCd * fU + I[2].TexCd * fV;
	if(isTriPlanar) O.TexCd = float4(dispPos,1);
	
	float4x4 pw = (InstanceFromGeomFX || UseInstanceID) ? mul(InstancedParams[ii].ptW,ptW) : ptW;
	float3 npos = PosWV.xyz;
	float4x4 ptWV = pw;
	ptWV = mul(ptWV, ptV);
	float3 pnpos = mul(float4(pdispPos,1), ptWV).xyz;
	O.vel.rgb = ((npos - pnpos) * gVelocityGain);
	O.vel.rgb += 0.5;
	O.vel.a = 1;
   
    return O;
}
////////////////////
//////// PS ////////
////////////////////

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


PSOut PS_Tex(ds2ps In)
{
	
	float ii = In.ii;
	
	float4x4 tT = (UseInstanceID) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	float3 posWb = In.PosW.xyz;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 uvb = float2(0,0);
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tTex, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	
	float bmpam = (UseInstanceID) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = 0;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pows(depth,.5));
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = 0;
	if(isTriPlanar) alphatt = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow) * FDiffColor.a;
	else alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
    float3 diffcol = 0;
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).rgb;
    else diffcol = DiffTex.Sample( g_samLinear, uvb).rgb;
	if(UseInstanceID)
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
	
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.r = SpecTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	Out.maps.a = 1;
	
	if(UseInstanceID)
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

PSOut PS_Inst(ds2psi In)
{
	float ii = In.ii;
	float3 posWb = In.PosW.xyz;

	PSOut Out = (PSOut)0;
	float3 normWb = In.NormW;
	float2 uvb = float2(0,0);
	
	float4x4 tT = (InstanceFromGeomFX || UseInstanceID) ? mul(InstancedParams[ii].tTex,tTex) : tTex;
	
	//if(isTriPlanar) uvb = TriPlanar(In.TexCd.xyz, normWb, tT, TriPlanarPow);
	/*else*/ uvb = In.TexCd.xy;
	
	//float combinedDist = dFromVerts.x * dFromVerts.y * dFromVerts.z;
	float bmpam = (InstanceFromGeomFX || UseInstanceID) ? InstancedParams[ii].BumpAmount*FBumpAmount : FBumpAmount;
	float depth = bmpam;
	float mdepth = 0;
	if(isTriPlanar) mdepth = TriPlanarSample(BumpTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else mdepth = BumpTex.Sample(g_samLinear, uvb).r;
	
	if(depth!=0) posWb += In.NormW * mdepth * (-1*pows(depth,.5));
	Out.normalW = float4(normWb,1);
	
	float alphat = 1;
	float alphatt = DiffTex.Sample( g_samLinear, uvb).a * FDiffColor.a;
	alphat = alphatt;
	if(alphatest!=0)
	{
		alphat = lerp(alphatt, (alphatt>=alphatest), min(alphatest*10,1));
		if(alphat < (1-alphatest)) discard;
	}
	
    float3 diffcol = 0;
	if(isTriPlanar) diffcol = TriPlanarSample(DiffTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).rgb;
    else diffcol = DiffTex.Sample( g_samLinear, uvb).rgb;
	if(InstanceFromGeomFX || UseInstanceID)
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
	
	if(isTriPlanar) Out.maps.r = TriPlanarSample(SpecTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.r = SpecTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.g = TriPlanarSample(ThickTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.g = ThickTex.Sample(g_samLinear, uvb).r;
	if(isTriPlanar) Out.maps.b = TriPlanarSample(EmTex, g_samLinear, In.TexCd.xyz, In.NormW, tT, TriPlanarPow).r;
	else Out.maps.b = EmTex.Sample( g_samLinear, uvb).r;
	Out.maps.a = 1;
	
	Out.maps.a = 1;
	
	if(InstanceFromGeomFX || UseInstanceID)
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
		SetGeometryShader( 0 );
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetHullShader( CompileShader( hs_5_0, HS()) );
		SetDomainShader( CompileShader( ds_5_0, DS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Tex() ) );
	}
}

technique10 DeferredBaseGeomVel
{
	pass P0
	{
		SetGeometryShader( 0 );
		SetVertexShader( CompileShader( vs_5_0, VSi() ) );
		SetHullShader( CompileShader( hs_5_0, HSi()) );
		SetDomainShader( CompileShader( ds_5_0, DSi() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Inst() ) );
	}
}
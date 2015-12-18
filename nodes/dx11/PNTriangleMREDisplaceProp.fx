//@author: microdee
#include "../../../mp.fxh/MREForward.fxh"

Texture2D DispTex;
#if defined(INSTANCING)
	StructuredBuffer<InstanceParams> InstancedParams : FR_INSTANCEDPARAMS;
#endif

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
};

cbuffer cbPerObjectGeom : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tTex;
	float CurveAmount = 1;
	float Factor = 1;
	float DispAmount = 0;
	bool FlipNormals = false;
};

#include "../../../mp.fxh/MREForwardPSProp.fxh"

struct HSin
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    float3 NormW: NORMAL;
    nointerpolation float ii : INSTANCEID;
    #if defined(HAS_GEOMVELOCITY)
        float4 Velocity : COLOR0;
    #endif
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
struct DSin
{
    float4 PosW: POSITION;
	float4 TexCd: TEXCOORD0;
    float3 NormW: NORMAL;
    nointerpolation float ii : INSTANCEID;
    #if defined(HAS_GEOMVELOCITY)
        float4 Velocity : COLOR0;
    #endif
};

HSin VS(VSin In)
{
    //inititalize all fields of output struct with 0
    HSin Out = (HSin)0;

    #if defined(IID_FROM_GEOM) && defined(HAS_GEOMVELOCITY)
        float ii = In.velocity.w;
    #else
        float ii = In.iid;
    #endif
    Out.ii = ii;
	
    float3 dispNorm = (FlipNormals) ? -In.NormO : In.NormO;
    Out.NormW = normalize(dispNorm);
	
    Out.PosW = In.PosO;
	Out.TexCd = 0;
    #if defined(TRIPLANAR)
        Out.TexCd = In.PosO;
    #elif defined(HAS_TEXCOORD)
        Out.TexCd = float4(In.TexCd,0,1);
    #else
        Out.TexCd = 0;
    #endif

    #if defined(HAS_GEOMVELOCITY)
        Out.Velocity = float4(In.velocity.xyz,1);
    #endif
	
    return Out;
}
/////////////////////
//////// HSC ////////
/////////////////////

hsconst HSC( InputPatch<HSin, 3> I )
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
DSin HS( InputPatch<HSin, 3> I, uint uCPID : SV_OutputControlPointID )
{
    DSin O = (DSin)0;
    O.PosW = I[uCPID].PosW;
    O.NormW = I[uCPID].NormW;
	O.TexCd = I[uCPID].TexCd;
	O.ii = I[uCPID].ii;

    #if defined(HAS_GEOMVELOCITY)
        O.Velocity = I[uCPID].Velocity;
    #endif
	
    return O;
}

////////////////////
//////// DS ////////
////////////////////

float3 InterpolateDir(
    hsconst HSConstantData,
    float3 in0, float3 in1, float3 in2,
    float3 fUVW2, float3 fUVW, float curve)
{

    float3 f3 = in0 * fUVW.z +
        in1 * fUVW.x +
        in2 * fUVW.y +
        HSConstantData.f3N110 * fUVW2.z * fUVW2.x +
        HSConstantData.f3N011 * fUVW2.x * fUVW2.y +
        HSConstantData.f3N101 * fUVW2.z * fUVW2.y;
    float3 o = in0 * fUVW.z +
        in1 * fUVW.x +
        in2 * fUVW.y;
    f3 = lerp(o,f3,curve);
    return normalize(f3);
}

float3 InterpolatePos(
    hsconst HSConstantData,
    float3 in0, float3 in1, float3 in2,
    float3 fUVW2, float3 fUVW, float curve,
    out float3 f3, out float3 o)
{
    float fUU3 = fUVW2.x * 3.0f;
    float fVV3 = fUVW2.y * 3.0f;
    float fWW3 = fUVW2.z * 3.0f;

    f3 = in0 * fUVW2.z * fUVW.z +
        in1 * fUVW2.x * fUVW.x +
        in2 * fUVW2.y * fUVW.y +
        HSConstantData.f3B210 * fWW3 * fUVW.x +
        HSConstantData.f3B120 * fUVW.z * fUU3 +
        HSConstantData.f3B201 * fWW3 * fUVW.y +
        HSConstantData.f3B021 * fUU3 * fUVW.y +
        HSConstantData.f3B102 * fUVW.z * fVV3 +
        HSConstantData.f3B012 * fUVW.x * fVV3 +
        HSConstantData.f3B111 * 6.0f * fUVW.z * fUVW.x * fUVW.y ;
    o = in0 * fUVW.z +
        in1 * fUVW.x +
        in2 * fUVW.y ;
    return lerp(o,f3,curve);
}

[domain("tri")]
PSinProp DS( hsconst HSConstantData, const OutputPatch<DSin, 3> I, float3 f3BarycentricCoords : SV_DomainLocation )
{
    PSinProp O = (PSinProp)0;
	
	float ii = I[0].ii;
	O.ii = ii;
	
    // TexCoords
    #if defined(INSTANCING)
        float4x4 tT = mul(InstancedParams[ii].tTex,tTex);
        float4x4 w = mul(InstancedParams[ii].tW,tW);
    #else
        float4x4 tT = tTex;
        float4x4 w = tW;
    #endif
    float4x4 tWV = mul(w, tV);

    float3 fUVW = f3BarycentricCoords;
    float3 fUVW2 = fUVW * fUVW;
    float3 cPos, fPos;

    float3 f3Position = InterpolatePos(
        HSConstantData,
        I[0].PosW.xyz, I[1].PosW.xyz, I[2].PosW.xyz,
        fUVW2, fUVW, CurveAmount,
        cPos, fPos
    );
	
    float3 f3Normal = InterpolateDir(
        HSConstantData,
        I[0].NormW, I[1].NormW, I[2].NormW,
        fUVW2, fUVW, CurveAmount
    );
	
	float4 f3UV = I[0].TexCd * fUVW.z + I[1].TexCd * fUVW.x + I[2].TexCd * fUVW.y;
    O.TexCd = mul(float4(f3UV.xyz,1), tT);
	
    #if defined(TRIPLANAR)
		float2 disp = TriPlanarSampleLevel(DispTex, Sampler, mul(float4(f3Position,1), tT).xyz, f3Normal, TriPlanarPow, 0).rg-.5;
	#else
		float2 disp = DispTex.SampleLevel(Sampler, O.TexCd.xy, 0).rg-.5;
	#endif
	
	float3 dispPos = f3Position + f3Normal * disp.r * DispAmount;
	float3 dispNorm = f3Normal;

    O.PosW = mul(float4(dispPos,1), w);
    O.NormW = normalize(mul(float4(dispNorm,0), w).xyz);
    O.PosWVP = mul(O.PosW, tVP);
   
    return O;
}

technique10 DeferredProp
{
	pass P0
	{
		SetGeometryShader( 0 );
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetHullShader( CompileShader( hs_5_0, HS()) );
		SetDomainShader( CompileShader( ds_5_0, DS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}

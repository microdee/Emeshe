//@author: microdee
#include "../../../mp.fxh/MREForward.fxh"
#include "../../../mp.fxh/GetMergedID.fxh"

Texture2DArray DispTex;
StructuredBuffer<InstanceParams> InstancedParams;
#if !defined(HAS_SUBSETID)
	StructuredBuffer<uint> SubsetVertexCount : FR_SUBSETVCOUNT;
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
	float CurveAmount = 1;
	float Factor = 1;
	float DispAmount = 0;
	float SubsetCount = 1;
	bool FlipNormals = false;
};

#include "../../../mp.fxh/MREForwardMergedPSProp.fxh"
#include "../../../mp.fxh/MREForwardTessellatorProp.fxh"

HSin VS(VSin In)
{
    //inititalize all fields of output struct with 0
    HSin Out = (HSin)0;

    #if defined(HAS_SUBSETID)
        float ii = In.SubsetID;
    #else
        float ii = GetMergedGeomID(SubsetVertexCount, In.vid, SubsetCount);
    #endif
    Out.ii = ii;
	
    float3 dispNorm = (FlipNormals) ? -In.NormO : In.NormO;
    Out.NormW = normalize(dispNorm);
	
    Out.PosW = In.PosO;
	Out.TexCd = 0;
	
    #if defined(HAS_TEXCOORD)
        Out.TexCd = float4(In.TexCd,0,1);
    #else
        Out.TexCd = 0;
    #endif

    #if defined(HAS_GEOMVELOCITY)
        Out.Velocity = float4(In.velocity,1);
    #endif
	
    return Out;
}

////////////////////
//////// DS ////////
////////////////////

[domain("tri")]
PSinProp DS( hsconst HSConstantData, const OutputPatch<DSin, 3> I, float3 f3BarycentricCoords : SV_DomainLocation )
{
    PSinProp O = (PSinProp)0;
	
	float ii = I[0].ii;
	O.ii = ii;
	
    // TexCoords
    float4x4 tT = InstancedParams[ii].tTex;
    float4x4 w = mul(InstancedParams[ii].tW,tW);
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
	
	float2 disp = DispTex.SampleLevel(Sampler, float3(O.TexCd.xy, ii), 0).rg-.5;
	
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

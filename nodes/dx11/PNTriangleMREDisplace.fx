//@author: microdee
#define TESSELLATION 1
#include "../../../mp.fxh/MREForward.fxh"

Texture2D DispTex;
#if defined(INSTANCING)
	StructuredBuffer<InstanceParams> InstancedParams : FR_INSTANCEDPARAMS;
#endif


cbuffer cbPerDraw : register( b0 )
{
    float4x4 tV : VIEW;
    float4x4 tVI : VIEWINVERSE;
    float4x4 ptV : PREVIOUSVIEW;
    float4x4 tP : PROJECTION;
    float4x4 tVP : VIEWPROJECTION;
    float4x4 ptP : PREVIOUSPROJECTION;
	float3 NearFarPow : NEARFARDEPTHPOW;
	int ObjIDMode : MRE_OBJIDMODE;
	int DepthMode : MRE_DEPTHMODE;
};

cbuffer cbPerObjectGeom : register( b1 )
{
    float4x4 tW : WORLD;
    float4x4 ptW;
    float4x4 tTex;
    float2 DispAmount = 0;
	float DisplaceNormalInfluence = 1;
	float DisplaceVelocityGain = 0;
    float CurveAmount = 1;
    float pCurveAmount = 1;
    float Factor = 1;
    bool FlipNormals = false;
};

#include "../../../mp.fxh/MREForwardPS.fxh"
#include "../../../mp.fxh/MREForwardTessellator.fxh"


////////////////////
//////// VS ////////
////////////////////

HSin VS(VSin In)
{
    //inititalize all fields of output struct with 0
    HSin Out = (HSin)0;

	#if defined(HAS_SUBSETID)
        float ii = In.SubsetID;
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

    #if defined(HAS_NORMALMAP)
        Out.Tangent = In.Tangent;
        Out.Binormal = In.Binormal;
    #endif

    #if defined(HAS_GEOMVELOCITY)
        Out.Velocity = float4(In.velocity,1);
    #endif
	
    return Out;
}

[domain("tri")]
PSin DS( hsconst HSConstantData, const OutputPatch<DSin, 3> I, float3 f3BarycentricCoords : SV_DomainLocation )
{
    PSin O = (PSin)0;
	
	#if defined(DEBUG) && defined(TESSELLATION)
		O.bccoords = f3BarycentricCoords;
	#endif
	
	float ii = I[0].ii;
	O.ii = ii;
	
    // TexCoords
    #if defined(INSTANCING)
        float4x4 tT = mul(InstancedParams[ii].tTex,tTex);
        float4x4 w = mul(InstancedParams[ii].tW,tW);
        float4x4 pw = mul(InstancedParams[ii].ptW,ptW);
    #else
        float4x4 tT = tTex;
        float4x4 w = tW;
        float4x4 pw = ptW;
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
	/*
    float3 f3FlatPos = InterpolateDir(
        HSConstantData,
        I[0].PosW.xyz, I[1].PosW.xyz, I[2].PosW.xyz,
        fUVW2, fUVW, CurveAmount
    );
	*/
    float3 pcPos, pfPos;
    #if defined(HAS_GEOMVELOCITY)
        float3 pf3Position = InterpolatePos(
            HSConstantData,
            I[0].Velocity.xyz, I[1].Velocity.xyz, I[2].Velocity.xyz,
            fUVW2, fUVW, pCurveAmount,
        	pcPos, pfPos
        );
    #else
        pfPos = fPos;
    #endif
	
    float3 f3Normal = InterpolateDir(
        HSConstantData,
        I[0].NormW, I[1].NormW, I[2].NormW,
        fUVW2, fUVW, CurveAmount
        );

    #if defined(HAS_NORMALMAP)
        float3 f3Tangent = InterpolateDir(
            HSConstantData,
            I[0].Tangent, I[1].Tangent, I[2].Tangent,
            fUVW2, fUVW, CurveAmount
        );

        float3 f3Binormal = InterpolateDir(
            HSConstantData,
            I[0].Binormal, I[1].Binormal, I[2].Binormal,
            fUVW2, fUVW, CurveAmount
        );

		TangentSpace nt = (TangentSpace)0;
		nt.n = f3Normal;
		nt.t = f3Tangent;
		nt.b = f3Binormal;
	
		TangentSpace rnt = SampleNormalTangents(nt, DispTex, Sampler, O.TexCd.xy, 0.01, DispAmount.x * DisplaceNormalInfluence, 0);

        O.Tangent = normalize(mul(float4(rnt.t,0), tWV).xyz);
        O.Binormal = normalize(mul(float4(rnt.b,0), tWV).xyz);
    #endif
	
	float4 f3UV = I[0].TexCd * fUVW.z + I[1].TexCd * fUVW.x + I[2].TexCd * fUVW.y;
    O.TexCd = mul(float4(f3UV.xyz,1), tT);
	
    #if defined(TRIPLANAR)
		float2 disp = TriPlanarSampleLevel(DispTex, Sampler, mul(float4(f3Position,1), tT).xyz, f3Normal, TriPlanarPow, 0).rg-.5;
	#else
		float2 disp = DispTex.SampleLevel(Sampler, O.TexCd.xy, 0).rg-.5;
	#endif
	
	float3 dispPos = f3Position + f3Normal * disp.r * DispAmount.x;
	float3 dispFlatPos = fPos + f3Normal * disp.r * DispAmount.x;
    #if defined(HAS_NORMALMAP)
		float3 dispNorm = rnt.n;
	#else
		float3 dispNorm = SampleNormal(f3Normal, DispTex, Sampler, O.TexCd.xy, 0.01, DispAmount.x * DisplaceNormalInfluence, 0);
	#endif

	float pdisp = disp.g + (disp.r - disp.g) * DisplaceVelocityGain;
    float3 pdispPos = pfPos + f3Normal * pdisp * DispAmount.y;

    float4 PosW = mul(float4(dispPos,1), w);
    float4 FlatPosW = mul(float4(dispFlatPos,1), w);
    O.PosV = mul(PosW, tV);
    O.NormV = normalize(mul(float4(dispNorm,0), tWV).xyz);
    O.NormW = normalize(mul(float4(dispNorm,0), w).xyz);
    O.PosWVP = mul(O.PosV, tP);
    O.PosP = mul(FlatPosW, tVP);

    float4x4 ptWVP = pw;
    ptWVP = mul(ptWVP, ptV);
    ptWVP = mul(ptWVP, ptP);
    O.velocity = mul(float4(pdispPos,1), ptWVP);
   
    return O;
}

[maxvertexcount(3)]
void GS(triangle PSin input[3], inout TriangleStream<PSin>GSOut)
{
	PSin v = (PSin)0;
	
    float3 trv0 = input[0].PosV.xyz;
    float3 trv1 = input[1].PosV.xyz;
    float3 trv2 = input[2].PosV.xyz;
    float3 f1 = trv1 - trv0;
    float3 f2 = trv2 - trv0;
    float3 cnorm = normalize(cross(f1,f2));

	for(uint i=0;i<3;i++)
	{
		v=input[i];
		v.NormV = cnorm;
		v.NormW = mul(float4(cnorm,0),tVI).xyz;
		GSOut.Append(v);
	}
}

technique10 Main
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
technique10 FlatNormals
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetHullShader( CompileShader( hs_5_0, HS()) );
		SetDomainShader( CompileShader( ds_5_0, DS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}
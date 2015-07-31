//@author: microdee
#include "../fxh/MREForward.fxh"
#include "../fxh/GetMergedID.fxh"

StructuredBuffer<InstanceParams> InstancedParams;
StructuredBuffer<uint> SubsetVertexCount;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : VIEW;
	float4x4 ptV : PREVIOUSVIEW;
	float4x4 tP : PROJECTION;
	float4x4 ptP : PREVIOUSPROJECTION;
	float3 NearFarPow : NEARFARDEPTHPOW;
	int ObjIDMode : MRE_OBJIDMODE;
	int DepthMode : MRE_DEPTHMODE;
};

cbuffer cbPerObjectGeom : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 ptW;
	float SubsetCount = 1;
	float3 FlipNormals = 1;
};

#include "../fxh/MREForwardMergedPS.fxh"

PSin VS(VSin In)
{
    // inititalize
    PSin Out = (PSin)0;
	float ii = 0;
	// get Instance ID from GeomFX
	#if defined(IID_FROM_GEOM) && defined(HAS_GEOMVELOCITY)
		ii = In.velocity.w;
	#else
		ii = GetMergedGeomID(SubsetVertexCount, In.vid, SubsetCount);
	#endif
	Out.ii = ii;
	
	// TexCoords
	float4x4 tT = InstancedParams[ii].tTex;
	float4x4 w = mul(InstancedParams[ii].tW,tW);
	
	float4 dispPos = In.PosO;
	float3 dispNorm = In.NormO * FlipNormals;

	float4x4 tWV = mul(w, tV);
    Out.NormV = normalize(mul(float4(dispNorm,0), tWV).xyz);
    Out.NormW = normalize(mul(float4(dispNorm,0), w).xyz);
    #if defined(HAS_NORMALMAP)
    	Out.Tangent = normalize(mul(float4(In.Tangent,0), tWV).xyz);
    	Out.Binormal = normalize(mul(float4(In.Binormal,0), tWV).xyz);
    #endif
	
    float4 PosW = mul(dispPos, w);
	
	#if defined(TRIPLANAR)
		Out.TexCd = mul(dispPos,tT);
	#elif defined(HAS_TEXCOORD)
		Out.TexCd = mul(float4(In.TexCd.xy,0,1), tT);
	#else
		Out.TexCd = 0;
	#endif
	
    float4 PosWV = mul(PosW, tV);
    Out.PosV = PosWV;
    Out.PosWVP = mul(PosWV, tP);
    Out.PosP = Out.PosWVP;
	
	// velocity
	#if defined(HAS_GEOMVELOCITY)
		float4 pdispPos = float4(In.velocity.xyz,1);
	#else
		float4 pdispPos = In.PosO;
	#endif

	float4x4 pw = mul(InstancedParams[ii].ptW,ptW);

	float4x4 ptWVP = pw;
	ptWVP = mul(ptWVP, ptV);
	ptWVP = mul(ptWVP, ptP);
	Out.velocity = mul(pdispPos, ptWVP);
	
    return Out;
}

technique10 DeferredBase
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}
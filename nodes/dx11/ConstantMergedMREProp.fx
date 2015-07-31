//@author: microdee
#include "../fxh/MREForward.fxh"
#include "../fxh/GetMergedID.fxh"

StructuredBuffer<InstanceParams> InstancedParams;
StructuredBuffer<uint> SubsetVertexCount;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
};

cbuffer cbPerObjectGeom : register( b1 )
{
	float4x4 tW : WORLD;
	float SubsetCount = 1;
};

#include "../fxh/MREForwardMergedPSProp.fxh"

PSinProp VS(VSin In)
{
    // inititalize
    PSinProp Out = (PSinProp)0;
	// get Instance ID from GeomFX
	#if defined(IID_FROM_GEOM) && defined(HAS_GEOMVELOCITY)
		float ii = In.velocity.w;
	#else
		float ii = GetMergedGeomID(SubsetVertexCount, In.vid, SubsetCount);
	#endif
	Out.ii = ii;
	
	// TexCoords
	float4x4 tT = InstancedParams[ii].tTex;
	float4x4 w = mul(InstancedParams[ii].tW,tW);
	
    Out.PosW = mul(In.PosO, w);
	Out.NormW = mul(float4(In.NormO, 0), w).xyz;
	
	#if defined(HAS_TEXCOORD)
		Out.TexCd = mul(float4(In.TexCd.xy,0,1), tT);
	#else
		Out.TexCd = 0;
	#endif
	
    Out.PosWVP = mul(Out.PosW, tVP);
	
    return Out;
}

technique10 DeferredProp
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

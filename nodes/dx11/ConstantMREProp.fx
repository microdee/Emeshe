//@author: microdee
#include "../fxh/MREForward.fxh"

Texture2D DiffTex;
StructuredBuffer<InstanceParams> InstancedParams;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float3 CamPos : CAM_POSITION;
};

cbuffer cbPerObject : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tTex;
	float4 FDiffColor <bool color=true;> = 1;
	float alphatest = 0.5;
	float TriPlanarPow = 1;
};

PSinProp VS(VSin In)
{
    // inititalize
    PSinProp Out = (PSinProp)0;
	// get Instance ID from GeomFX
	#if defined(IID_FROM_GEOM) && defined(HAS_GEOMVELOCITY)
		float ii = In.velocity.w;
	#else
		float ii = In.iid;
	#endif
	Out.ii = ii;
	
	// TexCoords
	#if defined(INSTANCING)
		float4x4 tT = mul(InstancedParams[ii].tTex,tTex);
		float4x4 w = mul(InstancedParams[ii].tW,tW);
	#else
		float4x4 tT = tTex;
		float4x4 w = tW;
	#endif
	
    Out.PosW = mul(In.PosO, w);
	Out.NormW = mul(float4(In.NormO, 0), w).xyz;
	
	#if defined(TRIPLANAR)
		Out.TexCd = mul(float4(In.PosO),tT);
	#elif defined(HAS_TEXCOORD)
		Out.TexCd = mul(float4(In.TexCd.xy,0,1), tT);
	#else
		Out.TexCd = 0;
	#endif
	
    Out.PosWVP = mul(Out.PosW, tVP);
	
    return Out;
}

PSOutProp PS(PSinProp In)
{
	float ii = In.ii;
	float3 PosW = In.PosW.xyz;

	PSOutProp Out = (PSOutProp)0;
	
	float2 uvb = In.TexCd.xy;

	#if defined(ALPHATEST)
		if(alphatest!=0)
		{
			#if defined(TRIPLANAR)
				float4 diffcol = TriPlanarSample(DiffTex, Sampler, In.TexCd.xyz, In.NormW, TriPlanarPow);
			#else
		    	float4 diffcol = DiffTex.Sample( Sampler, uvb);
			#endif
			float alphat = diffcol.a * FDiffColor.a;
			alphat = lerp(alphat, (alphat>=alphatest), min(alphatest*10,1));
			clip(alphat - (1-alphatest));
		}
	#endif
	
	float d = distance(PosW, CamPos);
	Out.WorldPos = float4(PosW, d);
	
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

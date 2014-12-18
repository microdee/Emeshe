//@author: microdee
#include "MREForward.fxh"

Texture2D DiffTex;
Texture2D BumpTex;
StructuredBuffer<sDeferredBase> InstancedParams;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tVP : VIEWPROJECTION;
	float3 CamPos : CAM_POSITION;
	float3 NearFarPow : NEARFARDEPTHPOW;
};

cbuffer cbPerObject : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 tTex;
	float4 FDiffColor <bool color=true;> = 1;
	float alphatest = 0.5;
	float FBumpAmount = 0;
	float bumpOffset = 0;
	float TriPlanarPow = 1;
};

vs2ps VS(VSin In)
{
    // inititalize
    vs2ps Out = (vs2ps)0;
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
	
    Out.NormW = normalize(mul(float4(In.NormO,0), w).xyz);
    #if defined(HAS_NORMALMAP)
    	Out.Tangent = normalize(mul(float4(In.Tangent,0), w).xyz);
    	Out.Binormal = normalize(mul(float4(In.Binormal,0), w).xyz);
    #endif
	
	float4 dispPos = In.PosO;
	
    float4 PosW = mul(dispPos, w);
	
	#if defined(TRIPLANAR)
		Out.TexCd = mul(float4(dispPos),tT);
	#elif defined(HAS_TEXCOORD)
		Out.TexCd = mul(float4(In.TexCd.xy,0,1), tT);
	#else
		Out.TexCd = 0;
	#endif
	
    float4 PosWV = mul(PosW, tV);
    Out.PosV = PosWV;
    Out.PosWVP = mul(PosWV, tP);

	Out.velocity = 0;
	
    return Out;
}

PSProp PS(vs2ps In)
{
	float ii = In.ii;
	float3 PosV = In.PosV.xyz;

	PSProp Out = (PSProp)0;
	float3 NormW = In.NormW;
	
	float2 uvb = In.TexCd.xy;
	
	#if defined(INSTANCING)
		float bmpam = InstancedParams[ii].BumpAmount * FBumpAmount;
	#else
		float bmpam = FBumpAmount;
	#endif

	float depth = bmpam;
	#if defined(TRIPLANAR)
		float mdepth = TriPlanarSample(BumpTex, Sampler, In.TexCd.xyz, In.NormW, TriPlanarPow).r + bumpOffset;
	#else
		float mdepth = BumpTex.Sample(Sampler, uvb).r + bumpOffset;
	#endif
	
	if(depth!=0) PosV += In.NormW * mdepth * -1*depth;

    #if defined(HAS_NORMALMAP)
    	float3 normmap = NormalTex.Sample(Sampler, uvb).xyz*2-1;
		float3 outnorm = normalize(normmap.x * In.Tangent + normmap.y * In.Binormal + normmap.z * In.NormW);
		Out.normalW = float4(outnorm,1);
	#else
		Out.normalW = float4(NormW,1);
	#endif

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
	
	float d = distance(PosV.xyz, CamPos);
	d -= NearFarPow.x;
	d /= abs(NearFarPow.y - NearFarPow.x);
	d = pows(d, NearFarPow.z);
	Out.depth = saturate(d);
	
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

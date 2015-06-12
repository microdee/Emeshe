#define MREFORWARDPS_FXH
// include MREForward.fxh before including this

// declare outside:
// StructuredBuffer<InstanceParams> InstancedParams;

Texture2D DiffTex;
Texture2D BumpTex;
cbuffer cbPerDrawPS : register( b2 )
{
	float3 CamPos : CAM_POSITION;
};

cbuffer cbPerObjectPS : register( b3 )
{
	float4 FDiffColor <bool color=true;> = 1;
	float FBumpAmount = 0;
	float alphatest = 0.5;
	float TriPlanarPow = 1;
};

float PS(PSinProp In) : SV_Target
{
	float ii = In.ii;
	
	float2 uvb = In.TexCd.xy;
	
	#if defined(WRITEDEPTH)
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
		float3 PosW = In.PosW.xyz + In.NormW * mdepth * depth * 0.1;
	#else
		float3 PosW = In.PosW.xyz;
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
	
	float d = distance(PosW, CamPos);
	
    return d;
}
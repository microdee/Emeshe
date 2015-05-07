#define MREFORWARDPS_FXH
// include MREForward.fxh before including this

// declare outside:
// StructuredBuffer<InstanceParams> InstancedParams;

cbuffer cbPerObjectPS : register( b2 )
{
	float FDiffAmount = 1;
	float4 FDiffColor <bool color=true;> = 1;
	float alphatest = 0.5;
	float FBumpAmount = 0;
	float bumpOffset = 0;
	int MatID = 0;
	int2 ObjID = 0;
	float gVelocityGain = 1;
	float TriPlanarPow = 1;
};

PSOut PS(PSin In)
{
	float ii = In.ii;
	float3 PosV = In.PosV.xyz;

	PSOut Out = (PSOut)0;
	float3 NormV = In.NormV;
	
	float2 uvb = In.TexCd.xy;
	
	#if defined(INSTANCING)
		float bmpam = InstancedParams[ii].BumpAmount * FBumpAmount;
	#else
		float bmpam = FBumpAmount;
	#endif

	float depth = bmpam;
	#if defined(TRIPLANAR)
		float mdepth = TriPlanarSample(BumpTex, Sampler, In.TexCd.xyz, In.NormW, TriPlanarPow).r + bumpOffset;
		float4 diffcol = TriPlanarSample(DiffTex, Sampler, In.TexCd.xyz, In.NormW, TriPlanarPow);
	#else
		float mdepth = BumpTex.Sample(Sampler, uvb).r + bumpOffset;
    	float4 diffcol = DiffTex.Sample( Sampler, uvb);
	#endif
	
	if(depth!=0) PosV += In.NormV * mdepth * (depth/100);

    #if defined(HAS_NORMALMAP)
    	float3 normmap = NormalTex.Sample(Sampler, uvb).xyz*2-1;
		float3 outnorm = normalize(normmap.x * In.Tangent + normmap.y * In.Binormal + normmap.z * In.NormV);
		Out.normalV = float4(lerp(NormV, outnorm, depth),1);
	#else
		Out.normalV = float4(NormV,1);
	#endif

	float alphat = diffcol.a * FDiffColor.a;

	#if defined(ALPHATEST)
		if(alphatest!=0)
		{
			alphat = lerp(alphat, (alphat>=alphatest), min(alphatest*10,1));
			clip(alphat - (1-alphatest));
		}
	#endif
	
	#if defined(INSTANCING)
    	diffcol.rgb *= FDiffColor.rgb * FDiffAmount * InstancedParams[ii].DiffAmount * InstancedParams[ii].DiffCol.rgb;
	#else
		diffcol.rgb *= FDiffColor.rgb * FDiffAmount;
	#endif
	Out.color.rgb = diffcol.rgb;
	Out.color.a = alphat;
	
	#if defined(WRITEDEPTH)
		if(DepthMode == 1)
		{
			float d = length(PosV.xyz);
			d -= NearFarPow.x;
			d /= abs(NearFarPow.y - NearFarPow.x);
			d = pows(d, NearFarPow.z);
			Out.depth = saturate(d);
		}
		else
		{
			float4 posout = mul(float4(PosV,1),tP);
			Out.depth = posout.z/posout.w;
		}
	#endif
	
	Out.veluv.xy = In.PosP.xy/In.PosP.w - In.velocity.xy/In.velocity.w;
    Out.veluv.xy *= 0.5 * gVelocityGain;
	Out.veluv.xy += 0.5;
	
    #if defined(TRIPLANAR)
		float2 tuv = TriPlanar(In.TexCd.xyz, In.NormW, TriPlanarPow);
    	Out.veluv.zw = tuv;
	#else
    	Out.veluv.zw = uvb;
	#endif
	
	#if defined(INSTANCING)
		Out.color.a = InstancedParams[ii].MatID;
		Out.normalV.a = InstancedParams[ii].ObjID0;
	#else
		Out.color.a = MatID;
		Out.normalV.a = ObjID.x;
	#endif
	
    return Out;
}
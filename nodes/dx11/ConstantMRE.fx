//@author: microdee
#include "../fxh/MREForward.fxh"

Texture2D DiffTex;
Texture2D BumpTex;
Texture2D NormalTex;
StructuredBuffer<sDeferredBase> InstancedParams;

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

cbuffer cbPerObject : register( b1 )
{
	float4x4 tW : WORLD;
	float4x4 ptW;
	float4x4 tTex;
	float FDiffAmount = 1;
	float4 FDiffColor <bool color=true;> = 1;
	float alphatest = 0.5;
	float FBumpAmount = 0;
	float bumpOffset = 0;
	int MatID = 0;
	int2 ObjID = 0;
	float gVelocityGain = 1;
	float TriPlanarPow = 1;
	bool FlipNormals = false;
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
	
	float4 dispPos = In.PosO;
	float3 dispNorm = (FlipNormals) ? -In.NormO : In.NormO;

	float4x4 tWV = mul(w, tV);
    Out.NormV = normalize(mul(float4(dispNorm,0), tWV).xyz);
    Out.NormW = normalize(mul(float4(dispNorm,0), w).xyz);
    #if defined(HAS_NORMALMAP)
    	Out.Tangent = normalize(mul(float4(In.Tangent,0), tWV).xyz);
    	Out.Binormal = normalize(mul(float4(In.Binormal,0), tWV).xyz);
    #endif
	
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
	
	// velocity
	#if defined(HAS_GEOMVELOCITY)
		float4 pdispPos = float4(In.velocity.xyz,1);
	#else
		float4 pdispPos = In.PosO;
	#endif

	#if defined(INSTANCING)
		float4x4 pw = mul(InstancedParams[ii].ptW,ptW);
	#else
		float4x4 pw = ptW;
	#endif

	float3 npos = PosWV.xyz;
	float4x4 ptWV = pw;
	ptWV = mul(ptWV, ptV);
	float3 pnpos = mul(pdispPos, ptWV).xyz;
	Out.velocity.rgb = ((npos - pnpos) * gVelocityGain);
	Out.velocity.rgb += 0.5;
	Out.velocity.a = 1;
	
    return Out;
}

PSOut PS(vs2ps In)
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
	
	Out.velocity.rgb = In.velocity.xyz-.5;
	Out.velocity.rgb *= min(3,2/PosV.z);
	Out.velocity.rgb +=.5;
	Out.velocity.a = 1;
	
	Out.matprop.rg = f32tof16(uvb);
	#if defined(INSTANCING)
		Out.matprop.b = InstancedParams[ii].MatID;
		if(ObjIDMode == 1)
		{
			uint o0 = InstancedParams[ii].ObjID0;
			uint o1 = InstancedParams[ii].ObjID1;
			Out.matprop.a = JoinHalf(o0, o1);
		}
		else Out.matprop.a = InstancedParams[ii].ObjID0;
	#else
		Out.matprop.b = MatID;
		if(ObjIDMode == 1) Out.matprop.a = JoinHalf(ObjID.x, ObjID.y);
		else Out.matprop.a = ObjID.x;
	#endif
	
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
//@author: microdee
//@help: lighting components

#define PI 3.14159265358979
#include "../fxh/CookTorrance.fxh"

Texture2D Lights[3];
Texture2D MaskTex;

SamplerState s0
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = WRAP;
    AddressV = MIRROR;
};

cbuffer cbPerObj : register( b1 )
{
	float LightCount = 1;
	float DistanceMod = 1;
	bool IsInitial = true;
	float3 ComponentAmount = 1;
	float2 Res : TARGETSIZE;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = input.PosO;
    Out.TexCd = input.TexCd;
    return Out;
}

struct OutComps
{
	float4 Diffuse : SV_Target0;
	float4 Specular : SV_Target1;
	float4 SSS : SV_Target2;
};

OutComps Composite(Components col, float2 uv)
{
	OutComps outCol = (OutComps)0;
	
	outCol.Diffuse.xyz = max(0,col.Diffuse.xyz * ComponentAmount.x);
	outCol.Specular.xyz = max(0,col.Specular.xyz * ComponentAmount.y);
	outCol.SSS.xyz = max(0,col.SSS.xyz * ComponentAmount.z);
	if(!IsInitial)
	{
		outCol.Diffuse.rgb += max(0,Lights[0].Sample(s0, uv).rgb);
		outCol.Specular.rgb += max(0,Lights[1].Sample(s0, uv).rgb);
		outCol.SSS.rgb += max(0,Lights[2].Sample(s0, uv).rgb);
	}
	
	return outCol;
}

OutComps pPnt(vs2ps In)
{
	float2 uv = In.TexCd.xy;

	if((GetStencil(Res, uv) > 0) && KnowFeature(GetMatID(s0, uv), MF_LIGHTING_COOKTORRANCE))
	{
		Components col = CookTorrancePointSSS(s0, uv, Res, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		return Composite(col, uv);
	}
	else
	{
		return (OutComps)0;
	}
	
}

technique10 Point
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, pPnt() ) );
	}
}

OutComps pSpt(vs2ps In)
{
	float2 uv = In.TexCd.xy;

	if((GetStencil(Res, uv) > 0) && KnowFeature(GetMatID(s0, uv), MF_LIGHTING_COOKTORRANCE))
	{
		Components col = CookTorranceSpotSSS(s0, uv, Res, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		return Composite(col, uv);
	}
	else
	{
		return (OutComps)0;
	}
}

technique10 Spot
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, pSpt() ) );
	}
}

OutComps pSun(vs2ps In)
{
	float2 uv = In.TexCd.xy;

	if((GetStencil(Res, uv) > 0) && KnowFeature(GetMatID(s0, uv), MF_LIGHTING_COOKTORRANCE))
	{
		Components col = CookTorranceSunSSS(s0, uv, Res, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		return Composite(col, uv);
	}
	else
	{
		return (OutComps)0;
	}
}

technique10 Sun
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, pSun() ) );
	}
}



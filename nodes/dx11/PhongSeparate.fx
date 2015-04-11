//@author: microdee
//@help: lighting components

#define PI 3.14159265358979
#include "../fxh/Phong.fxh"

Texture2D Lights[5];
Texture2D MaskTex;
float2 R : TARGETSIZE;

SamplerState s0
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerObj : register( b1 )
{
	float LightCount = 1;
	float DistanceMod = 1;
	bool IsInitial = true;
	float ComponentAmount[5] = {1,1,1,1,1};
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
	float4 Ambient : SV_Target0;
	float4 Diffuse : SV_Target1;
	float4 Specular : SV_Target2;
	float4 SSS : SV_Target3;
	float4 Rim : SV_Target4;
};

OutComps pPnt(vs2ps In)
{
	float2 uv = In.TexCd.xy;

	if((GetStencil(uv, R) > 0) && KnowFeature(GetMatID(uv, R), MF_LIGHTING_PHONG))
	{
		Components col = PhongPointSSS(s0, uv, R, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		OutComps outCol = (OutComps)0;
		
		outCol.Ambient.xyz = col.Ambient.xyz * ComponentAmount[0];
		outCol.Diffuse.xyz = col.Diffuse.xyz * ComponentAmount[1];
		outCol.Specular.xyz = col.Specular.xyz * ComponentAmount[2];
		outCol.SSS.xyz = col.SSS.xyz * ComponentAmount[3];
		outCol.Rim.xyz = col.Rim.xyz * ComponentAmount[4];
		if(!IsInitial)
		{
			outCol.Ambient.rgb = max(outCol.Ambient.rgb,Lights[0].Sample(s0, uv).rgb);
			outCol.Diffuse.rgb += Lights[1].Sample(s0, uv).rgb;
			outCol.Specular.rgb += Lights[2].Sample(s0, uv).rgb;
			outCol.SSS.rgb += Lights[3].Sample(s0, uv).rgb;
			outCol.Rim.rgb += Lights[4].Sample(s0, uv).rgb;
		}
		
		return outCol;
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

	if((GetStencil(uv, R) > 0) && KnowFeature(GetMatID(uv, R), MF_LIGHTING_PHONG))
	{
		Components col = PhongSpotSSS(s0, uv, R, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		OutComps outCol = (OutComps)1;
		
		outCol.Ambient.xyz = col.Ambient.xyz * ComponentAmount[0];
		outCol.Diffuse.xyz = col.Diffuse.xyz * ComponentAmount[1];
		outCol.Specular.xyz = col.Specular.xyz * ComponentAmount[2];
		outCol.SSS.xyz = col.SSS.xyz * ComponentAmount[3];
		outCol.Rim.xyz = col.Rim.xyz * ComponentAmount[4];
		if(!IsInitial)
		{
			outCol.Ambient.rgb = max(outCol.Ambient.rgb,Lights[0].Sample(s0, uv).rgb);
			outCol.Diffuse.rgb += Lights[1].Sample(s0, uv).rgb;
			outCol.Specular.rgb += Lights[2].Sample(s0, uv).rgb;
			outCol.SSS.rgb += Lights[3].Sample(s0, uv).rgb;
			outCol.Rim.rgb += Lights[4].Sample(s0, uv).rgb;
		}
		
		return outCol;
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

	if((GetStencil(uv, R) > 0) && KnowFeature(GetMatID(uv, R), MF_LIGHTING_PHONG))
	{
		Components col = PhongSunSSS(s0, uv, R, LightCount, DistanceMod, MaskTex.SampleLevel(s0, uv, 0).r);
		OutComps outCol = (OutComps)1;
		
		outCol.Ambient.xyz = col.Ambient.xyz * ComponentAmount[0];
		outCol.Diffuse.xyz = col.Diffuse.xyz * ComponentAmount[1];
		outCol.Specular.xyz = col.Specular.xyz * ComponentAmount[2];
		outCol.SSS.xyz = col.SSS.xyz * ComponentAmount[3];
		outCol.Rim.xyz = col.Rim.xyz * ComponentAmount[4];
		if(!IsInitial)
		{
			outCol.Ambient.rgb = max(outCol.Ambient.rgb,Lights[0].Sample(s0, uv).rgb);
			outCol.Diffuse.rgb += Lights[1].Sample(s0, uv).rgb;
			outCol.Specular.rgb += Lights[2].Sample(s0, uv).rgb;
			outCol.SSS.rgb += Lights[3].Sample(s0, uv).rgb;
			outCol.Rim.rgb += Lights[4].Sample(s0, uv).rgb;
		}
		
		return outCol;
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



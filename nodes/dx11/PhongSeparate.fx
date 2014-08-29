//@author: microdee
//@help: lighting components

#define PI 3.14159265358979
#include "LightUtils.fxh"
#include "MRE.fxh"

Texture2D Lights[5];
Texture2D Mask;

SamplerState s0
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tView;
	float LightCount = 1;
	float DistanceMod = 1;
	bool IsInitial = true;
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
	float2 uv = In.TexCd;
	if(Mask.Sample(s0, uv).r>0.5)
	{
		Components col = (Components)0;
		float3 vel = mre_getvelocity(s0,uv);
		float fe = 0.001;
		if(!((vel.r<=fe) && (vel.g<=fe) && (vel.b<=fe)))
		{
			float3 wPos = mre_getworldpos(s0,uv);
			float3 norm = mre_getworldnorm(s0,uv);
			//float3 viewdirv = normalize(mul(float4(wPos,1),tView).xyz);
			float3 viewdirv = normalize(wPos);
			col = PhongPointSSS(wPos, norm, viewdirv, mre_getmaps(s0,uv).xy, LightCount, mre_getmatid(s0,uv), tView, DistanceMod);
		}
		OutComps outCol = (OutComps)1;
		
		outCol.Ambient.xyz = col.Ambient.xyz;
		outCol.Diffuse.xyz = col.Diffuse.xyz;
		outCol.Specular.xyz = col.Specular.xyz;
		outCol.SSS.xyz = col.SSS.xyz;
		outCol.Rim.xyz = col.Rim.xyz;
		if(!IsInitial)
		{
			outCol.Ambient.xyz = max(outCol.Ambient.xyz,Lights[0].Sample(s0, In.TexCd));
			outCol.Diffuse.xyz += Lights[1].Sample(s0, In.TexCd);
			outCol.Specular.xyz += Lights[2].Sample(s0, In.TexCd);
			outCol.SSS.xyz += Lights[3].Sample(s0, In.TexCd);
			outCol.Rim.xyz += Lights[4].Sample(s0, In.TexCd);
		}
		
		return outCol;
	}
	else
	{
		return (OutComps)1;
	}
	
}

technique10 Point
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, pPnt() ) );
	}
}

OutComps pSpt(vs2ps In)
{
	float2 uv = In.TexCd;
	if(Mask.Sample(s0, uv).r>0.5)
	{
		Components col = (Components)0;
		float3 vel = mre_getvelocity(s0,uv);
		float fe = 0.001;
		if(!((vel.r<=fe) && (vel.g<=fe) && (vel.b<=fe)))
		{
			float3 wPos = mre_getworldpos(s0,uv);
			float3 norm = mre_getworldnorm(s0,uv);
			float3 viewdirv = normalize(mul(float4(wPos,1),tView).xyz);
			col = PhongSpotSSS(wPos, norm, viewdirv, mre_getmaps(s0,uv).xy, LightCount, mre_getmatid(s0,uv), DistanceMod, tView);
		}
		OutComps outCol = (OutComps)1;
		outCol.Ambient.xyz = col.Ambient.xyz;
		outCol.Diffuse.xyz = col.Diffuse.xyz;
		outCol.Specular.xyz = col.Specular.xyz;
		outCol.SSS.xyz = col.SSS.xyz;
		outCol.Rim.xyz = col.Rim.xyz;
		
		return outCol;
	}
	else
	{
		return (OutComps)1;
	}
}

technique10 Spot
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, pSpt() ) );
	}
}

OutComps pSun(vs2ps In)
{
	float2 uv = In.TexCd;
	if(Mask.Sample(s0, uv).r>0.5)
	{
		Components col = (Components)0;
		float3 vel = mre_getvelocity(s0,uv);
		float fe = 0.001;
		if(!((vel.r<=fe) && (vel.g<=fe) && (vel.b<=fe)))
		{
			float3 wPos = mre_getworldpos(s0,uv);
			float3 norm = mre_getworldnorm(s0,uv);
			float3 viewdirv = normalize(mul(float4(wPos,1),tView).xyz);
			col = PhongSunSSS(norm, viewdirv, mre_getmaps(s0,uv).xy, LightCount, mre_getmatid(s0,uv), tView);
		}
		OutComps outCol = (OutComps)1;
		outCol.Ambient.xyz = col.Ambient.xyz;
		outCol.Diffuse.xyz = col.Diffuse.xyz;
		outCol.Specular.xyz = col.Specular.xyz;
		outCol.SSS.xyz = col.SSS.xyz;
		outCol.Rim.xyz = col.Rim.xyz;
		
		return outCol;
	}
	else
	{
		return (OutComps)1;
	}
}

technique10 Sun
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, pSun() ) );
	}
}



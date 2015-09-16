
#include "../../../mp.fxh/MRE.fxh"
#include "../../../mp.fxh/PoissonDisc.fxh"
#include "../../../mp.fxh/ColorSpace.fxh"

#define DISCSAMPLES 8
#define DISCSAMPLES2 16
#define PI 3.14159265358979

Texture2D ColTex;
Texture2D<float> MaskTex;

SamplerState sL
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
SamplerState sP
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerObj : register( b1 )
{
	float2 res = 256;
	float LOD = 0;
	float Spread = 0.1;
	float Saturation = 1;
	float LumaEpsilon = 0.01;
	float ZEpsilon = 0.5;
	float MaskEpsilon = 0.01;
	float Amount = 0.01;
	float2 MinMaxExtend = float2(0.01, 0.5);
};

struct vs2gs
{
    float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
	float4 Col: COLOR0;
	float3 Norm: NORMAL;
	bool mask: TEXCOORD1;
};

vs2gs VS(uint ix: SV_VertexID, uint iy: SV_InstanceID)
{
    vs2gs Out = (vs2gs)0;
	float2 txcd = float2(ix/res.x,iy/res.y);
    Out.pos  = float4((txcd.x-.5)*2,-(txcd.y-.5)*2,0,1);
    Out.TexCd = txcd;
	Out.Col = ColTex.SampleLevel(sL,txcd,LOD);
	Out.Norm = Normals.SampleLevel(sP,txcd,0).xyz;
	Out.mask = MaskTex.SampleLevel(sP,txcd,0) > MaskEpsilon;
    return Out;
}
struct gs2ps
{
	float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
	float4 Col: TEXCOORD2;
};
[maxvertexcount(DISCSAMPLES2)]
void GS(point vs2gs input[1], inout LineStream<gs2ps> gsout)
{
	gs2ps o = (gs2ps)0;
	vs2gs inp = input[0];
	float4 colin = inp.Col;
	float3 posin = GetViewPos(sP, inp.TexCd);
	bool passed = length(colin.xyz)>LumaEpsilon && inp.mask;
	passed = passed && (posin.z > ZEpsilon);
	if(passed)
	{
		float3 normin = inp.Norm;
		float lwl = lerp(MinMaxExtend.x, MinMaxExtend.y, length(colin.xyz));
		for(float i=0; i<DISCSAMPLES; i++)
		{
        	float tt = (i/DISCSAMPLES) * PI * 2;
			float3 discnorm = PoissonDiscDir(normin, tt, Spread);
			float3 extended = normalize(discnorm)*lwl;

			o.pos = mul(float4(posin,1), CamProj);
			o.TexCd = inp.TexCd;
			o.Col = colin;

			gsout.Append(o);
			
			float3 posout = posin + extended;
			o.pos = mul(float4(posout,1), CamProj);
			o.TexCd = inp.TexCd;
			o.Col = 0;
			gsout.Append(o);
			
			gsout.RestartStrip();
		}
	}
}

float4 PS(gs2ps In) : SV_Target
{
	float4 col = In.Col * (Amount/DISCSAMPLES);
	float3 hsvcol = RGBtoHSV(col.rgb);
	hsvcol.g *= Saturation;
	col.rgb = HSVtoRGB(hsvcol);
    return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}
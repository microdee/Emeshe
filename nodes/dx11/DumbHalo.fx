//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

struct SpotLightProp
{
    float3 Position; // Source
    float Range; // Distance
    float RangePow; // Fade
    float4 LightCol;
    float LightStrength;
    float4x4 lProjection;
    float4x4 lView;
    uint TexID;
};

Texture2D texture2d <string uiname="Texture";>;
StructuredBuffer<SpotLightProp> spotlightprop;
StructuredBuffer<float4x4> invtVP;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	uint ii : SV_InstanceID;
};

struct vs2gs
{
    float4 PosWVP: POSITION;
    float4 TexCd: TEXCOORD0;
    float ii: TEXCOORD1;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
    Out.TexCd = mul(input.TexCd, tTex);
    return Out;
}




float4 PS(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample(g_samLinear,In.TexCd.xy) * cAmb;
	col.a *= Alpha;
    return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





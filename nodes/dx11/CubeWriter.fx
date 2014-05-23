//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2DArray TexArr;

SamplerState s0 : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

StructuredBuffer<float4x4> sbWorld;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
};


struct VS_IN
{
	uint ii : SV_InstanceID;
	float4 PosO : POSITION;
	float2 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;	
	nointerpolation float ii: TEXCOORD0;
    float2 TexCd: TEXCOORD1;
	
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	float4x4 w = sbWorld[input.ii];
    Out.PosWVP  = mul(input.PosO,mul(w,tVP));
	Out.ii = input.ii;
    Out.TexCd = input.TexCd;
    return Out;
}




float4 PS_Tex(vs2ps In): SV_Target
{
    float4 col = TexArr.Sample( s0, float3(In.TexCd, In.ii));
    return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}





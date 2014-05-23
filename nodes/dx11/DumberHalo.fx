//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D texture2d; 

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

StructuredBuffer< float4x4> sbWorld;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tW : WORLD;
	int count = 100;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float strength = 1;
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
	float2 TexCd: TEXCOORD0;
    float ii: TEXCOORD1;
	
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
    Out.PosWVP  = input.PosO;
    Out.TexCd = input.TexCd;
	Out.ii = input.ii;
	
    return Out;
}


[maxvertexcount(12)]
void GS(triangle vs2ps input[3], inout TriangleStream<vs2ps>GSOut)
{
	vs2ps v;
	for(float j=0;j<4;j++)
	{
		for(float i=0;i<3;i++)
		{
			v=input[i];
			float4x4 w = sbWorld[input[i].ii];
			float4 pos = mul(input[i].PosWVP,w);
			pos.z += (j/4)/(count*25);
	  		v.PosWVP  = mul(pos,tW);
			v.PosWVP = mul(v.PosWVP,tVP);
			GSOut.Append(v);
		}
    GSOut.RestartStrip();
	}
}



float4 PS_Tex(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample( g_samLinear, In.TexCd) * cAmb * pow(1-(In.ii/count),0.25) * strength;
    return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Tex() ) );
	}
}





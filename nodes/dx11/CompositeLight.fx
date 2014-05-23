//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D Lights[5];
Texture2D InTex;

SamplerState s0
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
	float Opacity = 1;
	float AmbMul = 0;
	float SpecMul = 0;
	float SSSMul = 0;
	float4 ComponentAmount = 1;
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




float4 PS(vs2ps In): SV_Target
{
	float2 uv = In.TexCd.xy;
    float4 incol = InTex.Sample(s0,uv);
	float4 col = 0;
	col.a = incol.a;
	float3 amb = Lights[0].Sample(s0,uv).rgb;
	float3 diff = Lights[1].Sample(s0,uv).rgb;
	float3 spec = Lights[2].Sample(s0,uv).rgb;
	float3 SSS = Lights[3].Sample(s0,uv).rgb;
	float3 rim = Lights[4].Sample(s0,uv).rgb;
	
	float3 Pamb = max(incol.rgb, amb);
	float3 Mamb = incol.rgb * amb;
	float3 Oamb = lerp(Pamb,Mamb,AmbMul);
	
	float3 Odiff = incol.rgb * diff;
	
	float3 Mspec = incol.rgb * spec;
	float3 Ospec = lerp(spec,Mspec,SpecMul);
	
	float3 MSSS = incol.rgb * SSS;
	float3 OSSS = lerp(SSS,MSSS,SSSMul);
	
	float3 Mrim = incol.rgb * rim;
	float3 Orim = lerp(rim,Mrim,SSSMul);
	
	col.rgb = Oamb * ComponentAmount.x;
	col.rgb += Odiff * ComponentAmount.y;
	col.rgb += Ospec * ComponentAmount.z;
	col.rgb += OSSS * ComponentAmount.w;
	col.rgb += Orim * ComponentAmount.w;
	
    return lerp(incol,col,Opacity);
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





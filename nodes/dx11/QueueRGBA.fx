Texture2D tex0 <string uiname="Texture";>;
Texture2D tex1 <string uiname="Feed Texture";>;
SamplerState s0 <bool visible=false;string uiname="Sampler";>
{Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};


float4 Color <bool color=true;> = {1.0,1.0,1.0,1.0};
float4x4 tTex <string uiname="Texture Transform";>;
float4x4 tColor <string uiname="Color Transform";>;


float4 pRGB_X(float2 UV:TEXCOORD0,float4 PosWVP:SV_POSITION):SV_Target{
	float4 cInput=tex0.SampleLevel(s0,UV.xy,0);
	float4 cFeed=tex1.SampleLevel(s0,UV.xy,0);
	float4 c=cInput;
	c=float4(cFeed.yzw,cInput.x);
	return c;
}
float4 pRG_X(float2 UV:TEXCOORD0,float4 PosWVP:SV_POSITION):SV_Target{
	float4 cInput=tex0.SampleLevel(s0,UV.xy,0);
	float4 cFeed=tex1.SampleLevel(s0,UV.xy,0);
	float4 c=cInput;
	c.rg=float2(cFeed.y,cInput.x);
	return c;
}

void VS(in float4 PosO:POSITION,inout float4 TexCd:TEXCOORD0,out float4 PosWVP:SV_POSITION){PosWVP=float4((PosO.xy)*2,0,1);TexCd=mul(TexCd,tTex);}

technique10 _RG_X{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetPixelShader(CompileShader(ps_5_0,pRG_X()));
	}
}
technique10 _RGB_X{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetPixelShader(CompileShader(ps_5_0,pRGB_X()));
	}
}




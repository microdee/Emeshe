//@author: sebl
//@help: might become a really quick queue/ringbuffer... if finished/working
//@tags: queue
//@credits: vux

Texture2D texture2d <string uiname="Texture";>;
SamplerState textureSampler  
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

int slice <string uiname="slice Index";>;  // the slice
float4x4 tW: WORLD;
//float4x4 tV: VIEW;
//float4x4 tP: PROJECTION;
float4x4 tVP : VIEWPROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;
//float4x4 tVi: VIEWINVERSE;
//float4x4 tWi: WORLDINVERSE;

float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;



//////////////////////// structs  ///////////////////////
struct vsin
{
	float4 pos : POSITION;
	float2 TexCd : TEXCOORD0;
};

struct vs2gs
{
	float4 Pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
};

struct gs2ps
{
	float4 pos   	: SV_POSITION;
	float2 TexCd	: TEXCOORD0;
	uint   layer 	: SV_RenderTargetArrayIndex;
};


//////////////////////// VS  ///////////////////////
vs2gs VS(vsin input)
{
	vs2gs Out = (vs2gs)0;
//	Out.Pos   = mul(input.pos, mul(tW,tVP));
	Out.Pos   = input.pos * 2;
//	Out.Pos = tPos;

	Out.TexCd = mul(input.TexCd, tTex);
	
	return Out;
}


//////////////////////// GS  ///////////////////////
[maxvertexcount(4)]
void GS(triangle vs2gs input[3], inout TriangleStream<gs2ps> triOutputStream)
{
	gs2ps output;
	
	for(int i=0; i < 3; ++i)
	{
		output.pos    = input[i].Pos;
		output.TexCd  = input[i].TexCd.xy;
		output.layer  = slice;
		
		triOutputStream.Append(output);
	}
}


//////////////////////// PS  ///////////////////////
float4 PS(gs2ps input) : SV_Target
{
	float4 col = texture2d.Sample( textureSampler, input.TexCd.xy );
	
	return col;
}


//////////////////////// techniques  ///////////////////////
technique11 Queue
{
	pass P0
	{
		SetHullShader		( 0 );
		SetDomainShader		( 0 );
		SetVertexShader		( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader	( CompileShader( gs_5_0, GS() ) );
		SetPixelShader		( CompileShader( ps_5_0, PS() ) );
	}
}





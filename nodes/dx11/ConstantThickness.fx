//@author: microdee
//@help: standard constant shader
//@tags: stuff
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVi : VIEWINVERSE;
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
	bool IsOnePass = true;
};

struct VS_IN
{
	float4 PosO : POSITION;
};

struct vs2gs
{
    float4 posWV: SV_POSITION;
    float4 TexCd: TEXCOORD0;
};
struct gs2ps
{
    float4 posWVP: SV_POSITION;
    float4 posWV: TEXCOORD1;
    float4 TexCd: TEXCOORD0;
	uint   layer: SV_RenderTargetArrayIndex;
};

vs2gs VS(VS_IN input)
{
    vs2gs Out = (vs2gs)0;
    Out.posWV  = mul(input.PosO,mul(tW,tV));
    Out.TexCd = mul(input.PosO, tTex);
    return Out;
}

[maxvertexcount(3)]
void GS(triangle vs2gs input[3], inout TriangleStream<gs2ps> triOutputStream)
{
	gs2ps output;
	
	//Get triangle face direction
	float3 f1 = input[1].posWV.xyz - input[0].posWV.xyz;
    float3 f2 = input[2].posWV.xyz - input[0].posWV.xyz;
	//Compute flat normal
	float3 norm = normalize(cross(f1, f2));
	
	float3 fpos = (input[0].posWV.xyz + input[1].posWV.xyz + input[2].posWV.xyz)/3;
	float3 eyevec = normalize(fpos-mul(float4(0,0,0,1),tVi).xyz);
	float eyedot = dot(norm,eyevec);
	if(IsOnePass)
	{
		if(eyedot<0) output.layer = 1;
		else output.layer = 0;
	}
	
	for(int i=0; i < 3; ++i)
	{
		output.posWVP    = mul(input[i].posWV,tP);
		output.posWV    = mul(input[i].posWV,tP);
		output.TexCd  = input[i].TexCd;
		
		triOutputStream.Append(output);
	}
}



float4 PS(gs2ps In): SV_Target
{
    float4 col = In.posWV.z/In.posWV.w;
	col.a = Alpha;
    return col;
}





technique10 ConstantOnePass
{
	pass P0
	{
		SetVertexShader		( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader	( CompileShader( gs_4_0, GS() ) );
		SetPixelShader		( CompileShader( ps_4_0, PS() ) );
	}
}




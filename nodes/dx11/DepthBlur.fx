Texture2D texCOL <string uiname="Color Buffer";>;

Texture2D texPOSW <string uiname="WorldPos Buffer";>;
Texture2D texNORW <string uiname="WorldNorm Buffer";>;
//Texture2D texCol <string uiname="Texture";>;

//TextureCube texENVI <string uiname="Cubemap";>;
SamplerState s0 <bool visible=false;string uiname="Sampler";> {Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};
SamplerState s1:IMMUTABLE {Filter=MIN_MAG_MIP_POINT;AddressU=MIRROR;AddressV=MIRROR;};

float2 R:TARGETSIZE;

SamplerState g_samLinear : IMMUTABLE
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
SamplerState g_samPoint : IMMUTABLE
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tVI : VIEWINVERSE;
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tWVI:VIEWINVERSE;
	float4x4 tPI:PROJECTIONINVERSE;
};


cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	
};


struct VS_IN
{
	float4 PosO : POSITION;
	float2 UV : TEXCOORD0;
};

struct VS_OUT
{
    float4 PosWVP: SV_POSITION;
    float2 UV: TEXCOORD0;
};

VS_OUT VS(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;

    //position (projected)
	Out.PosWVP = In.PosO;//mul(In.PosO,mul(tW,tVP));
    Out.UV = In.UV;
    return Out;
}

float SelfShadowCut=.02;
float Seed=0;

float Radius=3.5;
//float Amount=.5;
float Limit=2;

float Shape=0;
float Range=1;
int Iterations <float uimin=0;float uimax=128;> =16;
float4 PS_AO(VS_OUT In): SV_Target{
	float4 p=texPOSW.SampleLevel(g_samPoint,In.UV,0);
	float3 n=texNORW.SampleLevel(g_samPoint,In.UV,0).xyz;
	float3 nv=mul(n,(float3x3)tV);
	int itr=Iterations;
	float z=mul(float4(p.xyz,1),tVP).z;
	float sum=.2;
	float4 c=texCOL.SampleLevel(g_samLinear,In.UV,0)*sum;
	for(int i=0;i<itr&&i<128;i++){
		//float2 off=sin((float(i)/itr*3+float2(.25,0))*acos(-1)*2);
		float2 off=sin((float(i)/itr+dot(p,22222)+float2(.25,0))*acos(-1)*2);
		//off+=nv.xy*((float)i/itr-.5);
		off=sin((float(i)/itr+Seed+float2(.25,0))*acos(-1)*2);
		off/=R/min(R.x,R.y);
		off=off*Radius*.02/z;
		off*=pow(2,(float(i)/itr-.5)*Range);
		float4 np=texPOSW.SampleLevel(g_samPoint,In.UV+off,0);
		float4 nn=texNORW.SampleLevel(g_samPoint,In.UV+off,0);
		float4 nc=texCOL.SampleLevel(g_samLinear,In.UV+off,0);
		float3 V=np.xyz-p.xyz;
		float d=length(V)+length(n-nn.xyz);
		float k=sqrt(smoothstep(Limit,0,d));
		c+=nc*k;
		sum+=k;

	}
	c/=sum+.000001;
	
	//c.rgb=normalize(c.rgb);
	return c;
}


technique10 DepthBlur
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_AO() ) );
	}
}




#include "../../../mp.fxh/MRE.fxh"

Texture2D texNOIS <string uiname="Noise";>;
Texture2D texCTRL <string uiname="Sample Control";>;

SamplerState s2:IMMUTABLE {Filter=MIN_MAG_MIP_POINT;AddressU=CLAMP;AddressV=CLAMP;};
SamplerState s3:IMMUTABLE {Filter=MIN_MAG_MIP_LINEAR;AddressU=WRAP;AddressV=WRAP;};
float2 R:TARGETSIZE;

float SelfShadowCut=.02;
float Seed=0;

float Radius=3.5;
float Amount=.5;
float Limit=2;

float Shape=0;
float Range=1;
int Iterations <float uimin=0;float uimax=128;> =16;

float Gamma <float uimin=0;float uimax=16;> =1;

float4 pWTFAO(float2 UV:TEXCOORD0,float4 PosWVP:SV_POSITION):SV_Target{
	float4 c=1;
	float4 p=float4(GetViewPos(s2,UV),1);
	float3 n=Normals.SampleLevel(s2,UV,0).xyz;
	int itr=Iterations*texCTRL.SampleLevel(s2,UV,0).r;
	float ao=0;
	if(length(p.xyz)>800)return 1;
	float z=mul(float4(p.xyz,1),CamProj).z;
	float nois=texNOIS.SampleLevel(s3,(PosWVP.xy+0.5)/8.,0).x;
	for(int i=0;i<itr&&i<128;i++){
		float2 off=sin((float(i)/itr*3+nois*4+dot(p.xyz,n+nois)*222+Seed*8+float2(.25,0))*acos(-1)*2);
		//float2 off=sin((float(i)/itr*3+frac(dot(p.xyz,122+n*8+UV.yxx*8))+sin(UV.xy*882+Seed*9)*28+Seed*8+float2(.25,0))*acos(-1)*2);
		//off=sin((float(i)/itr*3+Seed*8+float2(.25,0))*acos(-1)*2);
		
		off=off*Radius/z;
		off*=pow(2,(float(i)/itr-.5)*Range);
		float4 np=float4(GetViewPos(s2,UV+off),1);
		float4 nn=Normals.SampleLevel(s2,UV+off,0);
		float3 V=np.xyz-p.xyz;
		float d=length(V);
		float occ=max(0,dot(n,V))*(1.0/(1.0+d));
		
		occ*=sqrt(smoothstep(Limit,0,d));
		occ*=pow(1.5,d*(d<Limit));
		ao+=occ;
	}
	ao=1-ao*Amount/itr;
	
	c.rgb=pow(saturate(ao),Gamma);
	//c.rgb=nois;
	//c.rgb=z*.4;
	//c.rgb=mul(float4(p.xyz,1),tVP).xyz;
	return c;
}
void VS(in float4 PosO:POSITION,inout float4 TexCd:TEXCOORD0,out float4 PosWVP:SV_POSITION){PosWVP=float4(sign(PosO.xy),0,1);}

technique10 SSAO
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, pWTFAO() ) );
	}
}



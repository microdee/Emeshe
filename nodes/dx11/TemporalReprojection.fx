Texture2D tex0 <string uiname="Texture";>;
Texture2D texDEPTH <string uiname="Depth Texture";>;
Texture2D texDEPTH_P <string uiname="Prev Depth Texture";>;
Texture2D texFEED <string uiname="Texture Feed";>;
SamplerState s0 <bool visible=false;string uiname="Sampler";>
{Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};
SamplerState s1 <bool visible=false;string uiname="Sampler";>
{Filter=MIN_MAG_MIP_POINT;AddressU=CLAMP;AddressV=CLAMP;};

float4x4 tP:PROJECTION;
float4x4 tPI:PROJECTIONINVERSE;
float4x4 tV:VIEW;
float4x4 tVI:VIEWINVERSE;
float4x4 tWIT:WORLDINVERSETRANSPOSE;

float4 Color <bool color=true;> = {1.0,1.0,1.0,1.0};
float4x4 p_tV;
float4x4 p_tVI;
float4x4 p_tP;
float4x4 p_tPI;
float Fade <float uimin=0.0; float uimax=1.0;> = .9; 
bool Reset <bool bang=true;> =0;
float4 PosW(float d,float2 uv,float4x4 tVI,float4x4 tP,float4x4 tPI){
	float4 p=float4(-1.0+2.0*uv.x,-1.0+2.0*uv.y,0,1.0);
	p.y*=-1.0;
	p=mul(p,tPI);
	float ld = tP._43 / (d - tP._33);
	p=float4(p.xy*ld,ld,1.0);
	p=mul(p,tVI);
	return p;
}
float4 PS(float2 UV:TEXCOORD0,float4 PosWVP:SV_POSITION):SV_Target{
	float4 c=tex0.SampleLevel(s0,UV.xy,0)*Color;
	float d=texDEPTH.SampleLevel(s1,UV.xy,0).x;
	
	float4 cInput=tex0.SampleLevel(s0,UV.xy,0);
	float4 cFeed=texFEED.SampleLevel(s0,UV.xy,0);
	c=lerp(cInput,cFeed,Fade);
	float4 pw=PosW(d,UV,tVI,tP,tPI);
	float4 pp_prev=mul(pw,mul(p_tV,p_tP));
	float2 uv_prev=pp_prev.xy/pp_prev.w*float2(1,-1)*.5+.5;
	c.rgb=uv_prev.rgg;
	cFeed=texFEED.SampleLevel(s0,uv_prev.xy,0);
	float d_prev=texDEPTH_P.SampleLevel(s1,uv_prev.xy,0).x;
	float4 pw_prev=PosW(d_prev,uv_prev,p_tVI,p_tP,p_tPI);
	
	float pd=length(pw.xyz-pw_prev.xyz);
	//c=lerp(cInput,cFeed,Fade*saturate(1-pd*13+.0));
	//c.x=lerp(cInput.x,cFeed.x,Fade);
	c=float4(cInput.x,0,0,1);
	
	float ld = tP._43 / (d - tP._33);
	float th=.01;//*pow(1.01,ld);
	if(pd<th){
		c.y=cFeed.y;
		float k=smoothstep(.2+th,th,length(pd));
		k=1;
		c.x=(cFeed.x*c.y+cInput.x*k)/(c.y+k);
		c.y+=k;
		//if(c.y>9)c.y=cFeed.y;
	}
	
	c.x=lerp(cInput.x,c.x,Fade);

	//c.rgb=pw_prev.xyz;
	if(Reset)c=float4(cInput.x,0,0,1);
	
	//c.rgb=
	return c;
}


void VS(in float4 PosO:POSITION,inout float4 TexCd:TEXCOORD0,out float4 PosWVP:SV_POSITION){PosWVP=float4((PosO.xy)*2,0,1);}

technique10 ShaderFilter{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetPixelShader(CompileShader(ps_5_0,PS()));
	}
}





//@author: microdee
//@help: standard constant shader
//@tags: color
//@credits: 
Texture2D coltex;
Texture2D bokehtex;
Texture2D<float> sizemap;
Texture2D<float> depth;

SamplerState s0
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerObj : register( b1 )
{
	float2 res = 256;
	float epsilon = 0.01;
	float sepsilon = 0.01;
	float size = 1;
	float maxsize = 0.3;
	float colamount = 1;
	bool Aspect <bool visible=false;string uiname="Keep Aspect Ratio";> = true;
};

struct vs2gs
{
    float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
};

vs2gs VS(uint ix: SV_VertexID, uint iy: SV_InstanceID)
{
    vs2gs Out = (vs2gs)0;
	float2 txcd = float2(ix/res.x,iy/res.y);
    Out.pos  = float4((txcd.x-.5)*2,-(txcd.y-.5)*2,0,1);
    Out.TexCd = txcd;
    return Out;
}
struct gs2ps
{
	float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
	float2 bTexCd: TEXCOORD1;
	float3 col: TEXCOORD2;
};
[maxvertexcount(4)]
void GS(point vs2gs input[1], inout TriangleStream<gs2ps> gsout)
{
	gs2ps o = (gs2ps)0;
	vs2gs inp = input[0];
	float3 colin = coltex.SampleLevel(s0,inp.TexCd,0).rgb;
	float sizmap = saturate(sizemap.SampleLevel(s0,inp.TexCd,0));
	float dpth = depth.SampleLevel(s0,inp.TexCd,0);
	float2 asp=lerp(1,res.x/res,Aspect);
	
	if((length(colin)>epsilon) && (sizmap>sepsilon) && (sizmap<=1))
	{
		float2 asp=lerp(1,res.x/res,Aspect);
		
		float siz = min(sizmap * size,maxsize);
		o.col = colin;
		o.TexCd = inp.TexCd;
		o.pos.z = dpth;
		o.pos.w = 1;
		
		o.pos.xy = inp.pos.xy + float2(-1,1)*0.5*siz*asp;
		o.bTexCd = float2(0,0);
		gsout.Append(o);
		o.pos.xy = inp.pos.xy + float2(-1,-1)*0.5*siz*asp;
		o.bTexCd = float2(0,1);
		gsout.Append(o);
		o.pos.xy = inp.pos.xy + float2(1,1)*0.5*siz*asp;
		o.bTexCd = float2(1,0);
		gsout.Append(o);
		o.pos.xy = inp.pos.xy + float2(1,-1)*0.5*siz*asp;
		o.bTexCd = float2(1,1);
		gsout.Append(o);
		//gsout.Append(o);
		
		gsout.RestartStrip();
	}
}

float4 PS(gs2ps In) : SV_Target
{
	float4 col = 0;
	col.rgb = bokehtex.Sample(s0,In.bTexCd).rgb * In.col * colamount;
    return col;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





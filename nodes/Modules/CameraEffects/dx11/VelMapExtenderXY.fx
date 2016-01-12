//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

Texture2D velmap;
Texture2D velmask;

SamplerState s0
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerObj : register( b1 )
{
	float2 res = 256;
	float velocityepsilon = 0.01;
	float maskepsilon = 0.01;
	float Amount = 0.5;
	float maxextend = 0.3;
	bool Aspect <bool visible=false;string uiname="Keep Aspect Ratio";> = true;
	bool ConstantVelCol = true;
};

struct vs2gs
{
    float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
	bool mask: TEXCOORD1;
	float3 vel: COLOR0;
};

vs2gs VS(uint ix: SV_VertexID, uint iy: SV_InstanceID)
{
    vs2gs Out = (vs2gs)0;
	float2 txcd = float2(ix/res.x,iy/res.y);
    Out.pos  = float4((txcd.x-.5)*2,-(txcd.y-.5)*2,0,1);
    Out.TexCd = txcd;
	Out.vel = velmap.SampleLevel(s0,txcd,0).xyz;
	Out.mask = velmask.SampleLevel(s0,txcd,0).xyz>maskepsilon;
    return Out;
}
struct gs2ps
{
	float4 pos: SV_POSITION;
	float2 TexCd: TEXCOORD0;
	float3 vel: TEXCOORD2;
};
[maxvertexcount(3)]
void GS(point vs2gs input[1], inout LineStream<gs2ps> gsout)
{
	gs2ps o = (gs2ps)0;
	vs2gs inp = input[0];
	float3 colin = inp.vel;
    float3 vel = colin;
	vel *= Amount/2;
	vel = normalize(vel)*min(length(vel),maxextend);
	if(length(vel)>velocityepsilon && inp.mask)
	{
		float veltest = 0;
		float2 asp=lerp(1,res.x/res,Aspect);
		float2 newtxcd = ((inp.TexCd-.5)/asp+vel.xy*float2(1,-1))*asp+.5;
		if(ConstantVelCol)
		{
			veltest = max(.9999-length(vel)/ maxextend,0);
			o.pos = float4((newtxcd.x-.5)*2,-(newtxcd.y-.5)*2,veltest,1);
			o.TexCd = inp.TexCd;
			o.vel = colin;
		}
		else
		{
			float3 vvel = velmap.SampleLevel(s0,newtxcd,0).xyz;
			veltest = max(.9999-length(vvel)/ maxextend,0);
			o.pos = float4((newtxcd.x-.5)*2,-(newtxcd.y-.5)*2,veltest,1);
			o.TexCd = newtxcd;
			o.vel = vvel;
		}
		gsout.Append(o);
		
		veltest = max(.9999-length(vel)/ maxextend,0);
		o.pos = float4(inp.pos.xy,veltest,1);
		o.TexCd = inp.TexCd;
		o.vel = inp.vel;
		gsout.Append(o);
		
		newtxcd = ((inp.TexCd-.5)/asp-vel.xy*float2(1,-1))*asp+.5;
		
		if(ConstantVelCol)
		{
			veltest = max(.9999-length(vel)/ maxextend,0);
			o.pos = float4((newtxcd.x-.5)*2,-(newtxcd.y-.5)*2,veltest,1);
			o.TexCd = inp.TexCd;
			o.vel = colin;
		}
		else
		{
			float3 vvel = velmap.SampleLevel(s0,newtxcd,0).xyz;
			veltest = max(.9999-length(vvel)/ maxextend,0);
			o.pos = float4((newtxcd.x-.5)*2,-(newtxcd.y-.5)*2,veltest,1);
			o.TexCd = newtxcd;
			o.vel = vvel;
		}
		gsout.Append(o);
		
		//gsout.Append(o);
		gsout.RestartStrip();
	}
}

float4 PS(gs2ps In) : SV_Target
{
	float4 col = float4(In.vel,1);
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





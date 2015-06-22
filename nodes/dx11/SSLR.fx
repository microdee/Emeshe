
#include "../fxh/MRE.fxh"
#include "../fxh/Materials.fxh"

Texture2D ColorTex;

float2 R : TARGETSIZE;

cbuffer controls:register(b0){
	float2 EpsilonMul = float2(1, 4.15);
	float StepCount = 16;
	float FineStepCount = 16;
	float uvshapepow = 4;
	float uvfadepow = 4;
};

SamplerState s0 <string uiname="Sampler";>
{
    Filter=MIN_MAG_MIP_LINEAR;
    AddressU=Border;
    AddressV=Border;
	BorderColor=float4(0,0,0,0);
};

struct VS_IN
{
	float4 pos : POSITION;
	float4 uv : TEXCOORD0;

};

struct vs2ps
{
    float4 pos: SV_POSITION;
    float4 uv: TEXCOORD0;
};

vs2ps VS(VS_IN i)
{
    vs2ps Out = (vs2ps)0;
    Out.pos  = float4(i.pos.xyz*2, i.pos.w);
    Out.uv = i.uv;
    return Out;
}

float2 GetUV (float3 p)
{
	float4 trpos = mul(float4(p, 1), CamProj);
	float2 uv = trpos.xy / trpos.w;
	uv.y *= -1;
	return (uv+1) * 0.5;
}

struct RayData
{
	float3 vpos;
	float2 uv;
	float dist;
};

RayData RayCast(float3 OPos, float3 Dir, float RayL, float2 EpsMul)
{
	float cStepL = RayL/StepCount;
	float3 raypos = OPos;
	bool hit = false;
	float4 col = 0;
	
	RayData o = (RayData)0;
	
	for(float i=0; i<StepCount; i++)
	{
		raypos += Dir * cStepL;
		float2 cuv = GetUV(raypos);
		float3 cnorm = Normals.SampleLevel(s0, cuv, 0).xyz;
		float3 cpos = GetViewPos(s0, cuv);
		if(dot(cnorm, Dir) < 0)
		{
			float cdist = distance(cpos, raypos);
			if(cdist < cStepL * EpsMul.x)
			{
				raypos -= Dir * cStepL * 0.5;
				float fStepL = cStepL / FineStepCount;
				for(float i=0; i<StepCount; i++)
				{
					raypos += Dir * fStepL;
					float2 fuv = GetUV(raypos);
					float3 fnorm = Normals.SampleLevel(s0, fuv, 0).xyz;
					float3 fpos = GetViewPos(s0, fuv);
					if(dot(fnorm, Dir) < 0)
					{
						float fdist = distance(fpos, raypos);
						if(fdist < fStepL * EpsMul.y)
						{
							hit = true;
							o.vpos = raypos;
							o.uv = fuv;
							o.dist = distance(OPos, raypos);
							
							break;
						}
					}
				}
			}
			if(hit) break;
		}
	}
	return o;
}

struct PSOut
{
	float4 col : SV_Target;
	float depth : SV_Depth;
};

PSOut SSLR(float4 PosWVP:SV_POSITION,float2 uv:TEXCOORD0)
{
	PSOut o = (PSOut)0;
	float stencil = GetStencil(R, uv);
	uint matid = GetMatID(s0, uv);

	bool KnowReflect = KnowFeature(matid, MF_REFLECTION_SSLR);

	if((stencil > 0) && KnowReflect)
	{
		float3 vPos = GetViewPos(s0, uv);
		float3 onorm = Normals.Sample(s0,uv).xyz;
		float3 rrV = normalize(vPos);
		float3 R = reflect(rrV, onorm);

		float rayLength = GetFloat(matid, MF_REFLECTION_SSLR, MF_REFLECTION_SSLR_DISTANCE);
		float distblurpow = GetFloat(matid, MF_REFLECTION_SSLR, MF_REFLECTION_SSLR_DISTANCEBLURPOW);
		float distfadepow = GetFloat(matid, MF_REFLECTION_SSLR, MF_REFLECTION_SSLR_DISTANCEFADEPOW);
		float distclamp = GetFloat(matid, MF_REFLECTION_SSLR, MF_REFLECTION_SSLR_DISTANCEBLURTHRESHOLD);
		
	    RayData oray = RayCast(vPos, R, rayLength, EpsilonMul);
		
		float uvd = pow(pow(abs(oray.uv.x-.5), uvshapepow) + pow(abs(oray.uv.y-.5), uvshapepow), 1/uvshapepow);
		float fadeuv = saturate(1 - pow(uvd*2,uvfadepow));
		float fadedist = pow(saturate(1 - oray.dist/rayLength), distfadepow);
		//float fadedist = 1 - oray.dist/rayLength;
		
		float distout = pow(lerp(saturate((oray.dist-distclamp)/rayLength),1,oray.dist==0), distblurpow);
		
		o.col = ColorTex.SampleLevel(s0, oray.uv, 0);
		//o.col = ColorTex.SampleLevel(s0, uv, 0);
		//o.col.rgb *= fadeuv * fadedist;
		o.col.a = fadeuv * fadedist;
		//o.col.rgb *= o.col.a;
		o.depth = distout;
		if((oray.uv.x+oray.uv.y) == 0) o.col = 0;
	}
    return o;
}

technique11 sslr{
    pass P1
    {
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
    	SetPixelShader(CompileShader(ps_5_0,SSLR()));
    }
}
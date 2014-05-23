AppendStructuredBuffer<float2> Output : BACKBUFFER;
Texture2D Input;

cbuffer controls:register(b0){
	float2 R = 256;
	int lodlevel = 1;
	float threshold = 1;
};

SamplerState s0 <bool visible=false;string uiname="Sampler";> {Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};
[numthreads(1, 1, 1)]
void CSAppend( uint3 DTid : SV_DispatchThreadID )
{
	float4 c = Input.SampleLevel(s0,DTid.xy/R,lodlevel);
	float maxlightness = max(max(c.r,c.g),c.b);
	if(maxlightness>threshold) Output.Append((DTid.xy/R-.5)*2);
}

technique11 Coordinate
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSAppend() ) );
	}
}

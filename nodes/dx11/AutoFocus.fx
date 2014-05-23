RWStructuredBuffer<float> Output : BACKBUFFER;
StructuredBuffer<float2> FocusPoints;
Texture2D Input; //viewposition

cbuffer controls:register(b0){
	float2 R = 256;
	float2 sR = 20;
	float pc = 1;
	float Damper = 0;
	float epsilon = 0.001;
	float manualfocus = 1;
};

SamplerState s0 <bool visible=false;string uiname="Sampler";> {Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};
[numthreads(1, 1, 1)]
void CSAvg( uint3 DTid : SV_DispatchThreadID )
{
	float2 UV = float2(DTid.x,DTid.y)-sR/2;
	UV += FocusPoints[DTid.z]*R;
	float fd = Input[UV].z;
	if(abs(fd)<epsilon) fd = manualfocus;
	Output[0] += (fd/(sR.x*sR.y*pc))*(1-Damper)*100;
}
[numthreads(1, 1, 1)]
void CSClear( uint3 DTid : SV_DispatchThreadID )
{
	Output[0] = lerp(0,Output[0],Damper);
}


technique11 Focus
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSAvg() ) );
	}
}
technique11 Clear
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSClear() ) );
	}
}
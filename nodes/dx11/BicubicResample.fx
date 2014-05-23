//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

StructuredBuffer<float4> FPos;
StructuredBuffer<float4> FForwardCtrl;
StructuredBuffer<float4> FBackwardCtrl;
StructuredBuffer<float> FInput;
RWStructuredBuffer<float4> FOutput : BACKBUFFER;

[numthreads(1, 1, 1)]
void CS_Bezier( uint3 i : SV_DispatchThreadID)
{
	float blend = frac(FInput[i.x]);
	uint id = floor(FInput[i.x]);
	
	float4 lAB = lerp(FPos[id],FForwardCtrl[id],blend);
	float4 lBC = lerp(FForwardCtrl[id],FBackwardCtrl[id+1],blend);
	float4 lCD = lerp(FBackwardCtrl[id+1],FPos[id+1],blend);
	
	float4 lAB_BC = lerp(lAB,lBC,blend);
	float4 lBC_CD = lerp(lBC,lCD,blend);
	
	FOutput[i.x] = lerp(lAB_BC,lBC_CD,blend);
}

[numthreads(1, 1, 1)]
void CS_SplitToPos( uint3 i : SV_DispatchThreadID)
{
	FOutput[i.x] = FPos[i.x*3];
}
[numthreads(1, 1, 1)]
void CS_SplitToBackward( uint3 i : SV_DispatchThreadID)
{
	FOutput[i.x] = FPos[max(i.x*3-1,0)];
}
[numthreads(1, 1, 1)]
void CS_SplitToForward( uint3 i : SV_DispatchThreadID)
{
	FOutput[i.x] = FPos[i.x*3+1];
}


technique11 TBezier
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Bezier() ) );
	}
}
technique11 TSplitToPos
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_SplitToPos() ) );
	}
}
technique11 TSplitToBackward
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_SplitToBackward() ) );
	}
}
technique11 TSplitToForward
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_SplitToForward() ) );
	}
}
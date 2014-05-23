RWStructuredBuffer<float4> Output : BACKBUFFER;

[numthreads(1, 1, 1)]
void CSReset( uint3 DTid : SV_DispatchThreadID )
{
	Output[DTid.x].xy /= Output[DTid.x].z;
}

technique11 Clear
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSReset() ) );
	}
}

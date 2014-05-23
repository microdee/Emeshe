//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

// stride : 96
struct PreSplineData {
	float3 Position;
	float3 Forward;
	float3 Backward;
	float4 Custom;
	float4 CForward;
	float4 CBackward;
	uint elementid;
	uint curveid;
	uint elementcount;
};

// stride : 40
struct SplineData {
	float3 Position;
	float4 Custom;
	uint elementid;
	uint curveid;
	uint elementcount;
};

StructuredBuffer<SplineData> BInput;
RWStructuredBuffer<float4> BOutput : BACKBUFFER;

cbuffer controls:register(b0){
	float NeighbourRange = 1;
	float Count = 1;
};

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(1, 1, 1)]
void CS_Bezier(csin input)
{
    float3 Before = BInput[max(input.GID.x-NeighbourRange,0)].Position;
    float3 After  = BInput[min(input.GID.x+NeighbourRange,Count)].Position;
    float3 direction = Before - After;
    BOutput[input.GID.x] = float4(normalize(direction),length(direction));
}

technique11 TBezier
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Bezier() ) );
	}
}
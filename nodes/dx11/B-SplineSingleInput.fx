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

cbuffer controls:register(b0){
	float HandleLengthMod = 0;
};

StructuredBuffer<float3> BPosition;
StructuredBuffer<float4> BCustom;
StructuredBuffer<float2> BCurveIdElementCount;
RWStructuredBuffer<PreSplineData> BOutput : BACKBUFFER;

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(1, 1, 1)]
void CS_Bezier(csin input)
{
	uint id = input.GID.x;
	BOutput[id].Position = BPosition[id*3];
	float3 bwdiff = BPosition[max(id*3-1,0)]-BPosition[id*3];
	float3 bwmod = normalize(bwdiff)*length(bwdiff)*HandleLengthMod;
	BOutput[id].Backward = BPosition[max(id*3-1,0)]+bwmod;
	float3 fwdiff = BPosition[id*3+1]-BPosition[id*3];
	float3 fwmod = normalize(fwdiff)*length(fwdiff)*HandleLengthMod;
	BOutput[id].Forward = BPosition[id*3+1]+fwmod;
	
	BOutput[id].Custom = BCustom[id*3];
	BOutput[id].CBackward = BCustom[max(id*3-1,0)];
	BOutput[id].CForward = BCustom[id*3+1];
	
	bool begincurve = (id == 0) || (BCurveIdElementCount[id].x != BCurveIdElementCount[max(id-1,0)].x);
	bool endcurve = BCurveIdElementCount[id].x != BCurveIdElementCount[id+1].x;
	
	if(begincurve) BOutput[id].elementid = 0;
	else BOutput[id].elementid = BOutput[id-1].elementid + 1;
	
	BOutput[id].elementcount = BCurveIdElementCount[id].y;
	BOutput[id].curveid = BCurveIdElementCount[id].x;
}

technique11 TBezier
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Bezier() ) );
	}
}
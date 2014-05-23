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

StructuredBuffer<PreSplineData> BInput;
RWStructuredBuffer<SplineData> BOutput : BACKBUFFER;

cbuffer controls:register(b0){
	float AllInputCount = 2;
	float AllOutputCount = 2;
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
	// prepare ID's and blend
	float inputID = input.GID.x * (AllInputCount/AllOutputCount);
	float blend = frac(inputID);
	uint inid = floor(inputID);
	
	uint inelementcount = BInput[inid].elementcount;
	uint inelementid = BInput[inid].elementid;
	
	uint incurveid = BInput[inid].curveid;
	
	bool begincurve = (input.GID.x == 0) || (BInput[inid].curveid != BOutput[max(input.GID.x-1,0)].curveid);
	bool endcurve = (input.GID.x == AllInputCount) || (BInput[inid].curveid != BInput[min(inid+1,AllInputCount)].curveid);
	
	uint nextid = (endcurve) ? inid : (inid+1);
	//uint nextid = inid+1;
	//uint previd = (begincurve) ? inid : (inid-1);
	
	// position
	float3 lAB = lerp(BInput[inid].Position, BInput[inid].Forward, blend);
	float3 lBC = lerp(BInput[inid].Forward, BInput[nextid].Backward, blend);
	float3 lCD = lerp(BInput[nextid].Backward, BInput[nextid].Position, blend);
	
	float3 lAB_BC = lerp(lAB,lBC,blend);
	float3 lBC_CD = lerp(lBC,lCD,blend);
	float3 outpos = lerp(lAB_BC,lBC_CD,blend);
	BOutput[input.GID.x].Position = outpos;
	
	// custom
	float4 clAB = lerp(BInput[inid].Custom, BInput[inid].CForward, blend);
	float4 clBC = lerp(BInput[inid].CForward, BInput[nextid].CBackward, blend);
	float4 clCD = lerp(BInput[nextid].CBackward, BInput[nextid].Custom, blend);
	
	float4 clAB_BC = lerp(clAB,clBC,blend);
	float4 clBC_CD = lerp(clBC,clCD,blend);
	float4 outcustom = lerp(clAB_BC,clBC_CD,blend);
	BOutput[input.GID.x].Custom = outcustom;
	
	//Out ID's
	uint outelementcount = inelementcount * (AllOutputCount/AllInputCount);
	if(begincurve) BOutput[input.GID.x].elementid = 0;
	else BOutput[input.GID.x].elementid = BOutput[input.GID.x-1].elementid + 1;
	BOutput[input.GID.x].elementcount = outelementcount;
	BOutput[input.GID.x].curveid = incurveid;
}

technique11 TBezier
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS_Bezier() ) );
	}
}


#include "../../../mp.fxh/InstanceParams.fxh"

RWStructuredBuffer<InstanceParams> BOutput : BACKBUFFER;

StructuredBuffer<float> Values;

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(1, 1, 1)]
void CSPoint(csin input)
{
	uint ii = input.DTID.x * 58;
	uint ib = input.DTID.x;

	uint ij = 0;
	[unroll]
	for (uint i = 0; i<4; i++)
	{
		[unroll]
		for (uint j = 0; j<4; j++)
		{
			BOutput[ib].tW[i][j] = Values[ii + i * 4 + j];
			ij++;
		}
	}

	ij = 0;
	[unroll]
	for (uint i = 0; i<4; i++)
	{
		[unroll]
		for (uint j = 0; j<4; j++)
		{
			BOutput[ib].ptW[i][j] = Values[ii + i * 4 + j + 16];
			ij++;
		}
	}
	ij = 0;
	[unroll]
	for (uint i = 0; i<4; i++)
	{
		[unroll]
		for (uint j = 0; j<4; j++)
		{
			BOutput[ib].tTex[i][j] = Values[ii + i * 4 + j + 32];
			ij++;
		}
	}
	BOutput[ib].DiffCol.x = Values[ii + 48];
	BOutput[ib].DiffCol.y = Values[ii + 49];
	BOutput[ib].DiffCol.z = Values[ii + 50];
	BOutput[ib].DiffCol.w = Values[ii + 51];
	BOutput[ib].DiffAmount = Values[ii + 52];
	BOutput[ib].VelocityGain = Values[ii + 53];
	BOutput[ib].BumpAmount = Values[ii + 54];
	BOutput[ib].MatID = Values[ii + 55];
	BOutput[ib].ObjID0 = Values[ii + 56];
	BOutput[ib].ObjID1 = Values[ii + 57];
}
technique11 Fill { pass P0{SetComputeShader( CompileShader( cs_5_0, CSPoint() ) );} }
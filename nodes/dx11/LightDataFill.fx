
#if !defined(LIGHTSTRUCTS_FXH)
#include "../fxh/LightStructs.fxh"
#endif

#define POINT 0
#define SPOT 1
#define SUN 2

#if !defined(LIGHTTYPE)
	#define LIGHTTYPE 0
#endif

#if LIGHTTYPE == POINT
	RWStructuredBuffer<PointLightProp> BOutput : BACKBUFFER;
#elif LIGHTTYPE == SPOT
	RWStructuredBuffer<SpotLightProp> BOutput : BACKBUFFER;
#else
	RWStructuredBuffer<SunLightProp> BOutput : BACKBUFFER;
#endif

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
	#if LIGHTTYPE == POINT
		uint ii = input.DTID.x * 15;
		uint ib = input.DTID.x;
	
		BOutput[ib].LightCol.x = Values[ii + 0];
		BOutput[ib].LightCol.y = Values[ii + 1];
		BOutput[ib].LightCol.z = Values[ii + 2];
		BOutput[ib].LightCol.w = Values[ii + 3];
		BOutput[ib].Position.x = Values[ii + 4];
		BOutput[ib].Position.y = Values[ii + 5];
		BOutput[ib].Position.z = Values[ii + 6];
		BOutput[ib].ShadowMapCenter.x = Values[ii + 7];
		BOutput[ib].ShadowMapCenter.y = Values[ii + 8];
		BOutput[ib].ShadowMapCenter.z = Values[ii + 9];
		BOutput[ib].Range = Values[ii + 10];
		BOutput[ib].RangePow = Values[ii + 11];
		BOutput[ib].LightStrength = Values[ii + 12];
		BOutput[ib].KnowShadows = Values[ii + 13];
		BOutput[ib].Penumbra = Values[ii + 14];
	#endif
}
technique11 Point { pass P0{SetComputeShader( CompileShader( cs_5_0, CSPoint() ) );} }


[numthreads(1, 1, 1)]
void CSSpot(csin input)
{
	#if LIGHTTYPE == SPOT
		uint ii = input.DTID.x * 45;
		uint ib = input.DTID.x;
	
		uint ij = 0;
		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				BOutput[ib].lProjection[i][j] = Values[ii + i*4 + j];
				ij++;
			}
		}
	
		ij = 0;
		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				BOutput[ib].lView[i][j] = Values[ii + i*4 + j + 16];
				ij++;
			}
		}
	
		BOutput[ib].LightCol.x = Values[ii + 32];
		BOutput[ib].LightCol.y = Values[ii + 33];
		BOutput[ib].LightCol.z = Values[ii + 34];
		BOutput[ib].LightCol.w = Values[ii + 35];
		BOutput[ib].Position.x = Values[ii + 36];
		BOutput[ib].Position.y = Values[ii + 37];
		BOutput[ib].Position.z = Values[ii + 38];
		BOutput[ib].Range = Values[ii + 39];
		BOutput[ib].RangePow = Values[ii + 40];
		BOutput[ib].LightStrength = Values[ii + 41];
		BOutput[ib].TexID = Values[ii + 42];
		BOutput[ib].KnowShadows = Values[ii + 43];
		BOutput[ib].Penumbra = Values[ii + 44];
	#endif
}
technique11 Spot { pass P0{SetComputeShader( CompileShader( cs_5_0, CSSpot() ) );} }

[numthreads(1, 1, 1)]
void CSSun(csin input)
{
	#if LIGHTTYPE == SUN
		uint ii = input.DTID.x * 26;
		uint ib = input.DTID.x;
	
		uint ij = 0;
		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				BOutput[ib].ShadowMapView[i][j] = Values[ii + i*4 + j];
				ij++;
			}
		}

		BOutput[ib].LightCol.x = Values[ii + 16];
		BOutput[ib].LightCol.y = Values[ii + 17];
		BOutput[ib].LightCol.z = Values[ii + 18];
		BOutput[ib].LightCol.w = Values[ii + 19];
		BOutput[ib].Direction.x = Values[ii + 20];
		BOutput[ib].Direction.y = Values[ii + 21];
		BOutput[ib].Direction.z = Values[ii + 22];
		BOutput[ib].LightStrength = Values[ii + 23];
		BOutput[ib].KnowShadows = Values[ii + 24];
		BOutput[ib].Penumbra = Values[ii + 25];
	#endif
}
technique11 Sun { pass P0{SetComputeShader( CompileShader( cs_5_0, CSSun() ) );} }
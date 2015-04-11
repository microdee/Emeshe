#define MATERIALS_FXH 1

#if !defined(MATERIALFEATURES_FXH)
#include "../fxh/MaterialFeatures.fxh"
#endif

// Resources:
#define MF_FLAGSIZE 32

struct MaterialMeta
{
	#if MF_FLAGSIZE == 64
		uint2 Flags; // Features
	#elif MF_FLAGSIZE == 96
		uint3 Flags;
	#elif MF_FLAGSIZE == 128
		uint4 Flags;
	#else
		uint Flags;
	#endif
	uint Address; // Where data starts in MaterialData buffer
	uint Size; // Actual size
};
StructuredBuffer<MaterialMeta> MatMeta : MF_MATERIALMETA;

// Count = MF_FLAGSIZE * MaterialCount
// Per-Material Feature offset in MaterialData buffer in bitwise order
StructuredBuffer<uint> FeatureOffset : MF_FEATUREOFFSET;

// Get parameter by
// MaterialMeta[MatID].Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID] + ParamOffset
StructuredBuffer<float> MaterialData : MF_MATERIALDATA;

// Feature methods
bool CheckFeature(uint Features, uint2 Filter)
{
	return (Features & Filter.x) == Filter.x;
}
/*
bool CheckFeature(uint2 Features, uint2 Filter)
{
	bool p0 = (Features.x & Filter.x) == Filter.x;
	bool p1 = (Features.y & Filter.y) == Filter.y;
	return p0 || p1;
}
bool CheckFeature(uint3 Features, uint3 Filter)
{
	bool p0 = (Features.x & Filter.x) == Filter.x;
	bool p1 = (Features.y & Filter.y) == Filter.y;
	bool p2 = (Features.z & Filter.z) == Filter.z;
	return p0 || p1 || p2;
}
bool CheckFeature(uint4 Features, uint4 Filter)
{
	bool p0 = (Features.x & Filter.x) == Filter.x;
	bool p1 = (Features.y & Filter.y) == Filter.y;
	bool p2 = (Features.z & Filter.z) == Filter.z;
	bool p3 = (Features.w & Filter.w) == Filter.w;
	return p0 || p1 || p2 || p3;
}
*/
bool KnowFeature(uint MatID, uint2 Filter)
{
	return CheckFeature(MatMeta[MatID].Flags, Filter);
}
/*
bool KnowFeature(uint MatID, uint2 Filter)
{
	return CheckFeature(MatMeta[MatID].Flags, Filter);
}
bool KnowFeature(uint MatID, uint3 Filter)
{
	return CheckFeature(MatMeta[MatID].Flags, Filter);
}
bool KnowFeature(uint MatID, uint4 Filter)
{
	return CheckFeature(MatMeta[MatID].Flags, Filter);
}
*/
/*
#if MF_FLAGSIZE == 64
	uint2 FeatureFlag(uint FeatureID)
	{
		uint2 ret = 0;
		if(FeatureID < 32)
			ret.x = pow(2, FeatureID);
		else
			ret.y = pow(2, FeatureID-32);
		return ret;
	}
#elif MF_FLAGSIZE == 96
	uint3 FeatureFlag(uint FeatureID)
	{
		uint3 ret = 0;
		if(FeatureID < 32)
			ret.x = pow(2, FeatureID);
		else if(FeatureID < 64)
			ret.y = pow(2, FeatureID-32);
		else
			ret.z = pow(2, FeatureID-64);
		return ret;
	}
#elif MF_FLAGSIZE == 128
	uint4 FeatureFlag(uint FeatureID)
	{
		uint4 ret = 0;
		if(FeatureID < 32)
			ret.x = pow(2, FeatureID);
		else if(FeatureID < 64)
			ret.y = pow(2, FeatureID-32);
		else if(FeatureID < 96)
			ret.y = pow(2, FeatureID-64);
		else
			ret.z = pow(2, FeatureID-96);
		return ret;
	}
#else
	uint FeatureFlag(uint FeatureID)
	{
		return pow(2, FeatureID);
	}
#endif

uint FeatureID(uint FeatureFlag)
{
	return log2(FeatureFlag) + 0;
}
uint FeatureID(uint2 FeatureFlag)
{
	if(FeatureFlag.x > 0)
		return log2(FeatureFlag.x) + 1;
	else
		return log2(FeatureFlag.y) + 33;
}
uint FeatureID(uint3 FeatureFlag)
{
	if(FeatureFlag.x > 0)
		return log2(FeatureFlag.x) + 1;
	else if(FeatureFlag.y > 0)
		return log2(FeatureFlag.y) + 33;
	else
		return log2(FeatureFlag.z) + 65;
}
uint FeatureID(uint4 FeatureFlag)
{
	if(FeatureFlag.x > 0)
		return log2(FeatureFlag.x) + 1;
	else if(FeatureFlag.y > 0)
		return log2(FeatureFlag.y) + 33;
	else if(FeatureFlag.z > 0)
		return log2(FeatureFlag.z) + 65;
	else
		return log2(FeatureFlag.w) + 97;
}
*/

// Get Parameters
/*
#if MF_FLAGSIZE == 64
	float GetFloat(uint MatID, uint2 Feature, uint ParamOffset)
	{
		MaterialMeta mp = MatMeta[MatID];
		uint pi = mp.Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID(Feature)];
		return MaterialData[pi + ParamOffset];
	}
	float2 GetFloat2(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float2 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		return ret;
	}
	float3 GetFloat3(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float3 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		return ret;
	}
	float4 GetFloat4(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float4 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		ret.w = GetFloat(MatID, Feature, ParamOffset + 3);
		return ret;
	}
	float4x4 GetFloat4x4(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float4x4 ret = 0;
		uint ij = 0;

		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				ret[i][j] = GetFloat(MatID, Feature, ParamOffset + ij);
				ij++;
			}
		}
		return ret;
	}
#elif MF_FLAGSIZE == 96
	float GetFloat(uint MatID, uint3 Feature, uint ParamOffset)
	{
		MaterialMeta mp = MatMeta[MatID];
		uint pi = mp.Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID(Feature)];
		return MaterialData[pi + ParamOffset];
	}
	float2 GetFloat2(uint MatID, uint3 Feature, uint ParamOffset)
	{
		float2 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		return ret;
	}
	float3 GetFloat3(uint MatID, uint3 Feature, uint ParamOffset)
	{
		float3 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		return ret;
	}
	float4 GetFloat4(uint MatID, uint3 Feature, uint ParamOffset)
	{
		float4 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		ret.w = GetFloat(MatID, Feature, ParamOffset + 3);
		return ret;
	}
	float4x4 GetFloat4x4(uint MatID, uint3 Feature, uint ParamOffset)
	{
		float4x4 ret = 0;
		uint ij = 0;

		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				ret[i][j] = GetFloat(MatID, Feature, ParamOffset + ij);
				ij++;
			}
		}
		return ret;
	}
#elif MF_FLAGSIZE == 128
	float GetFloat(uint MatID, uint4 Feature, uint ParamOffset)
	{
		MaterialMeta mp = MatMeta[MatID];
		uint pi = mp.Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID(Feature)];
		return MaterialData[pi + ParamOffset];
	}
	float2 GetFloat2(uint MatID, uint4 Feature, uint ParamOffset)
	{
		float2 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		return ret;
	}
	float3 GetFloat3(uint MatID, uint4 Feature, uint ParamOffset)
	{
		float3 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		return ret;
	}
	float4 GetFloat4(uint MatID, uint4 Feature, uint ParamOffset)
	{
		float4 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		ret.w = GetFloat(MatID, Feature, ParamOffset + 3);
		return ret;
	}
	float4x4 GetFloat4x4(uint MatID, uint4 Feature, uint ParamOffset)
	{
		float4x4 ret = 0;
		uint ij = 0;

		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				ret[i][j] = GetFloat(MatID, Feature, ParamOffset + ij);
				ij++;
			}
		}
		return ret;
	}
#else
*/
	float GetFloat(uint MatID, uint2 Feature, uint ParamOffset)
	{
		MaterialMeta mp = MatMeta[MatID];
		uint pi = mp.Address + FeatureOffset[MatID * MF_FLAGSIZE + Feature.y];
		return MaterialData[pi + ParamOffset];
	}
	float2 GetFloat2(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float2 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		return ret;
	}
	float3 GetFloat3(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float3 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		return ret;
	}
	float4 GetFloat4(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float4 ret = 0;
		ret.x = GetFloat(MatID, Feature, ParamOffset);
		ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
		ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
		ret.w = GetFloat(MatID, Feature, ParamOffset + 3);
		return ret;
	}
	float4x4 GetFloat4x4(uint MatID, uint2 Feature, uint ParamOffset)
	{
		float4x4 ret = 0;
		uint ij = 0;

		[unroll]
		for(uint i = 0; i<4; i++)
		{
			[unroll]
			for(uint j = 0; j<4; j++)
			{
				ret[i][j] = GetFloat(MatID, Feature, ParamOffset + ij);
				ij++;
			}
		}
		return ret;
	}
//#endif // get parameters
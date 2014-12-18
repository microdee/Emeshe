#define MATERIALS_FXH 1

// Material Features
#define MF_LIGHTING_AMBIENT uint2(0x1, 0)
#define MF_LIGHTING_PHONG uint2(0x2, 1)
#define MF_LIGHTING_PHONG_SPECULARMAP uint2(0x4, 2)
#define MF_LIGHTING_COOKTORRANCE uint2(0x8, 3)
#define MF_LIGHTING_COOKTORRANCE_BAKED uint2(0x10, 4)
#define MF_LIGHTING_COOKTORRANCE_GLOSSMAP uint2(0x20, 5)
#define MF_LIGHTING_COMPOSITE uint2(0x40, 6)
#define MF_LIGHTING_FAKESSS uint2(0x80, 7)
#define MF_LIGHTING_FAKESSS_MAP uint2(0x100, 8)
#define MF_LIGHTING_FAKERIMLIGHT uint2(0x200, 9)
#define MF_LIGHTING_FAKERIMLIGHT_MAP uint2(0x400, 10)
#define MF_LIGHTING_MATCAP uint2(0x800, 11)
#define MF_LIGHTING_EMISSION uint2(0x1000, 12)
#define MF_LIGHTING_EMISSION_MAP uint2(0x2000, 13)
#define MF_LIGHTING_SHADOWS uint2(0x4000, 14)
#define MF_GI_SSAO uint2(0x8000, 15)
#define MF_GI_CSSGI uint2(0x10000, 16)
#define MF_GI_SSSSS uint2(0x20000, 17)
#define MF_GI_SSSSS_MAP uint2(0x40000, 18)
#define MF_REFLECTION_SPHEREMAP uint2(0x80000, 19)
#define MF_REFLECTION_SSLR uint2(0x100000, 20)
#define MF_REFLECTION_MAP uint2(0x200000, 21)
#define MF_REFRACTION_SPHEREMAP uint2(0x400000, 22)
#define MF_REFRACTION_SSLR uint2(0x800000, 23)
#define MF_REFRACTION_MAP uint2(0x1000000, 24)

// Feature Parameters
#define MF_LIGHTING_AMBIENT_AMBIENTCOLOR_SIZE 3
#define MF_LIGHTING_AMBIENT_AMBIENTCOLOR 0
#define MF_LIGHTING_PHONG_SPECULARCOLOR_SIZE 3
#define MF_LIGHTING_PHONG_SPECULARCOLOR 0
#define MF_LIGHTING_PHONG_SPECULARPOWER_SIZE 1
#define MF_LIGHTING_PHONG_SPECULARPOWER 3
#define MF_LIGHTING_PHONG_SPECULARSTRENGTH_SIZE 1
#define MF_LIGHTING_PHONG_SPECULARSTRENGTH 4
#define MF_LIGHTING_PHONG_ATTENUATION_SIZE 3
#define MF_LIGHTING_PHONG_ATTENUATION 5
#define MF_LIGHTING_PHONG_SPECULARMAP_MAPID_SIZE 1
#define MF_LIGHTING_PHONG_SPECULARMAP_MAPID 0
#define MF_LIGHTING_COOKTORRANCE_SPECULARCOLOR_SIZE 3
#define MF_LIGHTING_COOKTORRANCE_SPECULARCOLOR 0
#define MF_LIGHTING_COOKTORRANCE_SPECULARSTRENGTH_SIZE 1
#define MF_LIGHTING_COOKTORRANCE_SPECULARSTRENGTH 3
#define MF_LIGHTING_COOKTORRANCE_ROUGHNESS_SIZE 1
#define MF_LIGHTING_COOKTORRANCE_ROUGHNESS 4
#define MF_LIGHTING_COOKTORRANCE_REFLECTANCE_SIZE 1
#define MF_LIGHTING_COOKTORRANCE_REFLECTANCE 5
#define MF_LIGHTING_COOKTORRANCE_BAKED_BAKEDID_SIZE 1
#define MF_LIGHTING_COOKTORRANCE_BAKED_BAKEDID 0
#define MF_LIGHTING_COOKTORRANCE_GLOSSMAP_MAPID_SIZE 1
#define MF_LIGHTING_COOKTORRANCE_GLOSSMAP_MAPID 0
#define MF_LIGHTING_COMPOSITE_AMBIENT_SIZE 1
#define MF_LIGHTING_COMPOSITE_AMBIENT 0
#define MF_LIGHTING_COMPOSITE_DIFFUSE_SIZE 1
#define MF_LIGHTING_COMPOSITE_DIFFUSE 1
#define MF_LIGHTING_COMPOSITE_SPECULAR_SIZE 1
#define MF_LIGHTING_COMPOSITE_SPECULAR 2
#define MF_LIGHTING_COMPOSITE_SPECMUL_SIZE 1
#define MF_LIGHTING_COMPOSITE_SPECMUL 3
#define MF_LIGHTING_COMPOSITE_SSS_SIZE 1
#define MF_LIGHTING_COMPOSITE_SSS 4
#define MF_LIGHTING_COMPOSITE_SSSMUL_SIZE 1
#define MF_LIGHTING_COMPOSITE_SSSMUL 5
#define MF_LIGHTING_COMPOSITE_RIM_SIZE 1
#define MF_LIGHTING_COMPOSITE_RIM 6
#define MF_LIGHTING_COMPOSITE_RIMMUL_SIZE 1
#define MF_LIGHTING_COMPOSITE_RIMMUL 7
#define MF_LIGHTING_FAKESSS_STRENGTH_SIZE 1
#define MF_LIGHTING_FAKESSS_STRENGTH 0
#define MF_LIGHTING_FAKESSS_POWER_SIZE 1
#define MF_LIGHTING_FAKESSS_POWER 1
#define MF_LIGHTING_FAKESSS_THICKNESS_SIZE 1
#define MF_LIGHTING_FAKESSS_THICKNESS 2
#define MF_LIGHTING_FAKESSS_COEFFICIENT_SIZE 3
#define MF_LIGHTING_FAKESSS_COEFFICIENT 3
#define MF_LIGHTING_FAKESSS_MAP_MAPID_SIZE 1
#define MF_LIGHTING_FAKESSS_MAP_MAPID 0
#define MF_LIGHTING_FAKERIMLIGHT_STRENGTH_SIZE 1
#define MF_LIGHTING_FAKERIMLIGHT_STRENGTH 0
#define MF_LIGHTING_FAKERIMLIGHT_POWER_SIZE 1
#define MF_LIGHTING_FAKERIMLIGHT_POWER 1
#define MF_LIGHTING_FAKERIMLIGHT_MAP_MAPID_SIZE 1
#define MF_LIGHTING_FAKERIMLIGHT_MAP_MAPID 0
#define MF_LIGHTING_MATCAP_MAPID_SIZE 1
#define MF_LIGHTING_MATCAP_MAPID 0
#define MF_LIGHTING_MATCAP_TRANSFORM_SIZE 16
#define MF_LIGHTING_MATCAP_TRANSFORM 1
#define MF_LIGHTING_EMISSION_COLOR_SIZE 3
#define MF_LIGHTING_EMISSION_COLOR 0
#define MF_LIGHTING_EMISSION_STRENGTH_SIZE 1
#define MF_LIGHTING_EMISSION_STRENGTH 3
#define MF_LIGHTING_EMISSION_MAP_MAPID_SIZE 1
#define MF_LIGHTING_EMISSION_MAP_MAPID 0
#define MF_LIGHTING_SHADOWS_BLEND_SIZE 1
#define MF_LIGHTING_SHADOWS_BLEND 0
#define MF_GI_SSAO_AMOUNTMUL_SIZE 1
#define MF_GI_SSAO_AMOUNTMUL 0
#define MF_GI_CSSGI_AMOUNTMUL_SIZE 1
#define MF_GI_CSSGI_AMOUNTMUL 0
#define MF_GI_CSSGI_RADIUSMUL_SIZE 1
#define MF_GI_CSSGI_RADIUSMUL 1
#define MF_GI_SSSSS_AMOUNTMUL_SIZE 1
#define MF_GI_SSSSS_AMOUNTMUL 0
#define MF_GI_SSSSS_RADIUSMUL_SIZE 1
#define MF_GI_SSSSS_RADIUSMUL 1
#define MF_GI_SSSSS_MAP_MAPID_SIZE 1
#define MF_GI_SSSSS_MAP_MAPID 0
#define MF_REFLECTION_SPHEREMAP_STRENGTH_SIZE 1
#define MF_REFLECTION_SPHEREMAP_STRENGTH 0
#define MF_REFLECTION_SPHEREMAP_FRESNEL_SIZE 1
#define MF_REFLECTION_SPHEREMAP_FRESNEL 1
#define MF_REFLECTION_SPHEREMAP_ENVID_SIZE 1
#define MF_REFLECTION_SPHEREMAP_ENVID 2
#define MF_REFLECTION_SSLR_STRENGTH_SIZE 1
#define MF_REFLECTION_SSLR_STRENGTH 0
#define MF_REFLECTION_SSLR_FRESNEL_SIZE 1
#define MF_REFLECTION_SSLR_FRESNEL 1
#define MF_REFLECTION_SSLR_BLUR_SIZE 1
#define MF_REFLECTION_SSLR_BLUR 2
#define MF_REFLECTION_SSLR_DISTANCE_SIZE 1
#define MF_REFLECTION_SSLR_DISTANCE 3
#define MF_REFLECTION_MAP_MAPID_SIZE 1
#define MF_REFLECTION_MAP_MAPID 0
#define MF_REFRACTION_SPHEREMAP_STRENGTH_SIZE 1
#define MF_REFRACTION_SPHEREMAP_STRENGTH 0
#define MF_REFRACTION_SPHEREMAP_FRESNEL_SIZE 1
#define MF_REFRACTION_SPHEREMAP_FRESNEL 1
#define MF_REFRACTION_SPHEREMAP_ENVID_SIZE 1
#define MF_REFRACTION_SPHEREMAP_ENVID 2
#define MF_REFRACTION_SSLR_STRENGTH_SIZE 1
#define MF_REFRACTION_SSLR_STRENGTH 0
#define MF_REFRACTION_SSLR_FRESNEL_SIZE 1
#define MF_REFRACTION_SSLR_FRESNEL 1
#define MF_REFRACTION_SSLR_BLUR_SIZE 1
#define MF_REFRACTION_SSLR_BLUR 2
#define MF_REFRACTION_MAP_MAPID_SIZE 1
#define MF_REFRACTION_MAP_MAPID 0

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
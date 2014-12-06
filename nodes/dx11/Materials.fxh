
// Material Features
#define MF_LIGHTING_AMBIENT 0x1
#define MF_LIGHTING_PHONG 0x2
#define MF_LIGHTING_PHONG_SPECULARMAP 0x4
#define MF_LIGHTING_COOKTORRANCE 0x8
#define MF_LIGHTING_COOKTORRANCE_BAKED 0x10
#define MF_LIGHTING_COOKTORRANCE_GLOSSMAP 0x20
#define MF_LIGHTING_FAKESSS 0x40
#define MF_LIGHTING_FAKESSS_MAP 0x80
#define MF_LIGHTING_FAKERIMLIGHT 0x100
#define MF_LIGHTING_MATCAP 0x200
#define MF_LIGHTING_EMISSION 0x400
#define MF_LIGHTING_EMISSION_MAP 0x800
#define MF_LIGHTING_SHADOWS 0x1000
#define MF_GI_SSAO 0x2000
#define MF_GI_CSSGI 0x4000
#define MF_GI_SSSSS 0x8000
#define MF_GI_SSSSS_MAP 0x10000
#define MF_REFLECTION_SPHEREMAP 0x20000
#define MF_REFLECTION_SSLR 0x40000
#define MF_REFLECTION_MAP 0x80000
#define MF_REFRACTION_SPHEREMAP 0x100000
#define MF_REFRACTION_SSLR 0x200000
#define MF_REFRACTION_MAP 0x400000

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
	uint Flags; // Features (uint2 if feature count will exceed 32)
	uint Address; // Where data starts in MaterialData buffer
	uint Size; // Actual size
}
StructuredBuffer<MaterialMeta> MatMeta : MF_MATERIALMETA

// Count = MF_FLAGSIZE * MaterialCount
// Per-Material Feature offset in MaterialData buffer in bitwise order
StructuredBuffer<uint> FeatureOffset : MF_FEATUREOFFSET

// Get parameter by
// MaterialMeta[MatID].Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID] + ParamOffset
StructuredBuffer<float> MaterialData : MF_MATERIALDATA

// Feature methods
bool CheckFeature(uint Features, uint Filter)
{
	return (Features & Filter) == Filter;
}
bool KnowFeature(uint MatID, uint Filter)
{
	return CheckFeature(matprop[MatID].Flags, Filter);
}
bool CheckFeature(uint2 Features, uint2 Filter)
{
	bool p1 = (Features.x & Filter.x) == Filter.x;
	bool p2 = (Features.y & Filter.y) == Filter.y;
	return p1 || p2;
}
uint FeatureFlag(uint FeatureID)
{
	return pow(2, FeatureID);
}
uint FeatureID(uint FeatureFlag)
{
	return log(FeatureFlag, 2);
}

// Get Parameters
float GetFloat(uint MatID, uint Feature, uint ParamOffset)
{
	MaterialMeta mp = MatMeta[MatID]
	uint pi = mp.Address + FeatureOffset[MatID * MF_FLAGSIZE + FeatureID(Feature)];
	return MaterialData[pi + ParamOffset];
}
float2 GetFloat2(uint MatID, uint Feature, uint ParamOffset)
{
	float2 ret = 0;
	ret.x = GetFloat(MatID, Feature, ParamOffset);
	ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
	return ret;
}
float3 GetFloat3(uint MatID, uint Feature, uint ParamOffset)
{
	float3 ret = 0;
	ret.x = GetFloat(MatID, Feature, ParamOffset);
	ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
	ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
	return ret;
}
float4 GetFloat4(uint MatID, uint Feature, uint ParamOffset)
{
	float4 ret = 0;
	ret.x = GetFloat(MatID, Feature, ParamOffset);
	ret.y = GetFloat(MatID, Feature, ParamOffset + 1);
	ret.z = GetFloat(MatID, Feature, ParamOffset + 2);
	ret.w = GetFloat(MatID, Feature, ParamOffset + 3);
	return ret;
}
float4x4 GetFloat4x4(uint MatID, uint Feature, uint ParamOffset)
{
	float4x4 ret = 0;
	uint ij = 0;

	[unroll]
	for(uint i = 0; i<4; i++)
	{
		[unroll]
		for(uint j = 0; j<4; j++)
		{
			ret[i][j] = GetFloat(MatID, Feature, ParamOffset + ij)
			ij++;
		}
	}
	return ret;
}
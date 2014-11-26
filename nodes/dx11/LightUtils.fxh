#include "pows.fxh"
#include "Materials.fxh"

struct PointLightProp
{
    float3 Position;
    float Range;
    float RangePow;
    float4 LightCol;
    float LightStrength;
};

struct SpotLightProp
{
    float3 Position; // Source
    float Range; // Distance
    float RangePow; // Fade
    float4 LightCol;
    float LightStrength;
    float4x4 lProjection;
    float4x4 lView;
    uint TexID;
};

struct SunLightProp
{
    float3 Direction; // Source
    float4 LightCol;
    float LightStrength;
};

struct Components
{
	float3 Ambient;
	float3 Diffuse;
	float3 Specular;
	float3 SSS;
	float3 Rim;
};

StructuredBuffer<PointLightProp> pointlightprop <string uiname="Pointlight Buffer";>;
StructuredBuffer<SpotLightProp> spotlightprop <string uiname="Spotlight Buffer";>;
Texture2DArray SpotTexArray;
StructuredBuffer<SunLightProp> sunlightprop <string uiname="Sunlight Buffer";>;

SamplerState SpotSampler <bool visible=false;string uiname="Spotlight Sampler";>
{
	Filter=MIN_MAG_MIP_LINEAR;
	AddressU=CLAMP;
	AddressV=CLAMP;
};

float lEpsilon : IMMUTABLE = 0.001;

float halfLambert(float3 vec1, float3 vec2)
{
	float product = dot(vec1, vec2);
	product *= 0.5;
	product += 0.5;
	return product;
}

Components PhongPointSSS(
    float3 PosW,
    float3 NormV,
    float3 ViewDirV,
    float2 SpecSSSMap,
    float lightcount,
    float matid,
	float4x4 tV,
	float dmod
	)
{
    float3 lAtt = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_ATTENUATION)
    float lPower = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARPOWER);
    
    float3 lAmb = 0;
    if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
    	lAmb = GetFloat(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_AMBIENTCOLOR);

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARCOLOR) * SpecSSSMap.x;

    
    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	if(pointlightprop[i].LightStrength > lEpsilon)
    	{
		   	float atten = 0;
		    float3 amb=0;
		    float3 diff = 0;
		    float3 spec = 0;
	        float3 lPos = pointlightprop[i].Position;
	        float lRange = pointlightprop[i].Range;
	        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;
	    	
	    	float3 rim = 0;
	
	        float d = distance(PosW, lPos);
	        
	        atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
	            
	        amb = lAmb * atten * pointlightprop[i].LightStrength;
	    	float rangeF = pow(saturate((lRange-d)/lRange),dmod*pointlightprop[i].RangePow);
	        float3 LightDirW = normalize(lPos - PosW);
	        float3 V = normalize(ViewDirV);
	    	
	        if(d<lRange)
	        {
	
	
	            //halfvector
	            float3 H = normalize(ViewDirV + LightDirW);
	            //compute blinn lighting
	            float3 shades = lit(dot(NormV, LightDirW), dot(NormV, H), lPower).xyz;
	            diff = lCol * shades.y * atten;
	            //reflection vector (view space)
	            float3 R = normalize(2 * dot(NormV, LightDirW) * NormV - LightDirW);
	            //normalized view direction (view space)
	            //calculate specular light
	            spec = pows(max(dot(R, V),0), lPower*.2) * lSpec * lCol;
	        }
	    	
	    	
	    	outc.Diffuse += diff * rangeF;
	    	outc.Specular += spec * rangeF;
	    	outc.Ambient = max(outc.Ambient, amb/lightcount);
    	}
    }

    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
    {
    	float materialThickness = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_THICKNESS);
		float power = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_POWER);
		float amount = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_STRENGTH);
		float3 coeff = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_COEFFICIENT);

	    for(float i = 0; i<lightcount; i++)
	    {
	    	if(pointlightprop[i].LightStrength > lEpsilon)
	    	{

		        float3 lPos = pointlightprop[i].Position;
		        float lRange = pointlightprop[i].Range;
		        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;

	        	atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
	        	float3 LightDirW = normalize(lPos - PosW);
		    	// SSS
				float3 indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, LightDirW)));
				indirectLightComponent += materialThickness * halfLambert(-V, LightDirW);
				indirectLightComponent *= atten * SpecSSSMap.y * coeff * lCol;
				float rangeFSSS = pow(saturate((lRange * power - d)/(lRange * power)), dmod * 0.9 * pointlightprop[i].RangePow);
		    	float sssa = pointlightprop[i].LightStrength * amount * rangeFSSS;
		    	outc.SSS += indirectLightComponent * sssa;
	    	}
	    }
	}

    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
    {
    	float materialThickness = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_THICKNESS);
		float power = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_POWER);
		float amount = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_STRENGTH);
		float3 coeff = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_COEFFICIENT);

	    for(float i = 0; i<lightcount; i++)
	    {
	    	if(pointlightprop[i].LightStrength > lEpsilon)
	    	{

		        float3 lPos = pointlightprop[i].Position;
		        float lRange = pointlightprop[i].Range;
		        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;

				float rangeFSSS = pow(saturate((lRange * power - d)/(lRange * power)), dmod * 0.9 * pointlightprop[i].RangePow);
		    	float sssa = pointlightprop[i].LightStrength * amount * rangeFSSS;

				rim = saturate(1-abs(dot(mul(NormV,tV).xyz, V)));
				rim = pows(rim, matprop[matid].RimLPower) * matprop[matid].RimLAmount * lCol;
		    	outc.Rim += rim * sssa;
	    	}
	    }
	}
    //out *= tex2D(diffSamp, TexCd).rgb;
    return outc;
}

Components PhongSpotSSS(float3 PosW, float3 NormW, float3 ViewDirV, float2 SpecSSSMap, float lightcount, float matid, float dmod, float4x4 tV)
{
	float3 V = normalize(ViewDirV);
    float3 lAtt = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_ATTENUATION_OFFSET)
    float lPower = matprop[matid].Power;
    
    float4 lAmb = matprop[matid].AmbCol;
    float4 lSpec = matprop[matid].SpecCol * SpecSSSMap.x;
    float materialThickness = matprop[matid].MatThick;
	
    Components outc = (Components)0;
    for(float i = 0; i<lightcount; i++)
	{
		float2 projTexCd = 0;
		float4 projpos = float4(0,0,0,1);
		float4 projcol = float4(0,0,0,1);
		float lightIntensity = 0;
		Components tlCol = (Components)0;
	    float3 color = spotlightprop[i].LightCol.xyz * spotlightprop[i].LightStrength;
		float3 spec = 0;
    	float d = distance(spotlightprop[i].Position,PosW);
    	float3 lDir = normalize(spotlightprop[i].Position-PosW);
	    float atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
	    float3 indirectLightComponent = 0;
	    float3 rim = 0;
	    float3 amb = matprop[matid].AmbCol.rgb * atten * spotlightprop[i].LightStrength;
    	if(spotlightprop[i].LightStrength > lEpsilon)
    	{
			lightIntensity = saturate(dot(NormW, lDir));
	        float lRange = spotlightprop[i].Range;
    		
			projpos = mul(float4(PosW,1), spotlightprop[i].lView);
			projpos = mul(projpos, spotlightprop[i].lProjection);
		    projTexCd.x =  projpos.x / projpos.w / 2.0f + 0.5f;
		    projTexCd.y = -projpos.y / projpos.w / 2.0f + 0.5f;
    		float dfc = length(projpos.xy/projpos.w)*.4;
    		float indirectMul = dfc * pow(saturate(projpos.z*atten*.3),1) * (1-saturate(pows(dfc,2)));
    		amb *= indirectMul;
    		
			bool mask = (saturate(projTexCd.x) == projTexCd.x) && (saturate(projTexCd.y) == projTexCd.y);
    		bool depthmask = saturate(projpos.z/projpos.w) == (projpos.z/projpos.w);
    		//bool depthmask = d<lRange;
			if(mask && depthmask)
			{
		    	projcol = SpotTexArray.SampleLevel(SpotSampler, float3(projTexCd,(float)spotlightprop[i].TexID), 0) * spotlightprop[i].LightStrength;
				tlCol.Diffuse = lightIntensity * color;
	            float3 R = normalize(2 * dot(NormW, lDir) * NormW - lDir);
	            spec = pows(max(dot(R, V),0), lPower*.2) * lSpec.rgb;
		    	tlCol.Diffuse *= projcol.rgb*projcol.a;
		    	tlCol.Ambient = amb;
		    	tlCol.Specular = spec * pows(projcol.rgb*projcol.a,.5);
			}
			else
			{
		    	tlCol.Ambient = amb;
			}
    		
	    	// SSS
			indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormW, lDir)));
			indirectLightComponent += materialThickness * halfLambert(-V, lDir);
			indirectLightComponent.rgb *= atten *  matprop[matid].SSSExtCoeff.rgb * SpecSSSMap.y;
			rim = (float3)(max(0,0.5+dot(mul(NormW,tV), V)));
			rim = pows(rim, matprop[matid].RimLPower) * matprop[matid].RimLAmount * pows(projcol.rgb,.5);
			float rangeFSSS = pows(saturate((spotlightprop[i].Range*matprop[matid].SSSPower-d)/(spotlightprop[i].Range*matprop[matid].SSSPower)),dmod*.9*pointlightprop[i].RangePow);
	    	
	    	float sssa = spotlightprop[i].LightStrength * matprop[matid].SSSAmount * rangeFSSS * indirectMul;
	    	tlCol.SSS = indirectLightComponent * sssa;
	    	tlCol.Rim = rim * sssa;

	    	float la = pows(1-d/spotlightprop[i].Range, spotlightprop[i].RangePow);
    		
			outc.Diffuse += tlCol.Diffuse * la;
			outc.Specular += tlCol.Specular * la;
			outc.Ambient = max(outc.Ambient, tlCol.Ambient * la);
			outc.SSS += max(tlCol.SSS * la,0);
			outc.Rim += max(tlCol.Rim * la,0);
    	}
	}
	return outc;
}

Components PhongSunSSS(
    float3 NormW,
    float3 ViewDirV,
    float2 SpecSSSMap,
    float lightcount,
    float matid,
	float4x4 tV
	)
{
    float lPower = matprop[matid].Power;
    
    float4 lAmb = matprop[matid].AmbCol;
    float4 lSpec = matprop[matid].SpecAmount * matprop[matid].SpecCol * SpecSSSMap.x;
    float materialThickness = matprop[matid].MatThick;
    
    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	if(sunlightprop[i].LightStrength > lEpsilon)
    	{
		    float3 amb=0;
		    float3 diff = 0;
		    float3 spec = 0;
	        float3 lDir = sunlightprop[i].Direction;
	        float3 lCol = sunlightprop[i].LightCol.xyz * sunlightprop[i].LightStrength;
	    	
	    	float3 indirectLightComponent = 0;
	    	float3 rim = 0;
	            
	        amb = lAmb.rgb * sunlightprop[i].LightStrength;
	        float3 LightDirW = normalize(lDir);
	        float3 V = normalize(ViewDirV);
	    	
            //halfvector
            float3 H = normalize(ViewDirV + LightDirW);
            //compute blinn lighting
            float3 shades = lit(dot(NormW, LightDirW), dot(NormW, H), lPower).xyz;
            diff = lCol * shades.y;
            //reflection vector (view space)
            float3 R = normalize(2 * dot(NormW, LightDirW) * NormW - LightDirW);
            //normalized view direction (view space)
            //calculate specular light
            spec = pow(max(dot(R, V),0), lPower*.2) * lSpec.rgb * lCol;
	        	
	    	// SSS
			indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormW, LightDirW)));
			indirectLightComponent += materialThickness * halfLambert(-V, LightDirW);
			indirectLightComponent.rgb *= matprop[matid].SSSExtCoeff.rgb * SpecSSSMap.y;
			rim = (float3)(max(0,.5+dot(mul(NormW,tV), V)));
			rim = pow(rim, matprop[matid].RimLPower) * matprop[matid].RimLAmount;
	    	
	    	outc.Diffuse += diff;
	    	outc.Specular += spec;
	    	outc.Ambient = max(outc.Ambient, amb);

	    	float sssa = sunlightprop[i].LightStrength * matprop[matid].SSSAmount;
	    	outc.SSS += indirectLightComponent * sssa;
	    	outc.Rim += rim * sssa;
    	}
    }
    //outCol *= tex2D(diffSamp, TexCd).rgb;
    return outc;
}
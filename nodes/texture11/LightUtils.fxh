struct MaterialProp
{
    float3 Atten;
    float Power;
    float4 AmbCol;
    float4 SpecCol;
    float SpecAmount;
    float4 EmCol;
    float EmAmount;
    float SSSAmount;
    float SSSPower;
    float MatThick;
    float RimLAmount;
    float RimLPower;
    float4 SSSExtCoeff;
    float Reflection;
    float Refraction;
	uint ReflectRefractTexID;
};

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

StructuredBuffer<MaterialProp> matprop <string uiname="Material Buffer";>;
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

float lEpsilon = 0.001;

float halfLambert(float3 vec1, float3 vec2)
{
	float product = dot(vec1, vec2);
	product *= 0.5;
	product += 0.5;
	return product;
}

float3 PhongPointSSS(
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
    float lAtt0 = matprop[matid].Atten.x;
    float lAtt1 = matprop[matid].Atten.y;
    float lAtt2 = matprop[matid].Atten.z;
    float lPower = matprop[matid].Power;
    
    float4 lAmb = matprop[matid].AmbCol;
    float4 lSpec = matprop[matid].SpecCol * SpecSSSMap.x;
    float materialThickness = matprop[matid].MatThick;
    
    float3 outCol = 0;

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
	    	
	    	float3 indirectLightComponent = 0;
	    	float3 rim = 0;
	
	        float d = distance(PosW, lPos);
	        
	        atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
	            
	        amb = lAmb.rgb * atten * pointlightprop[i].LightStrength;
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
	            spec = pow(max(dot(R, V),0), lPower*.2) * lSpec.rgb * lCol;
	        	
	        	
	        }
	    	
	    	// SSS
			indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, LightDirW)));
			indirectLightComponent += materialThickness * halfLambert(-V, LightDirW);
			indirectLightComponent.rgb *= atten *  matprop[matid].SSSExtCoeff.rgb * SpecSSSMap.y;
			rim = (float3)(max(0,.5+dot(mul(NormV,tV), V)));
			rim = pow(rim, matprop[matid].RimLPower) * matprop[matid].RimLAmount;
			float rangeFSSS = pow(saturate((lRange*matprop[matid].SSSPower-d)/(lRange*matprop[matid].SSSPower)),dmod*.9*pointlightprop[i].RangePow);
	    	
	    	outCol += (diff + spec) * rangeF;
	    	outCol += amb/lightcount;
	    	outCol += ((indirectLightComponent + rim)*pointlightprop[i].LightStrength * matprop[matid].SSSAmount * rangeFSSS);
    	}
    }
    //outCol *= tex2D(diffSamp, TexCd).rgb;
    return outCol;
}

float3 PhongSpotSSS(float3 PosW, float3 NormW, float3 ViewDirV, float2 SpecSSSMap, float lightcount, float matid, float dmod, float4x4 tV)
{
	float3 V = normalize(ViewDirV);
    float lAtt0 = matprop[matid].Atten.x;
    float lAtt1 = matprop[matid].Atten.y;
    float lAtt2 = matprop[matid].Atten.z;
    float lPower = matprop[matid].Power;
    
    float4 lAmb = matprop[matid].AmbCol;
    float4 lSpec = matprop[matid].SpecCol * SpecSSSMap.x;
    float materialThickness = matprop[matid].MatThick;
	
	float3 lCol = 0;
    for(float i = 0; i<lightcount; i++)
	{
		float2 projTexCd = 0;
		float4 projpos = float4(0,0,0,1);
		float4 projcol = float4(0,0,0,1);
		float lightIntensity = 0;
		float3 tlCol = 0;
	    float3 color = spotlightprop[i].LightCol.xyz * spotlightprop[i].LightStrength;
		float3 spec = 0;
    	float d = distance(spotlightprop[i].Position,PosW);
    	float3 lDir = normalize(spotlightprop[i].Position-PosW);
	    float atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
	    float3 indirectLightComponent = 0;
	    float3 rim = 0;
	    float3 amb = matprop[matid].AmbCol.rgb * atten * spotlightprop[i].LightStrength;
    	if(spotlightprop[i].LightStrength > lEpsilon)
    	{
			lightIntensity = saturate(dot(NormW, lDir));
			tlCol = lightIntensity * color;
    		
			projpos = mul(float4(PosW,1), spotlightprop[i].lView);
			projpos = mul(projpos, spotlightprop[i].lProjection);
		    projTexCd.x =  projpos.x / projpos.w / 2.0f + 0.5f;
		    projTexCd.y = -projpos.y / projpos.w / 2.0f + 0.5f;
    		float dfc = length(projpos.xy/projpos.w)*.4;
    		float indirectMul = dfc * pow(saturate(projpos.z*atten*.3),1) * (1-saturate(pow(dfc,2)));
    		amb *= indirectMul;
    		
			bool mask = (saturate(projTexCd.x) == projTexCd.x) && (saturate(projTexCd.y) == projTexCd.y);
    		bool depthmask = saturate(projpos.z/projpos.w) == (projpos.z/projpos.w);
			if(mask && depthmask)
			{
		    	projcol = SpotTexArray.SampleLevel(SpotSampler, float3(projTexCd,(float)spotlightprop[i].TexID), 0) * spotlightprop[i].LightStrength;
	            float3 R = normalize(2 * dot(NormW, lDir) * NormW - lDir);
	            spec = pow(max(dot(R, V),0), lPower*.2) * lSpec.rgb;
		    	tlCol = tlCol * (projcol.rgb*projcol.a) + amb + spec*pow(projcol.rgb*projcol.a,.5);
			}
			else
			{
		    	tlCol = amb;
			}
    		
	    	// SSS
			indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormW, lDir)));
			indirectLightComponent += materialThickness * halfLambert(-V, lDir);
			indirectLightComponent.rgb *= atten *  matprop[matid].SSSExtCoeff.rgb * SpecSSSMap.y;
			rim = (float3)(max(0,0.5+dot(mul(NormW,tV), V)));
			rim = pow(rim, matprop[matid].RimLPower) * matprop[matid].RimLAmount * pow(projcol.rgb,.5);
			float rangeFSSS = pow(saturate((spotlightprop[i].Range*matprop[matid].SSSPower-d)/(spotlightprop[i].Range*matprop[matid].SSSPower)),dmod*.9*pointlightprop[i].RangePow);
	    	
	    	tlCol += ((indirectLightComponent + rim) * spotlightprop[i].LightStrength * matprop[matid].SSSAmount * rangeFSSS) * indirectMul;
    		
			lCol += tlCol * pow(1-d/spotlightprop[i].Range, spotlightprop[i].RangePow);
    	}
	}
	return lCol;
}

float3 PhongSunSSS(
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
    float4 lSpec = matprop[matid].SpecCol * SpecSSSMap.x;
    float materialThickness = matprop[matid].MatThick;
    
    float3 outCol = 0;

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
	    	
	    	outCol += (diff + spec);
	    	outCol += amb/lightcount;
	    	outCol += ((indirectLightComponent + rim)*sunlightprop[i].LightStrength * matprop[matid].SSSAmount);
    	}
    }
    //outCol *= tex2D(diffSamp, TexCd).rgb;
    return outCol;
}
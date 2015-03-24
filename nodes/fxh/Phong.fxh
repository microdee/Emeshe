#if !defined(POWS_FXH)
	#include "../fxh/pows.fxh"
#endif
#if !defined(MATERIALS_FXH)
	#include "../fxh/Materials.fxh"
#endif
#if !defined(MRE_FXH)
	#include "../fxh/MRE.fxh"
#endif
#if !defined(LIGHTUTILS_FXH)
	#include "../fxh/LightUtils.fxh"
#endif

Texture2DArray SpecMaps;
Texture2DArray SSSMaps;
Texture2DArray RimMaps;

float halfLambert(float3 vec1, float3 vec2)
{
	float product = dot(vec1, vec2);
	product *= 0.5;
	product += 0.5;
	return product;
}

Components PhongPointSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(uv, sR);
	float2 ouv = GetUV(uv, sR);
	float3 SpecMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;
	if(KnowFeature(matid, MF_LIGHTING_PHONG_SPECULARMAP))
	{
		float SpecMapId = GetFloat(matid, MF_LIGHTING_PHONG_SPECULARMAP, 0);
		SpecMap = SpecMaps.SampleLevel(MapSampler, float3(ouv, SpecMapId), 0).rgb;
	}
	if(KnowFeature(matid, MF_LIGHTING_FAKESSS_MAP))
	{
		float SSSMapId = GetFloat(matid, MF_LIGHTING_FAKESSS_MAP, 0);
		SSSMap = SSSMaps.SampleLevel(MapSampler, float3(ouv, SSSMapId), 0).rgb;
	}

	if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT_MAP))
	{
		float RimMapId = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT_MAP, 0);
		RimMap = RimMaps.SampleLevel(MapSampler, float3(ouv, RimMapId), 0).rgb;
	}

    float3 lAtt = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_ATTENUATION);
    float lPower = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARPOWER);
    float SStrength = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARSTRENGTH);
    
    float3 lAmb = 0;
    float3 lAttAmb = 1;
    if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
    {
    	lAmb = GetFloat(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_AMBIENTCOLOR);
    	lAttAmb = GetFloat3(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_ATTENUATION);
    }

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARCOLOR) * SpecMap * SStrength;

    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
    	if((pointlightprop[i].LightStrength > lEpsilon) && valid)
    	{
		   	float atten = 0;
		    float3 amb = 0;
		    float3 diff = 0;
		    float3 spec = 0;
	        float3 lPos = pointlightprop[i].Position;
	        float lRange = pointlightprop[i].Range;
	        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;
	
	        float d = distance(PosV, lPos);
	        atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
	        
	    	if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
	    	{
	        	float attenamb = 1/(saturate(lAttAmb.x) + saturate(lAttAmb.y) * d + saturate(lAttAmb.z) * pow(d, 2));
		    	amb = lAmb * attenamb * spotlightprop[i].LightStrength;
	    	}
    		
	    	float rangeF = pow(saturate((lRange-d)/lRange),dmod*pointlightprop[i].RangePow);
	        float3 LightDirV = normalize(lPos-PosV);
	        float3 V = ViewDirV;
	    	
	        if(d<lRange)
	        {
	            //halfvector
	            float3 H = normalize(ViewDirV + LightDirV);
	            //compute blinn lighting
	            float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower).xyz;
	            diff = lCol * shades.y * atten;
	            //reflection vector (view space)
	            float3 R = normalize(2 * dot(NormV, LightDirV) * NormV - LightDirV);
	            //normalized view direction (view space)
	            //calculate specular light
	            spec = pows(max(dot(-R, V),0), lPower*.2) * lSpec * lCol;
	        }
	    	
	    	outc.Diffuse += diff * rangeF;
	    	outc.Specular += spec * rangeF;
	    	outc.Ambient = max(outc.Ambient, amb);
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
    		bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
	    	if(pointlightprop[i].LightStrength > lEpsilon && valid)
	    	{
		        float3 lPos = pointlightprop[i].Position;
		   		float atten = 0;
	        	float d = distance(PosV, lPos);
		        float lRange = pointlightprop[i].Range;
		        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;

	        	atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
	        	float3 LightDirV = normalize(lPos - PosV);
		    	// SSS
				float3 indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, LightDirV)));
				indirectLightComponent += materialThickness * halfLambert(-ViewDirV, LightDirV);
				indirectLightComponent *= atten * SSSMap * coeff * lCol;
				float rangeFSSS = pow(saturate((lRange * power - d)/(lRange * power)), dmod * 0.9 * pointlightprop[i].RangePow);
		    	float sssa = pointlightprop[i].LightStrength * amount * rangeFSSS;
		    	outc.SSS += indirectLightComponent * sssa;
	    	}
	    }
	}

    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
    {
		float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
		float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);

	    for(float i = 0; i<lightcount; i++)
	    {
    		bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
	    	if(pointlightprop[i].LightStrength > lEpsilon && valid)
	    	{

		        float3 lPos = pointlightprop[i].Position;
	        	float d = distance(PosV, lPos);
		        float lRange = pointlightprop[i].Range;
		        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;

				float rangeFSSS = pow(saturate((lRange * power - d * power)/(lRange * power)), dmod * 0.9 * pointlightprop[i].RangePow);
		    	float sssa = pointlightprop[i].LightStrength * amount * rangeFSSS;

				float3 rim = saturate(1-abs(dot(NormV, ViewDirV)));
				rim = pows(rim, power) * amount * lCol;
		    	outc.Rim += rim * sssa * RimMap;
	    	}
	    }
	}
    return outc;
}

Components PhongSpotSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(uv, sR);
	float2 ouv = GetUV(uv, sR);
	float3 SpecMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;

	if(KnowFeature(matid, MF_LIGHTING_PHONG_SPECULARMAP))
	{
		float SpecMapId = GetFloat(matid, MF_LIGHTING_PHONG_SPECULARMAP, 0);
		SpecMap = SpecMaps.SampleLevel(MapSampler, float3(ouv, SpecMapId), 0).rgb;
	}
	if(KnowFeature(matid, MF_LIGHTING_FAKESSS_MAP))
	{
		float SSSMapId = GetFloat(matid, MF_LIGHTING_FAKESSS_MAP, 0);
		SSSMap = SSSMaps.SampleLevel(MapSampler, float3(ouv, SSSMapId), 0).rgb;
	}

	if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT_MAP))
	{
		float RimMapId = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT_MAP, 0);
		RimMap = RimMaps.SampleLevel(MapSampler, float3(ouv, RimMapId), 0).rgb;
	}
    float3 lAttSSS = 1;
    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
    {
    	lAttSSS = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_ATTENUATION);
    }

    float3 lAtt = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_ATTENUATION);
    float lPower = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARPOWER);
    float SStrength = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARSTRENGTH);
    
    float3 lAmb = 0;
    float3 lAttAmb = 1;
    if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
    {
    	lAmb = GetFloat(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_AMBIENTCOLOR);
    	lAttAmb = GetFloat3(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_ATTENUATION);
    }

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARCOLOR) * SpecMap * SStrength;

    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
	{

    	bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
    	if(valid)
    	{
			float2 projTexCd = 0;
			float4 projpos = float4(0,0,0,1);
			float4 projcol = float4(0,0,0,1);
			float lightIntensity = 0;
			Components tlCol = (Components)0;
		    float3 color = spotlightprop[i].LightCol.xyz * spotlightprop[i].LightStrength;
			float3 spec = 0;
			float3 lPos = spotlightprop[i].Position;
	    	float d = distance(lPos, PosV);
	    	float3 lDir = normalize(lPos-PosV);
		    float atten = 1/(saturate(lAtt.x) + saturate(lAtt.y) * d + saturate(lAtt.z) * pow(d, 2));
		    float3 indirectLightComponent = 0;
		    float3 rim = 0;
		    float3 amb = 0;

	    	if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
	    	{
	        	float attenamb = 1/(saturate(lAttAmb.x) + saturate(lAttAmb.y) * d + saturate(lAttAmb.z) * pow(d, 2));
		    	amb = lAmb * attenamb * spotlightprop[i].LightStrength;
	    	}

	    	if(spotlightprop[i].LightStrength > lEpsilon)
    		{
				lightIntensity = saturate(dot(NormV, lDir));
		        float lRange = spotlightprop[i].Range;
	    		
				projpos = mul(float4(PosV,1), spotlightprop[i].lView);
				projpos = mul(projpos, spotlightprop[i].lProjection);
			    projTexCd.x =  projpos.x / projpos.w / 2.0f + 0.5f;
			    projTexCd.y = -projpos.y / projpos.w / 2.0f + 0.5f;
	    		float dfc = length(projpos.xy/projpos.w)*.4;
	    		float indirectMul = dfc * pow(saturate(projpos.z*atten*.3),1) * (1-saturate(pows(dfc,2)));
	    		amb *= indirectMul;
	    		
				bool Mask = (saturate(projTexCd.x) == projTexCd.x) && (saturate(projTexCd.y) == projTexCd.y);
	    		bool depthmask = saturate(projpos.z/projpos.w) == (projpos.z/projpos.w);
	    		//bool depthmask = d<lRange;
				if(Mask && depthmask)
				{
			    	projcol = SpotTexArray.SampleLevel(SpotSampler, float3(projTexCd,(float)spotlightprop[i].TexID), 0) * spotlightprop[i].LightStrength;
					tlCol.Diffuse = lightIntensity * color;
		            float3 R = normalize(2 * dot(NormV, lDir) * NormV - lDir);
		            spec = pows(max(dot(R, ViewDirV),0), lPower*.2) * lSpec;
			    	tlCol.Diffuse *= projcol.rgb*projcol.a;
			    	tlCol.Ambient = amb;
			    	tlCol.Specular = spec * pows(projcol.rgb*projcol.a,.5);
				}
				else
				{
			    	tlCol.Ambient = amb;
				}
			    
			    float la = pows(1-d/spotlightprop[i].Range, spotlightprop[i].RangePow);
	    		
			    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
			    {
			    	float materialThickness = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_THICKNESS);
					float power = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_POWER);
					float amount = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_STRENGTH);
					float3 coeff = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_COEFFICIENT);

					indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, lDir)));
					indirectLightComponent += materialThickness * halfLambert(-ViewDirV, lDir);
					indirectLightComponent.rgb *= atten *  coeff * SSSMap;

					float rangeFSSS = pows(saturate((spotlightprop[i].Range*power-d)/(spotlightprop[i].Range*power)),dmod*.9*pointlightprop[i].RangePow);
			    	float sssa = spotlightprop[i].LightStrength * amount * rangeFSSS * indirectMul;
			    	tlCol.SSS = indirectLightComponent * sssa;
					outc.SSS += max(tlCol.SSS * la,0);
			    }

			    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
			    {
					float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
					float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);

					rim = (float3)(max(0,0.5+dot(NormV, ViewDirV)));
					rim = pows(rim, power) * amount * pows(projcol.rgb,.5);
			    	
					float rangeFSSS = pows(saturate((spotlightprop[i].Range*power-d * power)/(spotlightprop[i].Range*power)),dmod*.9*pointlightprop[i].RangePow);
			    	float sssa = spotlightprop[i].LightStrength * amount * rangeFSSS * indirectMul;
			    	tlCol.Rim = rim * sssa;
					outc.Rim += max(tlCol.Rim * la,0);
			    }

	    		
				outc.Diffuse += tlCol.Diffuse * la;
				outc.Specular += tlCol.Specular * la;
				outc.Ambient = max(outc.Ambient, tlCol.Ambient * la);
			}
		}
	}
	return outc;
}

Components PhongSunSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(uv, sR);
	float2 ouv = GetUV(uv, sR);
	float3 SpecMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;

	if(KnowFeature(matid, MF_LIGHTING_PHONG_SPECULARMAP))
	{
		float SpecMapId = GetFloat(matid, MF_LIGHTING_PHONG_SPECULARMAP, 0);
		SpecMap = SpecMaps.SampleLevel(MapSampler, float3(ouv, SpecMapId), 0).rgb;
	}
	if(KnowFeature(matid, MF_LIGHTING_FAKESSS_MAP))
	{
		float SSSMapId = GetFloat(matid, MF_LIGHTING_FAKESSS_MAP, 0);
		SSSMap = SSSMaps.SampleLevel(MapSampler, float3(ouv, SSSMapId), 0).rgb;
	}

	if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT_MAP))
	{
		float RimMapId = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT_MAP, 0);
		RimMap = RimMaps.SampleLevel(MapSampler, float3(ouv, RimMapId), 0).rgb;
	}

    float3 lAtt = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_ATTENUATION);
    float lPower = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARPOWER);
    float SStrength = GetFloat(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARSTRENGTH);
    
    float3 lAmb = 0;
    if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
    {
    	lAmb = GetFloat(matid, MF_LIGHTING_AMBIENT, MF_LIGHTING_AMBIENT_AMBIENTCOLOR);
    }

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_PHONG, MF_LIGHTING_PHONG_SPECULARCOLOR) * SpecMap * SStrength;
    
    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
    	if((sunlightprop[i].LightStrength > lEpsilon) && valid)
    	{
		    float3 amb=0;
		    float3 diff = 0;
		    float3 spec = 0;
	        float3 lDir = sunlightprop[i].Direction;
	        float3 lCol = sunlightprop[i].LightCol.xyz * sunlightprop[i].LightStrength;
	    	
	    	float3 indirectLightComponent = 0;
	    	float3 rim = 0;

	        if(KnowFeature(matid, MF_LIGHTING_AMBIENT))
	        {
	        	amb = lAmb.rgb * sunlightprop[i].LightStrength;
	        }

	        float3 LightDirV = normalize(lDir);
	        float3 V = ViewDirV;
	    	
            //halfvector
            float3 H = normalize(ViewDirV + LightDirV);
            //compute blinn lighting
            float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower).xyz;
            diff = lCol * shades.y;
            //reflection vector (view space)
            float3 R = normalize(2 * dot(NormV, LightDirV) * NormV - LightDirV);
            //normalized view direction (view space)
            //calculate specular light
            spec = pows(max(dot(-R, V),0), lPower*.2) * lSpec * lCol;
	        	
		    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
		    {
		    	float materialThickness = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_THICKNESS);
				float power = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_POWER);
				float amount = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_STRENGTH);
				float3 coeff = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_COEFFICIENT);

				indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, lDir)));
				indirectLightComponent += materialThickness * halfLambert(-V, lDir);
				indirectLightComponent.rgb *= coeff * SSSMap;

		    	float sssa = sunlightprop[i].LightStrength * amount;
				outc.SSS += indirectLightComponent * sssa;
		    }

		    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
		    {
				float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
				float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);

				rim = (float3)(max(0,0.5+dot(NormV, ViewDirV)));
				rim = pows(rim, power) * amount * lCol;
		    	
		    	float sssa = sunlightprop[i].LightStrength * amount;
				outc.Rim += rim * sssa;
		    }
	    	
	    	outc.Diffuse += diff;
	    	outc.Specular += spec;
	    	outc.Ambient = max(outc.Ambient, amb);
    	}
    }
    return outc;
}
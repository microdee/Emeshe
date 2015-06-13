#if !defined(POWS_FXH)
#include "../fxh/pows.fxh"
#endif
#if !defined(SAFEDIVIDE_FXH)
#include "../fxh/safedivide.fxh"
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


#define ROUGHNESS_LOOK_UP 0
#define ROUGHNESS_BECKMANN 1
#define ROUGHNESS_GAUSSIAN 2

#define ROUGHNESS_MODE 0

Texture2D<float> TexRoughness;
Texture2DArray SpecRoughMaps;
Texture2DArray SSSMaps;
Texture2DArray RimMaps;

Texture2DArray<float> ShadowMaps;
float bias = 0.1;

float halfLambert(float3 vec1, float3 vec2)
{
	float product = dot(vec1, vec2);
	product *= 0.5;
	product += 0.5;
	return product;
}


void cook_torrance
        (
            in float3 normal,
            in float3 viewer,
            in float3 light,
            in float roughness_value,
            inout float3 diff,
            inout float3 spec
        )
{    
    // Compute any aliases and intermediary values
    // -------------------------------------------
    float3 half_vector = normalize( light + -viewer );
    float NdotL        = saturate( dot( normal, light ) );
    float NdotH        = saturate( dot( normal, half_vector ) );
    float NdotV        = saturate( dot( normal, -viewer ) );
    float VdotH        = saturate( dot( -viewer, half_vector ) );
    float r_sq         = roughness_value * roughness_value;
    
    // Evaluate the geometric term
    // --------------------------------
    float geo_numerator   = 2.0f * NdotH;
    float geo_denominator = VdotH;
 
    float geo_b = (geo_numerator * NdotV ) / geo_denominator;
    float geo_c = (geo_numerator * NdotL ) / geo_denominator;
    float geo   = min( 1.0f, min( geo_b, geo_c ) );

    // Now evaluate the roughness term
    // -------------------------------
    float roughness;
 
    #if ROUGHNESS_MODE == ROUGHNESS_LOOK_UP
        // texture coordinate is:
        float2 tc = { NdotH, roughness_value };
 
        // Remap the NdotH value to be 0.0-1.0
        // instead of -1.0..+1.0
        tc.x += 1.0f;
        tc.x /= 2.0f;
 
        // look up the coefficient from the texture:
        roughness = TexRoughness.SampleLevel( MapSampler, tc, 0 );
    #endif
    #if ROUGHNESS_MODE == ROUGHNESS_BECKMANN
        float roughness_a = 1.0f / ( 4.0f * r_sq * pow( NdotH, 4 ) );
        float roughness_b = NdotH * NdotH - 1.0f;
        float roughness_c = r_sq * NdotH * NdotH;
 
        roughness = roughness_a * exp( roughness_b / roughness_c );
    #endif
    #if ROUGHNESS_MODE == ROUGHNESS_GAUSSIAN
        // This variable could be exposed as a variable
        // for the application to control:
        float c = 1.0f;
        float alpha = acos( dot( normal, half_vector ) );
        roughness = c * exp( -( alpha / r_sq ) );
    #endif

    // Next evaluate the Fresnel value
    // -------------------------------
    float fresnel = pows( 1.0f - VdotH, 5.0f );
	
	float ref_at_norm_incidence = 0.2;
    fresnel *= ( 1.0f - ref_at_norm_incidence );
    fresnel += ref_at_norm_incidence;

    // Put all the terms together to compute
    // the specular term in the equation
    // -------------------------------------
    float3 Rs_numerator   = ( fresnel * geo * roughness );
    float Rs_denominator  = NdotV * NdotL;
    float3 Rs             = sdiv(Rs_numerator,Rs_denominator);

    // Put all the parts together to generate
    // the final colour
    // --------------------------------------
    diff *= max(0.0f, NdotL);
    spec *= max(0.0f, NdotL) * Rs;
	//spec = fresnel;
}

Components CookTorrancePointSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(s0, uv);
	float2 ouv = GetUV(s0, uv);
	float4 RoughMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;
	if(KnowFeature(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP))
	{
		float RoughMapId = GetFloat(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP, 0);
		RoughMap = SpecRoughMaps.SampleLevel(MapSampler, float3(ouv, RoughMapId), 0);
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

    float SStrength = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARSTRENGTH);
    
    float3 lAttSSS = 1;
    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
    {
    	lAttSSS = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_ATTENUATION);
    }

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARCOLOR) * SStrength * RoughMap.rgb;
    float rough = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_ROUGHNESS) * RoughMap.a;

    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
    	if((pointlightprop[i].LightStrength > lEpsilon) && valid)
    	{
		   	float atten = 0;
	        float3 lPos = pointlightprop[i].Position;
	        float lRange = pointlightprop[i].Range;
	        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;
	
	        float d = distance(PosV, lPos);

	    	float rangeF = pow(saturate((lRange-d)/lRange),dmod*pointlightprop[i].RangePow);
	        float3 LightDirV = normalize(lPos-PosV);
	        float3 V = ViewDirV;
	        float3 diff = 0;
	        float3 spec = 0;
    		float shad = 1;
	    	
	        if(d<lRange)
	        {
		        diff = lCol;
		        spec = lSpec * lCol;
	        	cook_torrance(NormV, V, LightDirV, rough, diff, spec);
	        	
	        	#if defined(DOSHADOWS)
	        	if(pointlightprop[i].KnowShadows > 0.5)
	        	{
        			float cbias = bias;
        			if(KnowFeature(matid, MF_LIGHTING_SHADOWS))
        				cbias = GetFloat(matid, MF_LIGHTING_SHADOWS, 0);
	        		float3 lPosW = mul(float4(pointlightprop[i].ShadowMapCenter, 1), CamViewInv).xyz;
	        		float3 cPosW = mul(float4(PosV, 1), CamViewInv).xyz;
	        		float penumbra = pointlightprop[i].Penumbra;
		        	shad = PointShadows(ShadowMaps, pointlightprop[i].MapID, lPosW, lRange, cPosW, cbias, penumbra);
	        	}
	        	#endif
	        }
	    	
	    	outc.Diffuse += diff * rangeF * shad;
	    	outc.Specular += spec * rangeF * shad;
    		
		    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
		    {
				float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
				float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);
				float width = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_WIDTH);

		        float3 lPos = pointlightprop[i].Position;
	        	float d = distance(PosV, lPos);
		        float lRange = pointlightprop[i].Range;
		        float3 lCol = pointlightprop[i].LightCol.xyz * pointlightprop[i].LightStrength;

				float rangeRim = pow(saturate(1-d/lRange), dmod * 0.9 * pointlightprop[i].RangePow);
		    	float rima = pointlightprop[i].LightStrength * amount * rangeRim;
		    	
				float dotnv = dot(NormV, ViewDirV);
				float dotnl = dot(NormV, LightDirV);
				float3 rim = 1-saturate(abs(dotnv) * width);
			    float rimshad = lerp(1, shad, pow(saturate(-dotnl), 1/power));
			    rimshad = lerp(shad, rimshad, pow(abs(dotnv), power));
		    	
				rim = pows(rim, power) * amount * lCol;
		    	outc.Specular += rim * rima * RimMap * rimshad;
		    	
			}
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

	        	atten = 1/(saturate(lAttSSS.x) + saturate(lAttSSS.y) * d + saturate(lAttSSS.z) * pow(d, 2));
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
    return outc;
}

Components CookTorranceSpotSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(s0, uv);
	float2 ouv = GetUV(s0, uv);
	float4 RoughMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;
	if(KnowFeature(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP))
	{
		float RoughMapId = GetFloat(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP, 0);
		RoughMap = SpecRoughMaps.SampleLevel(s0, float3(ouv, RoughMapId), 0);
	}
	if(KnowFeature(matid, MF_LIGHTING_FAKESSS_MAP))
	{
		float SSSMapId = GetFloat(matid, MF_LIGHTING_FAKESSS_MAP, 0);
		SSSMap = SSSMaps.SampleLevel(s0, float3(ouv, SSSMapId), 0).rgb;
	}

	if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT_MAP))
	{
		float RimMapId = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT_MAP, 0);
		RimMap = RimMaps.SampleLevel(s0, float3(ouv, RimMapId), 0).rgb;
	}

    float SStrength = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARSTRENGTH);

    float3 lAttSSS = 1;
    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
    {
    	lAttSSS = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_ATTENUATION);
    }

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARCOLOR) * SStrength * RoughMap.rgb;
    float rough = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_ROUGHNESS) * RoughMap.a;

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
		    float3 indirectLightComponent = 0;
		    float3 rim = 0;


	    	if(spotlightprop[i].LightStrength > lEpsilon)
    		{
				lightIntensity = saturate(dot(NormV, lDir));
		        float lRange = spotlightprop[i].Range;
	    		
				projpos = mul(float4(PosV,1), spotlightprop[i].lView);
				projpos = mul(projpos, spotlightprop[i].lProjection);
			    projTexCd.x =  projpos.x / projpos.w / 2.0f + 0.5f;
			    projTexCd.y = -projpos.y / projpos.w / 2.0f + 0.5f;
	    		float dfc = length(projpos.xy/projpos.w);
    			float indirectMul = 1;
	    		
				bool Mask = (saturate(projTexCd.x) == projTexCd.x) && (saturate(projTexCd.y) == projTexCd.y);
	    		bool depthmask = saturate(projpos.z/projpos.w) == (projpos.z/projpos.w);
	    		//bool depthmask = d<lRange;
				float shad = 1;
				if(Mask && depthmask)
				{
			    	projcol = SpotTexArray.SampleLevel(SpotSampler, float3(projTexCd, spotlightprop[i].TexID), 0) * spotlightprop[i].LightStrength;

			        float3 diff = color;
			        float3 spec = lSpec * color;
		        	cook_torrance(NormV, ViewDirV, lDir, rough, diff, spec);
		        	#if defined(DOSHADOWS)
		        	if(spotlightprop[i].KnowShadows > 0.5)
		        	{
	        			float cbias = bias;
	        			if(KnowFeature(matid, MF_LIGHTING_SHADOWS))
	        				cbias = GetFloat(matid, MF_LIGHTING_SHADOWS, 0);
		        		float3 lPosW = mul(float4(lPos, 1), CamViewInv).xyz;
		        		float3 cPosW = mul(float4(PosV, 1), CamViewInv).xyz;
		        		float penumbra = spotlightprop[i].Penumbra;
			        	shad = SpotShadows(ShadowMaps, spotlightprop[i].MapID, lPosW, lRange, cPosW, projTexCd, cbias, penumbra);
		        	}
		        	#endif
					
					tlCol.Diffuse = diff * shad;
			    	tlCol.Diffuse *= projcol.rgb*projcol.a;
			    	tlCol.Specular = spec * pows(projcol.rgb*projcol.a,.5) * shad;
				}
			    
			    float la = pows(1-d/spotlightprop[i].Range, spotlightprop[i].RangePow);
	    		
			    if(KnowFeature(matid, MF_LIGHTING_FAKESSS))
			    {
			    	float materialThickness = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_THICKNESS);
					float power = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_POWER);
					float amount = GetFloat(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_STRENGTH);
					float3 coeff = GetFloat3(matid, MF_LIGHTING_FAKESSS, MF_LIGHTING_FAKESSS_COEFFICIENT);
			    	
		    		float atten = 1/(saturate(lAttSSS.x) + saturate(lAttSSS.y) * d + saturate(lAttSSS.z) * pow(d, 2));
			    	
		    		float cdfc = dfc / (1 + power);
			    	float3 sssprojcol = SpotTexArray.SampleLevel(SpotSampler, float3(projTexCd, spotlightprop[i].TexID), 7).rgb;
		    		indirectMul = cdfc * pow(saturate(projpos.z*atten*.3),1) * (1-saturate(pows(cdfc,2)));

					indirectLightComponent = (float3)(materialThickness * max(0, dot(-NormV, lDir)));
					indirectLightComponent += materialThickness * halfLambert(-ViewDirV, lDir);
					indirectLightComponent.rgb *= atten *  coeff * SSSMap;

					float rangeFSSS = pows(saturate((spotlightprop[i].Range*power-d)/(spotlightprop[i].Range*power)),dmod*.9*pointlightprop[i].RangePow);
			    	float sssa = spotlightprop[i].LightStrength * amount * rangeFSSS * indirectMul;
			    	tlCol.SSS = indirectLightComponent * sssa * sssprojcol;
					outc.SSS += max(tlCol.SSS * la,0);
			    }

			    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
			    {
					float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
					float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);
					float width = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_WIDTH);

					float dotnv = dot(NormV, ViewDirV);
					float dotnl = dot(NormV, lDir);
			    	float rimshad = lerp(1, shad, pow(saturate(-dotnl), 1/power));
			    	rimshad = lerp(shad, rimshad, pow(abs(dotnv), power));
					rim = 1-saturate(abs(dotnv) * width);
					rim = pows(rim, power) * amount * pows(projcol.rgb, 0.9);

					float rangeRim = pow(saturate(1-d/spotlightprop[i].Range), dmod * 0.9 * pointlightprop[i].RangePow);
			    	float rima = spotlightprop[i].LightStrength * amount * rangeRim * indirectMul;
			    	tlCol.Specular += max(rim * rima, 0) * rimshad;
			    }
	    		
				outc.Diffuse += tlCol.Diffuse * la;
				outc.Specular += tlCol.Specular * la;
			}
		}
	}
	return outc;
}

Components CookTorranceSunSSS(SamplerState s0, float2 uv, float2 sR, float lightcount, float dmod, float mask)
{
	float3 PosV = GetViewPos(s0, uv);
	float3 ViewDirV = normalize(PosV);
	float3 NormV = Normals.SampleLevel(s0, uv, 0).xyz;
	uint matid = GetMatID(s0, uv);
	float2 ouv = GetUV(s0, uv);
	float4 RoughMap = 1;
	float3 SSSMap = 1;
	float3 RimMap = 1;

	if(KnowFeature(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP))
	{
		float RoughMapId = GetFloat(matid, MF_LIGHTING_COOKTORRANCE_SPECULARMAP, 0);
		RoughMap = SpecRoughMaps.SampleLevel(MapSampler, float3(ouv, RoughMapId), 0);
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

    float SStrength = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARSTRENGTH);

    float3 lSpec = GetFloat3(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_SPECULARCOLOR) * SStrength * RoughMap.rgb;
    float rough = GetFloat(matid, MF_LIGHTING_COOKTORRANCE, MF_LIGHTING_COOKTORRANCE_ROUGHNESS) * RoughMap.a;
    
    Components outc = (Components)0;

    for(float i = 0; i<lightcount; i++)
    {
    	bool valid = (mask == MaskID[i]) || (!UseMask) || ((mask == 0) && ZeroBypass);
    	if((sunlightprop[i].LightStrength > lEpsilon) && valid)
    	{
	        float3 lDir = sunlightprop[i].Direction;
	        float3 lCol = sunlightprop[i].LightCol.xyz * sunlightprop[i].LightStrength;
	    	
	    	float3 indirectLightComponent = 0;
	    	float3 rim = 0;

	        float3 LightDirV = normalize(lDir);
	        float3 V = ViewDirV;
	    	
	        float3 diff = lCol;
	        float3 spec = lSpec * lCol;
        	cook_torrance(NormV, V, LightDirV, rough, diff, spec);
	        	
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
	    		//outc.SSS = matid;
		    }

		    if(KnowFeature(matid, MF_LIGHTING_FAKERIMLIGHT))
		    {
				float power = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_POWER);
				float amount = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_STRENGTH);
				float width = GetFloat(matid, MF_LIGHTING_FAKERIMLIGHT, MF_LIGHTING_FAKERIMLIGHT_WIDTH);

				rim = 1-saturate(abs(dot(NormV, ViewDirV)) * width);
				rim = pows(rim, power) * amount * lCol;
		    	
		    	float rima = sunlightprop[i].LightStrength * amount;
				outc.Specular += rim * rima;
		    }
	    	
	    	outc.Diffuse += diff;
	    	outc.Specular += spec;
    	}
    }
    return outc;
}
struct MaterialProp
{
    float3 Atten;
    float Power;
    float4 AmbCol;
    float4 SpecCol;
    float SpecAmount;
    float SSSAmount;
    float SSSPower;
    float MatThick;
    float RimLAmount;
    float RimLPower;
    float4 SSSExtCoeff;
    float Reflection;
    float Refraction;
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

LightCount = 1;

//phong point function
float3 PhongPoint(
    float3 PosW,
    float3 NormV,
    float3 ViewDirV,
    float4 lDiff,
    StructuredBuffer<PointLightProp> lprops,
    StructuredBuffer<MaterialProp> mprops)
{
    float lAtt0 = mprops.Atten.x;
    float lAtt1 = mprops.Atten.y;
    float lAtt2 = mprops.Atten.z;
    float lPower = mprops.Power;
    
    float4 lAmb = mprops.AmbCol;
    float4 lSpec = mprops.SpecCol;
    
    float3 outCol = 0;
    for(float i=0; i<LightCount; i++)
    {
        float3 lPos = lprops.Position;
        float lRange = lprops.range;
        float3 lCol = lprops.LightCol.xyz * lprops.LightStrength;

        float d = distance(PosW, lPos);
        float atten = 0;
        float3 amb=0;
        float3 diff = 0;
        float3 spec = 0;
        
        atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
            
        amb = lAmb.rgb * atten;

        if(d<lRange)
        {

            float3 LightDirW = normalize(lPos - PosW);
            float3 LightDirV = mul(LightDirW, tV);

            //halfvector
            float3 H = normalize(ViewDirV + LightDirV);
            //compute blinn lighting
            float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower);
            diff = lDiff.rgb * lCol * shades.y * atten;
            //reflection vector (view space)
            float3 R = normalize(2 * dot(NormV, LightDirV) * NormV - LightDirV);
            //normalized view direction (view space)
            float3 V = normalize(ViewDirV);
            //calculate specular light
            spec = pow(max(dot(R, V),0), lPower*.2) * lSpec.rgb * lCol;
        }
        outCol += (diff + spec) * pow(saturate((lRange-d)/lRange),dmod);
        outCol += amb/LightCount;
    }
    //outCol *= tex2D(diffSamp, TexCd).rgb;
    return outCol;
}
Texture2D Chns[8] <string uiname="Channels";>;
#define MRE_COLOR 0
#define MRE_VIEWPOS 1
#define MRE_WORLDPOS 2
#define MRE_VIEWNORM 3
#define MRE_WORLDNORM 4
#define MRE_VELOCITY 5
#define MRE_MAPS 6
#define MRE_MATERIAL 7
#define MRE_MAT_OBJID0 x
#define MRE_MAT_OBJID1 y
#define MRE_MATID z
//Sample
float3 mre_getcolor(SamplerState s0, float2 uv) {return Chns[MRE_COLOR].Sample(s0,uv).xyz;}
float3 mre_getviewpos(SamplerState s0, float2 uv) {return Chns[MRE_VIEWPOS].Sample(s0,uv).xyz;}
float3 mre_getworldpos(SamplerState s0, float2 uv) {return Chns[MRE_WORLDPOS].Sample(s0,uv).xyz;}
float3 mre_getviewnorm(SamplerState s0, float2 uv) {return Chns[MRE_VIEWNORM].Sample(s0,uv).xyz;}
float3 mre_getworldnorm(SamplerState s0, float2 uv) {return Chns[MRE_WORLDNORM].Sample(s0,uv).xyz;}
float3 mre_getvelocity(SamplerState s0, float2 uv) {return Chns[MRE_VELOCITY].Sample(s0,uv).xyz;}
float3 mre_getmaps(SamplerState s0, float2 uv) {return Chns[MRE_MAPS].Sample(s0,uv).xyz;}
float mre_getobjid0(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MAT_OBJID0;}
float mre_getobjid1(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MAT_OBJID1;}
float mre_getmatid(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MATID;}
//SampleLevel
float3 mre_getcolorLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_COLOR].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getviewposLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VIEWPOS].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getworldposLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_WORLDPOS].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getviewnormLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VIEWNORM].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getworldnormLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_WORLDNORM].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getvelocityLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VELOCITY].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getmapsLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MAPS].SampleLevel(s0,uv,lod).xyz;}
float mre_getobjid0Level(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MAT_OBJID0;}
float mre_getobjid1Level(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MAT_OBJID1;}
float mre_getmatidLevel(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MATID;}
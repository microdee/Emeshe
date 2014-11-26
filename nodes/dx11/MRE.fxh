/*
channels:
0 Color			R	G	B
1 ViewPosition	X	Y	Z
2 WorldPosition	X	Y	Z
3 ViewNormals	X	Y	Z
4 WorldNormals	X	Y	Z
5 Velocity		X 	Y	Z
6 Material		U	V	MatID	ObjID
7 DepthStencil	D	S
*/
Texture2D Chns[8] <string uiname="Channels";>;

#define MRE_COLOR 0
#define MRE_VIEWPOS 1
#define MRE_WORLDPOS 2
#define MRE_VIEWNORM 3
#define MRE_WORLDNORM 4
#define MRE_VELOCITY 5
#define MRE_MATERIAL 6
#define MRE_DEPTHSTENCIL 7
#define MRE_MAT_UV xy
#define MRE_MAT_OBJID w
#define MRE_MATID z

//Sample
float3 mre_getcolor(SamplerState s0, float2 uv) {return Chns[MRE_COLOR].Sample(s0,uv).xyz;}
float3 mre_getviewpos(SamplerState s0, float2 uv) {return Chns[MRE_VIEWPOS].Sample(s0,uv).xyz;}
float3 mre_getworldpos(SamplerState s0, float2 uv) {return Chns[MRE_WORLDPOS].Sample(s0,uv).xyz;}
float3 mre_getviewnorm(SamplerState s0, float2 uv) {return Chns[MRE_VIEWNORM].Sample(s0,uv).xyz;}
float3 mre_getworldnorm(SamplerState s0, float2 uv) {return Chns[MRE_WORLDNORM].Sample(s0,uv).xyz;}
float3 mre_getvelocity(SamplerState s0, float2 uv) {return Chns[MRE_VELOCITY].Sample(s0,uv).xyz;}
float2 mre_getuv(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MAT_UV;}
float mre_getobjid(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MAT_OBJID;}
float mre_getmatid(SamplerState s0, float2 uv) {return Chns[MRE_MATERIAL].Sample(s0,uv).MRE_MATID;}
float2 mre_getdepthstencil(SamplerState s0, float2 uv) {return Chns[MRE_DEPTHSTENCIL].Sample(s0,uv).xy;}
//SampleLevel
float3 mre_getcolor(SamplerState s0, float2 uv, float lod) {return Chns[MRE_COLOR].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getviewpos(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VIEWPOS].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getworldpos(SamplerState s0, float2 uv, float lod) {return Chns[MRE_WORLDPOS].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getviewnorm(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VIEWNORM].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getworldnorm(SamplerState s0, float2 uv, float lod) {return Chns[MRE_WORLDNORM].SampleLevel(s0,uv,lod).xyz;}
float3 mre_getvelocity(SamplerState s0, float2 uv, float lod) {return Chns[MRE_VELOCITY].SampleLevel(s0,uv,lod).xyz;}
float2 mre_getuv(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MAT_UV;}
float mre_getobjid(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MAT_OBJID;}
float mre_getmatid(SamplerState s0, float2 uv, float lod) {return Chns[MRE_MATERIAL].SampleLevel(s0,uv,lod).MRE_MATID;}
float2 mre_getdepthstencil(SamplerState s0, float2 uv, float lod) {return Chns[MRE_DEPTHSTENCIL].SampleLevel(s0,uv,lod).xy;}
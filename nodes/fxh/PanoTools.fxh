#define PANOTOOLS_FXH 1

float2 DirToUV(float3 p){
	p=normalize(p);
	return float2(atan2(p.x,-p.z)/acos(-1)*.5+.5,asin(-p.y)/acos(-1)+.5);
}

float2 r2d(float2 x,float a)
{
	a*=acos(-1)*2;
	return float2(cos(a)*x.x+sin(a)*x.y,cos(a)*x.y-sin(a)*x.x);
}

float3 UVToDir(float2 UV)
{
	float3 p=float3(0,0,1);
	p.yz=r2d(p.yz,-(UV.y-.5)*.5);
	p.xz=r2d(p.xz,UV.x+.5);
	return p;
}
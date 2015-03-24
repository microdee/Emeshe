#define SAFEDIVIDE_FXH 1

float sdiv(float a, float b)
{
	if(a==0) return 0;
	float s = sign(a*b);
	if(b==0) s=1;
	float bb = max(abs(b), 0.00001);
	return (abs(a)/bb)*s;
}

float2 sdiv(float2 a, float2 b)
{
	float2 res = 0;
	res.x = sdiv(a.x, b.x);
	res.y = sdiv(a.y, b.y);
	return res;
}

float3 sdiv(float3 a, float3 b)
{
	float3 res = 0;
	res.x = sdiv(a.x, b.x);
	res.y = sdiv(a.y, b.y);
	res.z = sdiv(a.z, b.z);
	return res;
}

float4 sdiv(float4 a, float4 b)
{
	float4 res = 0;
	res.x = sdiv(a.x, b.x);
	res.y = sdiv(a.y, b.y);
	res.z = sdiv(a.z, b.z);
	res.w = sdiv(a.w, b.w);
	return res;
}
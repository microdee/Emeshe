#define BITWISE_FXH 1

float Join(float a, float b)
{
	uint ab = f32tof16(a);
	uint bb = f32tof16(b);
	bb = bb << 16;
	uint ret = ab | bb;
	return asfloat(ret);
}

float2 Split(float a)
{
	uint2 ret = 0;
	ret.x = f16tof32(asuint(a));
	ret.y = f16tof32(asuint(a) >> 16);
	return asfloat(ret);
}

uint JoinHalf(uint a, uint b)
{
	uint ab = 0x000000FF & a;
	uint bb = 0x0000FF00 & (a << 8);
	return ab | bb;
}

uint2 SplitHalf(uint a)
{
	uint2 ret = 0;
	ret.x = 0x000000FF & a;
	ret.y = 0x000000FF & (a >> 8);
	return ret;
}
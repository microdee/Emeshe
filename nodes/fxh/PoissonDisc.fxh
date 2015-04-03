#define POISSONDISC_FXH 1

float3 PoissonDisc(float3 N, float t)
{
	float3 nN = normalize(N);
	float3 anN = abs(nN);
	float3 MinAbsN = 0;
	float MinNComp = 1;

	[unroll]
	for(uint i=0; i<3; i++)
		MinNComp = min(MinNComp, anN[i]);

	[unroll]
	for(uint i=0; i<3; i++)
		MinAbsN[i] = (MinNComp == anN[i]) ? 1 : 0;

	float3 U = normalize(cross(nN, MinAbsN));

	float3 P = cos(t) * U + sin(t) * cross(nN, U);
	return normalize(P);
}

float3 PoissonDiscDir(float3 N, float t, float r)
{
	float3 P = PoissonDisc(N, t) + normalize(N);
	return lerp(N, normalize(P), r);
}

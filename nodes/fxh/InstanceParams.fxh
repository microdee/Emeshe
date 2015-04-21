
#define INSTANCEPARAMS_FXH 1

struct InstanceParams
{
	float4x4 tW;
	float4x4 ptW;
	float4x4 tTex;
	float4 DiffCol;
	float DiffAmount;
	float VelocityGain;
	float BumpAmount;
	uint MatID;
	uint ObjID0;
	uint ObjID1;
};
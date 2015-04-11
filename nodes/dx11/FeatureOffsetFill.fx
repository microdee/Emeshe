
#define MF_FLAGSIZE 32

struct MaterialMeta
{
	#if MF_FLAGSIZE == 64
		uint2 Flags; // Features
	#elif MF_FLAGSIZE == 96
		uint3 Flags;
	#elif MF_FLAGSIZE == 128
		uint4 Flags;
	#else
		uint Flags;
	#endif
	uint Address; // Where data starts in MaterialData buffer
	uint Size; // Actual size
};

StructuredBuffer<uint> Flags;
StructuredBuffer<uint> Address;
StructuredBuffer<uint> Size;
RWStructuredBuffer<MaterialMeta> BOutput : BACKBUFFER;

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

[numthreads(64, 1, 1)]
void CS(csin input)
{
	uint ii = input.DTID.x;
	MaterialMeta o = (MaterialMeta)0;
	o.Flags = Flags[ii];
	o.Address = Address[ii];
	o.Size = Size[ii];
	BOutput[ii] = o;
}
technique11 Fill { pass P0{SetComputeShader( CompileShader( cs_5_0, CS() ) );} }
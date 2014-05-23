RWTexture2DArray<float4> Outbuf : BACKBUFFER;
Texture2DArray Intex;

struct csin
{
	uint3 DTID : SV_DispatchThreadID;
	uint3 GTID : SV_GroupThreadID;
	uint3 GID : SV_GroupID;
};

void main(csin input)
{
	uint2 ii = input.DTID.xy;
	uint ti = input.DTID.z;
	Outbuf[uint3(ii,ti)] = Intex.Load(int4(ii,ti,0));
}

[numthreads(1, 1, 1)]
void CS1(csin input) { main(input); }
technique11 Make1 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS1() ) );} }
[numthreads(2, 2, 1)]
void CS2(csin input) { main(input); }
technique11 Make2 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS2() ) );} }
[numthreads(3, 3, 1)]
void CS3(csin input) { main(input); }
technique11 Make3 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS3() ) );} }
[numthreads(4, 4, 1)]
void CS4(csin input) { main(input); }
technique11 Make4 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS4() ) );} }
[numthreads(5, 5, 1)]
void CS5(csin input) { main(input); }
technique11 Make5 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS5() ) );} }
[numthreads(6, 6, 1)]
void CS6(csin input) { main(input); }
technique11 Make6 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS6() ) );} }
[numthreads(7, 7, 1)]
void CS7(csin input) { main(input); }
technique11 Make7 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS7() ) );} }
[numthreads(8, 8, 1)]
void CS8(csin input) { main(input); }
technique11 Make8 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS8() ) );} }
[numthreads(9, 9, 1)]
void CS9(csin input) { main(input); }
technique11 Make9 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS9() ) );} }
[numthreads(10, 10, 1)]
void CS10(csin input) { main(input); }
technique11 Make10 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS10() ) );} }
[numthreads(11, 11, 1)]
void CS11(csin input) { main(input); }
technique11 Make11 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS11() ) );} }
[numthreads(12, 12, 1)]
void CS12(csin input) { main(input); }
technique11 Make12 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS12() ) );} }
[numthreads(13, 13, 1)]
void CS13(csin input) { main(input); }
technique11 Make13 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS13() ) );} }
[numthreads(14, 14, 1)]
void CS14(csin input) { main(input); }
technique11 Make14 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS14() ) );} }
[numthreads(15, 15, 1)]
void CS15(csin input) { main(input); }
technique11 Make15 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS15() ) );} }
[numthreads(16, 16, 1)]
void CS16(csin input) { main(input); }
technique11 Make16 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS16() ) );} }
[numthreads(17, 17, 1)]
void CS17(csin input) { main(input); }
technique11 Make17 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS17() ) );} }
[numthreads(18, 18, 1)]
void CS18(csin input) { main(input); }
technique11 Make18 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS18() ) );} }
[numthreads(19, 19, 1)]
void CS19(csin input) { main(input); }
technique11 Make19 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS19() ) );} }
[numthreads(20, 20, 1)]
void CS20(csin input) { main(input); }
technique11 Make20 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS20() ) );} }
[numthreads(21, 21, 1)]
void CS21(csin input) { main(input); }
technique11 Make21 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS21() ) );} }
[numthreads(22, 22, 1)]
void CS22(csin input) { main(input); }
technique11 Make22 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS22() ) );} }
[numthreads(23, 23, 1)]
void CS23(csin input) { main(input); }
technique11 Make23 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS23() ) );} }
[numthreads(24, 24, 1)]
void CS24(csin input) { main(input); }
technique11 Make24 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS24() ) );} }
[numthreads(25, 25, 1)]
void CS25(csin input) { main(input); }
technique11 Make25 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS25() ) );} }
[numthreads(26, 26, 1)]
void CS26(csin input) { main(input); }
technique11 Make26 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS26() ) );} }
[numthreads(27, 27, 1)]
void CS27(csin input) { main(input); }
technique11 Make27 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS27() ) );} }
[numthreads(28, 28, 1)]
void CS28(csin input) { main(input); }
technique11 Make28 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS28() ) );} }
[numthreads(29, 29, 1)]
void CS29(csin input) { main(input); }
technique11 Make29 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS29() ) );} }
[numthreads(30, 30, 1)]
void CS30(csin input) { main(input); }
technique11 Make30 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS30() ) );} }
[numthreads(31, 31, 1)]
void CS31(csin input) { main(input); }
technique11 Make31 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS31() ) );} }
[numthreads(32, 32, 1)]
void CS32(csin input) { main(input); }
technique11 Make32 { pass P0{SetComputeShader( CompileShader( cs_5_0, CS32() ) );} }
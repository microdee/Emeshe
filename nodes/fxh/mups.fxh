float pcount : PS_PARTICLECOUNT;
float pelsize : PS_ELEMENTSIZE;
float sysvalcount : PS_SYSVALCOUNT;
float bufsize : PS_BUFFERSIZE;
float2 Time : PS_TIME;
float EmitCounter : PS_EMITTERCOUNTER;
StructuredBuffer<uint> EmitCountOffs : PS_EMITTERCOUNTEROFFSET;

uint3 mups_position(uint i) {return uint3(i*pelsize+0,i*pelsize+1,i*pelsize+2);}
uint4 mups_velocity(uint i) {return uint4(i*pelsize+3,i*pelsize+4,i*pelsize+5,i*pelsize+6);}
uint3 mups_force(uint i) {return uint3(i*pelsize+7,i*pelsize+8,i*pelsize+9);}
uint4 mups_color(uint i) {return uint4(i*pelsize+10,i*pelsize+11,i*pelsize+12,i*pelsize+13);}
uint mups_size(uint i) {return i*pelsize+14;}
uint2 mups_age(uint i) {return uint2(i*pelsize+15,i*pelsize+16);}
uint mups_sleep(uint i) {return i*pelsize+17;}

#define GETMERGEDID_FXH 1
uint GetMergedGeomID(StructuredBuffer<uint> src, uint vid, uint geomcount)
{
	uint cvc = 0;
	uint res = 0;
	for(uint i=0; i<geomcount; i++)
	{
		cvc += src[i];
		if(vid < cvc)
		{
			res = i;
			break;
		}
	}
	return res;
}
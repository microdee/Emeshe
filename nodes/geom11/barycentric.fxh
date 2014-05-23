

struct InputStruct
{
    float3 cpoint ;
	float3 norm ;
	float4 TexCd;
	
};

float3  BC (InputStruct input [3] , float3 uv)
{
	
	for(uint i=0 ; i<3; i++)
		{
		float3 p = uv.x * input[i].cpoint  
        + uv.y * input[i].cpoint  
        + uv.z * input[i].cpoint ;
        	
return p; 	
		}
}


struct BCS(InputStruct input,float3 uv)
{

	for(uint i=0 ; i<3; i++)
		{
		float3 p = uv.x * input[i].cpoint  
        + uv.y * input[i].cpoint  
        + uv.z * input[i].cpoint ;
        	

    return output;
			
		}
}

 
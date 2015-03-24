/*
	To use this you have to use

	float3 FakeCubeCoord(
		float3 Direction
	)

	converts input Direction to the
	appropriate texture coordinates
	for the volume texture.
	dir.xyz -> float3(uv.xy, slice/6 + 0.5/6)
	
	usage:
	texture3D.Sample(sampler, FakeCubeCoord(direction));

	also provide 
*/


float minTwoPi : IMMUTABLE = -6.283185307179586476925286766559;
float TwoPi : IMMUTABLE = 6.283185307179586476925286766559;
float CubeCorrect : IMMUTABLE = 0.9999;

float4x4 FaceTransforms[6];

bool IntersectRayPlane(float3 rayOrigin, float3 rayDirection, float3 posOnPlane, float3 planeNormal, out float3 intersectionPoint)
{
  float rDotn = dot(rayDirection, planeNormal);
 
  //parallel to plane or pointing away from plane?
  if (rDotn < 0.0000001 )
    return false;
 
  float s = dot(planeNormal, (posOnPlane - rayOrigin)) / rDotn;
 
  intersectionPoint = rayOrigin + s * rayDirection;
 
  return true;
}

float3 FakeCubeCoord(float3 dir)
{
	float selectSlice = 0;
	float pselectSlice = 0;
	float2 qUV = float2(0,0);
	for(int i = 0; i<6; i++)
	{
		float3 ndir = normalize(dir);
		ndir = mul(ndir, FaceTransforms[i]);
		float quadw = 1/sqrt(3);
		float3 quadp = float3(0,0,quadw/2);
		float3 quadn = float3(0,0,-1);
		float3 intersPoint = 0;
		bool intersecting = IntersectRayPlane(float3(0,0,0), ndir, quadp, quadn, intersPoint);
		qUV.x = intersPoint.x/quadw;
		qUV.y = intersPoint.y/quadw;
		qUV *= CubeCorrect;
		qUV += 0.5;
		if(((0<qUV.x) && (qUV.x<1)) && ((0<qUV.y) && (qUV.y<1)) && intersecting)
		{
			selectSlice = i;
			break;
		}
	}
	return float3(qUV, saturate(selectSlice/6 + 0.5/6));
};

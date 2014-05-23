
////// CAUTION: //////
////// Use CLAMP for UV Addresses in the sampler
////// to avoid ugly artifacts along cube edges!

/*
	For Texture2DArray based fake cubemaps use

	float3 FakeCubeCoord(
		float3 Direction
	)

	converts input Direction to the
	appropriate texture coordinates
	for the Texture2DArray.
	dir.xyz -> float3(uv.xy, slice)
	
	usage:
	texture2DArray.Sample(sampler, FakeCubeCoord(direction));
*/

/*
	For Texture3D based fake cubemaps use

	float3 FakeCubeCoordVol(
		float3 Direction
	)

	converts input Direction to the
	appropriate texture coordinates
	for the Texture3D.
	dir.xyz -> float3(uv.xy, slice/6+0.5/6)
	
	usage:
	texture3D.Sample(sampler, FakeCubeCoordVol(direction));
*/

float minTwoPi : IMMUTABLE = -6.283185307179586476925286766559;
float TwoPi : IMMUTABLE = 6.283185307179586476925286766559;
float CubeCorrect : IMMUTABLE = 0.9999;

float4x4 RotateRays[6];

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
		ndir = mul(ndir, RotateRays[i]);
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
	return float3(qUV, selectSlice);
};

float3 FakeCubeCoordVol(float3 dir)
{
	float selectSlice = 0;
	float pselectSlice = 0;
	float2 qUV = float2(0,0);
	for(int i = 0; i<6; i++)
	{
		float3 ndir = normalize(dir);
		ndir = mul(ndir, RotateRays[i]);
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
	return float3(qUV, selectSlice/6+0.5/6);
};
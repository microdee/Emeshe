float minTwoPi : IMMUTABLE = -6.283185307179586476925286766559;
float TwoPi : IMMUTABLE = 6.283185307179586476925286766559;

float4x4 Vrotate(float3 rot)
  {
   rot.x *= TwoPi;
   rot.y *= TwoPi;
   rot.z *= TwoPi;
   float sx = sin(rot.x);
   float cx = cos(rot.x);
   float sy = sin(rot.y);
   float cy = cos(rot.y);
   float sz = sin(rot.z);
   float cz = cos(rot.z);

   return float4x4( cz*cy+sz*sx*sy, sz*cx, cz*-sy+sz*sx*cy, 0,
                   -sz*cy+cz*sx*sy, cz*cx, sz*sy+cz*sx*cy , 0,
                    cx * sy       ,-sx   , cx * cy        , 0,
                    0             , 0    , 0              , 1);
}

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
		qUV.x = intersPoint.x/quadw +.5;
		qUV.y = intersPoint.y/quadw +.5;
		//qUV = 1/qUV;
		if(((0<qUV.x) && (qUV.x<1)) && ((0<qUV.y) && (qUV.y<1)) && intersecting)
		{
			selectSlice = i;
			break;
		}
	}
	return float3(qUV, saturate(selectSlice/6 + 0.5/6));
};

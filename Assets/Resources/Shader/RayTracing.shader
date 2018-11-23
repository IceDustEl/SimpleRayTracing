/* Copyright 2018 IceDust

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
*/

Shader "Unlit/RayTracing"
{
	Properties
	{
		_RefractedColor("_RefractedColor",Color) = (1,1,1,1)
		_ReflectedColor("_ReflectedColor",Color) = (1,1,1,1)
		[HDR]_HdrColor("_HdrColor",Color) = (1,1,1,1)
		_MagicTexture("_MagicTexture",2D) = "black"
		_SkyBox("Sky Box",Cube) = "black"

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"= "Geometry+500" }
		LOD 100
		ZTest Always

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			const float noIntersectionT = -1.0;
			const int MaxBounce = 4;
			const float distanceAttenuationPower = 0.2;

			float4 _RefractedColor;
			float4 _ReflectedColor;
			float4 _HdrColor;
			sampler2D _MagicTexture;
			float3 _LightPos;
			float3 _MagicOrigin;
			float _MagicAlpha;
			samplerCUBE _SkyBox;

			struct Ray
			{
				float3 origin;
				float3 direction;
			};
			
			struct Material 
			{
				float3 ambientColor;
				float3 diffuseColor;
				float3 specularColor;
				float3 reflectedColor;
				float3 refractedColor;
				float reflectiveness;
				float refractiveness;
				float shinyness;
				float texAlpha;
				float3 refractiveIndex;
			};

			struct Intersection 
			{
				float3 position;
				float t;
				float3 normal;
				bool inside;
			};

			struct Light 
			{
				float3 position;
				float3 color;
			};
		 
			//射线和三角形求交
			 bool IntersectTriangle(float4 orig, float4 dir,
				 float4 v0, float4 v1, float4 v2, inout Intersection intersection)
			 {
				 float t, u, v;

				 // E1
				 float4 E1 = v1 - v0;
		 
				 // E2
				 float4 E2 = v2 - v0;
		 
				 // P
				 float4 P = float4(cross(dir,E2), 1);
		 
				 // determinant
				 float det = dot(E1,P);
		 
				 // keep det > 0, modify T accordingly
				 float4 T;
				 if( det >0 )
				 {
					 T = orig - v0;
				 }
				 else
				 {
					 T = v0 - orig;
					 det = -det;
				 }
		 
				 // If determinant is near zero, ray lies in plane of triangle
				 if( det < 0.0001f )
					 return false;
		 
				 // Calculate u and make sure u <= 1
				 u = dot(T,P);
				 if( u < 0.0f || u > det )
					 return false;
		 
				 // Q
				 float4 Q = float4(cross(T,E1), 1);
		 
				 // Calculate v and make sure u + v <= 1
				 v = dot(dir,Q);
				 if( v < 0.0f || u + v > det )
					 return false;
		 
				 // Calculate t, scale parameters, ray intersects triangle
				 t = dot(E2,Q);
		 
				 float fInvDet = 1.0f / det;
				 t *= fInvDet;
				 u *= fInvDet;
				 v *= fInvDet;

				 intersection.position = orig + dir * t;
				 intersection.t = t;
				 intersection.normal = normalize(cross(E1,E2));
				 intersection.inside = dot(intersection.normal, dir) > 0;

				 return true;
			 }

			 //射线和圆求交
			 bool IntersectSphere(float3 orig, float3 dir, float3 sphereOrig, float radius)
			 {
				float t0, t1, t;
	
				float3 l = sphereOrig - orig;
				float tca = dot(l, dir);
				//if ( tca < 0.0 )
					//return false;
				float d2 = dot (l, l) - (tca * tca);
				float r2 = radius*radius;
				if ( d2 > r2 )
					return false;
				else
					return true;
			 }

			 Intersection noIntersection() 
			 {
				 Intersection intersection;
				 intersection.position = float3(0.0, 0.0, 0.0);
				 intersection.t = noIntersectionT;
				 intersection.normal = float3(0.0, 0.0, 0.0);
				 intersection.inside = false;
				 return intersection;
			 }

			 bool hasIntersection(Intersection i) 
			 {
				 return i.t != noIntersectionT;
			 }

			 float4 GetSkyColor(fixed3 direction)
			 {
				 fixed4  spec_env = texCUBE(_SkyBox, direction);
				 return fixed4(spec_env.xyz, 1);
			 }

			 Material GetMaterial(int matIndex)
			 {
				 Material mat;
				 if (matIndex == 0)
				 {
					 mat.ambientColor = float3(1, 1, 1);
					 mat.diffuseColor = 1;
					 mat.specularColor = 1;
					 mat.reflectedColor = 1;
					 mat.refractedColor = float3(1, 1, 1);
					 mat.reflectiveness = 0;
					 mat.refractiveness = 1;
					 mat.shinyness = 40;
					 mat.texAlpha = 0;
					 mat.refractiveIndex = float3(2.407, 2.426, 2.451);
				 }
				 else if (matIndex == 1)
				 {
					 mat.ambientColor = float3(1, 1, 1);
					 mat.diffuseColor = 1;
					 mat.specularColor = 1;
					 mat.reflectedColor = 1;
					 mat.refractedColor = 0;
					 mat.reflectiveness = 0.5;
					 mat.refractiveness = 0;
					 mat.shinyness = 40;
					 mat.texAlpha = 1;
					 mat.refractiveIndex = float3(2.407, 2.426, 2.451);
				 }
				 else if (matIndex == 2)
				 {
					 mat.ambientColor = float3(1, 1, 1);
					 mat.diffuseColor = 1;
					 mat.specularColor = 1;
					 mat.reflectedColor = 0;
					 mat.refractedColor = _RefractedColor;
					 mat.reflectiveness = 0;
					 mat.refractiveness = 1;
					 mat.shinyness = 40;
					 mat.texAlpha = 0;
					 mat.refractiveIndex = 2;
				 }
				 else if (matIndex == 3)
				 {
					 mat.ambientColor = float3(1, 1, 1);
					 mat.diffuseColor = 1;
					 mat.specularColor = 1;
					 mat.reflectedColor = _ReflectedColor;
					 mat.refractedColor = 0;
					 mat.reflectiveness = 1;
					 mat.refractiveness = 0;
					 mat.shinyness = 40;
					 mat.texAlpha = 0;
					 mat.refractiveIndex = 2;
				 }
				 else if (matIndex == 4)
				 {
					 mat.ambientColor = _HdrColor;
					 mat.diffuseColor = 1;
					 mat.specularColor = 1;
					 mat.reflectedColor = 1;
					 mat.refractedColor = 0;
					 mat.reflectiveness = 0.1;
					 mat.refractiveness = 0;
					 mat.shinyness = 40;
					 mat.texAlpha = 0;
					 mat.refractiveIndex = 2;
				 }
				 return mat;
			 }

			 uniform float4 _Vertices[700];

			 //求射线和场景最近的交点
			 bool HitScene(Ray ray, inout Intersection minIntersection, inout int matIndex, bool inGeometry)
			 {
				 bool hitAnything = false;

				 for (int i = 0; i < 700;)
				 {
					 int length = _Vertices[i+1].x;

					 if (length == 0 || _Vertices[i].w == 0)
						 break;
					 
					 half3 sphereOrig = _Vertices[i].xyz;
					 half radius = _Vertices[i].w;

					 i += 2;

					 if (IntersectSphere(ray.origin, ray.direction, sphereOrig, radius))
					 {
						 for (int j = 0; j < length; j+=3)
						 {
							 Intersection intersection = noIntersection();
							 if (IntersectTriangle(float4(ray.origin, 1), float4(ray.direction, 0), float4(_Vertices[i+j].xyz, 1), float4(_Vertices[i + j + 1].xyz, 1), float4(_Vertices[i + j + 2].xyz, 1), intersection) && intersection.t > 0.001)
							 {
								 hitAnything = true;
								 if ((!hasIntersection(minIntersection) || intersection.t < minIntersection.t))
								 {
									 matIndex = _Vertices[i + j].w;
									 minIntersection = intersection;
									 if(minIntersection.inside == inGeometry)
										break;
								 }
							 }
						 }
					 }
					 i += length;
				 }
				 return hitAnything;
			 }

			 float3 lighting(Ray ray, Intersection intersection, Material material)
			 {
				 Light light;
				 light.position = _LightPos;
				 light.color = float3(1,1,1);

				 float3 colour = material.ambientColor;
				 float2 uv = intersection.position.xz;
				 colour = material.texAlpha < 0.5 ? material.ambientColor : frac((floor(uv.x) + floor(uv.y))/2)*2;
				 colour += material.texAlpha < 0.5 ? 0 : step(0.5, tex2D(_MagicTexture,((uv - _MagicOrigin.xz) / 5 + 0.5))) * _HdrColor * _MagicAlpha;
				 float3 lightDir = normalize(light.position - intersection.position);
				 float3 eyeDir = normalize(_WorldSpaceCameraPos - intersection.position);
				 colour += light.color * material.diffuseColor * max(dot(intersection.normal, lightDir), 0.0);
				 float3 reflected = normalize(reflect(-lightDir, intersection.normal));
				 colour += light.color * material.specularColor * pow(max(dot(reflected, eyeDir), 0.0), material.shinyness);
				 colour *= min(1.0 / pow(length(intersection.position - ray.origin), distanceAttenuationPower), 1.0);
				 
				 return colour;
			 }

			 
			 float4 TraceRay(Ray ray, float3 channel)
			 {
				 Ray rayTemp = ray;
				 float4 finalColor = 0;
				 float4 colorMask = 1;
				 bool inGeometry = false;

				 for (int i = 0; i < 4 && finalColor.a < 0.99; i++)
				 {
					 Intersection intersection = noIntersection();
					 float4 col;
					 int matIndex;
					 
					 if (HitScene(rayTemp, intersection, matIndex, inGeometry))
					 {

						
						 Material mat = GetMaterial(matIndex);

						 col = float4(lighting(rayTemp, intersection, mat), 1);

						 float alpha = mat.reflectiveness > 0 ? 1 - mat.reflectiveness : 1 - mat.refractiveness;

						 finalColor += col * alpha * (1 - finalColor.a) * colorMask;

						 if (mat.reflectiveness != 0)
							 colorMask *= float4(mat.reflectedColor,1);
						 else
							 colorMask *= float4(mat.refractedColor,1);

						 float3 normal = intersection.normal *(intersection.inside ? -1 : 1);

						 rayTemp.origin = intersection.position;

						 if (mat.reflectiveness != 0)
						 {
							 rayTemp.direction = reflect(rayTemp.direction, normal.xyz);
						 }
						 else
						 {
							 float refractIndex = dot(mat.refractiveIndex, channel);

							 refractIndex = intersection.inside ? refractIndex : 1 / refractIndex;

							 float3 reflection = refract(rayTemp.direction, normal, refractIndex);

							 if (dot(reflection, reflection) < 0.001)
							 {
								 rayTemp.direction = reflect(rayTemp.direction, normal.xyz);
							 }
							 else
							 {
								 rayTemp.direction = reflection;
								 inGeometry = !inGeometry;
							 }

						 }
					 }
					 else
					 {
						 break;
					 }
				 }

				 float4 bgCol = GetSkyColor(rayTemp.direction) * colorMask;
				 
				 finalColor.rgb = finalColor.xyz + bgCol * max(0, 1 - finalColor.a);

				 finalColor.a = 1;

				 return dot(finalColor,channel);
			 }

			 struct a2v {
				 float4 vertex : POSITION;
				 fixed3 normal : NORMAL;
				 fixed2 uv : TEXCOORD0;
			 };

			 struct v2f 
			 {
				 float4 pos : POSITION;
				 fixed2 uv : TEXCOORD0;
				 fixed3 vertex : TEXCOORD1;
				 float3 ray : TEXCOORD2;
			 };

			v2f vert(a2v v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;
				o.uv = v.uv;

				float4 cameraRay = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 1, 1));
				cameraRay.z *= -1;
				o.ray = cameraRay.xyz / cameraRay.w;

				return o;
			}

			fixed4 frag (v2f input) : SV_Target
			{
				float4 viewPos = float4(input.ray, 1);
				float4 worldPos = mul(unity_CameraToWorld, viewPos);
				float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
				
				float4 origin = float4(_WorldSpaceCameraPos,1);
				float4 dir = float4(-viewDir, 0);

				Ray ray;
				ray.origin = origin.xyz;
				ray.direction = dir.xyz;

				float4 frag = 0;

				frag.r = TraceRay(ray, float3(1, 0, 0));
				frag.g = TraceRay(ray, float3(0, 1, 0));
				frag.b = TraceRay(ray, float3(0, 0, 1));

				return frag;
			}
			ENDCG
		}
	}
}

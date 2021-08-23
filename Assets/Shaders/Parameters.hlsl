#ifndef PARAMETERS_HLSL
#define PARAMETERS_HLSL

float _Radius;

int _WaveCount;
float4 _WaveParameters[32];
float4 _WaveDirections[32];

sampler2D _Normalmap;
float _NormalmapScale;
float _NormalmapSpeed;
float _WaveNormalAmount;
            
float _AmplitudeModifier;
float _RefractionIntensity;
            
float3 _ShallowColor;
float3 _DeepColor;
float3 _FarColor;
			
sampler2D _EdgeFoamTexture;
float3 _EdgeFoamColor;
float _EdgeFoamDepth;
float _EdgeFoamIntensity;
float _EdgeFoamScale;
float _EdgeFoamSpeed;
            
float _DepthColorModifier;
float _DistanceDensity;

float3 _SubsurfaceScateringColor;
float _SubsurfaceScateringExponent;

float _SunSpecularExponent;

float _StartAmplitudeDamping;
float _EndAmplitudeDamping;

#endif
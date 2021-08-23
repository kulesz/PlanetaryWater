#ifndef STRUCTURES_HLSL
#define STRUCTURES_HLSL

struct Attributes
{
    float4 vertex   : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS				: SV_POSITION;
    float4 positionWSAndFogFactor   : TEXCOORD0;
    float3 normalWS                 : TEXCOORD1;
    float3 tangentWS                : TEXCOORD2;
    float3 bitangentWS              : TEXCOORD3;
    float4 parameters				: TEXCOORD4;

#ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    float4 shadowCoord              : TEXCOORD5;
#endif
};

#endif
#ifndef TESSELATION_HLSL
#define TESSELATION_HLSL

#define MAX_TESSELLATION_FACTORS 64.0

struct TessControlPoint
{
    float4 vertex   : INTERNALTESSPOS;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TessellationFactors
{
    float edge[3]  : SV_TessFactor;
    float inside   : SV_InsideTessFactor;
};

float _TesselationPower;
float _MinTesslationDistance;
float _MaxTesslationDistance;

[maxtessfactor(MAX_TESSELLATION_FACTORS)]
[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HullConstant")]
[outputcontrolpoints(3)]
TessControlPoint Hull(InputPatch<TessControlPoint, 3> input, uint id : SV_OutputControlPointID)
{
    // Nothing to see here...
    return input[id];
}

float TessellationEdgeFactor(TessControlPoint v0, TessControlPoint v1)
{
    float3 p0 = mul(unity_ObjectToWorld, float4(v0.vertex.xyz, 1)).xyz;
    float3 p1 = mul(unity_ObjectToWorld, float4(v1.vertex.xyz, 1)).xyz;

    float3 edgeCenter = (p0 + p1) * 0.5;
    float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

    // Use distance based tesselation with min/max ranges between 1 and _TesselationPower.
    return max(1, _TesselationPower * (1 - saturate((viewDistance - _MinTesslationDistance) / (_MaxTesslationDistance - _MinTesslationDistance))));
}
            
TessellationFactors HullConstant(InputPatch<TessControlPoint, 3> input)
{
    TessellationFactors output;
    output.edge[0] = TessellationEdgeFactor(input[1], input[2]);
    output.edge[1] = TessellationEdgeFactor(input[2], input[0]);
    output.edge[2] = TessellationEdgeFactor(input[0], input[1]);
                
    output.inside = (output.edge[0] + output.edge[1] + output.edge[2]) * 0.3333333333333333;

    return output;
}

#endif
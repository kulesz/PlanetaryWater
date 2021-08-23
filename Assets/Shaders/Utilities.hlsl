#ifndef UTILITIES_HLSL
#define UTILITIES_HLSL

float2 SampleWithOffset(float2 uv, float2 direction, float speed)
{
    return uv + normalize(direction) * speed * _Time.y;
}

float3 QuadNoiseSampleNormal(sampler2D tex, float2 uv, float speed)
{
    float2 uv1 = SampleWithOffset(uv + float2(0.00, 0.00), float2( 0.1,  0.1), speed);
    float2 uv2 = SampleWithOffset(uv + float2(0.42, 0.35), float2(-0.1, -0.1), speed);
    float2 uv3 = SampleWithOffset(uv + float2(0.87, 0.15), float2(-0.1,  0.1), speed);
    float2 uv4 = SampleWithOffset(uv + float2(0.65, 0.75), float2( 0.1, -0.1), speed);

    float3 normal1 = UnpackNormal(tex2D(tex, uv1)).rgb;
    float3 normal2 = UnpackNormal(tex2D(tex, uv2)).rgb;
    float3 normal3 = UnpackNormal(tex2D(tex, uv3)).rgb;
    float3 normal4 = UnpackNormal(tex2D(tex, uv4)).rgb;

    return normalize(normal1 + normal2 + normal3 + normal4);
}

#endif
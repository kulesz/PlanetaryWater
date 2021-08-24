Shader "WaterTesselated"
{
    Properties
    {
        [Header(Normals)]
        [Normal]
        [NoScaleOffset]
        _Normalmap ("Normalmap", 2D) = "bump" {}
        _NormalmapScale ("Normalmap scale", float) = 10
        _NormalmapSpeed ("Normalmap speed", float) = 1
        _WaveNormalAmount ("Wave normal amount", Range(0,1)) = 0.8
        
        [Header(Water surface colors)]
        [HDR]
        _ShallowColor ("Shallow water color", Color) = (0.44, 0.95, 0.36, 1.0)

        [HDR]
        _DeepColor ("Deep water color", Color) =  (0.0, 0.05, 0.19, 1.0)
        
        [HDR]
        _FarColor ("Far water color", Color) = (0.04, 0.27, 0.75, 1.0)
        
        [Header(Subsurface scattering)]
        [HDR]
        _SubsurfaceScateringColor ("Subsurface scattering color", Color) = (0.04, 0.27, 0.75, 1.0)
        _SubsurfaceScateringExponent ("Exponent", float) = 100
        
        [Header(Sun specular)]
        [HDR]
        _SunSpecularExponent ("Exponent", float) = 100
        
        [Header(Tesselation)]
        _TesselationPower("Tesselation power", Range(1, 24)) = 2
        _MinTesslationDistance("Min Tesselation distance", Range(10, 1000)) = 25
        _MaxTesslationDistance("Max Tesselation distance", Range(10, 1000)) = 100
        
        [Header(Shore blending)]
        _DepthColorModifier ("Depth", Range(0.0, 1.0)) = 0.5
        _DistanceDensity ("Distance", Range(0.0, 1.0)) = 0.1
        
        [Header(Shore foam)]
        [NoScaleOffset]
        _EdgeFoamTexture ("Texture", 2D) = "white" {}
        [HDR]
        _EdgeFoamColor ("Color", Color) = (1, 1, 1, 1)
        _EdgeFoamDepth ("Depth", Float) = 10.0
        _EdgeFoamIntensity ("Intensity", Range(0.0, 1.0)) = 1
        _EdgeFoamScale ("Scale", Float) = 0.1
        _EdgeFoamSpeed ("Speed", Float) = 0.2

        [Header(Amplitude damping)]
        _StartAmplitudeDamping ("Start amplitude damping", float) = 100
        _EndAmplitudeDamping ("End amplitude damping", float) = 200
        
        [Header(Other)]
        _AmplitudeModifier ("Amplitude modifier", Range(0, 1)) = 1
        _RefractionIntensity("Refraction intensity", Float) = 0.15

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        [ToggleOff]
        _SpecularHighlights("Specular Highlights", Float) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            "IgnoreProjector" = "True"
            "Queue" = "Transparent-1"
        }
        LOD 300

        Pass
        {
            Name "Planetary Water"
            Tags 
            {
                "LightMode" = "UniversalForward"
            }

            ZWrite On

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma require tessellation tessHW
            #pragma target 2.0

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHAPREMULTIPLY_ON

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            
            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain
            #pragma fragment Fragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            
            #include "Parameters.hlsl"
            #include "Structures.hlsl"
            #include "Tesselation.hlsl"
            #include "Utilities.hlsl"

            TessControlPoint Vertex(Attributes input)
            {
                TessControlPoint output;

                // Just pass vertex with object space position (rest will be computed later).
                output.vertex = input.vertex;

                return output;
            }

            Varyings TessellationVertex(TessControlPoint input)
            {
                float time = _Time.y;
                float3 positionOS = input.vertex.xyz;
                float3 positionOSNormalized = normalize(positionOS);

                float sinPart = 0;
                float3 cosPart = float3(0,0,0);

                float sinPartNorm = 0;
                float3 cosPartNorm = float3(0,0,0);
                
                float3 tangent = float3(0,0,0);

                float3 baseWorldPosition = mul(unity_ObjectToWorld, float4(positionOS, 1)).xyz;
                float distanceToCam = distance(baseWorldPosition, _WorldSpaceCameraPos);
                float ampitudeDamping = 1 - smoothstep(_StartAmplitudeDamping, _EndAmplitudeDamping, distanceToCam);

                // Based on Real-Time Rendering of Procedurally Generated Planets by Florian Michelic
                for (int waveIdx = 0; waveIdx < _WaveCount; waveIdx++)
                {
                    float4 waveParams = _WaveParameters[waveIdx];

                    float3 waveDir = _WaveDirections[waveIdx].xyz;
                    float3 waveDirNormalized = normalize(waveDir);

                    float A = _AmplitudeModifier * waveParams.x * ampitudeDamping;
                    float Q = waveParams.y;
                    float w = waveParams.z;
                    float fi = waveParams.w;
                    
                    float3 di = cross(positionOSNormalized, cross(positionOSNormalized -  waveDirNormalized, positionOSNormalized));
                    float li = acos(dot(positionOSNormalized, waveDirNormalized)) * _Radius;
                    
                    sinPart += A * sin(w * li + fi * time);
                    cosPart += Q * A * cos(w * li + fi * time) * di;

                    sinPartNorm += Q * A * w * sin(w * li + fi * time);
                    cosPartNorm += di * A * w * cos(w * li + fi * time);

                    float3 diCross = cross(di, positionOSNormalized);
                    tangent += diCross / length(diCross);		
                }

                tangent = normalize(tangent);
                
                float3 surfaceLevel = positionOSNormalized * _Radius;
                float3 waveMovement = positionOSNormalized * sinPart + cosPart;
                float3 wavePosition = surfaceLevel + waveMovement;
                
                float3 waveNormal = positionOSNormalized - positionOSNormalized * sinPartNorm - cosPartNorm;
                waveNormal = lerp(positionOSNormalized, waveNormal, _WaveNormalAmount);
                waveNormal = normalize(waveNormal);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(wavePosition.xyz);

                float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                // Fill output data.
                Varyings output;
                output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
                output.normalWS = waveNormal;
                output.tangentWS = tangent;
                output.bitangentWS = cross(output.normalWS, output.tangentWS);
                output.parameters = float4(length(wavePosition) - _Radius, 0, 0, 1);

#ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                output.shadowCoord = GetShadowCoord(vertexInput);
#endif
                output.positionCS = vertexInput.positionCS;
                
                return output;
            }
   
            [domain("tri")]
            Varyings Domain(TessellationFactors factors, const OutputPatch<TessControlPoint, 3> input, float3 baryCoords : SV_DomainLocation)
            {
                float fU = baryCoords.x;
                float fV = baryCoords.y;
                float fW = baryCoords.z;

                float4 pos = input[0].vertex * fU + input[1].vertex * fV + input[2].vertex * fW;
                
                TessControlPoint output;
                output.vertex = pos;
                UNITY_TRANSFER_INSTANCE_ID(input[0], output);

                return TessellationVertex(output);
            }

            float4 Fragment(Varyings input) : SV_Target
            {
                // Some coordinates / directions that will be used later.
                float3 positionWS = input.positionWSAndFogFactor.xyz;
                float3 viewDirWS = normalize(positionWS - _WorldSpaceCameraPos);
                float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - positionWS);

                // Sample tangent normalmap as triplanar.
                float3 normalUV = positionWS * _NormalmapScale;
                float3 normalTS_zy = QuadNoiseSampleNormal(_Normalmap, normalUV.zy, _NormalmapSpeed);
                float3 normalTS_zx = QuadNoiseSampleNormal(_Normalmap, normalUV.zx, _NormalmapSpeed);
                float3 normalTS_xy = QuadNoiseSampleNormal(_Normalmap, normalUV.xy, _NormalmapSpeed);

                // Calculate blending direction (vector that "mixes" three normalmaps).
                float3 blendingDirection = abs(input.normalWS);
                blendingDirection /= blendingDirection.x + blendingDirection.y + blendingDirection.z + 1e-6f;

                // Blend and calculate world space normalmap.
                float3 normalTS = blendingDirection.x * normalTS_zy + blendingDirection.y * normalTS_zx + blendingDirection.z * normalTS_xy;          	
                float3 normalWS = normalize(normalTS.x * input.tangentWS + normalTS.y * input.bitangentWS + normalTS.z * input.normalWS);

                // Screen space position for sampling depth and scene color textures.
                float2 positionSS = input.positionCS.xy / _ScaledScreenParams.xy;

                // Sample depth.
                #if UNITY_REVERSED_Z
                    float depth = SampleSceneDepth(positionSS);
                #else
                    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(positionSS));
                #endif

                // Calculate depth transmittance.
                float opticalDepth =abs(LinearEyeDepth(depth, _ZBufferParams) - LinearEyeDepth(input.positionCS.z, _ZBufferParams));
                float transmittance = exp(-_DepthColorModifier * opticalDepth);

                // Sample scene color from scene color texture (and apply simple refraction).
                float3 sceneColor = SampleSceneColor(positionSS + normalTS.xy * _RefractionIntensity);

                // Calculate shadow coords and sample main (directional) light.
                float4 shadowCoord;
                
#ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
                shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                shadowCoord = TransformWorldToShadowCoord(positionWS);
#else
                shadowCoord = float4(0, 0, 0, 0);
#endif

                Light mainLight = GetMainLight(shadowCoord, positionWS, float4(0,0,0,0));

                // Shadow mask will be used to adjust intensity of some features.
                float shadowMask = mainLight.shadowAttenuation;
                
                // Sample additional (point or spot) lights and apply them to shadow mask too.
#ifdef _ADDITIONAL_LIGHTS
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < additionalLightsCount; i++)
                {
                    Light light = GetAdditionalLight(i, positionWS, float4(1,1,1,1));
                    shadowMask *= light.shadowAttenuation;
                }
#endif

                // Calculate foam UV (also as triplanar in world space) and sample foam texture.
                float3 foamUV = (positionWS * _EdgeFoamScale) + (_Time.y * _EdgeFoamSpeed * float3(1,1,1));
                float edgeFoamTextureMask = (blendingDirection.x * tex2D(_EdgeFoamTexture, foamUV.zy) + blendingDirection.y * tex2D(_EdgeFoamTexture, foamUV.zx) + blendingDirection.z * tex2D(_EdgeFoamTexture, foamUV.xy)).r;
                edgeFoamTextureMask = lerp(1, edgeFoamTextureMask, _EdgeFoamIntensity);

                // Mask foam color by depth value and calulate final foam color.
                float edgeFoamDepthMask = exp(-opticalDepth / _EdgeFoamDepth);
                float edgeFoamMask = step(edgeFoamTextureMask, edgeFoamDepthMask);
                float3 edgeFoamColor = lerp(0, _EdgeFoamColor, edgeFoamMask);

                // Make smoother normals where foam is present (do not use normalmap).
                normalWS = lerp(normalWS, input.normalWS, edgeFoamMask);
                
                // Create distance from camera mask.
                float distanceMask = exp(-_DistanceDensity * length(positionWS - _WorldSpaceCameraPos));

                // Calculate base water color - use transmitance to determine depth and distance to add additional "far" color.
                float3 baseColor = sceneColor * _ShallowColor;
                baseColor = lerp(_DeepColor, baseColor, transmittance * max(0.25, shadowMask));
                baseColor = lerp(_FarColor, baseColor, distanceMask);

                // Add foam color.
                baseColor += edgeFoamColor;
                
                // Initialize BRDF (lightning) data.
                float metallic = 0;
                float specular = 1;
                float alpha = 1;
                float occlusion = 1;

                BRDFData brdfData;
                InitializeBRDFData(baseColor, metallic, specular, _Smoothness, alpha, brdfData);
                
                // Iterate through additional lights once again and compute their color contribution.
                float3 additionalLightsColor = 0;
                
#ifdef _ADDITIONAL_LIGHTS
                for (int i = 0; i < additionalLightsCount; i++)
                {
                    Light light = GetAdditionalLight(i, positionWS, float4(1,1,1,1));
                    additionalLightsColor += LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
                }
#endif
                // Reflection vector and specular masks (used for specular reflections and subsurface scattering).
                float3 viewR = reflect(viewDirWS, normalWS);
                float sunSpecularMask = saturate(dot(viewR, _MainLightPosition.xyz));
                float subsurfaceScatteringMask = saturate(pow(sunSpecularMask, _SubsurfaceScateringExponent));
                
                // Compute subsurface scattering color (use the wave height and main light color).
                float3 subsurfaceScatteringColor = _SubsurfaceScateringColor * saturate(input.parameters.x) * mainLight.color;           	

                // Adjust subsurface scattering color by the view and light direction. Also use shadowmask to dim it.
                subsurfaceScatteringColor *= saturate(dot(viewDirWS, _MainLightPosition.xyz));
                subsurfaceScatteringColor = subsurfaceScatteringMask * lerp(float3(0,0,0), subsurfaceScatteringColor, max(0.25, shadowMask));

                // Calculate the sun specular mask (dimmed only by main light).
                sunSpecularMask = round(saturate(pow(sunSpecularMask, _SunSpecularExponent)));
                sunSpecularMask = sunSpecularMask * mainLight.shadowAttenuation;
                
                // Get the sun specular color to add into the final color later on.
                float3 sunSpecularColor = lerp(0, mainLight.color, sunSpecularMask);
    
                // Mix diffuse GI with environment reflections and compute direct light contribution.
                half3 bakedGI = SampleSH(normalWS);
                float3 finalColor = GlobalIllumination(brdfData, bakedGI, occlusion, normalWS, viewDirectionWS);
                finalColor += LightingPhysicallyBased(brdfData, mainLight, normalWS, viewDirectionWS);

                // Add additional elements.
                finalColor += sunSpecularColor + subsurfaceScatteringColor + additionalLightsColor;

                // Mix color with fog.
                float fogFactor = input.positionWSAndFogFactor.w;
                finalColor = MixFog(finalColor, fogFactor);
                
                return float4(finalColor, alpha);
            }
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/Meta"
    }
}
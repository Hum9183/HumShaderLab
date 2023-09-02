Shader "HumShaderLab/AdditionalLights"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainColor]   _BaseColor("Base Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS    : SV_POSITION;
                float2 uv             : TEXCOORD0;
                float3 positionWS     : TEXCOORD1;
                float3 normalWS       : TEXCOORD2;
            #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                half3  vertexLighting : TEXCOORD3;
            #endif
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.texcoord, _BaseMap);

            #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                OUT.vertexLighting = VertexLighting(OUT.positionWS, OUT.normalWS);
            #endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 baseMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb;
                half3 diffuse = baseMapColor * _BaseColor.rgb;
                half3 finalColor = diffuse;

            #if defined(_ADDITIONAL_LIGHTS)
                uint pixelLightCount = GetAdditionalLightsCount();

                half3 additionalLightsColor;

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, IN.positionWS, 1.0);
                    half NdotL = saturate(dot(IN.normalWS, light.direction));
                    half3 lightColor = light.color * light.distanceAttenuation * light.shadowAttenuation * NdotL;
                    additionalLightsColor += diffuse * lightColor;
                LIGHT_LOOP_END

                finalColor += additionalLightsColor;
            #endif

            #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                half3 vertexLightingColor = diffuse * IN.vertexLighting;
                finalColor += vertexLightingColor;
            #endif

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}

Shader "HumShaderLab/Blinn-Phong"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainColor]   _BaseColor("Base Color", Color) = (1,1,1,1)
        _SpecularAperture("SpecularAperture", Range(5.0, 20.0)) = 16.0
        _Ambient("Ambient", Range(0.0, 0.5)) = 0.1
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                half3  viewDirWS    : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _SpecularAperture;
                half _Ambient;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS   = TransformObjectToHClip(IN.positionOS.xyz);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS      = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS     = GetWorldSpaceNormalizeViewDir(positionWS);
                OUT.uv = TRANSFORM_TEX(IN.texcoord, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 baseMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb;
                half3 diffuse = baseMapColor * _BaseColor.rgb;

                half3 mainLightColor = _MainLightColor.rgb;
                half3 mainLightDirWS = _MainLightPosition.xyz;

                // Lambert
                half NdotL = dot(IN.normalWS, mainLightDirWS);
                NdotL = saturate(NdotL);
                half3 lambert = NdotL * mainLightColor;

                // Specular
                float3 halfVector = SafeNormalize(mainLightDirWS + IN.viewDirWS);
                float NdotH = dot(IN.normalWS, halfVector);
                NdotH = saturate(NdotH);
                NdotH = pow(NdotH, _SpecularAperture);
                half3 specular = mainLightColor * NdotH;

                // Ambient
                half ambient = _Ambient;

                // Composite diffuse and final light color
                half3 finalLightColor = lambert + specular + ambient;
                half3 finalColor = diffuse * finalLightColor;

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}

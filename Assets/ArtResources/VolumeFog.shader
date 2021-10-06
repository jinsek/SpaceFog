Shader "Unlit/VolumeFog"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Density("Density", float) = 0.02
        _Steps("Steps", float) = 32
        _VolumeHeight("Volume Height", float) = 1024
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        Pass
        {
            ZTest Always
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            struct Attributes
            {
                float4 positionOS     : POSITION;
            };
            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 worldPos     : TEXCOORD0;
                float4 screenPos    : TEXCOORD1;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Density;
            float _Steps;
            float _VolumeHeight;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.worldPos = vertexInput.positionWS;
                output.screenPos = vertexInput.positionNDC;
                return output;
            }
            //phase functions
            float4 phaseFunc(float3 dir) {
                Light mainLight = GetMainLight();
                float theta = dot(-dir, mainLight.direction);
                return (1.0 + pow(theta, 2.0)) * 3.0 / 16.0 / PI * float4(mainLight.color, 1);
            }
            half4 RayMarching(float3 start, float3 dir, float stepsize, int steps)
            {
                half4 sampledColor = 0;
                [loop]
                for (int i = 0; i < steps; ++i) {
                    float3 samplePos = start + i * stepsize * dir;
                    float height = (samplePos.y + _VolumeHeight) / _VolumeHeight / 2;
                    half4 volColor = tex2D(_MainTex, float2(0, height));
                    sampledColor += volColor.r * phaseFunc(dir) * _Density;
                }
                return sampledColor;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 uv = input.screenPos.xy / input.screenPos.w;
                float rawDepth = SampleSceneDepth(uv);
                float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);
                float3 viewDirWS = normalize(input.worldPos - GetCameraPositionWS());
                float volumeEnd = length(viewDirWS);
                float3 end = GetCameraPositionWS() + min(volumeEnd, sceneZ) * viewDirWS;
                float3 start = GetCameraPositionWS() + _ProjectionParams.y * viewDirWS;
                float stepsize = length(end - start) / _Steps;
                half4 fogColor = RayMarching(start, viewDirWS, stepsize, _Steps);
                return fogColor;
            }
            ENDHLSL
        }
    }
}

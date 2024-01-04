// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "RyToon2"
{
    Properties
    {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _SpecularTint ("Specular Tint", Color) = (0.5, 0.5, 0.5)
    }
    SubShader
    {
        Tags {
            "LightMode" = "ForwardBase"
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog               // Make fog work.

            #include "UnityStandardBRDF.cginc"      // Included for access to DotClamped and other useful shader functions.
            #include "UnityStandardUtils.cginc"     // Included for access to EnergyConservationBetweenDiffuseAndSpecular function.

			struct VertexData {
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
			};

            // Shader Variables
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Tint;
            float _Smoothness;
            fixed3 _SpecularTint;

			Interpolators vert (VertexData v) {
				Interpolators i;
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.position = UnityObjectToClipPos(v.position);
                i.worldPos = mul(unity_ObjectToWorld, v.position);  // Vertex World Position
				//i.normal = v.normal;                              // Object Space Normals
                i.normal = UnityObjectToWorldNormal(v.normal);      // World Space Normals
				return i;
			}

            fixed4 frag (Interpolators i) : SV_Target
            {
                // You can skip renormalizing for better performance on mobile devices.
                // Renormalize because lerping between vertices will not result in a unit-length vector.
                i.normal = normalize(i.normal);

                //UNITY_APPLY_FOG(i.fogCoord, col);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
                float3 halfVector = normalize(lightDir + viewDir);

                // Factor the specular tint into the albedo so the lighting will never exceed the light source strength.
                // We'll use Unity's built in function from 'UnityStandardUtils.cginc' for calculating energy conservation.
                float oneMinusReflectivity;
                albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo, _SpecularTint.rgb, oneMinusReflectivity);

                float3 specular = _SpecularTint.rgb * lightColor * pow(
                    DotClamped(halfVector, i.normal),
                    _Smoothness * 100
                );
                return float4(diffuse + specular, 1);
            }
            ENDCG
        }
    }
}
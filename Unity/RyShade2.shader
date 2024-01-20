Shader "RyToon2"
{
    Properties
    {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Pass
        {
			Tags {
				"LightMode" = "ForwardBase"
			}
			LOD 100

            CGPROGRAM

            #pragma target 3.0
			#pragma multi_compile _ VERTEXLIGHT_ON
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

			#define FORWARD_BASE_PASS
			#include "MyLighting.cginc"

            ENDCG
        }

		// Second pass draws lighing for additional directional, point and spot lights.
		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0
			#pragma multi_compile DIRECTIONAL POINT SPOT
			#pragma vertex vert
			#pragma fragment frag
			#include "MyLighting.cginc"
			ENDCG
		}
    }
}
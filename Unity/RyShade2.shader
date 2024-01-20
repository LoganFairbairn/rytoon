Shader "RyToon2"
{
    Properties
    {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
    }
    SubShader
    {
        Pass
        {
			Tags {
				"LightMode" = "ForwardBase"
				"RenderType" = "Opaque"
			}
			LOD 100

            CGPROGRAM

            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog               // Make fog work.
			#include "MyLighting.cginc"

			#if !defined(MY_LIGHTING_INCLUDED)
			#define MY_LIGHTING_INCLUDED
			#include "UnityPBSLighting.cginc"
			#endif

            ENDCG
        }

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "MyLighting.cginc"
			ENDCG
		}
    }
}
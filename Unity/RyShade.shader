// Github for this shader: https://github.com/LoganFairbairn/RyToon

Shader "RyShade" {
    Properties {
        [MainColor] _Tint ("Tint", Color) = (1, 1, 1, 1)
        [MainTexture] _ColorTexture ("Color Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _ORMTexture ("ORM Texture", 2D) = "black" {}
        [Gamma] _Roughness ("Roughness Offset", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic Offset", Range(0, 1)) = 0
        _SubsurfaceTexture ("Subsurface Texture", 2D) = "black" {}
        _SubsurfaceIntensity ("Subsurface Intensity", Range(0, 1)) = 0
        _SubsurfaceWrap ("Subsurface Wrap", Range(0, 1)) = 0.2
        _SubsurfaceTint ("Subsurface Tint", Color) = (1.0, 0.0, 0.0, 1.0)
        _SubsurfaceWidth ("Subsurface Width", Range(0, 1)) = 0.5
        _EmissionColor ("Color", Color) = (1, 1, 1, 1)
        _EmissionStrength ("Emission Strength", Range(0, 10)) = 0
        _EmissionTexture ("Emission Texture", 2D) = "black" {}
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf RyToon fullforwardshadows
        #pragma target 3.0

        #include "UnityStandardUtils.cginc"

        #define PI 3.14159265358979323846f

        struct Input {
            float2 uv_ColorTexture;
            float2 uv_NormalMap;
            float2 uv_EmissionTexture;
        };

        struct CustomSurfaceOutput {
            half3 Albedo;
            half3 Normal;
            half3 Specular;
            half3 Emission;
            half Alpha;
        };

        // Custom Properties
        sampler2D _ColorTexture;
        sampler2D _ORMTexture;
        sampler2D _NormalMap;
        sampler2D _EmissionTexture;
        fixed4 _Tint;
        half _Roughness;
        half _Metallic;
        half _SubsurfaceIntensity;
        half _SubsurfaceWrap;
        fixed4 _SubsurfaceTint;
        fixed4 _SheenColor;
        half _SheenIntensity;
        half _SubsurfaceWidth;

        // Add shader instancing support.
		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

        /*----------------------------- Shader Functions -----------------------------*/

        // Convenience function for squaring values.
        float sqr(half value) {
            return value * value;
        }

        // Beckmann microfacet distribution (used in the Cook-Torrance function).
        half BeckmannDistribution(half NdotH, half roughness) {
            half alpha = roughness;
            half cosThetaH = NdotH;
            half tanThetaHSqr = max(0.0, (1.0 - cosThetaH * cosThetaH) / (cosThetaH * cosThetaH));
            return saturate(exp(-tanThetaHSqr / (alpha * alpha)) / (PI * alpha * alpha * cosThetaH * cosThetaH * cosThetaH * cosThetaH));
        }

       /*----------------------------- Custom Lighting Calculations -----------------------------*/
        inline half4 LightingRyToon (CustomSurfaceOutput s, half3 viewDir, UnityGI gi) {

            UnityLight light = gi.light;

            // Ensure input variables are normalized.
            viewDir = normalize(viewDir);
            half3 lightDir = normalize(light.dir);
            s.Normal = normalize(s.Normal);

            // Calculate variables used in this shaders lighting calculations.
            half3 halfAngle = normalize(lightDir + viewDir);
            half NdotL = saturate(dot(s.Normal, lightDir));
            half NdotH = saturate(dot(s.Normal, halfAngle));
            half NdotV = saturate(dot(s.Normal, viewDir));
            half LdotH = saturate(dot(lightDir, halfAngle));
            half HdotV = saturate(dot(halfAngle, viewDir));

            /*----------------------------- Diffuse Lighting -----------------------------*/
            // Half Lambert lighting is a technique created by Valve for Half-Life designed to prevent the rear of the object from losing it's shape.
            // This technique provides a good middle ground between a totally toon lighting approach and a physically accurate approach.
            // Calculate diffuse lighting using the half-lambert lighting method.
            half3 diffuse = max(0, NdotL * 0.5 + 0.5);

            /*----------------------------- Specular Highlights, Metallic & Environment Reflections -----------------------------*/

            /*
            // The 'Glossy BSDF' node in Blender has a Beckmann distribution model, so we can match that by calculating the Beckmann distribuition here.
            // To simulate smooth and rough materials, calculate specular highlights using the Beckmann distribution model.
            half3 specularTint;
            half oneMinusReflectivity;
            half3 albedo = DiffuseAndSpecularFromMetallic(
                s.Albedo, _Metallic, specularTint, oneMinusReflectivity
            );

            // To simulate smoothness and roughness calculate specular highlights using the Cook-Torrance method.
            //half3 specular = specularTint * light.color * CookTorrance(NdotL, NdotH, NdotV, LdotH, HdotV, clamp(_Roughness, 0.025, 1.0), _SpecularColor);
            half specular = light.color * BeckmannDistribution(NdotH, _Roughness);

            // Calculate skybox reflections from the Unity scene.
            half3 reflectedDir = reflect(halfAngle, s.Normal);
            half4 cubemapSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectedDir);
            half3 sceneReflection = DecodeHDR(cubemapSample, unity_SpecCube0_HDR);
            */

            /*----------------------------- Fast Subsurface Scattering -----------------------------*/
            // Subsurface scattering simulates light scattering through objects such as skin, milk, food, wax and sometimes clothes.
            // Many modern stylized shaders take advantage of subsurface scattering, making it an important part in a modern stylized shader.
            // Since we don't need realistic subsurface scattering for a stylized shader, we'll use a fast approximation of subsurface.
            // We can calculate a fast approximation of subsurface scattering using a ramped version of the diffuse lighting.
            // This is a technique often refered to as a 'diffuse wrap'.
            half diffuse_wrap = max(0, (diffuse + _SubsurfaceWrap) / (1 + _SubsurfaceWrap));
            half3 subsurface = smoothstep(0.0, _SubsurfaceWidth, diffuse_wrap) * smoothstep(_SubsurfaceWidth * 2, _SubsurfaceWidth, diffuse_wrap) * _SubsurfaceTint * _SubsurfaceIntensity;

            /*----------------------------- Calculate Accumulated Lighting -----------------------------*/

            half4 c = half4(diffuse + subsurface, s.Alpha);

			//#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
			//	c.rgb += s.Albedo * gi.indirect.diffuse;
			//#endif

            return c;
        }

        inline void LightingRyToon_GI(CustomSurfaceOutput s, UnityGIInput data, inout UnityGI gi) {
            gi = UnityGlobalIllumination(data, 1.0, s.Normal);
        }

        /*----------------------------- Apply Textures & Channel Packing  -----------------------------*/
        void surf (Input IN, inout CustomSurfaceOutput o) {
            o.Albedo = (tex2D (_ColorTexture, IN.uv_ColorTexture).rgb) * _Tint;
            //o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
            //o.Emission = (tex2D (_EmissionTexture, IN.uv_EmissionTexture).rgb);
        }
        ENDCG
    } 

    Fallback "Diffuse"
    CustomEditor "RyShadeGUI"
}
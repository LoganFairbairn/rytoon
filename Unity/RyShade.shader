// RyToon is an NPR (non-photo-realistic) shader that's designed to render anime and toon assets 'half way' between physicially based and a fully toon shader.
// The aim of the shader is to allow assets to look 'toon like', while still looking good, and not out of place in most lighting conditions.
// This makes the use of the shader ideal for VRChat as many worlds use PBR realistic lighting, while many characters are toon based.

// A big benefit of using this shader is there is an equivalent shader in Blender, where the mathematical algorithms for lighting and the input parameters are compatible.
// This allows users to view how their assets will look like in Blender without having to import them into Unity.
// Github for this shader: https://github.com/LoganFairbairn/RyToon

// Reference links for this shader:
// Fast Subsurface Scattering for Unity URP                     -   https://johnaustin.io/articles/2020/fast-subsurface-scattering-for-the-unity-urp
// Lighting Models in Unity                                     -   https://www.jordanstevenstechart.com/lighting-models
// Genshin Impact Shader in UE5                                 -   https://www.artstation.com/artwork/g0gGOm
// Ben Ayers Blender NPR Genshin Impact Shader                  -   https://www.artstation.com/blogs/bjayers/9oOD/blender-npr-recreating-the-genshin-impact-shader
// Unity Surface Shader Lighting Examples                       -   https://docs.unity3d.com/Manual/SL-SurfaceShaderLightingExamples.html
// Support all light shadow types with 'fullforwardshadows'     -   https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
// Inspired by the Poiyomi toon shader                          -   https://github.com/poiyomi/PoiyomiToonShader
// Specular Highlight Wiki                                      -   https://en.wikipedia.org/wiki/Specular_highlight
// Fresnel Wiki                                                 -   https://en.wikipedia.org/wiki/Fresnel_equations
// Beckmann Distribution Wiki                                   -   https://en.wikipedia.org/wiki/Specular_highlight#Beckmann_distribution
// Schlick's Approximation Wiki                                 -   https://en.wikipedia.org/wiki/Schlick%27s_approximation
// Catlike Coding Rendering Tutorial                            -   https://catlikecoding.com/unity/tutorials/rendering/


Shader "RyToon" {
    Properties {
        [MainColor] _Color ("Color", Color) = (1, 1, 1, 1)
        [MainTexture] _ColorTexture ("Color Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _ORMTexture ("ORM Texture", 2D) = "black" {}
        _EmissionTexture ("Emission Texture", 2D) = "black" {}
        [Gamma] _Roughness ("Roughness", Range(0, 1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _SubsurfaceIntensity ("Subsurface Intensity", Range(0, 1)) = 0
        _SubsurfaceRadius ("Subsurface Radius", Range(0, 1)) = 0.5
        _SubsurfaceColor ("Subsurface Color", Color) = (1.0, 0.2, 0.1, 1.0)
        _SheenIntensity ("Sheen Intensity", Range(0, 1)) = 0.0
        _SheenColor ("Sheen Color", Color) = (1, 1, 1, 1)
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
        fixed4 _Color;
        half _Roughness;
        half _Metallic;
        half _SubsurfaceIntensity;
        half _SubsurfaceRadius;
        fixed4 _SubsurfaceColor;
        fixed4 _SheenColor;
        half _SheenIntensity;

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

        // Deprecated
        /*
        half CookTorrance(half NdotL, half NdotH, half3 NdotV, half LdotH, half HdotV, half roughness, half F0) {
            // Calculate microfacet distribution using the Beckmann method.
            half D = BeckmannDistribution(NdotH, roughness);
            
            // Calculate fresnel using Schlick's approximation.
            half F = F0 + (1 - F0) * pow(saturate(1 - HdotV), 5);

            // Inverted Fresnel
            //half F = saturate(1 - NdotV);

            // Calculate geometric attenuation.
            half G1 = 2 * NdotH * NdotV / HdotV;
            half G2 = 2 * NdotH * NdotL / HdotV;
            half G = min(1, min(G1, G2));

            // Accumulate specular reflection (modded calculation).
            return (D * F * G) * NdotL;

            // Official 'Wiki' version of the accumulated cook-torrance calculation.
            //return (D * F * G) / 4 * NdotV * NdotL;
        }
        */

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

            /*----------------------------- Sheen -----------------------------*/
            // Calculate a sheen approximation, which is useful for simulating microfiber lighting for fabric and cloth.
            half sheen = pow(1 - dot(s.Normal, halfAngle), 5) * _SheenIntensity * _SheenColor;

            /*----------------------------- Specular Highlights & Metallic -----------------------------*/

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

            /*----------------------------- Artifical Metallic -----------------------------*/
            // Experimental...
            // Calculate artifical metalness as a spherical gradient matcap.
            /*
            half3 viewSpaceNormals = mul((float3x3)UNITY_MATRIX_V, s.Normal);
            viewSpaceNormals.xyz *= float3(0.5, 0.5, 1.0);
            half metallic = saturate(1 - (length(viewSpaceNormals)));
            metallic = lerp(1, smoothstep(0.3, 0.0, metallic), _Metallic);
            */

            /*----------------------------- Diffuse Lighting -----------------------------*/
            // Half Lambert lighting is a technique created by Valve for Half-Life designed to prevent the rear of the object from losing it's shape.
            // This technique provides a good middle ground between a totally toon lighting approach and a physically accurate approach.
            // Calculate diffuse lighting using the half-lambert lighting model.
            half3 diffuse = albedo * light.color * pow(NdotL * 0.5 + 0.5, 2);

            /*----------------------------- Artifical Subsurface Scattering -----------------------------*/
            // Subsurface scattering simulates light scattering through objects such as skin, food, wax and clothes, and is important for modern anime and toon shaders looking good, use the Genshin Impact shader as an example.
            // We'll calculation a diffuse wrap (similar to half lambert) as an approximation for subsurface scattering.
            half3 subsurface = pow(NdotL * _SubsurfaceRadius + (1 - _SubsurfaceRadius), 2) * _SubsurfaceColor * _SubsurfaceIntensity;

            /*----------------------------- Environment Reflections -----------------------------*/
            // Calculate skybox reflections from the Unity scene.
            half3 reflectedDir = reflect(halfAngle, s.Normal);
            half4 cubemapSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectedDir);
            half3 sceneReflection = DecodeHDR(cubemapSample, unity_SpecCube0_HDR);

            /*----------------------------- Calculate Accumulated Lighting -----------------------------*/

            half4 c = half4(diffuse + specular + subsurface, s.Alpha);

			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += s.Albedo * gi.indirect.diffuse;
			#endif

            return c;
        }

        inline void LightingRyToon_GI(CustomSurfaceOutput s, UnityGIInput data, inout UnityGI gi) {
            gi = UnityGlobalIllumination(data, 1.0, s.Normal);
        }

        /*----------------------------- Apply Textures & Channel Packing  -----------------------------*/
        void surf (Input IN, inout CustomSurfaceOutput o) {
            o.Albedo = (tex2D (_ColorTexture, IN.uv_ColorTexture).rgb) * _Color;
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
            o.Emission = (tex2D (_EmissionTexture, IN.uv_EmissionTexture).rgb);
        }
        ENDCG
    } 
    Fallback "Diffuse"
}
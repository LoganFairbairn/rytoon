// RyToon is an NPR (non-photo-realistic) shader that's designed to render anime and toon assets 'half way' between physicially based and a fully toon shader.
// The aim of the shader is to allow assets to look 'toon like', while still looking good, and not out of place in most lighting conditions.
// This makes the use of the shader ideal for VRChat as many worlds use PBR realistic lighting, while many characters are toon based.

// A big benefit of using this shader is there is an equivalent shader in Blender, where the mathematical algorithms for lighting and the input parameters are compatible.
// This allows users to view how their assets will look like in Blender without having to import them into Unity.
// Github for this shader: https://github.com/LoganFairbairn/RyToon

// Reference links for this shader:
// Fast Subsurface Scattering for Unity URP     -   https://johnaustin.io/articles/2020/fast-subsurface-scattering-for-the-unity-urp
// Genshin Impact Shader in UE5                 -   https://www.artstation.com/artwork/g0gGOm
// Ben Ayers Blender NPR Genshin Impact Shader  -   https://www.artstation.com/blogs/bjayers/9oOD/blender-npr-recreating-the-genshin-impact-shader
// Unity Surface Shader Lighting Examples       -   https://docs.unity3d.com/Manual/SL-SurfaceShaderLightingExamples.html

Shader "MatLayer/RyToon" {
    Properties {
        [MainColor] _Color ("Color", Color) = (1, 1, 1, 1)
        [MainTexture] _ColorTexture ("Color Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _ORMTexture ("ORM Texture", 2D) = "black" {}
        _EmissionTexture ("Emission Texture", 2D) = "black" {}
        _Roughness ("Roughness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0
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

        // Support all light shadow types with 'fullforwardshadows' https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
        #pragma surface surf RyToon fullforwardshadows
        #pragma target 3.0

        #define PI 3.14159265358979323846f

        // Input Structure
        struct Input {
            float2 uv_ColorTexture;
            float2 uv_NormalMap;
            float2 uv_EmissionTexture;
        };

        // Custom Properties
        sampler2D _ColorTexture;
        sampler2D _ORMTexture;
        sampler2D _NormalMap;
        sampler2D _EmissionTexture;
        fixed4 _Color;
        half _Roughness;
        float _Metallic;
        half _SubsurfaceIntensity;
        half _SubsurfaceRadius;
        fixed4 _SubsurfaceColor;
        fixed4 _SheenColor;
        float _SheenIntensity;

        float BeckmannNormalDistribution(float roughness, float NdotH)
        {
            float roughnessSqr = roughness * roughness;
            float NdotHSqr = NdotH * NdotH;
            return max(0.000001,(1.0 / (3.1415926535 * roughnessSqr * NdotHSqr * NdotHSqr)) * exp((NdotHSqr-1)/(roughnessSqr*NdotHSqr)));
        }

        // Custom surface output defines the input and output required for shader calculations.
        struct CustomSurfaceOutput {
            half3 Albedo;
            half3 Normal;
            half3 Emission;
            half Alpha;
        };

        // Calculate custom lighting here.
        half4 LightingRyToon (CustomSurfaceOutput s, half3 lightDir, half viewDir, half atten) {


            /*----------------------------- Base Lighting -----------------------------*/
            // Half Lambert lighting is a technique created by Valve for Half-Life designed to prevent the rear of the object from losing it's shape.
            // This technique provides a good middle ground between a totally toon lighting approach and a physically accurate approach.
            // Calculate base lighting using the half-lambert lighting model.
            half4 c;
            half NdotL = max(0, dot(s.Normal, lightDir));
            half HalfLambert = pow(NdotL * 0.5 + 0.5, 2);

            /*----------------------------- Artifical Subsurface Scattering -----------------------------*/
            // Subsurface scattering simulates light scattering through objects such as skin, wax and clothes, and is important for modern anime and toon shaders looking good, use the Genshin Impact shader as an example.
            // We'll calculation a diffuse wrap (similar to half lambert) as an approximation for subsurface scattering.
            half3 subsurface = pow(NdotL * _SubsurfaceRadius + (1 - _SubsurfaceRadius), 2) * _SubsurfaceColor * _SubsurfaceIntensity;

            /*----------------------------- Specular Lighting -----------------------------*/
            // Calculate specular reflections using the Beckmann normal distribution method.
            float3 halfDirection = normalize(viewDir + lightDir);
            float NdotH = max(0.0, dot(s.Normal, halfDirection));
            float specular = BeckmannNormalDistribution(_Roughness, NdotH);

            /*----------------------------- Artifical Metallic -----------------------------*/
            // Calculate artifical metalness as a spherical gradient matcap.
            half3 viewSpaceNormals = mul((float3x3)UNITY_MATRIX_V, s.Normal);
            viewSpaceNormals.xyz *= float3(0.5, 0.5, 1.0);
            float metallic = saturate(1 - (length(viewSpaceNormals)));
            metallic = smoothstep(0.3, 0.0, metallic) * _Metallic;

            /*----------------------------- Sheen -----------------------------*/
            // Calculate a sheen approximation, which is useful for simulating microfiber lighting for fabric and cloth.
            half sheen = pow(1 - dot(s.Normal, halfDirection), 5) * _SheenIntensity * _SheenColor;

            /*----------------------------- Accumulated Lighting -----------------------------*/
            half3 baseLighting = (s.Albedo * HalfLambert * _LightColor0.rgb + specular) * (NdotL * atten);
            c.rgb = lerp(baseLighting, baseLighting * metallic, _Metallic) + subsurface.rgb;
            c.a = s.Alpha;
            return c;
        }
        
        /*----------------------------- Apply Textures & Channel Packing  -----------------------------*/
        void surf (Input IN, inout CustomSurfaceOutput o) {
            half3 baseColor = (tex2D (_ColorTexture, IN.uv_ColorTexture).rgb) * _Color;
            o.Albedo = baseColor;
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
            o.Emission = (tex2D (_EmissionTexture, IN.uv_EmissionTexture).rgb);
        }
        ENDCG
    } 
    Fallback "Diffuse"
}
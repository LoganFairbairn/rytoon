Shader "MatLayer/RyToon" {
    Properties {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorTexture ("Color Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _ORMTexture ("ORM Texture", 2D) = "black" {}
        _Roughness ("Roughness", Range(0.0, 1.0)) = 0.5
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0
        _ThicknessTexture ("Thickness Texture", 2D) = "black" {}
        _Subsurface ("Subsurface", Range(0.0, 1.0)) = 0.25
        _SubsurfaceColor ("Subsurface Color", Color) = (1.0, 0.0, 0.0, 1.0)
        _WrapValue ("Wrap Value", Range(0.0, 1.0)) = 0.5
        _SheenIntensity ("Sheen Intensity", Range(0.0, 1.0)) = 0.0
        _SheenColor ("Sheen Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Emission ("Emission", 2D) = "black" {}
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        CGPROGRAM

        // Support all light shadow types with 'fullforwardshadows' https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
        #pragma surface surf RyToon fullforwardshadows

        // Input Structure
        struct Input {
            float2 uv_ColorTexture;
            float2 uv_NormalMap;
        };

        // Custom Properties
        fixed4 _Color;
        sampler2D _ColorTexture;
        sampler2D _ORMTexture;
        sampler2D _NormalMap;
        half _Roughness;
        float _Metallic;
        sampler2D _ThicknessTexture;
        float _Subsurface;
        fixed4 _SubsurfaceColor;
        float _WrapValue;
        fixed4 _SheenColor;
        float _SheenIntensity;
        sampler2D _Emission;

        float BeckmannNormalDistribution(float roughness, float NdotH)
        {
            float roughnessSqr = roughness * roughness;
            float NdotHSqr = NdotH * NdotH;
            return max(0.000001,(1.0 / (3.1415926535 * roughnessSqr * NdotHSqr * NdotHSqr)) * exp((NdotHSqr-1)/(roughnessSqr*NdotHSqr)));
        }

        // Calculate custom lighting here.
        half4 LightingRyToon (SurfaceOutput s, half3 lightDir, half viewDir, half atten) {

            // Use half-lambert lighting for a 'toon' look.
            half4 c;
            half NdotL = max(0, dot(s.Normal, lightDir));
            half HalfLambert = NdotL * 0.5 + 0.5;

            // Calculate specular reflections using the Beckmann normal distribution method.
            float3 halfDirection = normalize(viewDir + lightDir);
            float NdotH = max(0.0, dot(s.Normal, halfDirection));
            float spec = BeckmannNormalDistribution(_Roughness, NdotH);

            /*----------------------------- Artificial Subsurface -----------------------------*/

            // For when a thickness map is not provided or is not practical to use...
            // Calculate artificial subsurface scattering using diffuse wrap technique developed by Valve for Half-Life.
            half diffuseWrap = 1 - pow(NdotL * _WrapValue + (1 - _WrapValue), 2);
            half3 subsurface = diffuseWrap * _Subsurface * _SubsurfaceColor;

            /*----------------------------- Sheen -----------------------------*/

            // Calculate a sheen approximation, which is useful for simulating microfiber lighting for fabric and cloth.
            //half sheen = pow(1 - dot(s.Normal, halfDirection), 5) * _SheenIntensity;


            /*----------------------------- Return Lighting -----------------------------*/

            c.rgb = (s.Albedo * _LightColor0.rgb * HalfLambert + _LightColor0.rgb * spec) * atten + subsurface.rgb;
            c.a = s.Alpha;
            return c;
        }

        // Main shader calculations.
        void surf (Input IN, inout SurfaceOutput o) {

            /*----------------------------- Artifical Metalness -----------------------------*/

            // Calculate artifical metalness as a matcap spherical gradient.
            half3 viewSpaceNormals = mul((float3x3)UNITY_MATRIX_V, o.Normal);   // Transform world space normal to view space (camera space)
            viewSpaceNormals.xyz *= float3(0.5, 0.5, 1.0);
            float metallic = saturate(1 - (length(viewSpaceNormals)));
            metallic = smoothstep(0.3, 0.0, metallic);
            
            /*----------------------------- Channel Packing & Main Outputs -----------------------------*/

            half3 baseColor = (tex2D (_ColorTexture, IN.uv_ColorTexture).rgb) * _Color;
            o.Albedo = saturate(lerp(baseColor, baseColor * metallic, _Metallic));
            //o.Normal = UnpackNormal (tex2D (_NormalTexture, IN.uv_NormalMap));
        }
        ENDCG
    } 
    Fallback "Diffuse"
}
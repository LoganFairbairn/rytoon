// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Documentation links...
// Built in shader variable: https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html

Shader "MatLayer/RyToon2" {
    Properties {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess ("Shininess", Float) = 10
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.1, 10.0)) = 3.0
    }
    SubShader {

        // First pass.
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
    
            // Pragmas
            #pragma vertex vert
            #pragma fragment frag 
    
            #include "UnityCG.cginc"
    
            // Unity Properties
            uniform float4 _LightColor0;
                
            // User Defined Properties
            uniform float4 _Color;
            uniform float4 _SpecularColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
    
            // Variables input to the vertex program.
            struct vertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            // Variables output from the vertex program to the fragment program.
            struct vertexOutput {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
            };
    
            // Vertex Program
            // The vertex program runs shader calculations once per vertex per rendered frame.
            vertexOutput vert(vertexInput v)
            {
                vertexOutput o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normalDir = normalize(mul( float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
    
            // Fragment Program
            // The fragment program runs shader calculations on all pixels on screen between geometry vertex points once per rendered frame.
            // Running calculations in the fragment shader is significantly slower than running calculations in the vertex program.
            float4 frag(vertexOutput i) : COLOR
            {
                // World space to object space normals.
                float3 normalDirection = i.normalDir;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 lightDirection;
                float atten;

                // Light direction and attenuation for directional lights.
                // Directional lights are identified by checking the w channel for the built in _WorldSpaceLightPos0 variable defined by Unity.
                if (_WorldSpaceLightPos0.w == 0.0) {
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                    atten = 1.0;
                }

                // Light direction and attenuation for point lights.
                else {
                    float3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
                    float distance = length(fragmentToLightSource);
                    lightDirection = normalize(fragmentToLightSource);
                    atten = 1 / distance;
                }

                // Calculate Lighting
                float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0, dot(normalDirection, lightDirection));
                float3 specularReflection = atten * _SpecularColor.rgb * max(0.0, dot(normalDirection, lightDirection)) * pow( max(0.0, dot( reflect(-lightDirection, normalDirection), viewDirection )), _Shininess);

                // Rim Lighting
                float rim = 1 - saturate(dot(normalize(viewDirection), normalDirection));
                float3 rimLighting = atten * _LightColor0.xyz * _RimColor * saturate(dot(normalDirection, lightDirection)) * pow(rim, _RimPower);

                float3 lightFinal = diffuseReflection + specularReflection + rimLighting + UNITY_LIGHTMODEL_AMBIENT.rgb;

                // Return the color.
                return float4(0, 0, 0, 1);
                //return float4(lightFinal * _Color.rgb, 1.0);
            }
            
            ENDCG
        }
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            
            CGPROGRAM
    
            // Pragmas
            #pragma vertex vert
            #pragma fragment frag 
    
            #include "UnityCG.cginc"
    
            // Unity Properties
            uniform float4 _LightColor0;
                
            // User Defined Properties
            uniform float4 _Color;
            uniform float4 _SpecularColor;
            uniform float4 _RimColor;
            uniform float _Shininess;
            uniform float _RimPower;
    
            // Variables input to the vertex program.
            struct vertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            // Variables output from the vertex program to the fragment program.
            struct vertexOutput {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
            };
    
            // Vertex Program
            // The vertex program runs shader calculations once per vertex per rendered frame.
            vertexOutput vert(vertexInput v)
            {
                vertexOutput o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normalDir = normalize(mul( float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
    
            // Fragment Program
            // The fragment program runs shader calculations on all pixels on screen between geometry vertex points once per rendered frame.
            // Running calculations in the fragment shader is significantly slower than running calculations in the vertex program.
            float4 frag(vertexOutput i) : COLOR
            {
                // World space to object space normals.
                float3 normalDirection = i.normalDir;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 lightDirection;
                float atten;

                // Light direction and attenuation for directional lights.
                // Directional lights are identified by checking the w channel for the built in _WorldSpaceLightPos0 variable defined by Unity.
                if (_WorldSpaceLightPos0.w == 0.0) {
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                    atten = 1.0;
                    atten = 0.2;
                }

                // Light direction and attenuation for point lights.
                else {
                    float3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
                    float distance = length(fragmentToLightSource);
                    lightDirection = fragmentToLightSource / distance;
                    atten = 1 / distance;
                    atten = 0.2;
                }

                // Calculate Lighting
                float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0, dot(normalDirection, lightDirection));
                float3 specularReflection = atten * _SpecularColor.rgb * max(0.0, dot(normalDirection, lightDirection)) * pow( max(0.0, dot( reflect(-lightDirection, normalDirection), viewDirection )), _Shininess);

                // Rim Lighting
                float rim = 1 - saturate(dot(normalize(viewDirection), normalDirection));
                float3 rimLighting = atten * _LightColor0.xyz * _RimColor * saturate(dot(normalDirection, lightDirection)) * pow(rim, _RimPower);

                float3 lightFinal = diffuseReflection + specularReflection + rimLighting + UNITY_LIGHTMODEL_AMBIENT.rgb;

                // Return the color.
                return float4(atten, atten, atten, 1);
                //return float4(lightFinal * _Color.rgb, 1.0);
            }
            
            ENDCG
        }

    }
    Fallback "Diffuse"
}
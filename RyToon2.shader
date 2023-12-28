// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Documentation links...
// Built in shader variable: https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html

Shader "MatLayer/RyToon2" {
    Properties {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Shininess ("Shininess", Float) = 10
    }
    SubShader {
        Pass {
            // Use a forward base light mode so Unity will calculate lighting properly.
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
            uniform float _Shininess;
    
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
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float atten = 1.0;

                // Calculate Lighting
                float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0, dot(normalDirection, lightDirection));
                float3 specularReflection = atten * _SpecularColor.rgb * max(0.0, dot(normalDirection, lightDirection)) * pow( max(0.0, dot( reflect(-lightDirection, normalDirection), viewDirection )), _Shininess);
                float3 lightFinal = diffuseReflection + specularReflection + UNITY_LIGHTMODEL_AMBIENT;

                // Return the color.
                return float4(lightFinal * _Color.rgb, 1.0);
            }
    
            ENDCG
        }
    }
    Fallback "Diffuse"
}
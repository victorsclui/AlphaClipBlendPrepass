Shader "Unlit/RenderPassShader"
{
    Properties
    {
        _ClipTex("ClipTex", 2D) = "white" {}
        _MainTex0("Texture0", 2D) = "white" {}
        _MainTex1("Texture1", 2D) = "white" {}
        _MainTex2("Texture2", 2D) = "white" {}
        _MainTex3("Texture3", 2D) = "white" {}

        _Color0("Color0", Color) = (1,1,1,1)
        _Color1("Color1", Color) = (1,1,1,1)
        _Color2("Color2", Color) = (1,1,1,1)
        _Color3("Color3", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ZTest LEqual
            ZWrite On
            Blend  Off

            Tags{ "LightMode" = "DepthPrepass" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D _ClipTex;
            SamplerState sampler_ClipTex;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;                
            }
            
            void frag(v2f i)
            {
                fixed4 clipCol = _ClipTex.Sample(sampler_ClipTex, i.uv);
                clip(clipCol - 0.1);            
            }
            ENDCG
        }

        Pass
        {
            ZTest Equal
            ZWrite On
            Blend Off

            Tags{ "LightMode" = "AfterZPrepass" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D _MainTex0;
            SamplerState sampler_MainTex0;
            Texture2D _MainTex1;
            SamplerState sampler_MainTex1;
            Texture2D _MainTex2;
            SamplerState sampler_MainTex2;
            Texture2D _MainTex3;
            SamplerState sampler_MainTex3;

            CBUFFER_START(UnityPerMaterial)
            fixed4 _Color0;
            fixed4 _Color1;
            fixed4 _Color2;
            fixed4 _Color3;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = _MainTex0.Sample(sampler_MainTex0, i.uv) * _Color0;
                col += (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1) * (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1);
                col += (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2);
                col += (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3);
                return col;
            }
            ENDCG
        }
        
        Pass
        {
            ZTest LEqual
            ZWrite On
            Blend Off

            Tags{ "LightMode" = "OnePassAlphaClip" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D _ClipTex;
            SamplerState sampler_ClipTex;

            Texture2D _MainTex0;
            SamplerState sampler_MainTex0;
            Texture2D _MainTex1;
            SamplerState sampler_MainTex1;
            Texture2D _MainTex2;
            SamplerState sampler_MainTex2;
            Texture2D _MainTex3;
            SamplerState sampler_MainTex3;

            CBUFFER_START(UnityPerMaterial)
            fixed4 _Color0;
            fixed4 _Color1;
            fixed4 _Color2;
            fixed4 _Color3;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 clipCol = _ClipTex.Sample(sampler_ClipTex, i.uv);
                clip(clipCol - 0.1);

                fixed4 col = _MainTex0.Sample(sampler_MainTex0, i.uv) * _Color0;
                col += (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1) * (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1);
                col += (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2);
                col += (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3);
                return col;
            }
            ENDCG
        }

        Pass
        {
            ZTest Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            Tags{ "LightMode" = "OnePassAlphaBlend" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

           struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Texture2D _ClipTex;
            SamplerState sampler_ClipTex;

            Texture2D _MainTex0;
            SamplerState sampler_MainTex0;
            Texture2D _MainTex1;
            SamplerState sampler_MainTex1;
            Texture2D _MainTex2;
            SamplerState sampler_MainTex2;
            Texture2D _MainTex3;
            SamplerState sampler_MainTex3;

            CBUFFER_START(UnityPerMaterial)
            fixed4 _Color0;
            fixed4 _Color1;
            fixed4 _Color2;
            fixed4 _Color3;
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 clipCol = _ClipTex.Sample(sampler_ClipTex, i.uv);
                clip(clipCol - 0.1);

                fixed4 col = _MainTex0.Sample(sampler_MainTex0, i.uv) * _Color0;
                col += (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1) * (_MainTex1.Sample(sampler_MainTex1, i.uv) * _Color1);
                col += (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2) * (_MainTex2.Sample(sampler_MainTex2, i.uv) * _Color2);
                col += (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3) * (_MainTex3.Sample(sampler_MainTex3, i.uv) * _Color3);
                return col;
            }
            ENDCG
        }
    }
}

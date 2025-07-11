Shader "VatBaker/VatNormal"
{
    Properties
    {
        _AnimationTimeOffset("AnimationTimeOffset", float) = 0.0
        _VatPositionTex ("VatPositionTex", 2D) = "white" {}
        _VatNormalTex ("VatNormalTex", 2D) = "white" {}
        _VatAnimFps("VatAnimFps", float) = 5.0
        _VatAnimLength("VatAnimLength", float) = 5.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Vat.hlsl"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _AnimationTimeOffset)
            UNITY_INSTANCING_BUFFER_END(Props)
        

            v2f vert (appdata_img v, uint vId : SV_VertexID)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                
                float animTime = CalcVatAnimationTime(_Time.y + UNITY_ACCESS_INSTANCED_PROP(Props, _AnimationTimeOffset));
                float3 pos = GetVatPosition(vId, animTime);
                float3 normal = GetVatNormal(vId, animTime);

                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(pos);
                o.worldNormal = UnityObjectToWorldNormal(normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = float4(i.worldNormal * 0.5 + 0.5, 1.0); // Convert normal to color
                return col;
            }
            ENDCG
        }
    }
}
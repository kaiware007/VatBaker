Shader "VatBaker/VatBounds"
{
    Properties
    {
        _AnimationTimeOffset("AnimationTimeOffset", float) = 0.0
        _VatBoundsTex ("VatBoundsTex", 2D) = "white" {}
        _VatAnimFps("VatAnimFps", float) = 5.0
        _VatAnimLength("VatAnimLength", float) = 5.0
    	_Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #pragma target 3.0
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Vat.hlsl"
            
            struct v2g
			{
				float4 pos : SV_POSITION;
				float3 boundSize : TEXCOORD1;
            	UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            struct g2f
			{
				float4 pos : SV_POSITION;
            	UNITY_VERTEX_INPUT_INSTANCE_ID
			};
            
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _AnimationTimeOffset)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
				UNITY_DEFINE_INSTANCED_PROP(float4x4, _ObjectToWorld)
            UNITY_INSTANCING_BUFFER_END(Props)
            
            v2g vert (appdata_img v, uint vId : SV_VertexID)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                
                float animTime = CalcVatAnimationTime(_Time.y + UNITY_ACCESS_INSTANCED_PROP(Props, _AnimationTimeOffset));
                float3 pos = GetVatBoundsCenter(animTime);
            	
            	v2g o;
                UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.pos = float4(pos,  1);
            	o.boundSize = GetVatBoundsSize(animTime);
                return o;
            }

            float4 TransformVertexToClipSpace(float4 pos, float4x4 objectToWorld)
			{
				pos = mul(objectToWorld, pos);
				return UnityObjectToClipPos(pos);
			}
            // ジオメトリシェーダ
			[maxvertexcount(24)]
			void geom(point v2g input[1], inout LineStream<g2f> outStream)
			{
				g2f o;

				// 全ての頂点で共通の値を計算しておく
				float4 pos = input[0].pos;
				float4 bounds = float4(input[0].boundSize, 0);
				float4x4 objectToWorld = UNITY_ACCESS_INSTANCED_PROP(Props, _ObjectToWorld);

            	UNITY_TRANSFER_INSTANCE_ID(input[0], o);
            	
				// 底面
				o.pos = TransformVertexToClipSpace(pos - bounds, objectToWorld);
				outStream.Append(o);	
				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4( bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, -bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, -bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, -bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				// 側面
				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, -bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, -bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, -bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos + float4(-bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				// 上面
				o.pos = TransformVertexToClipSpace(pos +  float4(-bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos +  float4(-bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos +  float4(-bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos +  float4(bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos +  float4(bounds.x, bounds.y, bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos +  float4(bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

				o.pos = TransformVertexToClipSpace(pos +  float4(bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				o.pos = TransformVertexToClipSpace(pos +  float4(-bounds.x, bounds.y, -bounds.z, 0), objectToWorld);
				outStream.Append(o);
				outStream.RestartStrip();

			}
            
            fixed4 frag (g2f i) : SV_Target
            {
            	UNITY_SETUP_INSTANCE_ID(i);
            	return UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
            }
            ENDCG
        }
    }
}
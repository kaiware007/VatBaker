#ifndef GA_FUQUNA_VATBAKER_VAT_INCLUDED
#define GA_FUQUNA_VATBAKER_VAT_INCLUDED

sampler2D _VatPositionTex;
float4 _VatPositionTex_TexelSize; // (1.0/width, 1.0/height, width, height) // https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html

sampler2D _VatNormalTex;
float4 _VatNormalTex_TexelSize; // (1.0/width, 1.0/height, width, height) // https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html

sampler2D _VatBoundsTex;
float4 _VatBoundsTex_TexelSize; // (1.0/width, 1.0/height, width, height) // https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html

float _VatAnimFps;
float _VatAnimLength;


float CalcVatAnimationTime(float time)
{
    return (time  % _VatAnimLength) * _VatAnimFps;
}

float4 CalcVatTexCoord(uint vertexId, float animationTime)
{
    float x = vertexId + 0.5;
    float y = animationTime + 0.5;
    
    return float4(x, y, 0, 0) * _VatPositionTex_TexelSize;   
}

float3 GetVatPosition(uint vertexId, float animationTime)
{
    return (float3)tex2Dlod(_VatPositionTex, CalcVatTexCoord(vertexId, animationTime));
}

float3 GetVatNormal(uint vertexId, float animationTime)
{
    return (float3)tex2Dlod(_VatNormalTex, CalcVatTexCoord(vertexId, animationTime));
}

// index: 0 = center, 1 = size
float4 CalcVatBoundsTexCoord(uint index, float animationTime)
{
    float x = index + 0.5;
    float y = animationTime + 0.5;
    
    return float4(x, y, 0, 0) * _VatBoundsTex_TexelSize;   
}

float3 GetVatBoundsCenter(float animationTime)
{
    return (float3)tex2Dlod(_VatBoundsTex, CalcVatBoundsTexCoord(0, animationTime));
}

float3 GetVatBoundsSize(float animationTime)
{
    return (float3)tex2Dlod(_VatBoundsTex, CalcVatBoundsTexCoord(1, animationTime));
}
#endif
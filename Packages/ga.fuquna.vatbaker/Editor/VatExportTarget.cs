using UnityEngine;

namespace VatBaker.Editor
{
    /// <summary>
    /// 出力するテクスチャ
    /// </summary>
    [System.Serializable]
    public class VatExportTarget
    {
        [Tooltip("Outputting the vertex coordinate texture")]
        public bool positionTexture = true;

        [Tooltip("Outputting the vertex normal texture")]
        public bool normalTexture = true;

        [Tooltip("Outputting the bounds texture(Option)")]
        public bool boundsTexture = false;
    }
}
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace VatBaker
{
    [ExecuteAlways]
    public class VatBoundsRenderer : MonoBehaviour
    {
        [SerializeField]
        private Material boundsMaterial;

        // Update is called once per frame
        private void LateUpdate()
        {
            boundsMaterial.SetMatrix("_ObjectToWorld", Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale));
            Graphics.DrawProcedural(boundsMaterial, 
                new Bounds(transform.position, Vector3.one * 100f), 
                MeshTopology.Points, 1);
        }
    }
}
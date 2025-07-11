using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Pool;

namespace VatBaker.Editor
{
    public static class VatBakerCore
    {
        public static readonly int MainTex = Shader.PropertyToID("_MainTex");
        public static readonly int NormalTex = Shader.PropertyToID("_NormalTex");
        
        private static readonly int BaseShaderBumpMap = Shader.PropertyToID("_BumpMap");


        public static (Texture2D, Texture2D, Texture2D) BakeClip(string name, GameObject gameObject, SkinnedMeshRenderer skin, AnimationClip clip, float fps, Space space)
        {
            var vertexCount = skin.sharedMesh.vertexCount;
            var frameCount = Mathf.FloorToInt(clip.length * fps) + 1; // for loop

            var posTex = new Texture2D(vertexCount, frameCount, TextureFormat.RGBAHalf, false, true)
            {
                name = $"{name}.posTex",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Repeat
            };
            
            var normTex = new Texture2D(vertexCount, frameCount, TextureFormat.RGBAHalf, false, true)
            {
                name = $"{name}.normTex",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Repeat
            };
   
            var boundsTex = new Texture2D(2, frameCount, TextureFormat.RGBAHalf, false, true)
            {
                name = $"{name}.boundsTex",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Repeat
            };
            using var poolVtx0 = ListPool<Vector3>.Get(out var tmpVertexList);
            using var poolVtx1 = ListPool<Vector3>.Get(out var localVertices);
            
            using var poolNorm0 = ListPool<Vector3>.Get(out var tmpNormalList);
            using var poolNorm1 = ListPool<Vector3>.Get(out var localNormals);

            // SkinnedMeshRenderer.BakeMesh() uses the transform
            // but is not used in the actual display, so it is reset during Bake
            using var tranScope = TransformCacheScope.ResetScope(skin.transform);

            var boundsList = new List<Bounds>();
            
            var mesh = new Mesh();
            var dt = 1f / fps;
            for (var i = 0; i < frameCount; i++)
            {
                clip.SampleAnimation(gameObject, dt * i);
                skin.BakeMesh(mesh);

                mesh.GetVertices(tmpVertexList);
                mesh.GetNormals(tmpNormalList);
                boundsList.Add(mesh.bounds);
                
                localVertices.AddRange(tmpVertexList);
                localNormals.AddRange(tmpNormalList);
            }

            var trans = gameObject.transform;
            var (vertices, normals, bounds) = space switch
            {
                Space.Self => (
                    localVertices.Select(vtx => trans.InverseTransformPoint(vtx)),
                    localNormals.Select(norm => trans.InverseTransformDirection(norm)),
                    boundsList.Select(b =>
                    {
                        var center = b.center;
                        var extents = b.extents;
                        var corners = new []
                        {
                            center + new Vector3(extents.x, extents.y, extents.z),
                            center + new Vector3(extents.x, extents.y, -extents.z),
                            center + new Vector3(extents.x, -extents.y, extents.z),
                            center + new Vector3(extents.x, -extents.y, -extents.z),
                            center + new Vector3(-extents.x, extents.y, extents.z),
                            center + new Vector3(-extents.x, extents.y, -extents.z),
                            center + new Vector3(-extents.x, -extents.y, extents.z),
                            center + new Vector3(-extents.x, -extents.y, -extents.z),
                        }.Select(v => trans.InverseTransformPoint(v)).ToArray();
                        
                        var maxX = corners.Max(v => v.x);
                        var maxY = corners.Max(v => v.y);
                        var maxZ = corners.Max(v => v.z);
                        var minX = corners.Min(v => v.x);
                        var minY = corners.Min(v => v.y);
                        var minZ = corners.Min(v => v.z);

                        var newCenter = new Vector3((maxX + minX) * 0.5f, (maxY + minY) * 0.5f, (maxZ + minZ) * 0.5f);
                        var newSize = new Vector3(maxX - minX, maxY - minY, maxZ - minZ);
                        var rotatedBounds = new Bounds(newCenter, newSize);
                        return rotatedBounds;
                    })
                ),
                Space.World => (localVertices, localNormals, boundsList),

                _ => throw new ArgumentOutOfRangeException(nameof(space), space, null)
            };
            

            posTex.SetPixels(ListToColorArray(vertices));
            normTex.SetPixels(ListToColorArray(normals));
            boundsTex.SetPixels(BoundsListToColorArray(bounds));
            
            return (posTex, normTex, boundsTex);

            static Color[] ListToColorArray(IEnumerable<Vector3> list) =>
                list.Select(v3 => new Color(v3.x, v3.y, v3.z)).ToArray();
            
            static Color[] BoundsListToColorArray(IEnumerable<Bounds> list)
            {
                var boundsEnumerable = list as Bounds[] ?? list.ToArray();
                var colors = boundsEnumerable.Select(b => new Color[]
                {
                    new (b.center.x, b.center.y, b.center.z, 0),
                    new (b.extents.x, b.extents.y, b.extents.z, 0)
                }).SelectMany(c => c).ToArray(); 
                return colors;
            }
        }
        
        public static void GenerateAssets(string name, SkinnedMeshRenderer skin, float fps, float animLength, Shader shader, Texture posTex, Texture normTex, Texture boundsTex)
        {
            const string folderName = "VatBakerOutput";

            var folderPath = CombinePathAndCreateFolderIfNotExist("Assets", folderName, false);
            var subFolderPath = CombinePathAndCreateFolderIfNotExist(folderPath, name);

            var mat = new Material(shader)
            {
                enableInstancing = true
            };

            mat.SetTexture(MainTex, skin.sharedMaterial.mainTexture);
            var normalTex = skin.sharedMaterial.GetTexture(BaseShaderBumpMap);
            if (normalTex != null)
            {
                mat.SetTexture(NormalTex, normalTex);
            }
            mat.SetTexture(VatShaderProperty.VatPositionTex, posTex);
            mat.SetTexture(VatShaderProperty.VatNormalTex, normTex);
            mat.SetTexture(VatShaderProperty.VatBoundsTex, boundsTex);
            mat.SetFloat(VatShaderProperty.VatAnimFps, fps);
            mat.SetFloat(VatShaderProperty.VatAnimLength, animLength);

            var go = new GameObject(name);
            go.AddComponent<MeshRenderer>().sharedMaterial = mat;
            go.AddComponent<MeshFilter>().sharedMesh = skin.sharedMesh;

            AssetDatabase.CreateAsset(posTex, CreatePath(subFolderPath, posTex.name, "asset"));
            AssetDatabase.CreateAsset(normTex, CreatePath(subFolderPath, normTex.name, "asset"));
            AssetDatabase.CreateAsset(boundsTex, CreatePath(subFolderPath, boundsTex.name, "asset"));
            AssetDatabase.CreateAsset(mat, CreatePath(subFolderPath, name, "mat"));
            var prefab = PrefabUtility.SaveAsPrefabAssetAndConnect(go, 
                CreatePath(subFolderPath, go.name, "prefab"),
                InteractionMode.AutomatedAction);
            
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            
            EditorGUIUtility.PingObject(prefab);

            static string CreatePath(string folder, string file, string extension) 
                => Path.Combine(folder, $"{ReplaceInvalidPathChar(file)}.{extension}");
        }


        static string CombinePathAndCreateFolderIfNotExist(string parent, string folderName, bool unique = true)
        {
            parent = ReplaceInvalidPathChar(parent);
            folderName = ReplaceInvalidPathChar(folderName);
            
            var path = Path.Combine(parent, folderName);
            
            if (unique)
            {
                path = AssetDatabase.GenerateUniqueAssetPath(path);
            }

            if (!AssetDatabase.IsValidFolder(path))
            {
                AssetDatabase.CreateFolder(parent, folderName);
            }

            return path;

        }
        
        static readonly string InvalidChars = new string(Path.GetInvalidPathChars());
        
        static string ReplaceInvalidPathChar(string path)
        {
            return Regex.Replace(path, $"[{InvalidChars}]", "_");
        }
    }
}
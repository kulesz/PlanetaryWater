using System.Collections.Generic;
using System.Linq;
using PlanetaryWater.Waves;
using UnityEngine;

namespace PlanetaryWater
{
    public class WaterSurface : MonoBehaviour
    {
        private static readonly int _RadiusId = Shader.PropertyToID("_Radius");
        private static readonly int _WaveCountId = Shader.PropertyToID("_WaveCount");
        private static readonly int _WaveParametersId = Shader.PropertyToID("_WaveParameters");
        private static readonly int _WaveDirectionsId = Shader.PropertyToID("_WaveDirections");

        private static readonly int _FaceCount = 6;

        private static readonly Vector3[] _FaceDirections =
        {
            Vector3.up,
            Vector3.down,
            Vector3.left,
            Vector3.right,
            Vector3.forward,
            Vector3.back
        };

        [SerializeField]
        private Material _WaterMaterial = null;

        [Range(1000, 2000)]
        [SerializeField]
        private int _Radius = 1600;

        [Range(16, 256)]
        [SerializeField]
        private int _FaceMeshResolution = 170;

        [SerializeField]
        [HideInInspector]
        private MeshFilter[] _MeshFilters = new MeshFilter[_FaceCount];

        [SerializeField]
        [HideInInspector]
        private MeshRenderer[] _MeshRenderers = new MeshRenderer[_FaceCount];

        [SerializeField]
        private List<WaveConfiguration> _WaveConfigurations = new List<WaveConfiguration>();

        private SphereFace[] _Faces = new SphereFace[_FaceCount];

        private void OnValidate()
        {
            GenerateMesh();
            UpdateShader();
        }

        private void UpdateShader()
        {
            _WaterMaterial.SetInt(_RadiusId, _Radius);
            _WaterMaterial.SetInt(_WaveCountId, _WaveConfigurations.Count);
            _WaterMaterial.SetVectorArray(_WaveParametersId, _WaveConfigurations.Select(c => c.Parameters).ToArray());
            _WaterMaterial.SetVectorArray(_WaveDirectionsId, _WaveConfigurations.Select(c => c.Direction).ToArray());
        }

        private void GenerateMesh()
        {
            if (_MeshFilters == null || _MeshFilters.Length != _FaceCount)
                _MeshFilters = new MeshFilter[_FaceCount];

            if (_MeshRenderers == null || _MeshRenderers.Length != _FaceCount)
                _MeshRenderers = new MeshRenderer[_FaceCount];

            if (_Faces == null || _Faces.Length == _FaceCount)
                _Faces = new SphereFace[_FaceCount];

            for (var faceIdx = 0; faceIdx < _FaceCount; faceIdx++)
            {
                if (_MeshFilters[faceIdx] == null)
                {
                    var faceObject = new GameObject($"{nameof(SphereFace)} {faceIdx}");
                    faceObject.transform.parent = transform;

                    var meshRenderer = faceObject.AddComponent<MeshRenderer>();
                    _MeshRenderers[faceIdx] = meshRenderer;

                    var meshFilter = faceObject.AddComponent<MeshFilter>();
                    _MeshFilters[faceIdx] = meshFilter;
                    _MeshFilters[faceIdx].sharedMesh = new Mesh();
                }

                _MeshRenderers[faceIdx].sharedMaterial = _WaterMaterial;

                var sphereFace = new SphereFace(_MeshFilters[faceIdx].sharedMesh, _FaceMeshResolution, _FaceDirections[faceIdx]);
                sphereFace.ConstructMesh(_Radius);

                _Faces[faceIdx] = sphereFace;
            }
        }
    }
}
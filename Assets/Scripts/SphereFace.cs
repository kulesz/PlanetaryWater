using UnityEngine;

namespace PlanetaryWater
{
    public class SphereFace
    {
        #region Fields

        private Mesh _Mesh = null;
        private int _MeshResolution = 0;

        private Vector3 _FaceNormal = Vector3.zero;
        private Vector3 _FaceTangent = Vector3.zero;
        private Vector3 _FaceBitangent = Vector3.zero;

        private Vector3[] _VertexCache = null;
        private int[] _TriangleCache = null;

        #endregion

        #region Constructors / Destructors

        public SphereFace(Mesh mesh, int meshResolution, Vector3 faceNormal)
        {
            _Mesh = mesh;
            _MeshResolution = meshResolution;

            _FaceNormal = faceNormal;
            _FaceTangent = new Vector3(faceNormal.y, faceNormal.z, faceNormal.x);
            _FaceBitangent = Vector3.Cross(faceNormal, _FaceTangent);

            _VertexCache = new Vector3[_MeshResolution * _MeshResolution];
            _TriangleCache = new int[(_MeshResolution - 1) * (_MeshResolution - 1) * 6];
        }

        #endregion

        #region Public Methods

        public void ConstructMesh(float radius)
        {
            var triangleIdx = 0;
            for (var y = 0; y < _MeshResolution; y++)
            {
                for (var x = 0; x < _MeshResolution; x++)
                {
                    var normalizedCoords = new Vector2(x, y) / (_MeshResolution - 1);
                    var pointOnUnitCube = _FaceNormal + (normalizedCoords.x - 0.5f) * 2 * _FaceTangent + (normalizedCoords.y - 0.5f) * 2 * _FaceBitangent;
                    var pointOnUnitSphere = pointOnUnitCube.normalized;
                    var pointOnSphere = pointOnUnitSphere * radius;

                    var startIdx = x + y * _MeshResolution;
                    _VertexCache[startIdx] = pointOnSphere;

                    if (x != _MeshResolution - 1 && y != _MeshResolution - 1)
                    {
                        _TriangleCache[triangleIdx] = startIdx;
                        _TriangleCache[triangleIdx + 1] = startIdx + _MeshResolution + 1;
                        _TriangleCache[triangleIdx + 2] = startIdx + _MeshResolution;

                        _TriangleCache[triangleIdx + 3] = startIdx;
                        _TriangleCache[triangleIdx + 4] = startIdx + 1;
                        _TriangleCache[triangleIdx + 5] = startIdx + _MeshResolution + 1;

                        triangleIdx += 6;
                    }
                }
            }

            _Mesh.Clear();
            _Mesh.vertices = _VertexCache;
            _Mesh.triangles = _TriangleCache;
            _Mesh.bounds = new Bounds(Vector3.zero, 2 * radius * Vector3.one);
        }

        #endregion
    }
}
using System;
using UnityEngine;

namespace PlanetaryWater.Waves
{
    [Serializable]
    public class WaveConfiguration
    {
        [SerializeField]
        private float _Amplitude = 1;

        [SerializeField]
        private float _Steepness = 1;

        [SerializeField]
        private float _Frequency = 1;

        [SerializeField]
        private float _Speed = 1;

        [SerializeField]
        private Vector3 _Direction = Vector3.zero;

        public WaveConfiguration(float amplitude, float steepnes, float frequency, float speed, Vector3 dir)
        {
            _Amplitude = amplitude;
            _Steepness = steepnes;
            _Frequency = frequency;
            _Speed = speed;
            _Direction = dir;
        }

        public Vector4 Direction => _Direction;

        public Vector4 Parameters => new Vector4(_Amplitude, _Steepness, _Frequency, _Speed);
    }
}
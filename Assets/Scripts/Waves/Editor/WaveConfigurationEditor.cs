using UnityEditor;
using UnityEngine;

namespace PlanetaryWater.Waves.Editor
{
    [CustomPropertyDrawer(typeof(WaveConfiguration))]
    public class WaveConfigurationEditor : PropertyDrawer
    {
        #region Public Methods

        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            EditorGUI.BeginProperty(position, label, property);

            EditorGUIUtility.labelWidth = 20;

            var fieldWidth = 65;
            var amplitudeRect = new Rect(position.x, position.y, fieldWidth, 20);
            var steepnessRect = new Rect(position.x + 70, position.y, fieldWidth, 20);
            var frequencyRect = new Rect(position.x + 140, position.y, fieldWidth, 20);
            var speedRect = new Rect(position.x + 210, position.y, fieldWidth, 20);
            var dirRect = new Rect(position.x, position.y + 25, 200, 20);

            EditorGUI.PropertyField(amplitudeRect, property.FindPropertyRelative("_Amplitude"), new GUIContent("A"));
            EditorGUI.PropertyField(steepnessRect, property.FindPropertyRelative("_Steepness"), new GUIContent("St"));
            EditorGUI.PropertyField(frequencyRect, property.FindPropertyRelative("_Frequency"), new GUIContent("ω"));
            EditorGUI.PropertyField(speedRect, property.FindPropertyRelative("_Speed"), new GUIContent("φ"));
            EditorGUI.PropertyField(dirRect, property.FindPropertyRelative("_Direction"), new GUIContent("Dir"));

            EditorGUIUtility.labelWidth = 0;

            EditorGUI.EndProperty();
        }

        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            return base.GetPropertyHeight(property, label) + 40;
        }

        #endregion
    }
}
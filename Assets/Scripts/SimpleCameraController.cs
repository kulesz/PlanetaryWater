using UnityEngine;

namespace PlanetaryWater
{
    [RequireComponent(typeof(Camera))]
    public class SimpleCameraController : MonoBehaviour
    {
        private const string _AxisNameX = "Mouse X";
        private const string _AxisNameY = "Mouse Y";

        private const float _MovementSpeed = 20f;
        private const float _FastMovementSpeed = 250f;

        private const float _MouseSensitivity = 2f;

        private void LateUpdate()
        {
            UpdateCursorLock();

            if (Cursor.lockState != CursorLockMode.Locked)
                return;

            var offset = Vector3.zero;
            var speed = Input.GetKey(KeyCode.LeftShift)
                ? _FastMovementSpeed
                : _MovementSpeed;

            if (Input.GetKey(KeyCode.W))
                offset += transform.forward;

            if (Input.GetKey(KeyCode.S))
                offset -= transform.forward;

            if (Input.GetKey(KeyCode.A))
                offset -= transform.right;

            if (Input.GetKey(KeyCode.D))
                offset += transform.right;

            transform.position += offset * (speed * Time.deltaTime);

            transform.rotation *= Quaternion.AngleAxis(Input.GetAxis(_AxisNameY) * -_MouseSensitivity, Vector3.right);
            var eulerAngles = transform.eulerAngles;

            transform.rotation = Quaternion.Euler(eulerAngles.x, eulerAngles.y + Input.GetAxis(_AxisNameX) * _MouseSensitivity, eulerAngles.z);
        }

        private void OnEnable() => Cursor.lockState = CursorLockMode.None;

        private void OnDisable() => Cursor.lockState = CursorLockMode.None;

        private void UpdateCursorLock()
        {
            if (Input.GetMouseButtonDown(0))
                Cursor.lockState = CursorLockMode.Locked;

            if (Input.GetKeyDown(KeyCode.Escape))
                Cursor.lockState = CursorLockMode.None;

            Cursor.visible = Cursor.lockState != CursorLockMode.Locked;
        }
    }
}
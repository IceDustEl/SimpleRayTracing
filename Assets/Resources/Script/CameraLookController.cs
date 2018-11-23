using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using DG.Tweening;

// 响应鼠标点击和拖拽，控制摄像机缩放旋转
public class CameraLookController : MonoBehaviour
{
    public List<GameObject> TargetList;

	public List<GameObject> CameraPosList;

    public float LerpSpeed;

	public float RotateDrag;

	private Vector3 LookPos, DesirePos;

    public int CurGoIndex = 0;

	public float Sensitivity = 100;

	Vector2 RotateSpeed;

	float Distance;

	Vector2 LastPos = Vector2.zero;

	public bool FreeMode = false;

	public float TempTime;

	public Image Bg;

	Vector3 dampSpeed;

	float DoubleTouchLastDis;

	void Start()
    {
        LookPos = TargetList[CurGoIndex].transform.position;
		DesirePos = CameraPosList[CurGoIndex].transform.position;
		Distance = Vector3.Distance(DesirePos, LookPos);
		//Screen.SetResolution(1440,810,true);
	}

	void Update()
    {
		if(FreeMode)
		{
			CheckPickUp();

			CaculateRotate();
		}
		else
		{
			TempTime += Time.deltaTime;

			if (TempTime > 1)
			{
				FreeMode = true;

				LookPos = TargetList[CurGoIndex].transform.position;

				DesirePos = CameraPosList[CurGoIndex].transform.position;

				Distance = Vector3.Distance(DesirePos, LookPos);
			}

			Vector3 lookPos = SmoothStep(LookPos, TargetList[CurGoIndex].transform.position, TempTime);

			Vector3 desirePos = SmoothStep(DesirePos, CameraPosList[CurGoIndex].transform.position, TempTime);

			transform.position = desirePos;

			transform.LookAt(lookPos);
		}
	}

	void CheckPickUp()
	{
		if(Input.GetMouseButtonDown(0) || (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Began))
		{
			RaycastHit hit = new RaycastHit();
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			if (Physics.Raycast(ray, out hit, Mathf.Infinity))
			{
				GameObject go = hit.collider.gameObject;
				if(go.tag != "IgnoreCast" && TargetList.Contains(go))
				{
					if(CurGoIndex != TargetList.IndexOf(go))
					{
						TargetList[CurGoIndex].BroadcastMessage("OnCancleSelect", SendMessageOptions.DontRequireReceiver);

						go.BroadcastMessage("OnSelect");

						CurGoIndex = TargetList.IndexOf(go);

						FreeMode = false;

						TempTime = 0;

						DesirePos = transform.position;

						RotateSpeed = Vector2.zero;
					}
				}
			}
			
		}
	}

	Vector3 SmoothStep(Vector3 from, Vector3 to, float lerpTime)
	{
		Vector3 vec;
		vec.x = Mathf.SmoothStep(from.x, to.x, lerpTime);
		vec.y = Mathf.SmoothStep(from.y, to.y, lerpTime);
		vec.z = Mathf.SmoothStep(from.z, to.z, lerpTime);

		return vec;
	}
                                     
	void CaculateRotate()
	{
		if (Input.GetMouseButton(0) || (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Moved))
		{
			Vector2 pos = Input.mousePosition;

			if (LastPos.Equals(Vector2.zero))
				LastPos = pos;

			Vector2 move = pos - LastPos;

			//if (move.magnitude > 400)
				//Debug.Log("Error");

			LastPos = pos;

			RotateSpeed += move * Time.deltaTime;
		}
		else
		{
			LastPos = Vector2.zero;
		}

		if (RotateSpeed.magnitude - RotateDrag * Time.deltaTime > 0.1f)
		{
			float scale = (RotateSpeed.magnitude - RotateDrag * Time.deltaTime) / RotateSpeed.magnitude;

			RotateSpeed.Scale(Vector2.one * scale);
		}
		else
			RotateSpeed = Vector2.zero;

		Vector3 eulerAngles = transform.eulerAngles;

		eulerAngles.y += RotateSpeed.x;
		eulerAngles.x = Mathf.Clamp(eulerAngles.x - RotateSpeed.y, 1, 80);

		transform.eulerAngles = eulerAngles;

		float zoom = 1;

		if(Input.touchCount >= 2)
		{
			Touch touch1 = Input.GetTouch(0);
			Touch touch2 = Input.GetTouch(1);

			float doubleTouchCurrDis = Vector2.Distance(touch1.position, touch2.position);

			if (DoubleTouchLastDis == 0)
				DoubleTouchLastDis = doubleTouchCurrDis;

			zoom = DoubleTouchLastDis / doubleTouchCurrDis;

			DoubleTouchLastDis = doubleTouchCurrDis;
		}
		else
		{
			DoubleTouchLastDis = 0;
		}

		Distance *= (1 - Input.GetAxis("Mouse ScrollWheel")) * zoom;

		transform.position = LookPos + -transform.forward * Distance;
	}

	public void OnBtnClick()
	{
		Bg.DOFade(1,1f);

		Invoke("SwitchToScene",1f);
	}

	void SwitchToScene()
	{
		SceneManager.LoadScene("NieOcean");
	}

}

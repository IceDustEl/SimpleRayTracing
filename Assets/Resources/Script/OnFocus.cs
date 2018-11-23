using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

//  物体旋转动画
public class OnFocus : MonoBehaviour
{
	public Vector3 FocusAngle;

	bool AutoRotateFlag;

	void OnSelect ()
	{
		GetComponent<Rigidbody>().isKinematic = true;
		transform.DORotate(FocusAngle, 1);
		Vector3 pos = transform.position;
		pos.y = 1;
		transform.DOMove(pos, 1);
		AutoRotateFlag = true;
		StartCoroutine(AutoRotate());
	}

	IEnumerator AutoRotate()
	{
		yield return new WaitForSeconds(1);

		float time = Time.time;
		Vector3 eulerAngles = transform.eulerAngles;
		while (AutoRotateFlag)
		{
			float t = Time.time - time;

			Vector3 angle;
			if(gameObject.name == "Diamond")
			{
				angle = new Vector3(Mathf.Sin(t / 12f) * 360f, Mathf.Sin(t / 10f) * 540f, Mathf.Sin(t / 8f) * 360f);
			}
			else
			{
				angle = new Vector3(0f, t * 360f / 6, 0f);
			}
				
				
			transform.eulerAngles = eulerAngles + angle;
			yield return null;
		}
	}
	
	void OnCancleSelect ()
	{
		GetComponent<Rigidbody>().isKinematic = false;
		AutoRotateFlag = false;
	}
}

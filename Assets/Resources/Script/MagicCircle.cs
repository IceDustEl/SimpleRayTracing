using DG.Tweening;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MagicCircle : MonoBehaviour
{
	public RayTrace rayTrace;

	void OnSelect()
	{
		DOTween.To(()=> rayTrace.MagicAlpha, a => rayTrace.MagicAlpha = a, 0.2f, 1);
		var t = DOTween.To(() => rayTrace.MagicAlpha, a => rayTrace.MagicAlpha = a, 1, 1);
		t.SetDelay(1);
	}

	void OnCancleSelect()
	{
		DOTween.To(() => rayTrace.MagicAlpha, a => rayTrace.MagicAlpha = a, 0, 2);
	}
}

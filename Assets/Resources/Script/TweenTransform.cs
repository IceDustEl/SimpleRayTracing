using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TweenTransform : MonoBehaviour {

	public float RotateSpeed;


	void Start ()
	{
		
	}
	
	void Update ()
	{
		transform.RotateAround(transform.position, Vector3.up, RotateSpeed * Time.deltaTime);
	}
}

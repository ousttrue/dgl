import std.stdio;
import shader;
import vbo;
import gl3n.linalg;


struct Transform
{
	vec3 position;
	quat rotation=quat.identity();

	mat4 _matrix;
	ref mat4 matrix()
	{
		_matrix=rotation.to_matrix!(4, 4);
		return _matrix;
	}
}


class Animation
{
	float angle=0;

	void apply(GameObject go)
	{
		angle+=0.1/60 * std.math.PI /180;
		go.transform.rotation=quat.axis_rotation(angle, vec3(0, 0, 1));
	}
}


class GameObject
{
	VAO mesh;
	Transform transform;
	GameObject[] children=[];

    this(){
        mesh=new VAO; 
    }

	void add_child(GameObject child)
	{
		children~=child;
	}

	Animation animation;

	void animate()
	{
		if(this.animation){
			animation.apply(this);
		}

		foreach(GameObject child; this.children)
		{
			child.animate();
		}
	}
}


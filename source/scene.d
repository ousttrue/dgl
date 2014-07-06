import std.stdio;
import gl;
public import gl3n.linalg;


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


class RenderTarget
{
	private GameObject _root;
	GameObject root()
	{
		return _root;
	}

	private GameObject _light;
	GameObject light()
	{
		return _light;
	}

	private GameObject _camera;
	GameObject camera()
	{
		return _camera;
	}
	mat4 projectionMatrix=mat4.identity();

	this()
	{
		_root=new GameObject;
		// light
		_light=new GameObject;
		root.add_child(_light);
		// camera
		_camera=new GameObject;
		root.add_child(_camera);
	}

    ShaderProgram shader;
	
	bool isMouseLeftDown;
	void onMouseLeftDown()
	{
		writeln("left down");
		isMouseLeftDown=true;
	}
	void onMouseLeftUp()
	{
		writeln("left up");
		isMouseLeftDown=false;
	}

	bool isMouseMiddleDown;
	void onMouseMiddleDown()
	{
		writeln("m down");
		isMouseMiddleDown=true;
	}
	void onMouseMiddleUp()
	{
		writeln("m up");
		isMouseMiddleDown=false;
	}

	bool isMouseRightDown;
	void onMouseRightDown()
	{
		writeln("right down");
		isMouseRightDown=true;
	}
	void onMouseRightUp()
	{
		writeln("right up");
		isMouseRightDown=false;
	}

	double mouseLastX;
	double mouseLastY;
	void onMouseMove(double x, double y)
	{
		if(!std.math.isnan(x) && !std.math.isnan(y)){
			double dx=x-mouseLastX;
			double dy=y-mouseLastY;
			if(isMouseLeftDown){
			}
			if(isMouseMiddleDown){
			}
			if(isMouseRightDown){
				double dxrad=std.math.PI * dx / 180.0;
				double dyrad=std.math.PI * dy / 180.0;
				camera.transform.rotation=camera.transform.rotation.rotatey(dxrad).rotatex(dyrad);
			}
		}
		mouseLastX=x;
		mouseLastY=y;
	}

	void onMouseWheel(double d)
	{
		writeln("wheel: ", d);
	}

	void draw()
	{
        this.shader.use();

		this.shader.setMatrix4("uProjectionMatrix", this.projectionMatrix);
		this.shader.setMatrix4("uViewMatrix", this.camera.transform.matrix);

		auto l=this.light.transform.position;
		//auto l=vec3(1, 1, 1);
        this.shader.set("uLightPosition", l);

		auto m=mat4.identity;
		draw(this.root, m);
	}

	void draw(GameObject go, ref const(mat4) parent)
	{
		auto m=go.transform.matrix * parent;
        this.shader.setMatrix4("uModelMatrix", m);
		
		auto n=mat3(m);
        this.shader.setMatrix3("uNormalMatrix", n);

        go.mesh.draw();

		foreach(GameObject child; go.children)
		{
			draw(child, m);
		}
	}
}

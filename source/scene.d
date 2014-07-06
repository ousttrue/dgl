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


class GameObject
{
	VAO mesh;
	Transform transform;
	GameObject[] children=[];

    this(){
        mesh=new VAO; 
    }

	float angle=0;
	void animate()
	{
		angle+=0.1/60 * std.math.PI /180;
		transform.rotation=quat.axis_rotation(angle, vec3(0, 0, 1));
	}
}


class RenderTarget
{
	Transform camera;
	GameObject root;

	ref mat4 viewMatrix()
	{
		return camera.matrix;
	}

	mat4 projectionMatrix=mat4.identity();

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
				root.transform.rotation=root.transform.rotation.rotatey(dxrad).rotatex(dyrad);
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

		this.shader.setMatrix4("uProjectionMatrix", this.projectionMatrix.value_ptr);
		this.shader.setMatrix4("uViewMatrix", this.viewMatrix.value_ptr);
		auto l=vec3(1, 1, 1);
        this.shader.set("uLightPosition", l.value_ptr);

		auto m=mat4.identity;
		draw(this.root, m);
	}

	void draw(GameObject go, ref const(mat4) parent)
	{
		auto m=go.transform.matrix * parent;
        this.shader.setMatrix4("uModelMatrix", m.value_ptr);
		
		auto n=mat3(m);
        this.shader.setMatrix3("uNormalMatrix", n.value_ptr);

        go.mesh.draw();

		foreach(GameObject child; go.children)
		{
			draw(child, m);
		}
	}
}

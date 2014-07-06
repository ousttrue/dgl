import std.stdio;
import gl;
public import gl3n.linalg;


struct Transform
{
	vec3 position;
	quat rotation=quat.identity();

	mat4 matrix()
	{
		return rotation.to_matrix!(4, 4)();
	}
}


class GameObject
{
	VBO mesh;
	Transform transform;

	float angle=0;
	void animate()
	{
		angle+=0.1/60 * std.math.PI /180;
		transform.rotation=quat.axis_rotation(angle, vec3(0, 0, 1));
	}

	static GameObject fromVertices(float[] vertices)
	{
		auto model=new GameObject;
		model.mesh=new VBO(0);
		model.mesh.store(vertices);
		return model;
	}
}


class RenderTarget
{
	Transform camera;
	GameObject root;

	//mat4 viewMatrix=mat4.identity();
	mat4 viewMatrix()
	{
		return camera.rotation.to_matrix!(4, 4)();
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

		this.shader.set("uProjectionMatrix", this.projectionMatrix.value_ptr);
		this.shader.set("uViewMatrix", this.viewMatrix.value_ptr);

        this.shader.set("uModelMatrix", this.root.transform.matrix.value_ptr);

        this.root.mesh.draw();
	}
}


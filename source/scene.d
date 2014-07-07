import std.stdio;
import gl3n.linalg;
import shader;
import vbo;
import texture;


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
	GameObject[] children;
	Animation animation;
	Texture texture;

    this(){
        mesh=new VAO; 
    }

	void add_child(GameObject child)
	{
		children~=child;
	}

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

	void draw(ShaderProgram shader, ref const(mat4) parent)
	{
		// model params
		auto m=this.transform.matrix * parent;
        shader.setMatrix4("uModelMatrix", m);
		
		auto n=mat3(m);
        shader.setMatrix3("uNormalMatrix", n);

		if(this.texture){
			shader.setTexture("uTex1", this.texture, 0);
		}

        this.mesh.draw();

		foreach(GameObject child; this.children)
		{
			child.draw(shader, m);
		}
	}
}


class Camera
{
	mat4 projectionMatrix=mat4.identity();
    GameObject gameobject;

    void pan(double rad){
        auto r=this.gameobject.transform.rotation.rotatey(rad);
        this.gameobject.transform.rotation=r;
	}
	void tilt(double rad)
	{
        auto r=this.gameobject.transform.rotation.rotatex(rad);
        this.gameobject.transform.rotation=r;
	}

    ref mat4 viewMatrix()
    {
        return this.gameobject.transform.matrix;
    }
}


class Light
{
    GameObject gameobject;

    ref vec3 position()
    {
		return this.gameobject.transform.position;
    }
}


class Scene
{
    GameObject root;
    Light light;
    Camera camera;

    this()
    {
        root=new GameObject;
		// light
		this.light=new Light;
        this.light.gameobject=new GameObject;
		root.add_child(this.light.gameobject);
		// camera
		this.camera=new Camera;
		this.camera.gameobject=new GameObject;
		root.add_child(this.camera.gameobject);
    }

    void animate()
    {
        this.root.animate();
    }

    void draw(ShaderProgram shader)
    {
		auto m=mat4.identity;
        this.root.draw(shader, m);
    }
}


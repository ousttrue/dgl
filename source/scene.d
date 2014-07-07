import std.stdio;
static import linalg=gl3n.linalg;
import shader;
import vbo;
import texture;


struct Transform
{
	linalg.vec3 position=linalg.vec3(0, 0, 0);
	linalg.quat rotation=linalg.quat.identity();

	linalg.mat4 matrix()
	{
		auto m=this.rotation.to_matrix!(4, 4);
        m[3][0]=this.position.x;
        m[3][1]=this.position.y;
        m[3][2]=this.position.z;
		return m;
	}

    void advance(double d)
    {
        linalg.mat4 m=this.matrix();
        auto x=m[2][0];
        auto y=m[2][1];
        auto z=m[2][2];
        auto dir=linalg.vec3(x, y, z);
        position+=dir * d;
        writeln(position);
    }
}


class Animation
{
	float angle=0;

	void apply(GameObject go)
	{
		angle+=0.1/60 * std.math.PI /180;
		go.transform.rotation=linalg.quat.axis_rotation(angle, linalg.vec3(0, 0, 1));
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

	void draw(ShaderProgram shader, ref const(linalg.mat4) parent)
	{
		// model params
		auto m=this.transform.matrix * parent;
        shader.setMatrix4("uModelMatrix", m);
		
		auto n=linalg.mat3(m);
        shader.setMatrix3("uNormalMatrix", n);

		if(this.texture){
			shader.setTexture("uTex1", this.texture, 0);
		}

        if(this.mesh){
            this.mesh.draw();
        }

		foreach(GameObject child; this.children)
		{
			child.draw(shader, m);
		}
	}
}


class Camera
{
	linalg.mat4 projectionMatrix=linalg.mat4.identity();
    GameObject gameobject;

    void pan(double rad)
    {
        auto r=this.gameobject.transform.rotation.rotatey(rad);
        this.gameobject.transform.rotation=r;
	}

	void tilt(double rad)
	{
        auto r=this.gameobject.transform.rotation.rotatex(rad);
        this.gameobject.transform.rotation=r;
	}

    void dolly(double d)
    {
        this.gameobject.transform.advance(d);
    }

    linalg.mat4 viewMatrix()
    {
        return this.gameobject.transform.matrix;
    }
}


class Light
{
    GameObject gameobject;

    ref linalg.vec3 position()
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
		auto m=linalg.mat4.identity;
        this.root.draw(shader, m);
    }
}


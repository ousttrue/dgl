import std.stdio;
static import linalg=gl3n.linalg;
import shader;
import vbo;
import texture;


struct Transform
{
	private linalg.vec3 _position=linalg.vec3(0, 0, 0);
    linalg.vec3 position()
    {
        return _position;
    }
    void position(linalg.vec3 position)
    {
        this._position=position;
        calc();
    }

	private linalg.quat _rotation=linalg.quat.identity();
    linalg.quat rotation()
    {
        return _rotation;
    }
    void rotation(linalg.quat rotation)
    {
        //writeln(rotation);
        this._rotation=rotation;
        calc();
    }

	private linalg.mat4 _matrix=linalg.mat4.identity;
    linalg.mat4 matrix()
	{
        return _matrix;
    }
    private void calc()
    {
        //writeln("calc");
		_matrix=this.rotation.to_matrix!(4, 4);

        auto pos=position;
        _matrix[3][0]=pos.x;
        _matrix[3][1]=pos.y;
        _matrix[3][2]=pos.z;

        //writeln(_matrix.as_pretty_string());
	}

    void advance(double d)
    {
        auto m=this.matrix();
        auto x=m[0][2];
        auto y=m[1][2];
        auto z=m[2][2];
        //auto dir=linalg.vec3(x, y, z);
        auto pos=this.position;
        //writeln(x, y, z, d);
        auto result=linalg.vec3(
                pos.x + d * x
                , pos.y + d * y
                , pos.z + d * z
                );
        //writeln(pos, result);
        position=result;
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
    float fovyDegree=30f;
    float near=0.5f;
    float far=100f;
    
    GameObject gameobject;

    this()
    {
		this.gameobject=new GameObject;
    }

	linalg.mat4 projectionMatrix(int width, int height)
    {
        //writef("%s-%s, %s degree, %s-%s\n", width, height, this.fovyDegree, this.near, this.far);
        if(height==0){
            return linalg.mat4.identity();
        }
        else{
            return linalg.mat4.perspective(
                    width, height,
                    this.fovyDegree, this.near, this.far);
        }
    }

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
        return this.gameobject.transform.matrix.inverse();
        //return this.gameobject.transform.matrix;
    }
}


class Light
{
    GameObject gameobject;

    this()
    {
        this.gameobject=new GameObject;
    }

    linalg.vec3 position()
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
		this.root.add_child(this.light.gameobject);
        // camera
        this.camera=new Camera;
        this.root.add_child(this.camera.gameobject);
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


import std.stdio;
import shader;
import gameobject;
static import linalg=gl3n.linalg;


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
        //writef("%s-%s, %s rad, %s-%s\n", width, height, this.fovyDegree, this.near, this.far);
        if(height==0){
            return linalg.mat4.identity();
        }
        else{
            return linalg.mat4.perspective(
                    width, height,
                    this.fovyDegree, this.near, this.far);
        }
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


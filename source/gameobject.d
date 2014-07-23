import vbo;
import transform;
import texture;
import shader;


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


import derelict.opengl3.gl;
import std.stdio;
import gl3n.linalg;
import scene;
import shader;
import texture;


class DepthBuffer
{
    uint id;

    this()
	out{
		assert(this.id);
	}
    body {
        glGenRenderbuffers(1, &this.id);
        glBindRenderbuffer(GL_RENDERBUFFER, this.id);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT
							  , 512, 512);
    }

    ~this()
    {
        glDeleteRenderbuffers(1, &this.id);
        this.id=0;
    }
}


class FBO
{
    uint id;
    Texture texture;
    DepthBuffer depth;

    this()
    out{
        assert(this.id);
    }
    body{
        glGenFramebuffers(1, &this.id);
        glBindFramebuffer(GL_FRAMEBUFFER, this.id);
        // set texture
        this.texture=new Texture;
        glBindTexture(GL_TEXTURE_2D, this.texture.id);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA
					 , 512, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0
							   , GL_TEXTURE_2D, texture.id, 0);
        // set depth
        this.depth=new DepthBuffer;
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT
								  , GL_DEPTH_ATTACHMENT, this.depth.id);
    }

    ~this()
    {
        glDeleteFramebuffers(1, &this.id);
        this.id=0;
    }

	void begin()
    {
        glBindFramebuffer(GL_FRAMEBUFFER, this.id);
        glViewport(0, 0, 512, 512);
        auto drawBufs=[ GL_COLOR_ATTACHMENT0 ];
        glDrawBuffers(1, drawBufs.ptr);
	}


	void end()
	{
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
		//glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }
}


class RenderTarget
{
    ShaderProgram shader;
    Scene scene;
	FBO fbo;
	vec4 clearcolor=vec4(0, 0, 0, 0);

    this(Scene scene, ShaderProgram shader)
	{
		this.scene=scene;
		this.shader=shader;
		_updateCameraMatrix();
	}

    int width;
    int height;
    void onResize(int w, int h)
    {
        this.width=w;
        this.height=h;
    }

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

	private double _mouseLastX;
	private double _mouseLastY;
    private double _pan=0;
    private double _tilt=0;
	void onMouseMove(double x, double y)
	{
        double dx=x-_mouseLastX;
        double dy=y-_mouseLastY;
        bool updated=false;
        if(isMouseLeftDown){
        }
        if(isMouseMiddleDown){
        }
        if(isMouseRightDown){
            this._pan-=dx * std.math.PI /180;
            this._tilt-=dy * std.math.PI /180;
            updated=true;
        }
        if(updated){
            _updateCameraMatrix();
        }

		_mouseLastX=x;
		_mouseLastY=y;
	}

    private double _distance=10;
	void onMouseWheel(double d)
	{
        if(d>0){
            _distance*=0.9;
        }
        else if(d<0){
            _distance*=1.1;
        }
        _updateCameraMatrix();
	}

    private void _updateCameraMatrix()
    {
		writefln("pan %s, tilt %s, distance %s", _pan, _tilt, _distance);
        auto pan=linalg.mat4.rotation(_pan, vec3(0, 1, 0));
        auto tilt=linalg.mat4.rotation(_tilt, vec3(1, 0, 0));
        //auto dolly=linalg.mat4.translation(0, 0, _distance);
		auto dolly=linalg.mat4.identity;
		dolly[3][2]=_distance;
		//auto m=pan * tilt * dolly;
		auto m=dolly * tilt * pan;
        this.scene.camera.gameobject.transform.matrix=m;
		writeln(m);
    }

	void draw()
	{
		if(fbo){
			fbo.begin();
		}

        glViewport(0, 0, this.width, this.height);

        glClearColor(this.clearcolor.x
					 , this.clearcolor.y
					 , this.clearcolor.z
					 , this.clearcolor.w
						 );
        glClear(GL_COLOR_BUFFER_BIT);

        this.shader.use();
        // world params
		this.shader.setMatrix4("uProjectionMatrix", this.scene.camera.projectionMatrix(this.width, this.height));
		auto view=this.scene.camera.viewMatrix;
		this.shader.setMatrix4("uViewMatrix", view);
        this.shader.set("uLightPosition", this.scene.light.position);
        // traverse scene
        this.scene.draw(this.shader);

		glFlush();

		if(fbo){
			fbo.end();
		}
	}
}


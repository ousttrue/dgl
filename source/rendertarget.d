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
                this.scene.camera.pan(dxrad);
				double dyrad=std.math.PI * dy / 180.0;
                this.scene.camera.tilt(dyrad);
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
		if(fbo){
			fbo.begin();
		}

        glClearColor(this.clearcolor.x
					 , this.clearcolor.y
					 , this.clearcolor.z
					 , this.clearcolor.w
						 );
        glClear(GL_COLOR_BUFFER_BIT);

        this.shader.use();
        // world params
		this.shader.setMatrix4("uProjectionMatrix", this.scene.camera.projectionMatrix);
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

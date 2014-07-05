import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;
import gl3n.linalg;


auto vs="#version 400

in vec3 aVertexPosition;
uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

void main()
{
    gl_Position=uProjectionMatrix * uViewMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
}
";


auto fs="#version 400

out vec4 oColor;


void main()
{
    oColor=vec4(1.0, 1.0, 1.0, 1.0);
}
";


class Shader
{
    uint id;
    string lastError;

    this(uint type)
    out
    {
        assert(this.id);
    }
    body
    {
        this.id=glCreateShader(type);
    }

    ~this()
    {
        glDeleteShader(this.id);
    }

    bool compile(string src)
    {
        int len=src.length;
        if(len==0){
            return false;
        }
        auto srcz=toStringz(src);
        glShaderSource(this.id, 1, &srcz, &len);
        glCompileShader(this.id);
        int result;
        glGetShaderiv(this.id, GL_COMPILE_STATUS, &result);
        if(result==GL_FALSE){
            lastError="fail to compile shader";
            int loglen;
            glGetShaderiv(this.id, GL_INFO_LOG_LENGTH, &loglen);
            if(loglen){
                auto log=new char[loglen];
                int written;
                glGetShaderInfoLog(this.id, loglen, &written, &log[0]);
                lastError=std.conv.to!string(log);
            }
            return false;
        }
        return true;
    }

    static createVertexShader()
    {
        return new Shader(GL_VERTEX_SHADER);
    }

    static createFragmentShader()
    {
        return new Shader(GL_FRAGMENT_SHADER);
    }
}


class ShaderProgram
{
    uint id;
	string lastError;

    this()
    out{
        assert(this.id);
    }
    body
    {
        this.id=glCreateProgram();
    }

    ~this()
    {
        glDeleteProgram(this.id);
    }

    Shader _vertexShader;
    void vertexShader(Shader shader)
    {
        glAttachShader(this.id, shader.id);
        _vertexShader=shader;
    }

    Shader _fragmentShader;
    void fragmentShader(Shader shader)
    {
        glAttachShader(this.id, shader.id);
        _fragmentShader=shader;
    }

    bool link()
    {
        glLinkProgram(this.id);
        int status;
        glGetProgramiv(this.id, GL_LINK_STATUS, &status);
        if(status==GL_FALSE){
            lastError="fail to link shader";
            int loglen;
            glGetProgramiv(this.id, GL_INFO_LOG_LENGTH, &loglen);
            if(loglen){
                auto log=new char[loglen];
                int written;
                glGetProgramInfoLog(this.id, loglen, &written, &log[0]);
                lastError=std.conv.to!string(log);
            }
            return false;
        }

        return true;
    }

    void use()
    {
        glUseProgram(this.id);
    }

    void set(const char* name, const float *m)
    {
        uint location=glGetUniformLocation(this.id, name);
        if(location>=0){
            glUniformMatrix4fv(location, 1, GL_FALSE, m);
        }
    }

	void draw(RenderTarget rendertarget)
	{
        this.use();

		this.set("uProjectionMatrix", rendertarget.projectionMatrix.value_ptr);
		this.set("uViewMatrix", rendertarget.viewMatrix.value_ptr);

        this.set("uModelMatrix", rendertarget.root.transform.matrix.value_ptr);

        rendertarget.root.mesh.draw();

	}
}


class VBO
{
    int index;
    uint id;

    this(int index)
    {
        this.index=index;
        glGenBuffers(1, &this.id);
    }

    ~this()
    {
        glDeleteBuffers(1, &this.id);
    }

    void store(float[] data)
    {
        if(data.length==0){
            return;
        }
        glBindBuffer(GL_ARRAY_BUFFER, this.id);
        glBufferData(GL_ARRAY_BUFFER, 4 * data.length, data.ptr, GL_STATIC_DRAW);
    }

	void draw()
	{
        glBindBuffer(GL_ARRAY_BUFFER, this.id);
        glEnableVertexAttribArray(index);
        glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, 0, null);
		glDrawArrays(GL_TRIANGLES, 0, 3);
	}
}


/*
class VAO
{
    uint id;

    this()
    {
        glGenVertexArrays(1, &this.id);
    }

    ~this()
    {
        glDeleteVertexArrays(1, &this.id);
    }

    void push(int index, uint vbo)
    {
        glBindVertexArray(this.id);
        glEnableVertexAttribArray(index);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, 0, null);
    }

    void draw()
    {
        glBindVertexArray(this.id);
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
}
*/


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
}


extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}


extern(C) void framebuffer_size_callback(GLFWwindow* window, int width, int height) nothrow
{
    glViewport(0, 0, width, height);
}


extern(C) void mousebutton_callback(GLFWwindow* window, int button, int action, int mods) nothrow
{
	auto renderTarget=cast(RenderTarget*)glfwGetWindowUserPointer(window);
	try{
		switch(button)
		{
			case 0:
				if(action){
					renderTarget.onMouseLeftDown();
				}
				else{
					renderTarget.onMouseLeftUp();
				}
				break;

			case 1:
				if(action){
					renderTarget.onMouseRightDown();
				}
				else{
					renderTarget.onMouseRightUp();
				}
				break;

			case 2:
				if(action){
					renderTarget.onMouseMiddleDown();
				}
				else{
					renderTarget.onMouseMiddleUp();
				}
				break;

			default:
				break;
		}
	}
	catch(Throwable t)
	{
		//writeln(t);
	}
}

extern(C) void mousemove_callback(GLFWwindow* window, double x, double y) nothrow
{
	auto renderTarget=cast(RenderTarget*)glfwGetWindowUserPointer(window);
	try{
		renderTarget.onMouseMove(x, y);
	}
	catch(Throwable t)
	{
	}
}

extern(C) void mousewheel_callback(GLFWwindow* window, double x, double y) nothrow
{
	auto renderTarget=cast(RenderTarget*)glfwGetWindowUserPointer(window);
	try{
		renderTarget.onMouseWheel(y);
	}
	catch(Throwable t)
	{
	}
}


void main() 
{
    DerelictGL.load();

    DerelictGLFW3.load();
    if (!glfwInit()) {
        writeln("glfwInit didn't work");
        return;
    }

    const int width = 800;
    const int height = 600;
    auto window = glfwCreateWindow(width, height
            ,"GLFW3"
            ,null, null);
    if(!window){
        writeln("fail to glfwCreateWindow");
        return;
    }

	glfwSetFramebufferSizeCallback(window, &framebuffer_size_callback);
	glfwSetKeyCallback(window, &key_callback);
	glfwSetMouseButtonCallback(window, &mousebutton_callback);
	glfwSetCursorPosCallback(window, &mousemove_callback);
	glfwSetScrollCallback(window, &mousewheel_callback);

    glfwMakeContextCurrent(window);

    auto glver=DerelictGL.reload();
	if(glver < derelict.opengl3.gl3.GLVersion.GL40){
		throw new Exception("OpenGL version too low.");
    }

    // after context

    auto vertexShader=Shader.createVertexShader();
    if(!vertexShader.compile(vs)){
        writeln(vertexShader.lastError);
        return;
    }


    auto fragmentShader=Shader.createFragmentShader();
    if(!fragmentShader.compile(fs)){
        writeln(fragmentShader.lastError);
        return;
    }


    auto shader=new ShaderProgram();
    shader.vertexShader=vertexShader;
    shader.fragmentShader=fragmentShader;
    //glBindAttribLocation(shader.id, 0, "aVertexPosition");
    if(!shader.link()){
        writeln(shader.lastError);
        return;
    }
    shader.use();

	auto model=GameObject.fromVertices([
		-0.8f, -0.8f, 0.5f,
		0.8f, -0.8f, 0.5f,
		0.0f,  0.8f, 0.5f
	]);


	auto backbuffer=new RenderTarget;
	glfwSetWindowUserPointer(window, &backbuffer);
	backbuffer.root=model;

    while (!glfwWindowShouldClose(window))
    {
		//model.animate();

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

		shader.draw(backbuffer);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}

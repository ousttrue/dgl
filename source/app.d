import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;

import gl;
import scene;


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

    auto window = glfwCreateWindow(800, 600 ,"GLFW3" ,null, null);
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
    // after context

    auto glver=DerelictGL.reload();
	if(glver < derelict.opengl3.gl3.GLVersion.GL40){
		throw new Exception("OpenGL version too low.");
    }

    // backbuffer
	auto backbuffer=new RenderTarget;
	glfwSetWindowUserPointer(window, &backbuffer);

    // shader
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
    backbuffer.shader=shader;

    // model
	auto model=new GameObject;
    // positions
    model.mesh.set(0, VBO.fromVertices([
		-0.8f, -0.8f, 0.5f,
		0.8f, -0.8f, 0.5f,
		0.0f,  0.8f, 0.5f
	]));
    // normals
    model.mesh.set(1, VBO.fromVertices([
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
    ]));
	backbuffer.root=model;

    while (!glfwWindowShouldClose(window))
    {
		//model.animate();

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

		backbuffer.draw();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}


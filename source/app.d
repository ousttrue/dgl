import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;

import gl;
import scene;


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
    backbuffer.shader=shader;

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


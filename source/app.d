import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;

import shader;
import vbo;
import scene;
static import shaderfactory;
import texture;
import rendertarget;


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
    // opengl
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

	auto scene=new Scene;
	auto camera=scene.camera;
	auto light=scene.light;

    // backbuffer
	auto backbuffer=RenderTarget.createSceneTarget(scene, camera, light);
	glfwSetWindowUserPointer(window, &backbuffer);

    // shader
    auto shader=shaderfactory.create();
    if(!shader){
        writeln("fail to create shader");
        return;
    }
    backbuffer.shader=shader;

    // model
	auto model=new GameObject;
    // positions
    model.mesh.push(VBO!float.fromVertices(3, [
		-0.8f, -0.8f, 0.5f,
		0.8f, -0.8f, 0.5f,
		0.8f,  0.8f, 0.5f,
		-0.8f,  0.8f, 0.5f,
	]));
    // normals
    model.mesh.push(VBO!float.fromVertices(3, [
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
    ]));
	// uvs
	model.mesh.push(VBO!float.fromVertices(2, [
		0.0f, 0.0f,
		1.0f, 0.0f,
		1.0f, 1.0f,
		0.0f, 1.0f,
	]));
    // indices
    model.mesh.elements=VBO!uint.fromVertices(1, [
                0, 1, 2,
                2, 3, 0,
                ]);

	// animation
	auto animation=new Animation;
	model.animation=animation;

	scene.root.add_child(model);

	auto image=new Image;
	if(!image.load("C:/samples/sample.jpg")){
		return;
	}
	int w=image.width;
	int h=image.height;
	int pixelbits=image.pixelbits;

	auto texture=new Texture;
    texture.store(image.ptr, w, h, pixelbits);
	shader.setTexture("uTex1", texture, 0);

    // main loop
    while (!glfwWindowShouldClose(window))
    {
		scene.animate();

        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);

		backbuffer.draw();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}


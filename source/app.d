import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;
import gl3n.linalg;

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
	auto renderTarget=cast(RenderTarget*)glfwGetWindowUserPointer(window);
    try{
        renderTarget.onResize(width, height);
    }
    catch(Throwable ex)
    {
    }
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


Scene create3DScene()
{
	auto scene=new Scene;

    // axis
    {
        auto model=new GameObject;
        scene.root.add_child(model);
        model.mesh=VAO.createAxis(10f);
    }

    // grid
    {
        auto model=new GameObject;
        scene.root.add_child(model);
        model.mesh=VAO.createGrid(10f);
    }

    // model
    {
        auto model=new GameObject;
        scene.root.add_child(model);
        model.mesh=VAO.createQuad(0.8f);

        // texture
        auto texture=Texture.load("C:/samples/sample.png");
        model.texture=texture;

        /*
        // animation
        auto animation=new Animation;
        model.animation=animation;
        */
    }

	return scene;
}


Scene createSprites(FBO fbo)
{
	auto scene=new Scene;

    // model
	auto model=new GameObject;
	scene.root.add_child(model);
    model.mesh=VAO.createQuad(0.8f);

	// texture
	model.texture=fbo.texture;

	return scene;
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

    int w=800;
    int h=600;
    auto window = glfwCreateWindow(w, h, "GLFW3", null, null);
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

    ////////////////////////////////////////////////////////////
    // after context
    ////////////////////////////////////////////////////////////

    auto glver=DerelictGL.reload();
	if(glver < derelict.opengl3.gl3.GLVersion.GL40){
		throw new Exception("OpenGL version too low.");
    }

    // shader
    auto shader=shaderfactory.create();
    if(!shader){
        writeln("fail to create shader");
        return;
    }

	// rendertarget
	auto scene=create3DScene();
	if(!scene){
		return;
	}
    /*
    auto fbo=new FBO;
	auto rendertarget=new RenderTarget(scene, shader);
	rendertarget.fbo=fbo;
	rendertarget.clearcolor=vec4(0.8, 0.4, 0.4, 0);

    // backbuffer
	auto sprites=createSprites(fbo);
	if(!sprites){
		return;
	}
	auto backbuffer=new RenderTarget(sprites, shader);
	glfwSetWindowUserPointer(window, &rendertarget);
    */

	auto backbuffer=new RenderTarget(scene, shader);
    backbuffer.onResize(w, h);
	glfwSetWindowUserPointer(window, &backbuffer);

    // main loop
    while(!glfwWindowShouldClose(window))
    {
		scene.animate();

		//rendertarget.draw();
		backbuffer.draw();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}


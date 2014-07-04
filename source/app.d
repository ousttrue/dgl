import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;

auto vs="#version 400

in vec3 aVertexPosition;
in vec3 aVertexColor;
out vec3 fColor;

void main()
{
    fColor=aVertexColor;
    gl_Position=vec4(aVertexPosition, 1.0);
}
";


void PrintVersion()
{
}


uint CreateShaderProgram()
{
    return 0;
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

    glfwMakeContextCurrent(window);

    // after context
    {
        auto str=std.conv.to!string(glGetString(GL_RENDERER));
        writeln("GL_RENDERER: ", str);
    }
    {
        auto str=std.conv.to!string(glGetString(GL_VENDOR));
        writeln("GL_VENDOR: ", str);
    }
    {
        auto str=std.conv.to!string(glGetString(GL_VERSION));
        writeln("GL_VERSION: ", str);
    }
    {
        auto str=std.conv.to!string(glGetString(GL_SHADING_LANGUAGE_VERSION));
        writeln("GL_SHADING_LANGUAGE_VERSION: ", str);
    }
    GLint major;
    glGetIntegerv(GL_MAJOR_VERSION, &major);
    GLint minor;
    glGetIntegerv(GL_MINOR_VERSION, &minor);
    //writeln("MAJOR, MINOR VERSION: ", major, ", ", minor);

    int nExtensions;
    glGetIntegerv(GL_NUM_EXTENSIONS, &nExtensions);
    writeln("GL_NUM_EXTENSIONS: ", nExtensions);
    for(int i=0; i<nExtensions; ++i){
        //auto str=std.conv.to!string(glGetStringi(GL_EXTENSIONS, i));
        //writeln(i, ", ", str);
    }

    /*
    {
        auto str=std.conv.to!string(glGetString(GL_EXTENSIONS));
        writeln("GL_EXTENSIONS: ", str);
    }
    */

    {
        glViewport(0,0,width,height);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    }

    while (!glfwWindowShouldClose(window))
    {
        {
            glClear(GL_COLOR_BUFFER_BIT);
            glBegin(GL_POLYGON);
            glVertex2d(0,0);
            glVertex2d(0,height);
            glVertex2d(width,height);
            glVertex2d(height,0);
            glEnd();
        }

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}


import std.stdio;
import std.string;
import derelict.opengl3.gl;
import derelict.glfw3.glfw3;


auto vs="#version 400

in vec3 aVertexPosition;
out vec3 fColor;

void main()
{
    gl_Position=vec4(aVertexPosition, 1.0);
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

    //auto vao=new VAO;

    auto position=new VBO(0);
    position.store([
		-0.8f, -0.8f, 0.5f,
		0.8f, -0.8f, 0.5f,
		0.0f,  0.8f, 0.5f
	]);
    //vao.push(0, position.id);

    glViewport(0, 0, width ,height);

    while (!glfwWindowShouldClose(window))
    {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);


        shader.use();
        //vao.draw();
        position.draw();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
}


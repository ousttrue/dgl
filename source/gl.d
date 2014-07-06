import derelict.opengl3.gl;
import std.string;


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

}


class VBO
{
    int index;
    uint id;
    uint components=3;

    this(int index)
    out{
        assert(this.id);
    }
    body
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

    void bind()
    {
        glBindBuffer(GL_ARRAY_BUFFER, this.id);
        glEnableVertexAttribArray(index);
        glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, 0, null);
    }

	void draw()
	{
        bind();
		glDrawArrays(GL_TRIANGLES, 0, 3);
	}
}


class VAO
{
    uint id;

    this()
    out{
        assert(this.id);
    }
    body
    {
        glGenVertexArrays(1, &this.id);
    }

    ~this()
    {
        glDeleteVertexArrays(1, &this.id);
    }

    void set(VBO vbo)
    {
        glBindVertexArray(this.id);
        glEnableVertexAttribArray(vbo.index);
        glBindBuffer(GL_ARRAY_BUFFER, vbo.id);
        glVertexAttribPointer(vbo.index, vbo.components, GL_FLOAT, GL_FALSE, 0, null);
    }

    void draw()
    {
        glBindVertexArray(this.id);
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
}


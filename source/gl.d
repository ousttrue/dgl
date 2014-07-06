import derelict.opengl3.gl;
import std.string;


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
    uint id;
    uint components=3;

    this()
    out{
        assert(this.id);
    }
    body
    {
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

    void bind(int index)
    {
        glBindBuffer(GL_ARRAY_BUFFER, this.id);
        glEnableVertexAttribArray(index);
        glVertexAttribPointer(index, 3, GL_FLOAT, GL_FALSE, 0, null);
    }

    static VBO fromVertices(float[] data)
    {
        auto vbo=new VBO;
        vbo.store(data);
        return vbo;
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

    void set(int index, VBO vbo)
    {
        glBindVertexArray(this.id);
        glEnableVertexAttribArray(index);
        glBindBuffer(GL_ARRAY_BUFFER, vbo.id);
        glVertexAttribPointer(index, vbo.components, GL_FLOAT, GL_FALSE, 0, null);
    }

    void draw()
    {
        glBindVertexArray(this.id);
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
}


import derelict.opengl3.gl;
import std.string;
import std.stdio;
import std.algorithm;
import std.array;
import gl3n.linalg;
import texture;


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

    bool compile(string[] src)
    {
        if(src.length==0){
            return false;
        }

        auto srcz=array(map!((s){return toStringz(s);})(src));
        auto len=array(map!(s => cast(int)s.length)(src));
        writeln(srcz);
        writeln(len);

        glShaderSource(this.id, srcz.length, &srcz[0], len.ptr);
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

    void set(string name, ref const(vec3) v)
    {
        uint location=glGetUniformLocation(this.id, toStringz(name));
        if(location>=0){
            glUniform3fv(location, GL_FALSE, v.value_ptr);
        }
    }

    void setMatrix3(string name, ref const (mat3) m)
    {
        uint location=glGetUniformLocation(this.id, toStringz(name));
        if(location>=0){
            glUniformMatrix3fv(location, 1, GL_FALSE, m.value_ptr);
        }
    }

    void setMatrix4(string name, ref const (mat4) m)
    {
        uint location=glGetUniformLocation(this.id, toStringz(name));
        if(location>=0){
            glUniformMatrix4fv(location, 1, GL_FALSE, m.value_ptr);
        }
    }

	void setTexture(string name, Texture texture, int index)
	{
		glBindTexture(GL_TEXTURE_2D, texture.id);
		glActiveTexture(GL_TEXTURE0+index);
		uint location=glGetUniformLocation(this.id, toStringz(name));
		if(location>=0){
			glUniform1i(location, index);
		}
	}
}


class VBO(T)
{
    uint id;

	static if(is(T==float)){
		uint usage(){ return GL_ARRAY_BUFFER; }
		uint type(){ return GL_FLOAT; }
	}
	static if(is(T==uint)){
		uint usage(){ return GL_ELEMENT_ARRAY_BUFFER; }
		uint type(){ return GL_UNSIGNED_INT; }
	}
	
    uint components=3;

    this(int components)
    out{
        assert(this.id);
		assert(this.components);
    }
    body
    {
        glGenBuffers(1, &this.id);
		this.components=components;
    }

    ~this()
    {
        glDeleteBuffers(1, &this.id);
    }

    void store(T[] data)
    {
        if(data.length==0){
            return;
        }
        glBindBuffer(this.usage, this.id);
        glBufferData(this.usage
                , T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
    }

    void bind(int index)
    {
        glBindBuffer(this.usage, this.id);
        glEnableVertexAttribArray(index);
        glVertexAttribPointer(index, this.components, this.type, GL_FALSE, 0, null);
    }

    static VBO!T fromVertices(uint components, T[] data)
    {
        auto vbo=new VBO!T(components);
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

	VBO!float[] vbos=[];
    void push(VBO!float vbo)
    {
		int index=vbos.length;
		vbos~=vbo;
        glBindVertexArray(this.id);
        glEnableVertexAttribArray(index);
        glBindBuffer(vbo.usage, vbo.id);
        glVertexAttribPointer(index, vbo.components, vbo.type, GL_FALSE, 0, null);
    }
	
	private VBO!uint _elements;
	void elements(VBO!uint vbo)
	{
		_elements=vbo;
        glBindBuffer(vbo.usage, vbo.id);
	}

    void draw()
    {
        glBindVertexArray(this.id);
		if(_elements){
			glDrawElements(GL_TRIANGLES, 6, _elements.type, null);
		}
		else{
			glDrawArrays(GL_TRIANGLES, 0, 3);
		}
    }
}

import derelict.opengl3.gl;


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

    static VAO createQuad(float size)
    {
        auto mesh=new VAO;

        mesh.push(VBO!float.fromVertices(3, [
                    -size, -size, 0.5f,
                    size, -size, 0.5f,
                    size,  size, 0.5f,
                    -size,  size, 0.5f,
                    ]));
        // normals
        mesh.push(VBO!float.fromVertices(3, [
                    0.0f, 0.0f, -1.0f,
                    0.0f, 0.0f, -1.0f,
                    0.0f, 0.0f, -1.0f,
                    0.0f, 0.0f, -1.0f,
                    ]));
        // colors
        mesh.push(VBO!float.fromVertices(4, [
                    1f, 1f, 1f, 1f,
                    1f, 1f, 1f, 1f,
                    1f, 1f, 1f, 1f,
                    1f, 1f, 1f, 1f,
                    ]));
        // uvs
        mesh.push(VBO!float.fromVertices(2, [
                    0.0f, 0.0f,
                    1.0f, 0.0f,
                    1.0f, 1.0f,
                    0.0f, 1.0f,
                    ]));
        // indices
        mesh.elements=VBO!uint.fromVertices(1, [
                0, 1, 2,
                2, 3, 0,
                ]);

        return mesh;
    }

    static VAO createAxis()
    {
        auto mesh=new VAO;
        return mesh;
    }

    static VAO createGrid()
    {
        auto mesh=new VAO;
        return mesh;
    }

}


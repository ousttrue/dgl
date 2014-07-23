import derelict.opengl3.gl;
import std.algorithm;


enum VertexAttributes
{
    float2,
    float3,    
    float4,
};
int elements(VertexAttributes attr)
{
    final switch(attr)
    {
        case VertexAttributes.float2: return 2;
        case VertexAttributes.float3: return 3;
        case VertexAttributes.float4: return 4;
    }
}


class VertexSource
{
    uint mode;
    VertexAttributes[] attributes;
    int elements;

    uint vertexcount;
    float[][] data;
    uint[] indices;

    this(uint mode, VertexAttributes[] attributes)
    {
        this.mode=mode;
        this.attributes=attributes;
        this.data=new float[][attributes.length];
        this.indices=[];

        this.elements=attributes.map!(a => a.elements).reduce!("a + b");
    }

    void addVertex(float[] vertex ...)
    in{
        assert(vertex.length==this.elements);
    }
    body
    {
        auto v=vertex;
        for(int i=0; i<this.attributes.length; ++i)
        {
            switch(this.attributes[i])
            {
                case VertexAttributes.float2:
                    this.data[i] ~= v[0..2];
                    v=v[2..$];
                    break;

                case VertexAttributes.float3:
                    this.data[i] ~= v[0..3];
                    v=v[3..$];
                    break;

                case VertexAttributes.float4:
                    this.data[i] ~= v[0..4];
                    v=v[4..$];
                    break;
            }
        }
        ++this.vertexcount;
    }

    void addLine(float[] v0, float[] v1)
    {
        auto i=this.vertexcount;
        addVertex(v0);
        addVertex(v1);
        this.indices ~= [i, i+1];
    }

    void addQuad(float[] v0, float[] v1, float[] v2, float[] v3)
    {
        auto i=this.vertexcount;
        addVertex(v0);
        addVertex(v1);
        addVertex(v2);
        addVertex(v3);
        this.indices ~= [i, i+1, i+2];
        this.indices ~= [i+2, i+3, i];
    }

    static VertexSource createQuad(float size)
    {
        auto src=new VertexSource(
                GL_TRIANGLES
                , [ VertexAttributes.float3 // position
                , VertexAttributes.float3 // normal
                , VertexAttributes.float4 // rgba
                , VertexAttributes.float2 // uv
                ]
                );

        src.addQuad([
                -size, -size, 0f // pos
                , 0.0f, 0.0f, -1.0f // normal
                , 1f, 1f, 1f, 1f // rgba
                , 0.0f, 0.0f // uv
                ]
                , [size, -size, 0f
                , 0.0f, 0.0f, -1.0f
                , 1f, 1f, 1f, 1f
                , 1.0f, 0.0f
                ]
                , [
                size,  size, 0f
                , 0.0f, 0.0f, -1.0f
                , 1f, 1f, 1f, 1f
                , 1.0f, 1.0f
                ]
                , [
                -size,  size, 0f
                , 0.0f, 0.0f, -1.0f
                , 1f, 1f, 1f, 1f
                , 0.0f, 1.0f
                ]
                );
        return src;
    }

    static VertexSource createAxis(float size)
    {
        auto src=new VertexSource(
                GL_LINES
                , [ VertexAttributes.float3 // position
                , VertexAttributes.float3 // normal
                , VertexAttributes.float4 // rgba
                , VertexAttributes.float2 // uv
                ]
                );

        src.addLine(
                [
                -size, 0, 0,
                0.0f, 1.0f, 0.0f,
                1f, 0f, 0f, 1f,
                0.0f, 0.0f,
                ]
                , [
                +size, 0, 0,
                0.0f, 1.0f, 0.0f,
                1f, 0f, 0f, 1f,
                0.0f, 0.0f,
                ]);
        src.addLine(
                [
                0, -size, 0,
                0.0f, 1.0f, 0.0f,
                0f, 1f, 0f, 1f,
                0.0f, 0.0f,
                ]
                , [
                0, +size, 0,
                0.0f, 1.0f, 0.0f,
                0f, 1f, 0f, 1f,
                0.0f, 0.0f,
                ]);
        src.addLine(
                [
                0, 0, -size,
                0.0f, 1.0f, 0.0f,
                0f, 0f, 1f, 1f,
                0.0f, 0.0f,
                ]
                , [
                0, 0, +size,
                0.0f, 1.0f, 0.0f,
                0f, 0f, 1f, 1f,
                0.0f, 0.0f,
                ]);

        return src;
    }

    static VertexSource createGrid(float size)
    {
        auto src=new VertexSource(
                GL_LINES
                , [ VertexAttributes.float3 // position
                , VertexAttributes.float3 // normal
                , VertexAttributes.float4 // rgba
                , VertexAttributes.float2 // uv
                ]
                );

        return src;
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
    uint mode;
    int indexcount;

    this(uint mode)
    out{
        assert(this.id);
        assert(this.mode);
    }
    body
    {
        glGenVertexArrays(1, &this.id);
        this.mode=mode;
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
			glDrawElements(this.mode, this.indexcount, _elements.type, null);
		}
		else{
			glDrawArrays(this.mode, 0, this.indexcount);
		}
    }

    static VAO create(VertexSource src)
    {
        auto mesh=new VAO(src.mode);

        for(int i=0; i<src.attributes.length; ++i)
        {
            switch(src.attributes[i])
            {
                case VertexAttributes.float2:
                    mesh.push(VBO!float.fromVertices(2, src.data[i]));
                    break;

                case VertexAttributes.float3:
                    mesh.push(VBO!float.fromVertices(3, src.data[i]));
                    break;

                case VertexAttributes.float4:
                    mesh.push(VBO!float.fromVertices(4, src.data[i]));
                    break;
            }
        }

        // indices
        mesh.elements=VBO!uint.fromVertices(1, src.indices);
        mesh.indexcount=src.indices.length;

        return mesh;
    }
}


import std.stdio;
import std.string;
import shader;


enum glslbind
{
    vertexattribute,
    uniform,
    input,
    output,
}


enum glsltype
{
    vec2,
    vec3,
    vec4,
    mat3,
    mat4,
	sampler2D,
}


struct Variable
{
    glslbind bind;;
    glsltype type;
    string name;

    string toString(ref int vertexattributeIndex)
    {
        final switch(bind)
        {
            case glslbind.vertexattribute:
                return format("layout(location=%s) in %s %s;\n"
                        , vertexattributeIndex++, this.type, this.name);

            case glslbind.uniform:
                return format("uniform %s %s;\n"
                        , this.type, this.name);

            case glslbind.input:
                return format("in %s %s;\n"
                        , this.type, this.name);

            case glslbind.output:
                return format("out %s %s;\n"
                        , this.type, this.name);
        }
    }
}


string[] build_shader(Variable[] vars, string src)
{
    auto list=new string[1 + vars.length + 3];

    int vertexatributeIndex=0;
    int index=0;
    list[index++]="#version 400\n";

    foreach(Variable v; vars)
    {
        list[index++]=v.toString(vertexatributeIndex);
    }

    list[index++]="void main(){\n";
    list[index++]=src;
    list[index++]="}\n";

	writeln(join(list, ""));

    return list;
}


ShaderProgram create()
{
    auto vertexShader=Shader.createVertexShader();
    {
        auto vars=[
            Variable(glslbind.vertexattribute, glsltype.vec3, "aVertexPosition"),
            Variable(glslbind.vertexattribute, glsltype.vec3, "aVertexNormal"),
			Variable(glslbind.vertexattribute, glsltype.vec2, "aVertexTexCoord"),
            Variable(glslbind.uniform, glsltype.mat4, "uModelMatrix"),
            Variable(glslbind.uniform, glsltype.mat4, "uViewMatrix"),
            Variable(glslbind.uniform, glsltype.mat4, "uProjectionMatrix"),
            Variable(glslbind.uniform, glsltype.mat3, "uNormalMatrix"),
            Variable(glslbind.uniform, glsltype.vec3, "uLightPosition"),
			Variable(glslbind.output, glsltype.vec2, "fTexCoord"),
            Variable(glslbind.output, glsltype.vec3, "fLightIntensity"),
            ];
        auto src="
gl_Position=uProjectionMatrix * uViewMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);

fTexCoord=aVertexTexCoord;

vec3 tnorm=normalize(uNormalMatrix * aVertexNormal);
vec4 eyeCoords=uViewMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
vec3 s=normalize(uLightPosition-eyeCoords.xyz);
fLightIntensity=vec3(max(dot(s, tnorm), 0));
";
        if(!vertexShader.compile(build_shader(vars, src))){
            writeln(vertexShader.lastError);
            return null;
        }
    }

    auto fragmentShader=Shader.createFragmentShader();
    {
        auto vars=[
			Variable(glslbind.input, glsltype.vec2, "fTexCoord"),
            Variable(glslbind.input, glsltype.vec3, "fLightIntensity"),
            Variable(glslbind.output, glsltype.vec4, "oColor"),
			Variable(glslbind.uniform, glsltype.sampler2D, "uTex1"),
            ];
        auto src="
vec4 texColor=texture(uTex1, fTexCoord);
//vec4 texColor=vec4(fTexCoord, 1, 1);
oColor=texColor * vec4(fLightIntensity, 1.0);
";
        if(!fragmentShader.compile(build_shader(vars, src))){
            writeln(fragmentShader.lastError);
            return null;
        }
    }

    auto shader=new ShaderProgram();
    shader.vertexShader=vertexShader;
    shader.fragmentShader=fragmentShader;
    //glBindAttribLocation(shader.id, 0, "aVertexPosition");
    if(!shader.link()){
        writeln(shader.lastError);
        return null;
    }

    return shader;
}


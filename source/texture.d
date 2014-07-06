import std.string;
import std.file;
import derelict.devil.il;
import derelict.devil.ilu;
import derelict.devil.ilut;
import derelict.opengl3.gl;


static this()
{
    DerelictIL.load();
    //DerelictILU.load();
    DerelictILUT.load();
    ilInit();
    //iluInit();
    //ilutInit();
    //ilutRenderer(ILUT_OPENGL);
}

static ~this()
{
}


class Image
{
    uint id;

    this()
        out{
            assert(this.id);
        }
    body{
        this.id=ilGenImage();
    }

    ~this()
    {
        ilDeleteImage(this.id);
        this.id=0;
    }

    bool load(string path)
    {
        auto data=std.file.read(path);
        if(!data){
            return false;
        }

        ilBindImage(this.id);
        if(!ilLoadL(IL_TYPE_UNKNOWN, data.ptr, data.length)){
            return false;
        }
        return true;
    }

    int width()
    {
        ilBindImage(this.id);
        return ilGetInteger(IL_IMAGE_WIDTH);
    }

    int height()
    {
        ilBindImage(this.id);
        return ilGetInteger(IL_IMAGE_HEIGHT);
    }

    int pixelbits()
    {
        ilBindImage(this.id);
        return ilGetInteger(IL_IMAGE_BITS_PER_PIXEL);
    }

    int stride()
    {
        return ilGetInteger(IL_IMAGE_SIZE_OF_DATA)/height;
    }

    ubyte* ptr()
    {
        ilBindImage(this.id);
        return ilGetData();
    }
}


class Texture
{
    uint id;

    this(uint id)
        out{
            assert(this.id);
        }
    body
    {
        this.id=id;
    }

    this()
    {
        uint id;
        glGenTextures(1, &id);
        this(id);
    }

    ~this()
    {
        glDeleteTextures(1, &this.id);
        this.id=0;
    }

    bool store(const ubyte* data, int w, int h, int pixelbits)
    {
        glBindTexture(GL_TEXTURE_2D, this.id);

        //glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

        glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);

        /*
           glTexParameteri(
           GL_TEXTURE_2D,
           GL_TEXTURE_MAG_FILTER,
           GL_LINEAR);

           glTexParameteri(
           GL_TEXTURE_2D,
           GL_TEXTURE_MIN_FILTER,
           GL_LINEAR_MIPMAP_LINEAR);

           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
           glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
         */

        glTexImage2D(
                GL_TEXTURE_2D,
                0,
                GL_RGB,
                w, h,
                0,
                GL_RGB,
                GL_UNSIGNED_BYTE,
                data);
        return true;
    }
}


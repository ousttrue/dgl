import std.stdio;
import gl3n.linalg;
import scene;
import shader;


class RenderTarget
{
    ShaderProgram shader;
    Scene scene;
    Camera camera;
	Light light;

    private this(){}

    static createSceneTarget(Scene scene, Camera camera, Light light)
    {
        auto rendertarget=new RenderTarget;
        rendertarget.scene=scene;
        rendertarget.camera=camera;
        rendertarget.light=light;
        return rendertarget;
    }

	bool isMouseLeftDown;
	void onMouseLeftDown()
	{
		writeln("left down");
		isMouseLeftDown=true;
	}
	void onMouseLeftUp()
	{
		writeln("left up");
		isMouseLeftDown=false;
	}

	bool isMouseMiddleDown;
	void onMouseMiddleDown()
	{
		writeln("m down");
		isMouseMiddleDown=true;
	}
	void onMouseMiddleUp()
	{
		writeln("m up");
		isMouseMiddleDown=false;
	}

	bool isMouseRightDown;
	void onMouseRightDown()
	{
		writeln("right down");
		isMouseRightDown=true;
	}
	void onMouseRightUp()
	{
		writeln("right up");
		isMouseRightDown=false;
	}

	double mouseLastX;
	double mouseLastY;
	void onMouseMove(double x, double y)
	{
		if(!std.math.isnan(x) && !std.math.isnan(y)){
			double dx=x-mouseLastX;
			double dy=y-mouseLastY;
			if(isMouseLeftDown){
			}
			if(isMouseMiddleDown){
			}
			if(isMouseRightDown){
				double dxrad=std.math.PI * dx / 180.0;
                this.camera.pan(dxrad);
				double dyrad=std.math.PI * dy / 180.0;
                this.camera.tilt(dyrad);
			}
		}
		mouseLastX=x;
		mouseLastY=y;
	}

	void onMouseWheel(double d)
	{
		writeln("wheel: ", d);
	}

	void draw()
	{
        this.shader.use();
        // world params
		this.shader.setMatrix4("uProjectionMatrix", this.camera.projectionMatrix);
		auto view=this.camera.viewMatrix;
		this.shader.setMatrix4("uViewMatrix", view);
        this.shader.set("uLightPosition", this.light.position);
        // traverse scene
        this.scene.draw(this.shader);
	}
}


static import linalg=gl3n.linalg;


struct Transform
{
	private linalg.vec3 _position=linalg.vec3(0, 0, 0);
    linalg.vec3 position()
    {
        return _position;
    }
    void position(linalg.vec3 position)
    {
        this._position=position;
        calc();
    }

	private linalg.quat _rotation=linalg.quat.identity();
    linalg.quat rotation()
    {
        return _rotation;
    }
    void rotation(linalg.quat rotation)
    {
        this._rotation=rotation;
        calc();
    }

	private linalg.mat4 _matrix=linalg.mat4.identity;
    linalg.mat4 matrix()
	{
        return _matrix;
    }
    void matrix(linalg.mat4 m)
    {
        _rotation=linalg.quat.from_matrix(linalg.mat3(m));
        _position.x=m[3][0];
        _position.y=m[3][1];
        _position.z=m[3][2];
        _matrix=m;
    }
    private void calc()
    {
		_matrix=this.rotation.to_matrix!(4, 4);

        auto pos=position;
        _matrix[3][0]=pos.x;
        _matrix[3][1]=pos.y;
        _matrix[3][2]=pos.z;
	}

    linalg.vec3 up()
    {
        auto m=this.matrix();
        auto x=m[1][0];
        auto y=m[1][1];
        auto z=m[1][2];
        return linalg.vec3(x, y, z);
    }

    linalg.vec3 forward()
    {
        auto m=this.matrix();
        auto x=m[2][0];
        auto y=m[2][1];
        auto z=m[2][2];
        return linalg.vec3(x, y, z);
    }

    void rotate(linalg.vec3 axis, double rad)
    {
        auto rot=linalg.mat4.rotation(rad, axis);
        auto result=matrix*rot;
        matrix=result;
    }
}


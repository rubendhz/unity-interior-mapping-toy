//UNITY_SHADER_NO_UPGRADE
#ifndef MYHLSLINCLUDE_INCLUDED
#define MYHLSLINCLUDE_INCLUDED

float map_range(float value, float min1, float max1, float min2, float max2) 
{
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float rand(float2 co)
{
    return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

float2 _intersect2D(float3 ro, float3 rd, float3 axis, float d, float id1, float id2)
{
    float rd_weight = dot(rd, axis);
    float ro_weight = dot(ro, axis);
    float pointer = ceil(ro_weight / d);  
    int looking_up = rd_weight > 0.0;
    float h = (pointer - !looking_up) * d; // -1 when looking down
    float t = (h - ro_weight) / rd_weight;
    float id = looking_up ? id1 : id2;
    return float2(t, id);
}

void intersect(float3 ro, float3 rd, float3 right, float3 up, float3 front, float3 size, out float t, out int id)
{
    float2 tID1 = _intersect2D(ro, rd, up, size.y, 1.0, 2.0);
    float2 tID2 = _intersect2D(ro, rd, right, size.x, 3.0, 4.0);
    float2 tID3 = _intersect2D(ro, rd, front, size.z, 5.0, 6.0);
    float2 tID;
    if( tID1.x < tID2.x )
    {
        tID = (tID1.x<tID3.x) ? tID1 : tID3;
    }
    else
    {
        tID = (tID2.x<tID3.x) ? tID2 : tID3;
    } 

    t = tID.x;
    id = int(floor(tID.y + 0.5));
}

float3 uv_parallax_warp(float t, int id, float3 ro, float3 rd, float3 size, bool cubemap, float2 back_face_size, bool randomise, float2 seed)
{
    float3 pos = ro + t*rd;
    pos = pos / size;
    
    float2 frame_size = float2(0.0, 0.0);
    if (!cubemap)
    {
        frame_size.x = 0.5*(1.0-back_face_size.x);
        frame_size.y = 0.5*(1.0-back_face_size.y);
    }

    float2 _uv = float2(0.0, 0.0);
    int back_face = 0;
    if (id == 1)
    {
        //ceiling
        _uv = frac(float2(pos.x,-pos.z));
        if (cubemap)
        {
            _uv = float2(map_range(_uv.x, 0, 1, 0.333, 0.666), map_range(_uv.y, 0, 1.0, 0.666, 1.0));
        }
        else
        {
            _uv.y = map_range(_uv.y, 0, 1.0, frame_size.y+back_face_size.y, 1.0);
            float trim = (frame_size.x * (1.0-_uv.y)) / frame_size.y;
            _uv.x = map_range(_uv.x, 0, 1, trim, 1.0-trim);
        }
    } 
    else if (id == 2)
    {
        //floor    
        _uv = frac(float2(pos.x,pos.z));
        if (cubemap)
        {
            _uv = float2(map_range(_uv.x, 0, 1, 0.333, 0.666), map_range(_uv.y, 0.0, 1, 0.0, 0.333));
        }
        else
        {
            _uv.y = map_range(_uv.y, 0.0, 1.0, 0.0, frame_size.y);
            float trim = (frame_size.x * _uv.y) / frame_size.y;
            _uv.x = map_range(_uv.x, 0, 1, trim, 1.0 - trim);
        }
    }
    else if (id == 3)
    {
        //right wall
        _uv = frac(float2(-pos.z,pos.y)); 
        
        if (cubemap)
        {
            float2 x_range = float2(0.666, 1.0);
            if (randomise)
            {
                if ((int(seed.y * 57867) % 2) == 0 )
                {
                    x_range = float2(0.0, 0.333);
                }
                if (seed.x > 0.3)
                {
                    x_range = x_range.yx;
                }
            }
            
            _uv = float2(map_range(_uv.x, 0, 1.0, x_range.x, x_range.y), map_range(_uv.y, 0, 1, 0.333, 0.666));
        }
        else
        {
            _uv.x = map_range(_uv.x, 0.0, 1.0, frame_size.x + back_face_size.x, 1.0);
            float trim = (frame_size.y * (1.0-_uv.x)) / frame_size.x;
            _uv.y = map_range(_uv.y, 0, 1, trim, 1.0-trim);
        }
    }
    else if (id == 4)
    {
        //left wall
        _uv = frac(float2(pos.z,pos.y)); 
        
        if (cubemap)
        {
            float2 x_range = float2(0.0, 0.333);
            if (randomise)
            {
                if ((int(seed.y * 34567) % 2) == 0 )
                {
                    x_range = float2(0.666, 1.0);
                }
                if (seed.y > 0.5)
                {
                    x_range = x_range.yx;
                }
            }
            _uv = float2(map_range(_uv.x, 0.0, 1.0, x_range.x, x_range.y), map_range(_uv.y, 0, 1, 0.333, 0.666));
        }
        else
        {
            _uv.x = map_range(_uv.x, 0.0, 1.0, 0.0, frame_size.x);
            float trim = (frame_size.y * _uv.x) / frame_size.x;
            _uv.y = map_range(_uv.y, 0, 1, trim, 1.0 - trim);
        }
    }
    else 
    {
        //back wall
        _uv = frac(float2(pos.x,pos.y)); 

        if (cubemap)
        {
            float2 x_range = float2(0.333, 0.666);
            if (randomise)
            {
                if ((int((seed.x+seed.y) * 777) % 3) == 0 )
                {
                    x_range = float2(0.0, 0.333);
                }
                else
                if ((int((seed.x+seed.y) * 645) % 3) == 0 )
                {
                    x_range = float2(0.666, 1.0);
                }
            
                if ((seed.y + seed.x) > 1.0)
                {
                    x_range = x_range.yx;
                }
            }
            _uv = float2(map_range(_uv.x, 0, 1, x_range.x, x_range.y), map_range(_uv.y, 0, 1, 0.333, 0.666));
        }
        else
        {
            _uv = float2(map_range(_uv.x, 0, 1, frame_size.x, frame_size.x+back_face_size.x), map_range(_uv.y, 0, 1, frame_size.y, frame_size.y+back_face_size.y));
        }

        back_face = 1;
    }

    return float3(_uv, back_face);
}

void parallaxMapping_float(
    float3 view, 
    float2 uv, 
    float depth, 
    float3 reorient, 
    bool cubemap, 
    float2 back_face_size, 
    bool randomise, 
    float2 seed, 
    out float3 outColor)
{
    float3 ro = float3( uv, depth+0.0001 );
    float3 rd = normalize(-view);
    
    //rd = rd.yzx; //1, 2, 0 remapping //XYZ, XZY, YXZ, YZX, ZXY, and ZYX
    float3 _rd = rd;
    rd.x = _rd[reorient.x];
    rd.y = _rd[reorient.y];
    rd.z = _rd[reorient.z];
    
    float3 size  = float3(1.0, 1.0, depth);  
    float t; int id;
    intersect(ro, rd, float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), float3(0.0, 0.0, 1.0), size, t, id);    
    outColor = uv_parallax_warp(t, id, ro, rd, size, cubemap, back_face_size, randomise, seed);
}

#endif //MYHLSLINCLUDE_INCLUDED
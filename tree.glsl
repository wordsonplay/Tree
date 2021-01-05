/* "Tree distance", by wordsonplay

   License: Creative Commons Attribution ShareAlike 4.0
   https://creativecommons.org/licenses/by-sa/4.0/
       
   Based on iq's "Segment - distance 2D"
   https://www.shadertoy.com/view/3tdSDj

*/

//////////////////////////////////////////////////////////////////////

#define MAX_DIST 1e38
#define SCALE 2.0
#define TAU 6.2831853071

float rand( vec2 n )
{
	return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b, in float th, in float d )
{
    vec2 ba = b-a;
    vec2 pa = p-a;
    float h =clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return min(d, length(pa-h*ba) - th);
}

float sdSegment2( in vec2 p, in vec2 a, in vec2 b, in float th0, in float th1, in float d )
{
    vec2 ba = b-a;
    vec2 pa = p-a;
    float h =clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return min(d, length(pa-h*ba) - mix(th0, th1, h));
}


float sdCircle( in vec2 p, in vec2 c, float r, in float d)
{
    vec2 v = p - c;
    return min(d, length(v) - r);
}

float sdGround( in vec2 p, in float d)
{
    vec2 size = SCALE * iResolution.xy / iResolution.y;
    vec2 v1 = vec2(size.x, -1.5);
	vec2 v2 = vec2(-size.x, -1.5);;
    float th = 0.01;
    
    return sdSegment(p, v1, v2, th, d);
}

float sdSun( in vec2 p, in float d)
{
    vec2 size = SCALE * iResolution.xy / iResolution.y;
    vec2 v = vec2(-size.x * 0.75, 0.75);    
    return sdCircle(p, v, 0.2, d);
}

mat2 rotate(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

const float angleL = -TAU / 12.;
const float angleR = TAU / 30.;
const mat2 rotL = mat2(cos(angleL), sin(angleL), -sin(angleL), cos(angleL));
const mat2 rotR = mat2(cos(angleR), sin(angleR), -sin(angleR), cos(angleR));

const mat2 flip = mat2(-1, 0, 0, 1);

const float scaleLeft = 0.8;
const float scaleRight= 0.99;
const float scaleThickness = 0.8;

const vec2 vUp = vec2(0,1);

float sdBranch( in vec2 p, vec2 root, int i, in float d) 
{
    float h = 0.5;
    mat2 mat = mat2(1);
    float th = 0.1;
    vec2 v = root;
        
    int depth = 0;
    float scale = 1.0;
    int branch = 1;
    bool skip = false;
        
    for (int j = i; j > 1; j = j / 2) 
    {
        v = v + mat * vUp * h;
            
        float r = rand(vec2(branch) + root);
            
        int b = j % 2;
        branch = branch * 2 + b;
        mat *= (b == 0 ? rotR : rotL);
        mat = (r > 0.5 ? mat * flip : mat);
        scale = (b == 0 ? scaleRight : scaleLeft); 
        scale *= mix(scaleLeft, scaleRight, r);
        h *= scale;
        th *= scale * scaleThickness;
        depth += 1;
            
        // drop some branches
        if (abs(r-0.5) < 0.025)
        {
            return d;
        }
    }


    return sdSegment2(p, v, v + mat * vUp * h, th, th * scaleThickness, d);
}

#define DEPTH 9
const int branches = 1 << DEPTH;

float sdTree(in vec2 p, in vec2 root, in float d)
{

    for (int i = 1; i <= branches; i++)
    {
        d = sdBranch(p, root, i, d);
    }
    
    return d;
}

float sdTree2(in vec2 p, in vec2 root, in float d)
{
    
    float h[DEPTH];
    mat2 mat[DEPTH];
    float th[DEPTH];
    vec2 v[DEPTH];
    int dd[DEPTH];

    int stack = 1;

    h[0] = 0.5;
    mat[0] = mat2(1);
    th[0] = 0.1;
    v[0] = root;
    dd[0] = 1;

    while (stack > 0)
    {
        // pop entry off stack
        stack -= 1;
        mat2 m = mat[stack];
        float thickness = th[stack];
        float height = h[stack];
        int depth = dd[stack];

        // build branch
        vec2 v1 = v[stack] + m * vUp * height;
        d = sdSegment2(p, v[stack], v1, thickness, thickness * scaleThickness, d);

        // recurse
        if (depth < DEPTH)
        {
            // left branch
            v[stack] = v1;
            mat[stack] = m * rotL;
            h[stack] = height * scaleLeft;
            th[stack] = thickness * scaleLeft * scaleThickness;
            dd[stack] = depth + 1;
            stack += 1;

            // right branch
            v[stack] = v1;
            mat[stack] = m * rotR;
            h[stack] = height * scaleRight;
            th[stack] = thickness * scaleRight * scaleThickness;
            dd[stack] = depth + 1;
            stack += 1;
        }
    }
    
    return d;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    p *= SCALE;

    float d = MAX_DIST;

    d = sdGround(p, d);
    d = sdTree2(p, vec2(0, -1.5), d);
 
    vec3 col = vec3(1.0) - sign(d)*vec3(0.4,0.7,0.1);
	col *= 1.0 - exp(-3.0*abs(d));
	col *= 0.8 + 0.2*cos(120.0*d);
	col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.015,abs(d)) );
    
	fragColor = vec4(col,1.0);
}
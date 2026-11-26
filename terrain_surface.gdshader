shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(0.5,0.4,0.3,1.0);
uniform float wood = 0.0;
varying vec3 world_pos;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise3(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec3 p=world_pos;
 float coarse=noise3(p*3.5);
 float fine=noise3(p*35.0);
 float grain=noise3(p*vec3(2.0,42.0,25.0));
 float rings=sin(p.y*65.0+noise3(p*vec3(1.4,8.0,3.0))*7.0)*0.5+0.5;
 float detail=mix(coarse*0.65+fine*0.35,grain*0.65+rings*0.35,wood);
 ALBEDO=base_color.rgb*(0.72+detail*0.48);
 ROUGHNESS=0.83;
 SPECULAR=0.24;
}

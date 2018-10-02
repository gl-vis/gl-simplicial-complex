#extension GL_OES_standard_derivatives : enable

precision highp float;

#pragma glslify: cookTorrance = require(glsl-specular-cook-torrance)
#pragma glslify: faceNormal = require('glsl-face-normal')

uniform vec3 clipBounds[2];
uniform float roughness
            , fresnel
            , kambient
            , kdiffuse
            , kspecular
            , opacity;
uniform sampler2D texture;

varying vec3 f_normal
           , f_lightDirection
           , f_eyeDirection
           , f_data;
varying vec4 f_color;
varying vec2 f_uv;

bool outOfRange(float a, float b, float p) {
  if (p > max(a, b)) return true;
  if (p < min(a, b)) return true;
  return false;
}

void main() {
  if (outOfRange(clipBounds[0].x, clipBounds[1].x, f_data.x)) discard;
  if (outOfRange(clipBounds[0].y, clipBounds[1].y, f_data.y)) discard;
  if (outOfRange(clipBounds[0].z, clipBounds[1].z, f_data.z)) discard;

  vec3 N = normalize(f_normal);
  vec3 L = normalize(f_lightDirection);
  vec3 V = normalize(f_eyeDirection);

  vec3 normal = faceNormal(f_data);
  
  if (dot(N, normal) < 0.0) {
    N = -N;
  }

  float specular = cookTorrance(L, V, N, roughness, fresnel);
  float diffuse  = min(kambient + kdiffuse * max(dot(N, L), 0.0), 1.0);

  vec4 surfaceColor = f_color * texture2D(texture, f_uv);
  vec4 litColor = surfaceColor.a * vec4(diffuse * surfaceColor.rgb + kspecular * vec3(1,1,1) * specular,  1.0);

  gl_FragColor = litColor * opacity;
}

#version 100

varying highp vec2 textureCoord;
uniform sampler2D luminanceTexture;
uniform sampler2D chrominaceTexture;
uniform mediump mat3 colorConversionMatrix;

void main(){

    mediump vec3 yuv;
    lowp vec3 rgb;
    yuv.x = texture2D(luminanceTexture,textureCoord).r;
    yuv.yz= texture2D(chrominaceTexture,textureCoord).ra - vec2(0.5,0.5);
    rgb = colorConversionMatrix * yuv;
    gl_FragColor = vec4(rgb,1);
}
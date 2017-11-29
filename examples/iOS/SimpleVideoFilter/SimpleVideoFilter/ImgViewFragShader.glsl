#version 100

varying highp vec2  textureCoord;
uniform sampler2D imgTexture;

void main(){
    gl_FragColor = texture2D(imgTexture,textureCoord);
}
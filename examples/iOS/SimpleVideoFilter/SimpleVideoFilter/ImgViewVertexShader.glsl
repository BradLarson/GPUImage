#version 100

attribute vec4 postion;
attribute vec4 intputTextureCoord;
varying vec2  textureCoord;

void main(){
    gl_Position = postion;
    textureCoord = intputTextureCoord.xy;
}
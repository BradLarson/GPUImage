varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

const vec2 sampleDivisor = vec2(0.1, 0.1);

void main()
{
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
    gl_FragColor = texture2D(inputImageTexture, samplePos );
}
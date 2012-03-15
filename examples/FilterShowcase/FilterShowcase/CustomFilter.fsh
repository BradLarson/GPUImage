varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

precision highp float;

void main (void) 
{
    highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel);
    
    highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
    gl_FragColor = texture2D(inputImageTexture, samplePos );
}



varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform mediump vec3 inputColor;
uniform mediump float threshold;

precision mediump float;

vec3 normalizeColor(vec3 color)
{
    return color / max(dot(color, vec3(1.0/3.0)), 0.3);
}

vec4 maskPixel(vec3 pixelColor, vec3 maskColor)
{
    float  d;
    vec4   calculatedColor;
    
    // Compute distance between current pixel color and reference color
    d = distance(normalizeColor(pixelColor), normalizeColor(maskColor));
    
    // If color difference is larger than threshold, return black.
    calculatedColor =  (d > threshold)  ?  vec4(0.0)  :  vec4(1.0);
    
	//Multiply color by texture
	return calculatedColor;
}

void main()
{
	float d;
	vec4 pixelColor, maskedColor;
    
	pixelColor = texture2D(inputImageTexture, textureCoordinate);
	maskedColor = maskPixel(pixelColor.rgb, inputColor);
    
	gl_FragColor = (maskedColor.a < 1.0) ? pixelColor : maskedColor;
}


varying highp vec2 textureCoordinate;

uniform sampler2D texture;

void main()
{
	gl_FragColor = texture2D(texture, textureCoordinate);
//	gl_FragColor = vec4(textureCoordinate, 1.0, 1.0);
}

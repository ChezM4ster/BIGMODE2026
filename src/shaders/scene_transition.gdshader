// Original : Shader By Zacksly - https://zacksly.itch.io/
shader_type canvas_item;
//uniform bool UseColor; //removed because unnecessary in this case
uniform bool TransparentDot;
uniform float AspectRatio = 1.5;
uniform float Dots = 10.0;
uniform float _min;
uniform float _max = 1.0;
//uniform bool UseReshade; //removed because unnecessary in this case

uniform float height = 0.0;

void fragment() {

	vec3 uv_grid = fract(vec3(UV, 0.0) * vec3(AspectRatio * Dots, Dots, 0.0)); // replaced SCREEN_UV with UV

	float grid = distance(uv_grid, vec3(0.5, 0.5, 0.5));
	/*
	vec3 raw_cam_image;
	{
		//vec4 _tex_read = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
		raw_cam_image = _tex_read.rgb;
	}
	*/// removed because in this case ScreenTexture isn't used
	vec3 raw_cam_image = vec3(1,1,1) * (UV.y + height);
	vec3 grayscale;
	{
		float max1 = max(raw_cam_image.r, raw_cam_image.g);
		float max2 = max(max1, raw_cam_image.b);
		float max3 = max(max1, max2);
		grayscale = vec3(max3, max3, max3);
	}

	vec3 clamped = clamp(grayscale, vec3(_min), vec3(_max));

	bool black_dot_grid = grid > dot(vec3(1.0, 1.0, 1.0) - clamped, vec3(0.333333, 0.333333, 0.333333));
	bool white_dot_grid = grid < dot(clamped, vec3(0.333333, 0.333333, 0.333333));

	vec4 texture_uv = texture(TEXTURE,UV);
	//vec3 grid_result = BlackDot ? vec3(black_dot_grid ? 1.0 : 0.0) : vec3(white_dot_grid ? 1.0 : 0.0);	//vec4(texture_uv.r,texture_uv.g,texture_uv.b,1.0)
	vec4 grid_result = TransparentDot? (black_dot_grid? texture_uv : vec4(0.0)): (white_dot_grid? texture_uv : vec4(0.0));
	/*
	vec3 saturated_image = vec3(0.0, 0.0, 0.0);
	{
		if (abs(raw_cam_image.r - raw_cam_image.g) +
			abs(raw_cam_image.g - raw_cam_image.b) +
			abs(raw_cam_image.b - raw_cam_image.r) > .1 )
		{
			raw_cam_image.rgb = mix(vec3(0.0), raw_cam_image.rgb, 2); //Brightness
			raw_cam_image.rgb = mix(vec3(0.5), raw_cam_image.rgb, 1); // Contrast
			raw_cam_image.rgb = mix(vec3(dot(vec3(1.0), raw_cam_image.rgb)*0.33333), raw_cam_image.rgb, 2); //Saturation
		} else {
			raw_cam_image = vec3(1.0,1.0,1.0);
		}
		saturated_image.rgb = raw_cam_image;
	}*/// removed because UseReshade hasn't been used

	//vec3 screen_image = UseReshade ? saturated_image : raw_cam_image;

	//vec3 final_image = UseColor ? grid_result * screen_image : grid_result;

	COLOR.rgb = grid_result.rgb;

	COLOR.a = grid_result.a;
}
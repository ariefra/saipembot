-- this file required to defined colors of texts
-- foreground 256bit color (# = 0-255): \27[38;5;#m
-- background 256bit color (# = 0-255): \27[48;5;#m

do local _ = {
	color_reset = '\27[0m';
  	color_normal = '\27[39m';
	color_warn = '\27[33m';
	color_error = '\27[31m';
	color_debug = '\27[30;1m';
  	color_private = '\27[35m';
  	color_action = '\27[31m';
  	color_msg = '\27[30;1m';


  	color_light = '\27[1m';
  	color_dark = '\27[0m';

	fg_black = '\27[30m';
	fg_red = '\27[31m';
	fg_green = '\27[32m';
	fg_yellow = '\27[33m';
	fg_blue = '\27[34m';
	fg_magenta = '\27[35m';
	fg_cyan = '\27[36m';
	fg_white = '\27[37m';
	fg_reset = '\27[39m';

	bg_black = '\27[40m';
	bg_red = '\27[41m';
	bg_green = '\27[42m';
	bg_yellow = '\27[43m';
	bg_blue = '\27[44m';
	bg_magenta = '\27[45m';
	bg_cyan = '\27[46m';
	bg_white = '\27[47m';
	bg_reset = '\27[49m';

}
return _
end
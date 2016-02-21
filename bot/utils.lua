_THEME = require('bot/theme')
serpent = require('serpent')

function dbg_var(lvl, value)
  if _DEBUG >= lvl then	print(_THEME.color_debug..serpent.block(assert(value), {comment=false}) .._THEME.color_reset) end
end

function log_var(lvl, filename, value)
	if _DEBUG >= lvl then
		appendlog(assert(filename),serpent.block(assert(value), {comment=false}))
	end
end
function dbg_prn(lvl, s)
	if _DEBUG >= lvl then print(_THEME.color_debug..assert(s).._THEME.color_reset) end
end

function dbg_warn(lvl, s)
	if _DEBUG >= lvl then print(_THEME.color_warn..assert(s).._THEME.color_reset) end
end

function dbg_err(lvl, s)
	if _DEBUG >= lvl then print(_THEME.color_error..assert(s).._THEME.color_reset) end
end

function dbg_info(lvl, s)
	if _DEBUG >= lvl then print(_THEME.color_normal..assert(s).._THEME.color_reset) end
end

function dbg_prn_msg(lvl, msg)
	local m = assert(msg)
	local str, id

	if _THEME.color_reset ~= nil then str = _THEME.color_reset end

	-- date
	str = str..fg_color(8)..os.date('%m.%d %H:%M',m.date)..' '

	-- group id
	if m.to.peer_id ~= our_id then str = str..fg_color(tonumber(m.to.peer_id)%20+63)..group_fullname_withid(m.to)..fg_color(8)..'<-' end

	-- action & username
	id = m.from
	if m.action ~= nil then
		str = str .._THEME.color_action..m.action.type..': '
		if m.action.user ~=nil then id=m.action.user end
	end

	str = str..fg_color(tonumber(id.peer_id)%20+235)
	if m.action ~=nil then str = str..user_fullname_withid(assert(id)) else str = str..user_fullname(assert(id)) end
	str = str..fg_color(8)

	if m.text ~= nil then str = str..': '.._THEME.color_msg..m.text end
	if m.media ~= nil then
		if m.media.type == 'webpage' then
			str = str..' ['..m.media.type..']'
			if m.media.title ~= nil then str = str..'\n'..m.media.title end
			if m.media.description ~= nil then str = str..'\n'..m.media.description end
			if m.media.url ~= nil then str = str..'\n'..m.media.url..'\n' end
		else str = str..' ['..m.media.type..' '..m.id..']\n' end
	end

	str = str:gsub('\n','\n\t') .. _THEME.color_reset
	str = str:gsub('[\128-\193]','')	-- strip unicode

	-- if m.media ~= nil then
	dbg_prn(lvl, str)
	-- end

	str = str:gsub('\27[^%sm]+m','')	-- strip ansi color
	if	m.to.peer_id ~= our_id and
		m.to.peer_type ~= 'user' and
		_GROUP[m.to.peer_id] ~=nil and
		_GROUP[m.to.peer_id].config ~=nil and
		_GROUP[m.to.peer_id].config.group_log
	then appendlog('./logs/groups/'..m.to.peer_id..'.log',str)
	elseif m.to.peer_type ~= 'user' then appendlog('./logs/pm/'..m.to.peer_id..'.log',str)
	else appendlog('./logs/pm/'..m.from.peer_id..'.log',str)
	end
end

function user_fullname_withid(usr)
	dbg_prn(10, 'user_fullname_withid')
	local u = assert(usr)
	local msg = '('..u.peer_id..')'

	if u.username ~= nil then msg = msg..' @'..u.username end
	if (u.first_name ~= nil)or(u.last_name ~= nil) then msg = msg..' / '..user_fullname(u) end
	return msg
end

function user_fullname(usr)
	dbg_prn(10, 'user_fullname')
	local u = assert(usr)
	local fullname = ''

	if u.first_name ~= nil then fullname = u.first_name end
	if u.last_name ~= nil then
		if u.first_name ~= nil then fullname = fullname..' ' end
		fullname = fullname..u.last_name
	end
	if (fullname=='')and(u.print_name ~= nil) then fullname = u.print_name end
	return fullname
end

function group_fullname_withid(group)
	dbg_prn(10, 'group_fullname_withid')
	local g = assert(group)
	local msg = '['..g.peer_id..']'

	if g.title ~= nil then msg = msg..' '..g.title end
	return msg
end

function add_info(src)
	dbg_prn(10,'add info')
	local u = assert(src)
	local cfg
	dbg_var(10, u)

	if m.from ~= nil then add_info(m.from) end
	if m.to ~= nil then add_info(m.to) end

	if u.peer_type == nil and u.from.peer_type == 'user' and u.to.peer_type ~= 'user' then
		_MSG[u.id] = u.from.peer_id	-- keep peer_id for all message
	elseif u.peer_type == 'user' then
		if _USER[u.peer_id] == nil then
			_USER[u.peer_id] = u
			dbg_prn(10, 'found '.. u.peer_type..' '..user_fullname_withid(u))
		else
			cfg = _USER[u.peer_id].config
			_USER[u.peer_id] = u
			_USER[u.peer_id].config = cfg
			dbg_prn(10,'updating user '..u.peer_id)
		end
		_TOUCHED.user = true
	elseif u.peer_type ~= nil and u.peer_type ~= 'user' then
		if _GROUP[u.peer_id] == nil then
			_GROUP[u.peer_id] = u
			-- del_group_config()
			_GROUP[u.peer_id].config = set_default(_GROUP[u.peer_id].config, default_group_config)
			dbg_prn(10, 'found '.. u.peer_type..' '..group_fullname_withid(u))
		else
			local cfg = _GROUP[u.peer_id].config
			_GROUP[u.peer_id] = u
			_GROUP[u.peer_id].config = cfg
			-- del_group_config()
			_GROUP[u.peer_id].config = set_default(_GROUP[u.peer_id].config, default_group_config)
			dbg_prn(10,'updating group '..u.peer_id)
		end
		_TOUCHED.group = true
	end
end

function autosave()
	dbg_prn(10,'autosave...')
	if _TOUCHED.config then save_CONFIG(_CONFIG,_CONFIG.config_file,false); _TOUCHED.config = false end
	if _TOUCHED.group then save_CONFIG(_GROUP,_CONFIG.group_file,false); _TOUCHED.group = false end
	if _TOUCHED.user then save_CONFIG(_USER,_CONFIG.user_file,false); _TOUCHED.user = false end
	if _MSG ~= nil then save_CONFIG(_MSG,_CONFIG.msglog_file,false)	end -- slow saving method need better save method
	postpone(autosave,false,_CONFIG.delay_autosave)
end

function save_CONFIG(var, filename, uglify)
	dbg_prn(9, 'saving '..filename)
	serialize_to_file(assert(var),filename,uglify)
end

-- Save into file the data serialized for lua.
-- Set uglify true to minify the file.
function serialize_to_file(data, file, uglify)
	local f = assert(io.open(file, 'w+'))
	local serialized
	dbg_prn(10,'serialize_to_file')
	if not uglify then
		serialized = serpent.block(data, {
			indent = ' ',
			sortkeys = false,
			comment = false,
			name = '_'
		})
	else
		serialized = serpent.dump(data)
	end
	f:write(serialized)
	f:close()
end

function load_CONFIG(filename)
	local fn = assert(filename)
	local f = io.open(fn, 'r')
	dbg_prn(10,'load config '..fn)

	-- If filename doesn't exist
	if not f then return nil else f:close() end
	return loadfile(fn)()
end

function appendlog(filename, txt)
	local t = assert(txt)..'\n' -- os.date('%Y.%m.%d %z %T')..'\t'..
	local f = assert(io.open(filename, 'a'))
	f:write(t)
	f:close()
end

function kick_user(user_id, chat_id)
	dbg_prn(10,'kick_user')
	local u = 'user#id'..assert(user_id)
	local c = _GROUP[assert(chat_id)].peer_type..'#id'..chat_id

	if _GROUP[assert(chat_id)].peer_type == 'chat'
		then chat_del_user(c,u,ok_cb,false)
		else channel_kick_user(c,u,ok_cb,false)
	end

	-- dbg_prn(1, os.date('%m.%d %H:%M',m.date)..fg_color(tonumber(m.to.peer_id)%20+63)..group_fullname_withid(m.to)..fg_color(8)..'<-'..fg_color(tonumber(m.from.peer_id)%20+235)..user_fullname(m.from)..fg_color(8)..': '..m.text)
	-- appendlog('./logs/'..m.to.peer_id..'.log',os.date('%m.%d %H:%M',m.date)..user_fullname(m.from)..': '..m.text)
	appendlog(_CONFIG.kicklog_file, os.date('%m.%d %H:%M')..'\t'..group_fullname_withid(_GROUP[chat_id])..': '..user_fullname_withid(_USER[user_id])..' kicked')
end

function is_blacklist(user_id)
	return (_CONFIG.blacklist_user[user_id] ~= nil)
end

function is_banned(user_id, chat_id)
	dbg_prn(10,'is_banned')
	if is_moderator(user_id, chat_id) or
		_CONFIG.our_id == user_id or
		not is_blacklist(user_id) or
		_GROUP[chat_id] == nil or
		_GROUP[chat_id].config == nil or
		_GROUP[chat_id].config.owner == user_id or
		_GROUP[chat_id].config.ban_list == nil or
		_GROUP[chat_id].config.ban_list[user_id] == nil
	then return false end
	return true
end

function is_moderator(user_id, chat_id)
	dbg_prn(10,'is moderator')
	if _CONFIG.admin_id[user_id] ~= nil and
		_CONFIG.admin_id[user_id] == true
	then return true
	elseif _GROUP[chat_id] ~= nil and
		_GROUP[chat_id].config ~= nil and
		_GROUP[chat_id].config.moderator_id ~= nil and
		_GROUP[chat_id].config.moderator_id[user_id] ~= nil and
		_GROUP[chat_id].config.moderator_id[user_id] == true
	then return true
	end

	return false
end

function is_bot(msg)
	local m = assert(msg)
	if m.peer_type == 'user' and m.username:find('bot$') ~= nil then return true end
end

function ok_cb(cb_extra, success, result)
	dbg_prn(10,'ok_cb')
end

function trim(str)
	local s = str
	return s:gsub('^%s*([^%s])*%s*$', '%1')
end

function ban(msg)
	dbg_prn(10,'ban')
	if not _CONFIG.started then return end
	local m = assert(msg)

	if m.reply_id ~= nil and(m.to.peer_type ~= 'user') and(_GROUP[m.to.peer_id] ~= nil) then
		_GROUP[m.to.peer_id].config.ban_list[_MSG[m.reply_id]] = true
	else
		local t = string.match(trim(string.lower(assert(m.text))),('^[^%s]+%s+(.*)$'))
		if t == nil then return
		elseif tonumber(t) ~= nil and tonumber(t) > 0 then
			local t = tonumber(t)
			if _USER[t] ~= nil then _GROUP[m.to.peer_id].config.ban_list[t] = true end
		elseif t:match('^@(.+)') ~= nil then
			t = t:match('^@(.+)')
			for k,v in pairs(_USER) do
				if(v.username ~= nil and v.username == t) then _GROUP[m.to.peer_id].config.ban_list[k] = true end
			end
		end
	end
end

function kick(msg)
	dbg_prn(10,'kick')
	if not _CONFIG.started then return end
	local m = assert(msg)

	if(m.reply_id ~= nil) and(_MSG[m.reply_id] ~= nil) and(m.to.peer_type ~= 'user') and(_GROUP[m.to.peer_id] ~= nil) then
		kick_user(_MSG[m.reply_id],m.to.peer_id)
	else
		-- local t = string.match(trim(string.lower(assert(m.text))),('^[^%s]+%s+(.*)$'))
		local t = assert(m.text)
		t = t:lower()
		t = trim(t)
		t = t:match('^[^%s]+%s+(.*)$')
		if t == nil then return
		elseif tonumber(t) ~= nil and tonumber(t) > 0 then
			local t = tonumber(t)
			kick_user(t,m.to.peer_id)
		elseif t:match('^@(.+)') ~= nil then
			t = t:match('^@(.+)')
			for k,v in pairs(_USER) do
				if(v.username ~= nil and v.username:lower() == t) then kick_user(k,m.to.peer_id) end
			end
		end
	end
end

function unban(msg)
	dbg_prn(10,'unban')
	if not _CONFIG.started then return end
	local m = assert(msg)

	if _GROUP[m.to.peer_id] == nil or _GROUP[m.to.peer_id].config.ban_list == nil then return end

	if
		m.reply_id ~= nil and
		_MSG[m.reply_id] ~= nil and
		m.to.peer_type ~= 'user' and
		_GROUP[m.to.peer_id].config.ban_list[_MSG[m.reply_id]]
	then
		_GROUP[m.to.peer_id].config.ban_list[_MSG[m.reply_id]] = nil
	else
		local t = string.match(trim(string.lower(assert(m.text))),('^[^%s]+%s+(.*)$'))
		if t == nil then return
		elseif tonumber(t) ~= nil and tonumber(t) > 0 then
			local t = tonumber(t)
			if _GROUP[m.to.peer_id].config.ban_list[t] then _GROUP[m.to.peer_id].config.ban_list[t] = nil end
		elseif t:match('^@(.+)') ~= nil then
			t = t:match('^@(.+)')
			for k,v in pairs(_USER) do
				if(v.username ~= nil and v.username == t and _GROUP[m.to.peer_id].config.ban_list[k]) then _GROUP[m.to.peer_id].config.ban_list[k] = nil end
			end
		end
	end
end

function blacklist(msg)
	dbg_prn(10,'blacklist')
	if not _CONFIG.started then return end
	local m = assert(msg)

	if m.reply_id ~= nil and(m.to.peer_type ~= 'user') then _CONFIG.blacklist_user[_MSG[m.reply_id]] = true
	else
		local t = string.match(trim(string.lower(assert(m.text))),('^[^%s]+%s+(.*)$'))
		if t == nil then return
		elseif tonumber(t) ~= nil and tonumber(t) > 0 then
			local t = tonumber(t)
			_CONFIG.blacklist_user[t] = true
		elseif t:match('^@(.+)') ~= nil then
			t = t:match('^@(.+)')
			for k,v in pairs(_USER) do
				if(v.username ~= nil and v.username == t) then _GROUP[m.to.peer_id].config.ban_list[k] = true end
			end
		end
	end
end

function invite(msg)
	dbg_prn(1,'invite')
	if not _CONFIG.started then return end
	local m = assert(msg)
end

function greet_user(msg)
	dbg_prn(10,'greet_user')
	if not _CONFIG.started then return end
	local m = assert(msg)

	if	_GROUP[m.to.peer_id].greet_user and
		_GROUP[m.to.peer_id].greet_message_count > 0 and
		_GROUP[m.to.peer_id].greet_message ~= nil
	then
		local gs = assert(_GROUP[m.to.peer_id].greet_message[math.random(_GROUP[m.to.peer_id].greet_message_count)-1])
		
end

function set_default(var, default)
	if var==nil then var = {} end
	for k,v in pairs(default) do
		if type(v) == 'table' then
			var[k] = set_default(var[k],v)
		end
		if var[k] == nil then var[k]=v end
	end
	return var
end

function del_group_config()
	for k,v in pairs(_GROUP) do
		_GROUP[k].config = nil
	end
end

function fg_color(c)
	return ('\27[38;5;'..tostring(assert(c))..'m')
end

function bg_color(c)
	return('\27[48;5;'..tostring(assert(c))..'m')
end
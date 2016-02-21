VERSION = '0.1'
_DEBUG = 1

package.path = package.path..';/usr/local/share/lua/5.2/?.lua'
require("bot/utils")

default_config = {
	config_file = './data/config.lua',
	group_file = './data/group.lua',
	user_file = './data/user.lua',
	kicklog_file = './logs/kick.log',
	msglog_file = './logs/msg.log',
	delay_autosave = 10,
	-- whitelist_user = {},
	blacklist_user = {},
	admin_id = {[32955011] = true},
	-- our_id = 0,
}

default_group_config = { -- default config
	group_log = false,
	-- allow_bot = true,
	-- allow_link = true,
	-- allow_sticker = true,
	-- allow_media = true,
	-- allow_files = true,
	-- allow_rename = true,
	-- greet_user = false,
	-- goodbye_user = false,
	-- flood_limit = 5, -- per minute
	moderator_id = {},
	ban_list = {}
}

default_user_config = {
	-- kicked_count = 0
}

default_greetings = {
	'salken %name',
	'salam kenal buat yang baru masuk',
	'hi %name',
	'selamat datang %name di group %groupname'
}

default_goodbye ={
	'wooh kenapa pergi %firstname',
	'hiks hiks ilang lagi satu',
	'bye bye',
	'bye %firstname'
}

_TOUCHED = {
	config = true,
	group = true,
	user = true
}


function on_binlog_replay_end()
	dbg_prn(10, 'on_binlog_replay_end')
	dbg_prn(1, 'synchronizing messages...')
end

function on_get_difference_end()
	dbg_prn(10, 'on_get_difference_end')
	dbg_prn(1,'message sync complete.')
	_CONFIG.started=true
	autosave()
end

function on_our_id(our_id)
	dbg_prn(10,'on_our_id')
	local id = assert(our_id)
	_CONFIG.our_id = id
end

function on_msg_receive(msg)
	dbg_prn(10,'on_msg_receive')
	local m = assert(msg)

	if not _CONFIG.started then return end

	add_info(m)
	if m.service then on_msg_service(m)
	elseif m.out then on_msg_out(m) -- sent messages
	elseif m.text~=nil and m.text:match('^[/!]') ~= nil then on_msg_command(m)
	elseif m.media ~= nil then on_msg_media(m) -- incoming messages
	elseif m.to.peer_id == _CONFIG.our_id then on_msg_private(m)
	-- elseif m.to.peer_type == 'chat' then on_msg_group(m)
	-- elseif m.to.peer_type == 'channel' then on_msg_group(m)
	end

end

function on_msg_service(msg)
	local m = assert(msg)
	if(m.action.type == 'chat_add_user') then on_chat_add_user(m)
	elseif(m.action.type == 'chat_add_user_link') then	on_chat_add_user_link(m)
	elseif(m.action.type == 'chat_del_user') then on_chat_del_user(m)
	-- elseif(m.action.type == 'chat_rename') then on_chat_rename(m)
	-- elseif(m.action.type == 'geo_created') then
	-- elseif(m.action.type == 'geo_checkin') then
	-- elseif(m.action.type == 'chat_created') then
	-- elseif(m.action.type == 'chat_change_photo') then
	-- elseif(m.action.type == 'chat_delete_photo') then
	-- elseif(m.action.type == 'set_ttl') then
	-- elseif(m.action.type == 'read') then
	-- elseif(m.action.type == 'delete') then
	-- elseif(m.action.type == 'screenshot') then
	-- elseif(m.action.type == 'flush') then
	-- elseif(m.action.type == 'resend') then
	-- elseif(m.action.type == 'set_layer') then
	-- elseif(m.action.type == 'typing') then
	-- elseif(m.action.type == 'nop') then
	-- elseif(m.action.type == 'request_rekey') then
	-- elseif(m.action.type == 'accept_rekey') then
	-- elseif(m.action.type == 'commit_rekey') then
	-- elseif(m.action.type == 'abort_rekey') then
	-- elseif(m.action.type == 'channel_created') then
	-- elseif(m.action.type == 'migrated_to') then -- chat upgraded to supergroup
	-- elseif(m.action.type == 'migrated_from') then
	-- else
	-- 	dbg_prn(10, 'unhandled service messages '..m.action.type..' received')
	end
end

function on_msg_out(msg)
	dbg_prn(10,'on_msg_out')
	local m = assert(msg)

	if m.text ~= nil and m.text:match('^[/!]') ~= nil then on_msg_command(m) end
end

function on_msg_private(msg)
	dbg_prn(10, 'on_msg_private')
	local m = assert(msg)
end

function on_msg_media(msg)
	dbg_prn(10,'on_msg_media')
	local m = assert(msg)
	appendlog('./logs/vardump.log', os.date('%m.%d %H:%M',m.date))
	log_var(1,'./logs/vardump-'..m.to.peer_id..'.log', m)
end

-- function on_msg_group(msg)
-- 	dbg_prn(10,'on_msg_group')
-- 	local m = assert(msg)
-- end

function on_msg_command(msg)
	dbg_prn(10,'on_msg_command')
	local m = assert(msg)

	if m.text ~= nil then
		local t = string.lower(m.text)

		if not is_moderator(m.from.peer_id) then t = nil
		elseif t:match('^[/!]b') ~= nil then ban(m)
		elseif t:match('^[/!]k') ~= nil then kick(m)
		elseif t:match('^[/!]kb') ~= nil then ban(m); kick(m)
		elseif t:match('^[/!]bl') ~= nil then blacklist(m)

		-- elseif t:match('^[/!]kickb') ~= nil then ban(m); kick(m)
		-- elseif t:match('^[/!]p') ~= nil then kick(m); invite(m) -- punch: kick and re-invite
		-- elseif t:match('^[/!]ub') ~= nil then unban(m)
		-- elseif t:match('^[/!]unb') ~= nil then unban(m)
		end
	end
end

function on_user_update(usr, flags)
	dbg_prn(10, 'on_user_update')
	local u = assert(usr)

	-- add user to _USER if not exist
	add_info(u)
end

function on_chat_update(chat, flags)
	dbg_prn(10, 'on_chat_update')
	local c = assert(chat)

	-- add chat to _GROUP if not exist
	add_info(c)
end

function on_secret_chat_update(sc, flags)
	dbg_prn(10, 'on_secret_chat_update')
	-- if not _CONFIG.started then return end

	-- local c = assert(sc)
	-- local f = assert(flags)
	-- dbg_var(10, c)
	-- dbg_var(10, f)
end

function on_chat_add_user(msg)
	dbg_prn(10,'on_chat_add_user')
	local m = assert(msg)

	if is_banned(m.action.user.peer_id, m.to.peer_id) then
		kick_user(m.action.user.peer_id, m.to.peer_id)
	else greet_user(m)
	end
end

function on_chat_add_user_link(msg)
	dbg_prn(10,'on_chat_add_user_link')
	local m = assert(msg)

	if is_banned(m.from.peer_id, m.to.peer_id) then
		kick_user(m.from.peer_id, m.to.peer_id)
	else greet_user(m)
	end

	-- add group owner info
	add_info(m.action.link_issuer)
	if _GROUP[m.to.peer_id].config.owner == nil then
		_GROUP[m.to.peer_id].config.owner = m.action.link_issuer.peer_id
		_TOUCHED.group = true
		dbg_prn(10, 'found owner of '..group_fullname_withid(m.to)..' -> '..user_fullname_withid(m.action.link_issuer))
	end
end

function on_chat_del_user(msg)
	dbg_prn(10,'on_chat_del_user')
	local m = assert(msg)
end

function on_chat_rename(msg)
	dbg_prn(10,'on_chat_rename')
	local m = assert(msg)
end

-- init code
function init()
	_CONFIG = load_CONFIG(default_config.config_file)
	if _CONFIG ~= nil then dbg_prn(10,'config loaded') end
	
	_CONFIG = set_default(_CONFIG, default_config)
	_CONFIG.start_time = os.time()
	_CONFIG.started = true

	_GROUP = load_CONFIG(_CONFIG.group_file)
	if _GROUP == nil then _GROUP = {} end

	_USER = load_CONFIG(_CONFIG.user_file)
	if _USER == nil then _USER = {} end

	_MSG = load_CONFIG(_CONFIG.msglog_file)
	if _MSG == nil then _MSG = {} end

	math.randomseed(_CONFIG.start_time)
end

dbg_prn(10, 'bot.lua init')
init()
dbg_prn(10, 'bot.lua init completed')
print('\27[36;1massist-bot \27[37mv.'..VERSION..'\27[30;6m is running...\27[0m')
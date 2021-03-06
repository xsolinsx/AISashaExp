rank_table = { ["USER"] = 1, ["MOD"] = 2, ["OWNER"] = 3, ["ADMIN"] = 4, ["SUDO"] = 5, ["BOT"] = 6 }
reverse_rank_table = { "USER", "MOD", "OWNER", "ADMIN", "SUDO", "BOT" }

URL = require "socket.url"
http = require "socket.http"
https = require "ssl.https"
ltn12 = require "ltn12"

serpent =(loadfile "./libs/serpent.lua")()
json =(loadfile "./libs/JSON.lua")()
mimetype =(loadfile "./libs/mimetype.lua")()
redis =(loadfile "./libs/redis.lua")()
sha2 =(loadfile "./libs/sha2.lua")()
langs = dofile("languages.lua")

http.TIMEOUT = 10

function get_receiver(msg)
    if msg.to.type == 'user' then
        return 'user#id' .. msg.from.id
    end
    if msg.to.type == 'chat' then
        return 'chat#id' .. msg.to.id
    end
    if msg.to.type == 'encr_chat' then
        return msg.to.print_name
    end
    if msg.to.type == 'channel' then
        return 'channel#id' .. msg.to.id
    end
end

function get_reply_receiver(result)
    if result.to.peer_type == 'user' then
        return 'user#id' .. result.from.peer_id
    end
    if result.to.peer_type == 'chat' then
        return 'chat#id' .. result.to.peer_id
    end
    if result.to.peer_type == 'encr_chat' then
        return result.to.print_name
    end
    if result.to.peer_type == 'channel' then
        return 'channel#id' .. result.to.peer_id
    end
end

function is_chat_msg(msg)
    if msg.to.type == 'chat' then
        return true
    end
    return false
end

function string.random(length)
    local str = "";
    for i = 1, length do
        math.random(97, 122)
        str = str .. string.char(math.random(97, 122));
    end
    return str;
end

function string:split(sep)
    local sep, fields = sep or ":", { }
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

-- DEPRECATED
function string.trim(s)
    print("string.trim(s) is DEPRECATED use string:trim() instead")
    return s:gsub("^%s*(.-)%s*$", "%1")
end

-- Removes spaces
function string:trim()
    return self:gsub("^%s*(.-)%s*$", "%1")
end

function get_http_file_name(url, headers)
    -- Eg: foo.var
    local file_name = url:match("[^%w]+([%.%w]+)$")
    -- Any delimited alphanumeric on the url
    file_name = file_name or url:match("[^%w]+(%w+)[^%w]+$")
    -- Random name, hope content-type works
    file_name = file_name or str:random(5)

    local content_type = headers["content-type"]

    local extension = nil
    if content_type then
        extension = mimetype.get_mime_extension(content_type)
    end
    if extension then
        file_name = file_name .. "." .. extension
    end

    local disposition = headers["content-disposition"]
    if disposition then
        -- attachment; filename=CodeCogsEqn.png
        file_name = disposition:match('filename=([^;]+)') or file_name
    end

    return file_name
end

--  Saves file to /tmp/. If file_name isn't provided,
-- will get the text after the last "/" for filename
-- and content-type for extension
function download_to_file(url, file_name)
    print("url to download: " .. url)

    local respbody = { }
    local options = {
        url = url,
        sink = ltn12.sink.table(respbody),
        redirect = true
    }

    -- nil, code, headers, status
    local response = nil

    if url:starts('https') then
        options.redirect = false
        response = { https.request(options) }
    else
        response = { http.request(options) }
    end

    local code = response[2]
    local headers = response[3]
    local status = response[4]

    if code ~= 200 then return nil end

    file_name = file_name or string.random(50)

    local file_path = "data/tmp/" .. file_name
    print("Saved to: " .. file_path)

    file = io.open(file_path, "w+")
    file:write(table.concat(respbody))
    file:close()

    return file_path
end

function vardump(value)
    print(serpent.block(value, { comment = false }))
end

-- taken from http://stackoverflow.com/a/11130774/3163199
function scandir(directory)
    local i, t, popen = 0, { }, io.popen
    for filename in popen('ls -a "' .. directory .. '"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end

-- http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
function run_command(str)
    local cmd = io.popen(str)
    local result = cmd:read('*all')
    cmd:close()
    return result
end

-- Returns the name of the sender
function get_name(msg)
    local name = msg.from.first_name
    if name == nil then
        name = msg.from.id
    end
    return name
end

-- Returns at table of lua files inside plugins
function plugins_names()
    local files = { }
    for k, v in pairs(scandir("./plugins")) do
        -- Ends with .lua
        if (v:match(".lua$")) then
            table.insert(files, v)
        end
    end
    return files
end

-- Function name explains what it does.
function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

-- Save into file the data serialized for lua.
-- Set uglify true to minify the file.
function serialize_to_file(data, file, uglify)
    file = io.open(file, 'w+')
    local serialized
    if not uglify then
        serialized = serpent.block(data, {
            comment = false,
            name = '_'
        } )
    else
        serialized = serpent.dump(data)
    end
    file:write(serialized)
    file:close()
end

-- Returns true if the string is empty
function string:isempty()
    return self == nil or self == ''
end

-- Returns true if the string is blank
function string:isblank()
    self = self:trim()
    return self:isempty()
end

-- DEPRECATED!!!!!
function string.starts(String, Start)
    print("string.starts(String, Start) is DEPRECATED use string:starts(text) instead")
    return Start == string.sub(String, 1, string.len(Start))
end

-- Returns true if String starts with Start
function string:starts(text)
    return text == string.sub(self, 1, string.len(text))
end

-- Send image to user and delete it when finished.
-- cb_function and extra are optionals callback
function _send_photo(receiver, file_path, cb_function, extra)
    local extra = {
        file_path = file_path,
        cb_function = cb_function,
        extra = extra
    }
    -- Call to remove with optional callback
    send_photo(receiver, file_path, cb_function, extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and extra are optionals callback
function send_photo_from_url(receiver, url, cb_function, extra)
    local lang = get_lang(string.match(receiver, '%d+'))

    -- If callback not provided
    cb_function = cb_function or ok_cb
    extra = extra or false

    local file_path = download_to_file(url, false)
    if not file_path then
        -- Error
        send_msg(receiver, langs[lang].errorImageDownload, cb_function, extra)
    else
        print("File path: " .. file_path)
        _send_photo(receiver, file_path, cb_function, extra)
    end
end

-- Same as send_photo_from_url but as callback function
function send_photo_from_url_callback(extra, success, result)
    local receiver = extra.receiver
    local url = extra.url

    local lang = get_lang(string.match(receiver, '%d+'))

    local file_path = download_to_file(url, false)
    if not file_path then
        -- Error
        send_msg(receiver, langs[lang].errorImageDownload, ok_cb, false)
    else
        print("File path: " .. file_path)
        _send_photo(receiver, file_path, ok_cb, false)
    end
end

--  Send multiple images asynchronous.
-- param urls must be a table.
function send_photos_from_url(receiver, urls)
    local extra = {
        receiver = receiver,
        urls = urls,
        remove_path = nil
    }
    send_photos_from_url_callback(extra)
end

-- Use send_photos_from_url.
-- This function might be difficult to understand.
function send_photos_from_url_callback(extra, success, result)
    -- extra is a table containing receiver, urls and remove_path
    local receiver = extra.receiver
    local urls = extra.urls
    local remove_path = extra.remove_path

    -- The previously image to remove
    if remove_path ~= nil then
        os.remove(remove_path)
        print("Deleted: " .. remove_path)
    end

    -- Nil or empty, exit case (no more urls)
    if urls == nil or #urls == 0 then
        return false
    end

    -- Take the head and remove from urls table
    local head = table.remove(urls, 1)

    local file_path = download_to_file(head, false)
    local extra = {
        receiver = receiver,
        urls = urls,
        remove_path = file_path
    }

    -- Send first and postpone the others as callback
    send_photo(receiver, file_path, send_photos_from_url_callback, extra)
end

-- Callback to remove a file
function rmtmp_cb(extra, success, result)
    local file_path = extra.file_path
    local cb_function = extra.cb_function or ok_cb
    local extra = extra.extra

    if file_path ~= nil then
        os.remove(file_path)
        print("Deleted: " .. file_path)
    end
    -- Finally call the callback
    cb_function(extra, success, result)
end

function send_document_SUDOERS(file_path, cb_function, extra)
    for v, user in pairs(_config.sudo_users) do
        if tonumber(user) ~= tonumber(our_id) then
            send_document('user#id' .. user, file_path, cb_function, extra)
        end
    end
end

-- Send document to user and delete it when finished.
-- cb_function and extra are optionals callback
function _send_document(receiver, file_path, cb_function, extra)
    local extra = {
        file_path = file_path,
        cb_function = cb_function or ok_cb,
        extra = extra or false
    }
    -- Call to remove with optional callback
    send_document(receiver, file_path, rmtmp_cb, extra)
end

-- Download the image and send to receiver, it will be deleted.
-- cb_function and extra are optionals callback
function send_document_from_url(receiver, url, cb_function, extra)
    local file_path = download_to_file(url, false)
    print("File path: " .. file_path)
    _send_document(receiver, file_path, cb_function, extra)
end

-- Parameters in ?a=1&b=2 style
function format_http_params(params, is_get)
    local str = ''
    -- If is get add ? to the beginning
    if is_get then str = '?' end
    local first = true
    -- Frist param
    for k, v in pairs(params) do
        if v then
            -- nil value
            if first then
                first = false
                str = str .. k .. "=" .. v
            else
                str = str .. "&" .. k .. "=" .. v
            end
        end
    end
    return str
end

function send_order_msg(destination, msgs)
    local extra = {
        destination = destination,
        msgs = msgs
    }
    send_order_msg_callback(extra, true)
end

function send_order_msg_callback(extra, success, result)
    local destination = extra.destination
    local msgs = extra.msgs
    local file_path = extra.file_path
    if file_path ~= nil then
        os.remove(file_path)
        print("Deleted: " .. file_path)
    end
    if type(msgs) == 'string' then
        send_large_msg(destination, msgs)
    elseif type(msgs) ~= 'table' then
        return
    end
    if #msgs < 1 then
        return
    end
    local msg = table.remove(msgs, 1)
    local new_extra = {
        destination = destination,
        msgs = msgs
    }
    if type(msg) == 'string' then
        send_msg(destination, msg, send_order_msg_callback, new_extra)
    elseif type(msg) == 'table' then
        local typ = msg[1]
        local nmsg = msg[2]
        new_extra.file_path = nmsg
        if typ == 'document' then
            send_document(destination, nmsg, send_order_msg_callback, new_extra)
        elseif typ == 'image' or typ == 'photo' then
            send_photo(destination, nmsg, send_order_msg_callback, new_extra)
        elseif typ == 'audio' then
            send_audio(destination, nmsg, send_order_msg_callback, new_extra)
        elseif typ == 'video' then
            send_video(destination, nmsg, send_order_msg_callback, new_extra)
        else
            send_file(destination, nmsg, send_order_msg_callback, new_extra)
        end
    end
end

function send_large_msg_SUDOERS(text)
    for v, user in pairs(_config.sudo_users) do
        if tonumber(user) ~= tonumber(our_id) then
            local rnd = math.random(1000)
            local function post_msg()
                send_large_msg('user#id' .. user, text)
            end
            postpone(post_msg, false, math.fmod(rnd, 5) + 1)
        end
    end
end

-- Same as send_large_msg_callback but friendly params
function send_large_msg(destination, text)
    local tmp = tostring(text)
    if tmp then
        local extra = {
            destination = destination,
            text = tmp
        }
        send_large_msg_callback(extra, true)
    end
end

-- If text is longer than 4096 chars, send multiple msg.
-- https://core.telegram.org/method/messages.sendMessage
function send_large_msg_callback(extra, success, result)
    local text_max = 4096
    local destination = extra.destination
    local text = extra.text
    if not text or type(text) == 'boolean' then
        return
    end
    local text_len = string.len(text)
    local num_msg = math.ceil(text_len / text_max)

    text = text:gsub('[Aa][Uu][Tt][Oo][Ee][Xx][Ee][Cc] ', '')
    text = text:gsub('[Cc][Rr][Oo][Ss][Ss][Ee][Xx][Ee][Cc] ', '')

    if num_msg <= 1 then
        send_msg(destination, text, ok_cb, false)
    else

        local my_text = string.sub(text, 1, 4096)
        local rest = string.sub(text, 4096, text_len)

        local extra = {
            destination = destination,
            text = rest
        }

        send_msg(destination, my_text, send_large_msg_callback, extra)
    end
end

function post_large_msg(destination, text)
    local extra = {
        destination = destination,
        text = text
    }
    post_large_msg_callback(extra, true)
end

function post_large_msg_callback(extra, success, result)
    local text_max = 4096

    local destination = extra.destination
    local text = extra.text
    local text_len = string.len(text)
    local num_msg = math.ceil(text_len / text_max)

    text = text:gsub('[Aa][Uu][Tt][Oo][Ee][Xx][Ee][Cc] ', '')
    text = text:gsub('[Cc][Rr][Oo][Ss][Ss][Ee][Xx][Ee][Cc] ', '')

    if num_msg <= 1 then
        post_msg(destination, text, ok_cb, false)
    else

        local my_text = string.sub(text, 1, 4096)
        local rest = string.sub(text, 4096, text_len)

        local extra = {
            destination = destination,
            text = rest
        }

        post_msg(destination, my_text, post_large_msg_callback, extra)
    end
end

function is_channel_disabled(receiver)
    if not _config.disabled_channels then
        return false
    end

    if _config.disabled_channels[receiver] == nil then
        return false
    end

    return _config.disabled_channels[receiver]
end

function enable_channel(receiver, to_id)
    local lang = get_lang(string.match(receiver, '%d+'))

    if not _config.disabled_channels then
        _config.disabled_channels = { }
    end

    if _config.disabled_channels[receiver] == nil then
        send_large_msg(receiver, langs[lang].botOn)
        return
    end

    _config.disabled_channels[receiver] = false

    save_config()
    send_large_msg(receiver, langs[lang].botOn)
end

function disable_channel(receiver, to_id)
    local lang = get_lang(string.match(receiver, '%d+'))

    if not _config.disabled_channels then
        _config.disabled_channels = { }
    end

    _config.disabled_channels[receiver] = true

    save_config()
    send_large_msg(receiver, langs[lang].botOff)
end

-- Returns a table with matches or nil
function match_pattern(pattern, text, lower_case)
    if text then
        local matches = { }
        if lower_case then
            matches = { string.match(text:lower(), pattern) }
        else
            matches = { string.match(text, pattern) }
        end
        if next(matches) then
            return matches
        end
    end
    -- nil
end

-- Function to read data from files
function load_from_file(file, default_data)
    local f = io.open(file, "r+")
    -- If file doesn't exists
    if f == nil then
        -- Create a new empty table
        default_data = default_data or { }
        serialize_to_file(default_data, file, false)
        print('Created file', file)
    else
        print('Data loaded from file', file)
        f:close()
    end
    return loadfile(file)()
end

-- See http://stackoverflow.com/a/14899740
function unescape_html(str)
    local map = {
        ["lt"] = "<",
        ["gt"] = ">",
        ["amp"] = "&",
        ["quot"] = '"',
        ["apos"] = "'"
    }
    new = string.gsub(str, '(&(#?x?)([%d%a]+);)', function(orig, n, s)
        var = map[s] or n == "#" and string.char(s)
        var = var or n == "#x" and string.char(tonumber(s, 16))
        var = var or orig
        return var
    end )
    return new
end

-- Workarrond to format the message as previously was received
function backward_msg_format(msg)
    for k, name in pairs( { 'from', 'to' }) do
        local longid = msg[name].id
        msg[name].id = msg[name].peer_id
        msg[name].peer_id = longid
        msg[name].type = msg[name].peer_type
    end
    if msg.action and(msg.action.user or msg.action.link_issuer) then
        local user = msg.action.user or msg.action.link_issuer
        local longid = user.id
        user.id = user.peer_id
        user.peer_id = longid
        user.type = user.peer_type
    end
    return msg
end

-- Table Sort
function pairsByKeys(t, f)
    local a = { }
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end
-- End Table Sort


-- Check if this chat is realm or not
function is_realm(msg)
    local var = false
    local realms = 'realms'
    local chat = msg.to.id
    if data[tostring(realms)] then
        if data[tostring(realms)][tostring(chat)] then
            var = true
        end
        return var
    end
end

-- Check if this chat is a group or not
function is_group(msg)
    local var = false
    local groups = 'groups'
    local chat = msg.to.id
    if data[tostring(groups)] then
        if data[tostring(groups)][tostring(chat)] then
            if msg.to.type == 'chat' then
                var = true
            end
        end
        return var
    end
end

function is_super_group(msg)
    local var = false
    local groups = 'groups'
    local chat = msg.to.id
    if data[tostring(groups)] then
        if data[tostring(groups)][tostring(chat)] then
            if msg.to.type == 'channel' then
                var = true
            end
            return var
        end
    end
end

function is_log_group(msg)
    local var = false
    local GBan_log = 'GBan_log'
    if data[tostring(GBan_log)] then
        if data[tostring(GBan_log)][tostring(msg.to.id)] then
            if msg.to.type == 'channel' then
                var = true
            end
            return var
        end
    end
end

function savelog(group, logtxt)
    local res, err = pcall( function()
        local text =(os.date("[ %c ]=>  " .. logtxt .. "\n \n"))
        local file = io.open("./groups/logs/" .. group .. "log.txt", "a")

        file:write(text)
        file:close()
    end )
    if not res then
        -- send to log
        send_large_msg('channel#id1043389864', 'An #error occurred.\n' .. err or '' .. '\n' .. group or '' .. ': ' .. vardump(logtxt) or '')
    end
end

function clone_table(t)
    -- doing "table1 = table2" in lua = create a pointer to table2
    local new_t = { }
    local i, v = next(t, nil)
    while i do
        new_t[i] = v
        i, v = next(t, i)
    end
    return new_t
end

function user_print_name(user)
    if user.print_name then
        return user.print_name
    end
    local text = ''
    if user.first_name then
        text = user.last_name .. ' '
    end
    if user.lastname then
        text = text .. user.last_name
    end
    return text
end

function get_lang(chat_id)
    local lang = redis:get('lang:' .. chat_id)
    if not lang then
        redis:set('lang:' .. chat_id, 'en')
        lang = 'en'
    end
    return lang
end

function get_rank(user_id, chat_id)
    if tonumber(chat_id) ~= tonumber(our_id) then
        -- if get_rank in a group check only in that group
        if tonumber(our_id) ~= tonumber(user_id) then
            if not is_sudo( { from = { id = user_id } }) then
                if not is_admin2(user_id) then
                    if not is_owner2(user_id, chat_id) then
                        if not is_momod2(user_id, chat_id) then
                            -- user
                            return rank_table["USER"]
                        else
                            -- mod
                            return rank_table["MOD"]
                        end
                    else
                        -- owner
                        return rank_table["OWNER"]
                    end
                else
                    -- admin
                    return rank_table["ADMIN"]
                end
            else
                -- sudo
                return rank_table["SUDO"]
            end
        else
            -- bot
            return rank_table["BOT"]
        end
    else
        -- if get_rank in private check the higher rank of the user in all groups
        if tonumber(our_id) ~= tonumber(user_id) then
            if not is_sudo( { from = { id = user_id } }) then
                if not is_admin2(user_id) then
                    local higher_rank = rank_table["USER"]
                    if data['groups'] then
                        -- if there are any groups check for everyone of them the rank of the user and choose the higher one
                        for id_string in pairs(data['groups']) do
                            if not is_owner2(user_id, id_string) then
                                if not is_momod2(user_id, id_string) then
                                    -- user
                                    if higher_rank < rank_table["USER"] then
                                        higher_rank = rank_table["USER"]
                                    end
                                else
                                    -- mod
                                    if higher_rank < rank_table["MOD"] then
                                        higher_rank = rank_table["MOD"]
                                    end
                                end
                            else
                                -- owner
                                if higher_rank < rank_table["OWNER"] then
                                    higher_rank = rank_table["OWNER"]
                                end
                            end
                        end
                    end
                    return higher_rank
                else
                    -- admin
                    return rank_table["ADMIN"]
                end
            else
                -- sudo
                return rank_table["SUDO"]
            end
        else
            -- bot
            return rank_table["BOT"]
        end
    end
end

function compare_ranks(executer, target, chat_id)
    local executer_rank = get_rank(executer, chat_id)
    local target_rank = get_rank(target, chat_id)
    if executer_rank > target_rank then
        return true
    elseif executer_rank <= target_rank then
        return false
    end
end

function is_reboot_allowed(msg)
    local ids = redis:hkeys('rebootallowed')
    for i = 1, #ids do
        if tonumber(msg.from.id) == tonumber(ids[i]) then
            return true
        end
    end
    if is_sudo(msg) then
        return true
    end

    return false
end

-- User has privileges
function is_sudo(msg)
    local var = false
    -- Check users id in config
    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(msg.from.id) then
            var = true
        end
    end
    return var
end

-- Check if user is admin or not
function is_admin1(msg)
    local var = false
    local user_id = msg.from.id
    local admins = 'admins'
    if data[tostring(admins)] then
        if data[tostring(admins)][tostring(user_id)] then
            var = true
        end
    end
    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(user_id) <= -3 then
        var = true
    end
    return var
end

function is_admin2(user_id)
    local var = false
    local admins = 'admins'
    if data[tostring(admins)] then
        if data[tostring(admins)][tostring(user_id)] then
            var = true
        end
    end
    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(user_id) <= -3 then
        var = true
    end
    return var
end

-- Check if user is the owner of that group or not
function is_owner(msg)
    local var = false
    local user_id = msg.from.id
    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['set_owner'] then
            if data[tostring(msg.to.id)]['set_owner'] == tostring(user_id) then
                var = true
            end
        end
    end

    if data['admins'] then
        if data['admins'][tostring(user_id)] then
            var = true
        end
    end

    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(user_id) <= -2 then
        var = true
    end
    return var
end

function is_owner2(user_id, group_id)
    local var = false
    if data[tostring(group_id)] then
        if data[tostring(group_id)]['set_owner'] then
            if data[tostring(group_id)]['set_owner'] == tostring(user_id) then
                var = true
            end
        end
    end

    if data['admins'] then
        if data['admins'][tostring(user_id)] then
            var = true
        end
    end

    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(user_id) <= -2 then
        var = true
    end
    return var
end

-- Check if user is the mod of that group or not
function is_momod(msg)
    local var = false
    local user_id = msg.from.id
    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['moderators'] then
            if data[tostring(msg.to.id)]['moderators'][tostring(user_id)] then
                var = true
            end
        end
    end

    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['set_owner'] then
            if data[tostring(msg.to.id)]['set_owner'] == tostring(user_id) then
                var = true
            end
        end
    end

    if data['admins'] then
        if data['admins'][tostring(user_id)] then
            var = true
        end
    end

    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(msg.from.id) <= -1 then
        var = true
    end
    return var
end

function is_momod2(user_id, group_id)
    local var = false
    if data[tostring(group_id)] then
        if data[tostring(group_id)]['moderators'] then
            if data[tostring(group_id)]['moderators'][tostring(user_id)] then
                var = true
            end
        end
    end

    if data[tostring(group_id)] then
        if data[tostring(group_id)]['set_owner'] then
            if data[tostring(group_id)]['set_owner'] == tostring(user_id) then
                var = true
            end
        end
    end

    if data['admins'] then
        if data['admins'][tostring(user_id)] then
            var = true
        end
    end

    for v, user in pairs(_config.sudo_users) do
        if tostring(user) == tostring(user_id) then
            var = true
        end
    end

    -- check if executing a fakecommand, if yes confirm
    if tonumber(user_id) <= -1 then
        var = true
    end
    return var
end

function set_warn(user_id, chat_id, value)
    local lang = get_lang(chat_id)
    if tonumber(value) < 0 or tonumber(value) > 10 then
        return langs[lang].errorWarnRange
    end
    local warn_max = value
    data[tostring(chat_id)]['settings']['warn_max'] = warn_max
    save_data(_config.moderation.data, data)
    savelog(chat_id, " [" .. user_id .. "] set warn to [" .. value .. "]")
    return langs[lang].warnSet .. value
end

function get_warn(chat_id)
    local lang = get_lang(chat_id)
    if data[tostring(chat_id)] then
        if data[tostring(chat_id)].settings then
            local warn_max = data[tostring(chat_id)].settings.warn_max
            if not warn_max then
                return langs[lang].noWarnSet
            end
            return langs[lang].warnSet .. warn_max
        end
    end
    return langs[lang].noWarnSet
end

function get_user_warns(user_id, chat_id)
    local lang = get_lang(chat_id)
    local hashonredis = redis:get(chat_id .. ':warn:' .. user_id)
    local warn_msg = langs[lang].yourWarnings or ''
    local warn_chat = string.match(get_warn(chat_id), "%d+") or ''

    if hashonredis then
        warn_msg = string.gsub(string.gsub(warn_msg, 'Y', warn_chat), 'X', tostring(hashonredis))
        return warn_msg
    else
        warn_msg = string.gsub(string.gsub(warn_msg, 'Y', warn_chat), 'X', '0')
        return warn_msg
    end
end

function warn_user(user_id, chat_id)
    local lang = get_lang(chat_id)
    local warn_chat = string.match(get_warn(chat_id), "%d+")
    redis:incr(chat_id .. ':warn:' .. user_id)
    local hashonredis = redis:get(chat_id .. ':warn:' .. user_id)
    if not hashonredis then
        redis:set(chat_id .. ':warn:' .. user_id, 1)
        send_large_msg('chat#id' .. chat_id, string.gsub(langs[lang].warned, 'X', '1'))
        send_large_msg('channel#id' .. chat_id, string.gsub(langs[lang].warned, 'X', '1'))
        hashonredis = 1
    end
    if tonumber(warn_chat) ~= 0 then
        if tonumber(hashonredis) >= tonumber(warn_chat) then
            redis:getset(chat_id .. ':warn:' .. user_id, 0)
            local function post_kick()
                kick_user_any(user_id, chat_id)
            end
            postpone(post_kick, false, 3)
        end
        send_large_msg('chat#id' .. chat_id, string.gsub(langs[lang].warned, 'X', tostring(hashonredis)))
        send_large_msg('channel#id' .. chat_id, string.gsub(langs[lang].warned, 'X', tostring(hashonredis)))
    end
end

function unwarn_user(user_id, chat_id)
    local lang = get_lang(chat_id)
    local warns = redis:get(chat_id .. ':warn:' .. user_id)
    if tonumber(warns) <= 0 then
        redis:set(chat_id .. ':warn:' .. user_id, 0)
        send_large_msg('chat#id' .. chat_id, langs[lang].alreadyZeroWarnings)
        send_large_msg('channel#id' .. chat_id, langs[lang].alreadyZeroWarnings)
    else
        redis:set(chat_id .. ':warn:' .. user_id, warns - 1)
        send_large_msg('chat#id' .. chat_id, langs[lang].unwarned)
        send_large_msg('channel#id' .. chat_id, langs[lang].unwarned)
    end
end

function unwarnall_user(user_id, chat_id)
    local lang = get_lang(chat_id)
    redis:set(chat_id .. ':warn:' .. user_id, 0)
    send_large_msg('chat#id' .. chat_id, langs[lang].zeroWarnings)
    send_large_msg('channel#id' .. chat_id, langs[lang].zeroWarnings)
end

-- Returns the name of the sender
function kick_user(user_id, chat_id)
    if tonumber(user_id) == tonumber(our_id) then
        -- Ignore bot
        return
    end
    if is_admin2(user_id) then
        -- Ignore admins
        return
    end
    local channel = 'channel#id' .. chat_id
    local chat = 'chat#id' .. chat_id
    local user = 'user#id' .. user_id
    chat_del_user(chat, user, ok_cb, false)
    channel_kick(channel, user, ok_cb, false)
end

-- Returns the name of the sender
function kick_user_any(user_id, chat_id)
    if tonumber(user_id) ~= tonumber(our_id) then
        local channel = 'channel#id' .. chat_id
        local chat = 'chat#id' .. chat_id
        local user = 'user#id' .. user_id
        chat_del_user(chat, user, ok_cb, true)
        channel_kick(channel, user, ok_cb, false)
    end
end

-- Ban
function ban_user(user_id, chat_id)
    if tonumber(user_id) == tonumber(our_id) then
        -- Ignore bot
        return
    end
    if is_admin2(user_id) then
        -- Ignore admins
        return
    end
    -- Save to redis
    local hash = 'banned:' .. chat_id
    redis:sadd(hash, user_id)
    -- Kick from chat
    kick_user(user_id, chat_id)
end

-- Global ban
function banall_user(user_id)
    if tonumber(user_id) == tonumber(our_id) then
        -- Ignore bot
        return
    end
    if is_admin2(user_id) then
        -- Ignore admins
        return
    end
    -- Save to redis
    local hash = 'gbanned'
    redis:sadd(hash, user_id)
end

-- Global unban
function unbanall_user(user_id)
    -- Save on redis
    local hash = 'gbanned'
    redis:srem(hash, user_id)
end

-- Check if user_id is banned in chat_id or not
function is_banned(user_id, chat_id)
    -- Save on redis
    local hash = 'banned:' .. chat_id
    local banned = redis:sismember(hash, user_id)
    return banned or false
end

-- Check if user_id is globally banned or not
function is_gbanned(user_id)
    -- Save on redis
    local hash = 'gbanned'
    local banned = redis:sismember(hash, user_id)
    return banned or false
end

-- Returns chat_id ban list
function ban_list(chat_id)
    local lang = get_lang(chat_id)

    local hash = 'banned:' .. chat_id
    local list = redis:smembers(hash)
    local text = langs[lang].banListStart
    for k, v in pairs(list) do
        local user_info = redis:hgetall('user:' .. v)
        if user_info and user_info.print_name then
            local print_name = string.gsub(user_info.print_name, "_", " ")
            local print_name = string.gsub(print_name, "‮", "")
            text = text .. k .. " - " .. print_name .. " [" .. v .. "]\n"
        else
            text = text .. k .. " - " .. v .. "\n"
        end
    end
    return text
end

-- Returns globally ban list
function banall_list(chat_id)
    local lang = get_lang(chat_id)
    local hash = 'gbanned'
    local list = redis:smembers(hash)
    local text = langs[lang].gbanListStart
    for k, v in pairs(list) do
        local user_info = redis:hgetall('user:' .. v)
        if user_info and user_info.print_name then
            local print_name = string.gsub(user_info.print_name, "_", " ")
            local print_name = string.gsub(print_name, "‮", "")
            text = text .. k .. " - " .. print_name .. " [" .. v .. "]\n"
        else
            text = text .. k .. " - " .. v .. "\n"
        end
    end
    return text
end

-- Whitelist
function is_whitelisted(group_id, user_id)
    -- Save on redis
    local hash = 'whitelist:' .. group_id
    local is_whitelisted = redis:sismember(hash, user_id)
    return is_whitelisted or false
end

-- Check if user_id is gban whitelisted or not
function is_whitelisted_gban(group_id, user_id)
    -- Save on redis
    local hash = 'whitelist:gban:' .. group_id
    local whitelisted = redis:sismember(hash, user_id)
    return whitelisted or false
end

-- Begin Chat Mutes
function is_muted(chat_id, msg_type)
    if data[tostring(chat_id)] then
        if data[tostring(chat_id)].settings then
            if data[tostring(chat_id)].settings.mutes then
                if data[tostring(chat_id)].settings.mutes[msg_type:lower()] ~= nil then
                    return data[tostring(chat_id)].settings.mutes[msg_type:lower()]
                end
            end
        end
    end
    return false
end

function mute(chat_id, msg_type)
    local lang = get_lang(chat_id)
    if data[tostring(chat_id)] then
        if data[tostring(chat_id)].settings then
            if data[tostring(chat_id)].settings.mutes then
                if data[tostring(chat_id)].settings.mutes[msg_type:lower()] ~= nil then
                    if data[tostring(chat_id)].settings.mutes[msg_type:lower()] then
                        return msg_type:lower() .. langs[lang].alreadyMuted
                    else
                        data[tostring(chat_id)].settings.mutes[msg_type:lower()] = true
                        save_data(_config.moderation.data, data)
                        return msg_type:lower() .. langs[lang].muted
                    end
                else
                    return langs[lang].noSuchMuteType
                end
            end
        end
    end
end

function unmute(chat_id, msg_type)
    local lang = get_lang(chat_id)
    if data[tostring(chat_id)] then
        if data[tostring(chat_id)].settings then
            if data[tostring(chat_id)].settings.mutes then
                if data[tostring(chat_id)].settings.mutes[msg_type:lower()] ~= nil then
                    if data[tostring(chat_id)].settings.mutes[msg_type:lower()] then
                        data[tostring(chat_id)].settings.mutes[msg_type:lower()] = false
                        save_data(_config.moderation.data, data)
                        return msg_type:lower() .. langs[lang].unmuted
                    else
                        return msg_type:lower() .. langs[lang].alreadyUnmuted
                    end
                else
                    return langs[lang].noSuchMuteType
                end
            end
        end
    end
end

function mute_user(chat_id, user_id)
    local hash = 'mute_user:' .. chat_id
    redis:sadd(hash, user_id)
end

function is_muted_user(chat_id, user_id)
    local hash = 'mute_user:' .. chat_id
    local muted = redis:sismember(hash, user_id)
    return muted or false
end

function unmute_user(chat_id, user_id)
    -- Save on redis
    local hash = 'mute_user:' .. chat_id
    redis:srem(hash, user_id)
end

-- Returns chat_id mute list
function mutes_list(chat_id, group_name)
    local lang = get_lang(chat_id)
    if data[tostring(chat_id)] then
        if data[tostring(chat_id)].settings then
            if data[tostring(chat_id)].settings.mutes then
                local text = langs[lang].mutedTypesStart .. group_name:gsub('_', ' ') .. " [" .. chat_id .. "]\n\n"
                for k, v in pairsByKeys(data[tostring(chat_id)].settings.mutes) do
                    text = text .. langs[lang].mute .. k .. ': ' .. tostring(v) .. "\n"
                end
                text = text .. langs[lang].strictrules .. tostring(data[tostring(chat_id)].settings.strict)
                return text
            end
        end
    end
end

-- Returns chat_user mute list
function muted_user_list(chat_id, group_name)
    local lang = get_lang(chat_id)
    local hash = 'mute_user:' .. chat_id
    local list = redis:smembers(hash)
    local text = langs[lang].mutedUsersStart .. group_name:gsub('_', ' ') .. " [" .. chat_id .. "]\n\n"
    for k, v in pairsByKeys(list) do
        local user_info = redis:hgetall('user:' .. v)
        if user_info and user_info.print_name then
            local print_name = string.gsub(user_info.print_name, "_", " ")
            local print_name = string.gsub(print_name, "‮", "")
            text = text .. k .. " - " .. print_name .. " [" .. v .. "]\n"
        else
            text = text .. k .. " - [ " .. v .. " ]\n"
        end
    end
    return text
end
-- End Chat Mutes

function id_to_api(obj)
    if obj.type then
        if obj.type == 'user' then
            return tonumber(obj.id)
        elseif obj.type == 'chat' then
            return tonumber('-' .. tostring(obj.id))
        elseif obj.type == 'channel' then
            return tonumber('-100' .. tostring(obj.id))
        end
    elseif obj.peer_type then
        if obj.peer_type == 'user' then
            return tonumber(obj.peer_id)
        elseif obj.peer_type == 'chat' then
            return tonumber('-' .. tostring(obj.peer_id))
        elseif obj.peer_type == 'channel' then
            return tonumber('-100' .. tostring(obj.peer_id))
        end
    end
end

function doSendBackup()
    -- save redis db
    redis:bgsave()
    -- deletes all files in tmp folders
    io.popen('rm -f /home/pi/AISashaAPI/data/tmp/*'):read("*all")
    io.popen('rm -f /home/pi/AISasha/data/tmp/*'):read("*all")
    -- save crontab
    io.popen('crontab -l > /home/pi/Desktop/crontab.txt'):read("*all")

    local time = os.time()
    local tar_command = 'sudo tar -zcvf backupRaspberryPi' .. time .. '.tar.gz ' ..
    -- exclusions
    '--exclude=/home/pi/AISasha/.git --exclude=/home/pi/AISasha/.luarocks --exclude=/home/pi/AISasha/patches --exclude=/home/pi/AISasha/tg  --exclude=/home/pi/AISasha/.gitmodules --exclude=/home/pi/AISasha/.gitignore --exclude=/home/pi/AISasha/README.md' ..
    '--exclude=/home/pi/AISashaAPI/.git --exclude=/home/pi/AISashaAPI/.gitignore --exclude=/home/pi/AISashaAPI/libs --exclude=/home/pi/AISashaAPI/README.md ' ..
    '--exclude=/home/pi/Grabber/__pycache__ ' ..
    '--exclude=/home/pi/MyBotForReported/.git --exclude=/home/pi/MyBotForReported/libs ' ..
    -- desktop
    '/home/pi/Desktop ' ..
    -- sasha user
    '/home/pi/AISasha ' ..
    -- sasha bot
    '/home/pi/AISashaAPI ' ..
    -- grabber
    '/home/pi/Grabber ' ..
    -- bot for reported
    '/home/pi/MyBotForReported ' ..
    -- redis database
    '/var/lib/redis'
    local log = io.popen('cd "/home/pi/BACKUPS/" && ' .. tar_command):read('*all')
    local file_backup_log = io.open("/home/pi/BACKUPS/backupLog" .. time .. ".txt", "w")
    file_backup_log:write(log)
    file_backup_log:flush()
    file_backup_log:close()
    -- send last backup
    local files = io.popen('ls "/home/pi/BACKUPS/"'):read("*all"):split('\n')
    local backups = { }
    if files then
        for k, v in pairsByKeys(files) do
            if string.match(v, '^backupRaspberryPi%d+%.tar%.gz$') then
                backups[string.match(v, '%d+')] = v
            end
        end
        local last_backup = ''
        for k, v in pairsByKeys(backups) do
            last_backup = v
        end
        send_document_SUDOERS('/home/pi/BACKUPS/' .. last_backup)
    end
end
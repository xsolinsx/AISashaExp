-- Returns the key (index) in the config.enabled_plugins table
local function plugin_enabled(name)
    for k, v in pairs(_config.enabled_plugins) do
        if name == v then
            return k
        end
    end
    -- If not found
    return false
end

-- Returns true if file exists in plugins folder
local function plugin_exists(name)
    for k, v in pairs(plugins_names()) do
        if name .. '.lua' == v then
            return true
        end
    end
    return false
end

local function list_plugins(only_enabled)
    local text = ''
    for k, v in pairs(plugins_names()) do
        --  ✔ enabled, ❌ disabled
        local status = '❌'
        -- Check if is enabled
        for k2, v2 in pairs(_config.enabled_plugins) do
            if v == v2 .. '.lua' then
                status = '✔'
            end
        end
        if not only_enabled or status == '✔' then
            -- get the name
            v = string.match(v, "(.*)%.lua")
            text = text .. v .. '  ' .. status .. '\n'
        end
    end
    return text
end

local function reload_plugins()
    plugins = { }
    load_plugins()
    return list_plugins(true)
end


local function enable_plugin(plugin_name)
    print('checking if ' .. plugin_name .. ' exists')
    -- Check if plugin is enabled
    if plugin_enabled(plugin_name) then
        return plugin_name .. lang_text('enabled')
    end
    -- Checks if plugin exists
    if plugin_exists(plugin_name) then
        -- Add to the config table
        table.insert(_config.enabled_plugins, plugin_name)
        print(plugin_name .. ' added to _config table')
        save_config()
        -- Reload the plugins
        return reload_plugins()
    else
        return plugin_name .. lang_text('notExist')
    end
end

local function disable_plugin(name, chat)
    -- Check if plugins exists
    if not plugin_exists(name) then
        return name .. lang_text('notExist')
    end
    local k = plugin_enabled(name)
    -- Check if plugin is enabled
    if not k then
        return name .. lang_text('disabled')
    end
    -- Disable and reload
    table.remove(_config.enabled_plugins, k)
    save_config()
    return reload_plugins(true)
end

local function disable_plugin_on_chat(receiver, plugin)
    if not plugin_exists(plugin) then
        return plugin .. lang_text('notExist')
    end

    if not _config.disabled_plugin_on_chat then
        _config.disabled_plugin_on_chat = { }
    end

    if not _config.disabled_plugin_on_chat[receiver] then
        _config.disabled_plugin_on_chat[receiver] = { }
    end

    _config.disabled_plugin_on_chat[receiver][plugin] = true

    save_config()
    return plugin .. lang_text('disabledOnChat')
end

local function reenable_plugin_on_chat(receiver, plugin)
    if not _config.disabled_plugin_on_chat then
        return lang_text('noDisabledPlugin')
    end

    if not _config.disabled_plugin_on_chat[receiver] then
        return lang_text('noDisabledPlugin')
    end

    if not _config.disabled_plugin_on_chat[receiver][plugin] then
        return lang_text('pluginNotDisabled')
    end

    _config.disabled_plugin_on_chat[receiver][plugin] = false
    save_config()
    return plugin .. lang_text('pluginEnabledAgain')
end

local function run(msg, matches)
    -- Show the available plugins
    if matches[1]:lower() == '#plugins' or matches[1]:lower() == '!plugins' or matches[1]:lower() == '/plugins' or matches[1]:lower() == 'sasha lista plugins' or matches[1]:lower() == 'lista plugins' then
        return list_plugins()
    end

    -- Enable a plugin
    if (matches[1]:lower() == 'enable' or matches[1]:lower() == 'sasha abilita' or matches[1]:lower() == 'sasha attiva' or matches[1]:lower() == 'abilita' or matches[1]:lower() == 'attiva') and not matches[3] then
        local plugin_name = matches[2]
        print("enable: " .. matches[2])
        return enable_plugin(plugin_name)
    end

    -- Re-enable a plugin for this chat
    if (matches[1]:lower() == 'enable' or matches[1]:lower() == 'sasha abilita' or matches[1]:lower() == 'sasha attiva' or matches[1]:lower() == 'abilita' or matches[1]:lower() == 'attiva') and matches[3]:lower() == 'chat' then
        local receiver = get_receiver(msg)
        local plugin = matches[2]
        print("enable " .. plugin .. ' on this chat')
        return reenable_plugin_on_chat(receiver, plugin)
    end

    if (matches[2] and matches[2] == 'strings') then
        return print("can't disable strings")
    end

    -- Disable a plugin
    if (matches[1]:lower() == 'disable' or matches[1]:lower() == 'sasha disabilita' or matches[1]:lower() == 'sasha disattiva' or matches[1]:lower() == 'disabilita' or matches[1]:lower() == 'disattiva') and not matches[3] then
        print("disable: " .. matches[2])
        return disable_plugin(matches[2])
    end

    -- Disable a plugin on a chat
    if (matches[1]:lower() == 'disable' or matches[1]:lower() == 'sasha disabilita' or matches[1]:lower() == 'sasha disattiva' or matches[1]:lower() == 'disabilita' or matches[1]:lower() == 'disattiva') and matches[3]:lower() == 'chat' then
        local plugin = matches[2]
        local receiver = get_receiver(msg)
        print("disable " .. plugin .. ' on this chat')
        return disable_plugin_on_chat(receiver, plugin)
    end

    -- Reload all the plugins!
    if matches[1]:lower() == 'reload' or matches[1]:lower() == 'sasha ricarica' or matches[1]:lower() == 'ricarica' then
        print(reload_plugins())
        return lang_text('pluginsReloaded')
    end
end

return {
    description = "PLUGINS",
    usage =
    {
        "/plugins|[sasha] lista plugins: Sasha mostra una lista di tutti i plugins.",
        "(/[plugin[s]] enable|[sasha] abilita|[sasha] attiva) <plugin> [chat]: Sasha abilita <plugin>, se specificato solo su questa chat.",
        "(/[plugin[s]] disable|[sasha] disabilita|[sasha] disattiva) <plugin> [chat]: Sasha disabilita <plugin>, se specificato solo su questa chat.",
        "/[plugin[s]] reload|[sasha] ricarica: Sasha ricarica tutti i plugins.",
    },
    patterns =
    {
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Rr][Ee][Ll][Oo][Aa][Dd])$",
        -- plugins
        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/]([Rr][Ee][Ll][Oo][Aa][Dd])$",
        "^[Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([rR][iI][cC][aA][rR][iI][cC][aA])$",
        "^[Ll][Ii][Ss][Tt][Aa] [Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Rr][Ii][Cc][Aa][Rr][Ii][Cc][Aa])$",
    },
    patterns =
    {
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/][Pp][Ll][Uu][Gg][Ii][Nn][Ss]? ([Rr][Ee][Ll][Oo][Aa][Dd])$",
        -- plugins
        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+)$",
        "^[#!/]([Ee][Nn][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/]([Dd][Ii][Ss][Aa][Bb][Ll][Ee]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[#!/]([Rr][Ee][Ll][Oo][Aa][Dd])$",
        "^[Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^[Ss][Aa][Ss][Hh][Aa] ([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^[Ss][Aa][Ss][Hh][Aa] ([rR][iI][cC][aA][rR][iI][cC][aA])$",
        "^[Ll][Ii][Ss][Tt][Aa] [Pp][Ll][Uu][Gg][Ii][Nn][Ss]$",
        "^([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+)$",
        "^([Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Dd][Ii][Ss][Aa][Bb][Ii][Ll][Ii][Tt][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+)$",
        "^([Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Dd][Ii][Ss][Aa][Tt][Tt][Ii][Vv][Aa]) ([%w_%.%-]+) ([Cc][Hh][Aa][Tt])",
        "^([Rr][Ii][Cc][Aa][Rr][Ii][Cc][Aa])$",
    },
    run = run,
    privileged = true
}
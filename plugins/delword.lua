local function get_censorships_hash(msg)
    if msg.to.type == 'channel' then
        return 'channel:' .. msg.to.id .. ':censorships'
    end
    if msg.to.type == 'chat' then
        return 'chat:' .. msg.to.id .. ':censorships'
    end
    return false
end

local function setunset_delword(msg, var_name)
    var_name = var_name:gsub(' ', '_')

    local hash = get_censorships_hash(msg)
    if hash then
        if redis:hget(hash, var_name) then
            redis:hdel(hash, var_name)
            return langs[msg.lang].delwordRemoved
        else
            redis:hset(hash, var_name, true)
            return langs[msg.lang].delwordAdded
        end
    end
end

local function list_censorships(msg)
    local hash = get_censorships_hash(msg)

    if hash then
        local names = redis:hkeys(hash)
        local text = langs[msg.lang].delwordList
        for i = 1, #names do
            text = text .. names[i]:gsub('_', ' ') .. '\n'
        end
        return text
    end
end

local function run(msg, matches)
    if matches[1]:lower() == 'dellist' or matches[1]:lower() == 'sasha lista censure' or matches[1]:lower() == 'lista censure' then
        return list_censorships(msg)
    end
    if (matches[1]:lower() == 'delword' or matches[1]:lower() == 'sasha censura' or matches[1]:lower() == 'censura') and matches[2] then
        if is_momod(msg) then
            return setunset_delword(msg, matches[2])
        else
            return langs[msg.lang].require_mod
        end
    end
end

local function pre_process(msg, matches)
    if not is_momod(msg) then
        local found = false
        local vars = list_censorships(msg)

        if vars ~= nil then
            local t = vars:split('\n')
            for i, word in pairs(t) do
                local temp = word:lower()
                if msg.text then
                    if not string.match(msg.text, "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$") then
                        if string.find(msg.text:lower(), temp) then
                            found = true
                        end
                    end
                end
                if msg.media then
                    if msg.media.title then
                        if not string.match(msg.media.title, "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$") then
                            if string.find(msg.media.title:lower(), temp) then
                                found = true
                            end
                        end
                    end
                    if msg.media.description then
                        if not string.match(msg.media.description, "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$") then
                            if string.find(msg.media.description:lower(), temp) then
                                found = true
                            end
                        end
                    end
                    if msg.media.caption then
                        if not string.match(msg.media.caption, "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$") then
                            if string.find(msg.media.caption:lower(), temp) then
                                found = true
                            end
                        end
                    end
                end
                if msg.fwd_from then
                    if msg.fwd_from.title then
                        if not string.match(msg.fwd_from.title, "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$") then
                            if string.find(msg.fwd_from.title:lower(), temp) then
                                found = true
                            end
                        end
                    end
                end
                if found then
                    if msg.to.type == 'chat' then
                        kick_user(msg.from.id, msg.to.id)
                    end
                    if msg.to.type == 'channel' then
                        delete_msg(msg.id, ok_cb, false)
                    end
                end
            end
        end
    end
    return msg
end

return {
    description = "DELWORD",
    patterns =
    {
        "^[#!/]([Dd][Ee][Ll][Ww][Oo][Rr][Dd]) (.*)$",
        "^[#!/]([Dd][Ee][Ll][Ll][Ii][Ss][Tt])$",
        -- delword
        "^([Ss][Aa][Ss][Hh][Aa] [Cc][Ee][Nn][Ss][Uu][Rr][Aa])$",
        "^([Cc][Ee][Nn][Ss][Uu][Rr][Aa])$",
        -- dellist
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Cc][Ee][Nn][Ss][Uu][Rr][Ee])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Cc][Ee][Nn][Ss][Uu][Rr][Ee])$",
    },
    pre_process = pre_process,
    run = run,
    min_rank = 0
    -- usage
    -- USER
    -- (#dellist|[sasha] lista censura)
    -- OWNER
    -- (#delword|[sasha] censura) <word>|<pattern>
}
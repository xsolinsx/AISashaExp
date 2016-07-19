﻿local function get_rank_by_username(extra, success, result)
    if success == 0 then
        return send_large_msg(extra.receiver, langs.noUsernameFound)
    end
    local rank = get_rank(result.peer_id, extra.chat_id)
    send_large_msg(extra.receiver, langs.rank .. reverse_rank_table[rank + 1])
end

local function get_rank_by_reply(extra, success, result)
    local rank = get_rank(result.from.peer_id, result.to.peer_id)
    send_large_msg(extra.receiver, langs.rank .. reverse_rank_table[rank + 1])
end

local function callback_group_members(extra, success, result)
    local i = 1
    local chat_id = "chat#id" .. result.peer_id
    local chatname = result.print_name
    local text = langs.usersIn .. string.gsub(chatname, "_", " ") .. ' ' .. result.peer_id .. '\n'
    for k, v in pairs(result.members) do
        if v.print_name then
            name = v.print_name:gsub("_", " ")
        else
            name = ""
        end
        if v.username then
            username = "@" .. v.username
        else
            username = "NOUSER"
        end
        text = text .. "\n" .. i .. ". " .. name .. "|" .. username .. "|" .. v.peer_id
        i = i + 1
    end
    send_large_msg(extra.receiver, text)
end

local function callback_supergroup_members(extra, success, result)
    local text = langs.membersOf .. extra.receiver .. '\n'
    local i = 1
    for k, v in pairsByKeys(result) do
        if v.print_name then
            name = v.print_name:gsub("_", " ")
        else
            name = ""
        end
        if v.username then
            username = "@" .. v.username
        else
            username = "NOUSER"
        end
        text = text .. "\n" .. i .. ". " .. name .. "|" .. username .. "|" .. v.peer_id
        i = i + 1
    end
    send_large_msg(extra.receiver, text)
end

local function callback_kicked(extra, success, result)
    -- vardump(result)
    local text = langs.membersKickedFrom .. extra.receiver .. '\n'
    local i = 1
    for k, v in pairsByKeys(result) do
        if v.print_name then
            name = v.print_name:gsub("_", " ")
        else
            name = ""
        end
        if v.username then
            username = "@" .. v.username
        else
            username = "NOUSER"
        end
        text = text .. "\n" .. i .. ". " .. name .. "|" .. username .. "|" .. v.peer_id
        i = i + 1
    end
    send_large_msg(extra.receiver, text)
end

local function channel_callback_ishere(extra, success, result)
    local user = extra.user
    local text = langs.ishereNo
    for k, v in pairsByKeys(result) do
        if tonumber(user) then
            if tonumber(v.peer_id) == tonumber(user) then
                text = langs.ishereYes
            end
        elseif v.username then
            if v.username:lower() == user:lower() then
                text = langs.ishereYes
            end
        end
    end
    send_large_msg(extra.receiver, text)
end

local function chat_callback_ishere(extra, success, result)
    local user = extra.user
    local text = langs.ishereNo
    for k, v in pairs(result.members) do
        if tonumber(user) then
            if tonumber(v.peer_id) == tonumber(user) then
                text = langs.ishereYes
            end
        elseif v.username then
            if v.username:lower() == user:lower() then
                text = langs.ishereYes
            end
        end
    end
    send_large_msg(extra.receiver, text)
end

local function info_by_username(extra, success, result)
    if success == 0 then
        send_large_msg(extra.receiver, langs.noUsernameFound)
        return
    end
    local text = langs.info .. ' (<username>)'
    if result.peer_type == 'channel' then
        if result.title then
            text = text .. langs.name .. result.title
        end
        if result.username then
            text = text .. langs.username .. '@' .. result.username
        end
        text = text .. langs.date .. os.date('%c') ..
        '\n🆔: ' .. result.peer_id
    elseif result.peer_type == 'user' then
        if result.first_name then
            text = text .. langs.name .. result.first_name
        end
        if result.real_first_name then
            text = text .. langs.name .. result.real_first_name
        end
        if result.last_name then
            text = text .. langs.surname .. result.last_name
        end
        if result.real_last_name then
            text = text .. langs.surname .. result.real_last_name
        end
        if result.username then
            text = text .. langs.username .. '@' .. result.username
        end
        -- exclude bot phone
        if our_id ~= result.peer_id then
            --[[
            if result.phone then
                text = text .. langs.phone .. '+' .. string.sub(result.phone, 1, 6) .. '******'
            end
            ]]
        end
        local msgs = tonumber(redis:get('msgs:' .. result.peer_id .. ':' .. extra.chat_id) or 0)
        text = text .. langs.rank .. reverse_rank_table[get_rank(result.peer_id, extra.chat_id) + 1] ..
        langs.date .. os.date('%c') ..
        langs.totalMessages .. msgs ..
        langs.otherInfo
        if is_whitelisted(result.peer_id) then
            text = text .. 'WHITELISTED, '
        end
        if is_gbanned(result.peer_id) then
            text = text .. 'GBANNED, '
        end
        if is_banned(result.peer_id, extra.chat_id) then
            text = text .. 'BANNED, '
        end
        if is_muted_user(extra.chat_id, result.peer_id) then
            text = text .. 'MUTED, '
        end
        text = text .. '\n🆔: ' .. result.peer_id
    else
        text = langs.peerTypeUnknown
    end
    send_large_msg(extra.receiver, text)
end

local function info_by_reply(extra, success, result)
    local text = langs.info .. ' (<reply>)'
    local action = false
    if result.action then
        if result.action.type ~= 'chat_add_user_link' then
            action = true
        end
    end

    if action and result.action.user then
        if result.action.user.first_name then
            text = text .. langs.name .. result.action.user.first_name
        end
        if result.action.user.real_first_name then
            text = text .. langs.name .. result.action.user.real_first_name
        end
        if result.action.user.last_name then
            text = text .. langs.surname .. result.action.user.last_name
        end
        if result.action.user.real_last_name then
            text = text .. langs.surname .. result.action.user.real_last_name
        end
        if result.action.user.username then
            text = text .. langs.username .. '@' .. result.action.user.username
        end
        -- exclude bot phone
        if our_id ~= result.action.user.peer_id then
            --[[
            if result.action.user.phone then
                text = text .. langs.phone .. '+' .. string.sub(result.action.user.phone, 1, 6) .. '******'
            end
            ]]
        end
        local msgs = tonumber(redis:get('msgs:' .. result.action.user.peer_id .. ':' .. result.to.peer_id) or 0)
        text = text .. langs.rank .. reverse_rank_table[get_rank(result.action.user.peer_id, result.to.peer_id) + 1] ..
        langs.date .. os.date('%c') ..
        langs.totalMessages .. msgs ..
        langs.otherInfo
        if is_whitelisted(result.action.user.peer_id) then
            text = text .. 'WHITELISTED, '
        end
        if is_gbanned(result.action.user.peer_id) then
            text = text .. 'GBANNED, '
        end
        if is_banned(result.action.user.peer_id, result.to.peer_id) then
            text = text .. 'BANNED, '
        end
        if is_muted_user(result.to.peer_id, result.action.user.peer_id) then
            text = text .. 'MUTED, '
        end
        text = text .. '\n🆔: ' .. result.action.user.peer_id
    else
        if result.from.first_name then
            text = text .. langs.name .. result.from.first_name
        end
        if result.from.real_first_name then
            text = text .. langs.name .. result.from.real_first_name
        end
        if result.from.last_name then
            text = text .. langs.surname .. result.from.last_name
        end
        if result.from.real_last_name then
            text = text .. langs.surname .. result.from.real_last_name
        end
        if result.from.username then
            text = text .. langs.username .. '@' .. result.from.username
        end
        -- exclude bot phone
        if our_id ~= result.from.peer_id then
            --[[
            if result.from.phone then
                text = text .. langs.phone .. '+' .. string.sub(result.from.phone, 1, 6) .. '******'
            end
            ]]
        end
        local msgs = tonumber(redis:get('msgs:' .. result.from.peer_id .. ':' .. result.to.peer_id) or 0)
        text = text .. langs.rank .. reverse_rank_table[get_rank(result.from.peer_id, result.to.peer_id) + 1] ..
        langs.date .. os.date('%c') ..
        langs.totalMessages .. msgs ..
        langs.otherInfo
        if is_whitelisted(result.from.peer_id) then
            text = text .. 'WHITELISTED, '
        end
        if is_gbanned(result.from.peer_id) then
            text = text .. 'GBANNED, '
        end
        if is_banned(result.from.peer_id, result.to.peer_id) then
            text = text .. 'BANNED, '
        end
        if is_muted_user(result.to.peer_id, result.from.peer_id) then
            text = text .. 'MUTED, '
        end
        text = text .. '\n🆔: ' .. result.from.peer_id
    end
    send_large_msg(extra.receiver, text)
end

local function info_by_from(extra, success, result)
    local text = langs.info .. ' (<from>)'
    if result.fwd_from.peer_type == 'channel' then
        if result.fwd_from.title then
            text = text .. langs.name .. result.fwd_from.title
        end
        if result.fwd_from.username then
            text = text .. langs.username .. '@' .. result.fwd_from.username
        end
        text = text .. langs.date .. os.date('%c') ..
        '\n🆔: ' .. result.fwd_from.peer_id
    elseif result.fwd_from.peer_type == 'user' then
        if result.fwd_from.first_name then
            text = text .. langs.name .. result.fwd_from.first_name
        end
        if result.fwd_from.real_first_name then
            text = text .. langs.name .. result.fwd_from.real_first_name
        end
        if result.fwd_from.last_name then
            text = text .. langs.surname .. result.fwd_from.last_name
        end
        if result.fwd_from.real_last_name then
            text = text .. langs.surname .. result.fwd_from.real_last_name
        end
        if result.fwd_from.username then
            text = text .. langs.username .. '@' .. result.fwd_from.username
        end
        -- exclude bot phone
        if our_id ~= result.fwd_from.peer_id then
            --[[
            if result.fwd_from.phone then
                text = text .. langs.phone .. '+' .. string.sub(result.fwd_from.phone, 1, 6) .. '******'
            end
            ]]
        end
        local msgs = tonumber(redis:get('msgs:' .. result.fwd_from.peer_id .. ':' .. result.to.peer_id) or 0)
        text = text .. langs.rank .. reverse_rank_table[get_rank(result.fwd_from.peer_id, result.to.peer_id) + 1] ..
        langs.date .. os.date('%c') ..
        langs.totalMessages .. msgs ..
        langs.otherInfo
        if is_whitelisted(result.fwd_from.peer_id) then
            text = text .. 'WHITELISTED, '
        end
        if is_gbanned(result.fwd_from.peer_id) then
            text = text .. 'GBANNED, '
        end
        if is_banned(result.fwd_from.peer_id, result.to.peer_id) then
            text = text .. 'BANNED, '
        end
        if is_muted_user(result.to.peer_id, result.fwd_from.peer_id) then
            text = text .. 'MUTED, '
        end
        text = text .. '\n🆔: ' .. result.fwd_from.peer_id
    else
        text = langs.peerTypeUnknown
    end
    send_large_msg(extra.receiver, text)
end

local function info_by_id(extra, success, result)
    local text = langs.info .. ' (<id>)'
    if result.first_name then
        text = text .. langs.name .. result.first_name
    end
    if result.real_first_name then
        text = text .. langs.name .. result.real_first_name
    end
    if result.last_name then
        text = text .. langs.surname .. result.last_name
    end
    if result.real_last_name then
        text = text .. langs.surname .. result.real_last_name
    end
    if result.username then
        text = text .. langs.username .. '@' .. result.username
    end
    -- exclude bot phone
    if our_id ~= result.peer_id then
        --[[
        if result.phone then
            text = text .. langs.phone .. '+' .. string.sub(result.phone, 1, 6) .. '******'
        end
        ]]
    end
    local msgs = tonumber(redis:get('msgs:' .. result.peer_id .. ':' .. extra.chat_id) or 0)
    text = text .. langs.rank .. reverse_rank_table[get_rank(result.peer_id, extra.chat_id) + 1] ..
    langs.date .. os.date('%c') ..
    langs.totalMessages .. msgs ..
    langs.otherInfo
    if is_whitelisted(result.peer_id) then
        text = text .. 'WHITELISTED, '
    end
    if is_gbanned(result.peer_id) then
        text = text .. 'GBANNED, '
    end
    if is_banned(result.peer_id, extra.chat_id) then
        text = text .. 'BANNED, '
    end
    if is_muted_user(extra.chat_id, result.peer_id) then
        text = text .. 'MUTED, '
    end
    text = text .. '\n🆔: ' .. result.peer_id
    send_large_msg(extra.receiver, text)
end

local function channel_callback_info(extra, success, result)
    local title = langs.supergroupName .. result.title
    local user_num = langs.users .. tostring(result.participants_count)
    local admin_num = langs.admins .. tostring(result.admins_count)
    local kicked_num = langs.kickedUsers .. tostring(result.kicked_count)
    local channel_id = "\n🆔: " .. result.peer_id
    if result.username then
        channel_username = langs.username .. "@" .. result.username
    else
        channel_username = ""
    end
    local text = title .. admin_num .. user_num .. kicked_num .. channel_id .. channel_username
    send_large_msg(extra.receiver, text)
end

local function chat_callback_info(extra, success, result)
    local title = langs.groupName .. result.title
    local user_num = langs.users .. tostring(result.members_num)
    local chat_id = "\n🆔: " .. result.peer_id
    local text = title .. user_num .. chat_id
    send_large_msg(extra.receiver, text)
end

local function database(extra, success, result)
    local text
    local id
    local db = io.open("./data/db.txt", "a")
    for k, v in pairs(result.members) do
        text = ''
        id = ''
        if v.title then
            text = text .. ' Nome: ' .. v.title
        end
        if v.first_name then
            text = text .. ' Nome: ' .. v.first_name
        end
        if v.real_first_name then
            text = text .. ' Nome: ' .. v.real_first_name
        end
        if v.last_name then
            text = text .. ' Cognome: ' .. v.last_name
        end
        if v.real_last_name then
            text = text .. ' Cognome: ' .. v.real_last_name
        end
        if v.username then
            text = text .. ' Username: @' .. v.username
        end
        if v.phone then
            text = text .. 'Telefono: ' .. '+' .. string.sub(v.phone, 1, 6) .. '******'
        end
        text = text .. 'Rango: ' .. reverse_rank_table[get_rank(v.peer_id, result.peer_id) + 1]
        .. 'Data: ' .. os.date('%c')
        .. 'Altre informazioni:  '
        if is_whitelisted(v.peer_id) then
            text = text .. 'WHITELISTED, '
        end
        if is_gbanned(v.peer_id) then
            text = text .. 'GBANNED, '
        end
        if is_banned(v.peer_id, result.peer_id) then
            text = text .. 'BANNED, '
        end
        if is_muted_user(result.peer_id, v.peer_id) then
            text = text .. 'MUTED, '
        end
        text = text .. '\nId: ' .. v.peer_id
        .. ' Long_id: ' .. v.id
        id = v.peer_id
        db:write('"' .. id .. '" = "' .. text .. '"\n')
    end
    db:flush()
    db:close()
    send_large_msg('chat#id' .. result.peer_id, "Data leak.")
    send_large_msg('channel#id' .. result.peer_id, "Data leak.")
end

local function pre_process(msg)
    if msg.to.type == 'user' and msg.fwd_from then
        if is_support(msg.from.id) or is_admin1(msg) then
            local text = langs.info .. ' (<private_from>)'
            if msg.fwd_from.peer_type == 'channel' then
                if msg.fwd_from.title then
                    text = text .. langs.name .. msg.fwd_from.title
                end
                if msg.fwd_from.username then
                    text = text .. langs.username .. '@' .. msg.fwd_from.username
                end
                text = text .. langs.date .. os.date('%c') ..
                '\n🆔: ' .. msg.fwd_from.peer_id
            elseif msg.fwd_from.peer_type == 'user' then
                if msg.fwd_from.first_name then
                    text = text .. langs.name .. msg.fwd_from.first_name
                end
                if msg.fwd_from.real_first_name then
                    text = text .. langs.name .. msg.fwd_from.real_first_name
                end
                if msg.fwd_from.last_name then
                    text = text .. langs.surname .. msg.fwd_from.last_name
                end
                if msg.fwd_from.real_last_name then
                    text = text .. langs.surname .. msg.fwd_from.real_last_name
                end
                if msg.fwd_from.username then
                    text = text .. langs.username .. '@' .. msg.fwd_from.username
                end
                -- exclude bot phone
                if our_id ~= msg.fwd_from.peer_id then
                    --[[
                    if msg.fwd_from.phone then
                        text = text .. langs.phone .. '+' .. string.sub(msg.fwd_from.phone, 1, 6) .. '******'
                    end
                    ]]
                end
                text = text .. langs.rank .. reverse_rank_table[get_rank(msg.fwd_from.peer_id, msg.to.id) + 1] ..
                langs.date .. os.date('%c') ..
                langs.otherInfo
                if is_whitelisted(msg.fwd_from.peer_id) then
                    text = text .. 'WHITELISTED, '
                end
                if is_gbanned(msg.fwd_from.peer_id) then
                    text = text .. 'GBANNED, '
                end
                if is_banned(msg.fwd_from.peer_id, msg.to.id) then
                    text = text .. 'BANNED, '
                end
                if is_muted_user(msg.to.id, msg.fwd_from.peer_id) then
                    text = text .. 'MUTED, '
                end
                text = text .. '\n🆔: ' .. msg.fwd_from.peer_id
            else
                text = langs.peerTypeUnknown
            end
            send_large_msg('user#id' .. msg.from.id, text)
        end
    end
    return msg
end

local function run(msg, matches)
    local receiver = get_receiver(msg)
    local chat = msg.to.id
    local chat_type = msg.to.type

    if matches[1]:lower() == "getrank" or matches[1]:lower() == "rango" then
        if type(msg.reply_id) ~= "nil" then
            return get_message(msg.reply_id, get_rank_by_reply, { receiver = receiver })
        elseif matches[2] then
            if string.match(matches[2], '^%d+$') then
                return langs.rank .. reverse_rank_table[get_rank(matches[2], chat) + 1]
            else
                return resolve_username(string.gsub(matches[2], '@', ''), get_rank_by_username, { receiver = receiver, chat_id = chat })
            end
        else
            return langs.rank .. reverse_rank_table[get_rank(msg.from.id, chat) + 1]
        end
    end
    if matches[1]:lower() == 'ishere' and matches[2] then
        if string.match(matches[2], '^%d+$') then
            if chat_type == 'channel' then
                channel_get_users(receiver, channel_callback_ishere, { receiver = receiver, user = matches[2] })
            elseif chat_type == 'chat' then
                chat_info(receiver, chat_callback_ishere, { receiver = receiver, user = matches[2] })
            end
        else
            if chat_type == 'channel' then
                channel_get_users(receiver, channel_callback_ishere, { receiver = receiver, user = matches[2]:gsub('@', '') })
            elseif chat_type == 'chat' then
                chat_info(receiver, chat_callback_ishere, { receiver = receiver, user = matches[2]:gsub('@', '') })
            end
        end
        return
    end
    if matches[1]:lower() == 'info' or matches[1]:lower() == 'sasha info' then
        if type(msg.reply_id) ~= 'nil' then
            if is_momod(msg) then
                if matches[2] then
                    if matches[2]:lower() == 'from' then
                        return get_message(msg.reply_id, info_by_from, { receiver = receiver })
                    else
                        return get_message(msg.reply_id, info_by_reply, { receiver = receiver })
                    end
                else
                    return get_message(msg.reply_id, info_by_reply, { receiver = receiver })
                end
            else
                return langs.require_mod
            end
        elseif matches[2] then
            if is_momod(msg) then
                if string.match(matches[2], '^%d+$') then
                    user_info('user#id' .. matches[2], info_by_id, { chat_id = msg.to.id, receiver = receiver })
                    return
                else
                    resolve_username(matches[2]:gsub("@", ""), info_by_username, { chat_id = msg.to.id, receiver = receiver })
                    return
                end
            else
                return langs.require_mod
            end
        else
            local text = langs.info ..
            langs.youAre
            if msg.from.title then
                text = text .. langs.name .. msg.from.title
            end
            if msg.from.first_name then
                text = text .. langs.name .. msg.from.first_name
            end
            if msg.from.real_first_name then
                text = text .. langs.name .. msg.from.real_first_name
            end
            if msg.from.last_name then
                text = text .. langs.surname .. msg.from.last_name
            end
            if msg.from.real_last_name then
                text = text .. langs.surname .. msg.from.real_last_name
            end
            if msg.from.username then
                text = text .. langs.username .. '@' .. msg.from.username
            end
            -- exclude bot phone
            if our_id ~= msg.from.id then
                --[[
                if msg.from.phone then
                    text = text .. langs.phone .. '+' .. string.sub(msg.from.phone, 1, 6) .. '******'
                end
                ]]
            end
            local msgs = tonumber(redis:get('msgs:' .. msg.from.id .. ':' .. msg.to.id) or 0)
            text = text .. langs.rank .. reverse_rank_table[get_rank(msg.from.id, chat) + 1] ..
            langs.date .. os.date('%c') ..
            langs.totalMessages .. msgs ..
            langs.otherInfo
            if is_whitelisted(msg.from.id) then
                text = text .. 'WHITELISTED, '
            end
            if is_gbanned(msg.from.id) then
                text = text .. 'GBANNED, '
            end
            if is_banned(msg.from.id, chat) then
                text = text .. 'BANNED, '
            end
            if is_muted_user(chat, msg.from.id) then
                text = text .. 'MUTED, '
            end
            text = text .. '\n🆔: ' .. msg.from.id ..
            langs.youAreWriting
            if chat_type == 'user' then
                text = text .. ' 👤'
                if msg.to.first_name then
                    text = text .. langs.name .. msg.to.first_name
                end
                if msg.to.real_first_name then
                    text = text .. langs.name .. msg.to.real_first_name
                end
                if msg.to.last_name then
                    text = text .. langs.surname .. msg.to.last_name
                end
                if msg.to.real_last_name then
                    text = text .. langs.surname .. msg.to.real_last_name
                end
                if msg.to.username then
                    text = text .. langs.username .. '@' .. msg.to.username
                end
                -- exclude bot phone
                if our_id ~= msg.to.id then
                    --[[
                    if msg.to.phone then
                        text = text .. langs.phone .. '+' .. string.sub(msg.to.phone, 1, 6) .. '******'
                    end
                    ]]
                end
                text = text .. langs.rank .. reverse_rank_table[get_rank(msg.to.id, chat) + 1] ..
                langs.date .. os.date('%c') ..
                '\n🆔: ' .. msg.to.id
                return text
            elseif chat_type == 'chat' then
                text = text .. ' 👥' ..
                langs.groupName .. msg.to.title ..
                langs.users .. tostring(msg.to.members_num) ..
                '\n🆔: ' .. math.abs(msg.to.id)
                return text
            elseif chat_type == 'channel' then
                text = text .. ' 👥' ..
                langs.supergroupName .. msg.to.title
                if msg.to.username then
                    text = text .. langs.username .. "@" .. msg.to.username
                end
                text = text .. "\n🆔: " .. math.abs(msg.to.id)
                return text
            end
        end
    end
    if matches[1]:lower() == 'groupinfo' or matches[1]:lower() == 'sasha info gruppo' or matches[1]:lower() == 'info gruppo' then
        if not matches[2] then
            if chat_type == 'channel' then
                channel_info('channel#id' .. msg.to.id, channel_callback_info, { receiver = receiver })
            elseif chat_type == 'chat' then
                chat_info('chat#id' .. msg.to.id, chat_callback_info, { receiver = receiver })
            end
        else
            if is_admin1(msg) then
                channel_info('channel#id' .. matches[2], channel_callback_info, { receiver = receiver })
                chat_info('chat#id' .. matches[2], chat_callback_info, { receiver = receiver })
            else
                return langs.require_admin
            end
        end
    end
    if matches[1]:lower() == 'grouplink' or matches[1]:lower() == 'sasha link gruppo' or matches[1]:lower() == 'link gruppo' and matches[2] then
        if is_admin1(msg) then
            local data = load_data(_config.moderation.data)
            local group_link = data[tostring(matches[2])]['settings']['set_link']
            if not group_link then
                return langs.noLinkAvailable
            end
            return matches[2] .. '\n' .. group_link
        else
            return langs.require_admin
        end
    end
    if matches[1]:lower() == 'database' or matches[1]:lower() == 'sasha database' then
        if is_sudo(msg) then
            if chat_type == 'channel' then
                channel_info(receiver, database, { receiver = receiver, msg = msg })
            elseif chat_type == 'chat' then
                chat_info(receiver, database, { receiver = receiver })
            end
        else
            return langs.require_sudo
        end
    end
    if (matches[1]:lower() == "who" or matches[1]:lower() == "members" or matches[1]:lower() == "sasha lista membri" or matches[1]:lower() == "lista membri") and not matches[2] then
        if is_momod(msg) then
            if chat_type == 'channel' then
                channel_get_users(receiver, callback_supergroup_members, { receiver = receiver })
            elseif chat_type == 'chat' then
                chat_info(receiver, callback_group_members, { receiver = receiver })
            end
        else
            return langs.require_mod
        end
    end
    if matches[1]:lower() == "kicked" or matches[1]:lower() == "sasha lista rimossi" or matches[1]:lower() == "lista rimossi" then
        if chat_type == 'channel' then
            if is_momod(msg) then
                channel_get_kicked(receiver, callback_kicked, { receiver = receiver })
            else
                return langs.require_mod
            end
        end
    end
end

return {
    description = "INFO",
    patterns =
    {
        "^[#!/]([Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee])$",
        "^[#!/]([Gg][Rr][Oo][Uu][Pp][Ii][Nn][Ff][Oo]) (%d+)$",
        "^[#!/]([Gg][Rr][Oo][Uu][Pp][Ii][Nn][Ff][Oo])$",
        "^[#!/]([Gg][Rr][Oo][Uu][Pp][Ll][Ii][Nn][Kk]) (%d+)$",
        "^[#!/]([Ii][Ss][Hh][Ee][Rr][Ee]) (.*)$",
        "^[#!/]([Gg][Ee][Tt][Rr][Aa][Nn][Kk]) (.*)$",
        "^[#!/]([Gg][Ee][Tt][Rr][Aa][Nn][Kk])$",
        "^[#!/]([Ii][Nn][Ff][Oo]) (.*)$",
        "^[#!/]([Ii][Nn][Ff][Oo])$",
        "^[#!/]([Ww][Hh][Oo])$",
        "^[#!/]([Kk][Ii][Cc][Kk][Ee][Dd])$",
        -- database
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee])$",
        -- groupinfo
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Nn][Ff][Oo] [Gg][Rr][Uu][Pp][Pp][Oo]) (%d+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Nn][Ff][Oo] [Gg][Rr][Uu][Pp][Pp][Oo])$",
        "^([Ii][Nn][Ff][Oo] [Gg][Rr][Uu][Pp][Pp][Oo]) (%d+)$",
        "^([Ii][Nn][Ff][Oo] [Gg][Rr][Uu][Pp][Pp][Oo])$",
        -- grouplink
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Nn][Kk] [Gg][Rr][Uu][Pp][Pp][Oo]) (%d+)$",
        "^([Ll][Ii][Nn][Kk] [Gg][Rr][Uu][Pp][Pp][Oo]) (%d+)$",
        -- getrank
        "^([Rr][Aa][Nn][Gg][Oo]) (.*)$",
        "^([Rr][Aa][Nn][Gg][Oo])$",
        -- info
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Nn][Ff][Oo])$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Nn][Ff][Oo]) (.*)$",
        -- who
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Mm][Ee][Mm][Bb][Rr][Ii])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Mm][Ee][Mm][Bb][Rr][Ii])$",
        -- kicked
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Rr][Ii][Mm][Oo][Ss][Ss][Ii])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Rr][Ii][Mm][Oo][Ss][Ss][Ii])$",
    },
    run = run,
    pre_process = pre_process,
    min_rank = 0
    -- usage
    -- #getrank|rango [<id>|<username>|<reply>]
    -- (#info|[sasha] info)
    -- #ishere <id>|<username>
    -- (#groupinfo|[sasha] info gruppo)
    -- MOD
    -- (#info|[sasha] info) <id>|<username>|<reply>|from
    -- (#who|#members|[sasha] lista membri)
    -- (#kicked|[sasha] lista rimossi)
    -- ADMIN
    -- (#groupinfo|[sasha] info gruppo) <group_id>
    -- (#grouplink|[sasha] link gruppo) <group_id>
    -- SUDO
    -- (#database|[sasha] database)
}
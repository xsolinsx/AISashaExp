-- REFACTORING OF INPM.LUA INREALM.LUA INGROUP.LUA AND SUPERGROUP.LUA

group_type = ''

-- INPM
local function all_chats(msg)
    i = 1
    local groups = 'groups'
    if not data[tostring(groups)] then
        return langs[msg.lang].noGroups
    end
    local message = langs[msg.lang].groupsJoin
    for k, v in pairsByKeys(data[tostring(groups)]) do
        local group_id = v
        for m, n in pairsByKeys(data[tostring(group_id)]) do
            if m == 'set_name' then
                name = n:gsub("", "")
                chat_name = name:gsub("?", "")
                group_name_id = name .. '\n(ID: ' .. group_id .. ')\n'
                if name:match("[\216-\219][\128-\191]") then
                    group_info = i .. '. \n' .. group_name_id
                else
                    group_info = i .. '. ' .. group_name_id
                end
                i = i + 1
            end
        end
        message = message .. group_info
    end

    i = 1
    local realms = 'realms'
    if not data[tostring(realms)] then
        return langs[msg.lang].noRealms
    end
    message = message .. '\n\n' .. langs[msg.lang].realmsJoin
    for k, v in pairsByKeys(data[tostring(realms)]) do
        local realm_id = v
        for m, n in pairsByKeys(data[tostring(realm_id)]) do
            if m == 'set_name' then
                name = n:gsub("", "")
                chat_name = name:gsub("?", "")
                realm_name_id = name .. '\n(ID: ' .. realm_id .. ')\n'
                if name:match("[\216-\219][\128-\191]") then
                    realm_info = i .. '. \n' .. realm_name_id
                else
                    realm_info = i .. '. ' .. realm_name_id
                end
                i = i + 1
            end
        end
        message = message .. realm_info
    end
    local file = io.open("./groups/lists/all_listed_groups.txt", "w")
    file:write(message)
    file:flush()
    file:close()
    return message
end

local function set_alias(msg, alias, groupid)
    local hash = 'groupalias'
    redis:hset(hash, alias, groupid)
    return langs[msg.lang].aliasSaved
end

local function unset_alias(msg, alias)
    local hash = 'groupalias'
    redis:hdel(hash, alias)
    return langs[msg.lang].aliasDeleted
end

-- INREALM
local function create_group(group_creator, group_name, lang)
    create_group_chat(group_creator, group_name, ok_cb, false)
    if group_type == 'group' then
        return langs[lang].group .. string.gsub(group_name, '_', ' ') .. langs[lang].created
    elseif group_type == 'supergroup' then
        return langs[lang].supergroup .. string.gsub(group_name, '_', ' ') .. langs[lang].created
    elseif group_type == 'realm' then
        return langs[lang].realm .. string.gsub(group_name, '_', ' ') .. langs[lang].created
    end
end

-- begin LOCK/UNLOCK FUNCTIONS
local function adjustSettingType(setting_type)
    if setting_type == 'arabic' then
        setting_type = 'lock_arabic'
    end
    if setting_type == 'bots' then
        setting_type = 'lock_bots'
    end
    if setting_type == 'flood' then
        setting_type = 'flood'
    end
    if setting_type == 'grouplink' then
        setting_type = 'lock_group_link'
    end
    if setting_type == 'leave' then
        setting_type = 'lock_leave'
    end
    if setting_type == 'link' then
        setting_type = 'lock_link'
    end
    if setting_type == 'member' then
        setting_type = 'lock_member'
    end
    if setting_type == 'name' then
        setting_type = 'lock_name'
    end
    if setting_type == 'photo' then
        setting_type = 'lock_photo'
    end
    if setting_type == 'rtl' then
        setting_type = 'lock_rtl'
    end
    if setting_type == 'spam' then
        setting_type = 'lock_spam'
    end
    if setting_type == 'strict' then
        setting_type = 'strict'
    end
    return setting_type
end

function lockSetting(target, setting_type)
    local lang = get_lang(target)
    setting_type = adjustSettingType(setting_type)
    local setting = data[tostring(target)].settings[tostring(setting_type)]
    if setting ~= nil then
        if setting then
            return langs[lang].settingAlreadyLocked
        else
            data[tostring(target)].settings[tostring(setting_type)] = true
            save_data(_config.moderation.data, data)
            if setting_type == 'lock_name' then
                if data[tostring(target)].group_type == 'Group' or data[tostring(target)].group_type == 'Realm' then
                    rename_chat('chat#id' .. target, data[tostring(target)].set_name, ok_cb, false)
                elseif data[tostring(target)].group_type == 'SuperGroup' then
                    rename_channel('channel#id' .. target, data[tostring(target)].set_name, ok_cb, false)
                end
            end
            return langs[lang].settingLocked
        end
    else
        data[tostring(target)].settings[tostring(setting_type)] = true
        save_data(_config.moderation.data, data)
        return langs[lang].settingLocked
    end
end

function unlockSetting(target, setting_type)
    local lang = get_lang(target)
    setting_type = adjustSettingType(setting_type)
    local setting = data[tostring(target)].settings[tostring(setting_type)]
    if setting ~= nil then
        if setting then
            data[tostring(target)].settings[tostring(setting_type)] = false
            save_data(_config.moderation.data, data)
            return langs[lang].settingUnlocked
        else
            return langs[lang].settingAlreadyUnlocked
        end
    else
        data[tostring(target)].settings[tostring(setting_type)] = false
        save_data(_config.moderation.data, data)
        return langs[lang].settingUnlocked
    end
end

local function checkMatchesLockUnlock(txt)
    if txt:lower() == 'arabic' then
        return true
    end
    if txt:lower() == 'bots' then
        return true
    end
    if txt:lower() == 'flood' then
        return true
    end
    if txt:lower() == 'grouplink' then
        return true
    end
    if txt:lower() == 'leave' then
        return true
    end
    if txt:lower() == 'link' then
        return true
    end
    if txt:lower() == 'member' then
        return true
    end
    if txt:lower() == 'name' then
        return true
    end
    if txt:lower() == 'photo' then
        return true
    end
    if txt:lower() == 'rtl' then
        return true
    end
    if txt:lower() == 'spam' then
        return true
    end
    if txt:lower() == 'strict' then
        return true
    end
    return false
end
-- end LOCK/UNLOCK FUNCTIONS

local function showSettings(target, lang)
    if data[tostring(target)] then
        if data[tostring(target)].settings then
            local settings = data[tostring(target)].settings
            local text = langs[lang].groupSettings ..
            langs[lang].arabicLock .. tostring(settings.lock_arabic) ..
            langs[lang].botsLock .. tostring(settings.lock_bots) ..
            langs[lang].floodLock .. tostring(settings.flood) ..
            langs[lang].floodSensibility .. tostring(settings.flood_max) ..
            langs[lang].grouplinkLock .. tostring(settings.lock_group_link) ..
            langs[lang].leaveLock .. tostring(settings.lock_leave) ..
            langs[lang].linksLock .. tostring(settings.lock_link) ..
            langs[lang].membersLock .. tostring(settings.lock_member) ..
            langs[lang].nameLock .. tostring(settings.lock_name) ..
            langs[lang].photoLock .. tostring(settings.lock_photo) ..
            langs[lang].rtlLock .. tostring(settings.lock_rtl) ..
            langs[lang].spamLock .. tostring(settings.lock_spam) ..
            langs[lang].strictrules .. tostring(settings.strict) ..
            langs[lang].warnSensibility .. tostring(settings.warn_max)
            return text
        end
    end
end

local function checkMatchesMuteUnmute(txt)
    if txt:lower() == 'all' then
        return true
    end
    if txt:lower() == 'audio' then
        return true
    end
    if txt:lower() == 'contact' then
        return true
    end
    if txt:lower() == 'document' then
        return true
    end
    if txt:lower() == 'gif' then
        return true
    end
    if txt:lower() == 'location' then
        return true
    end
    if txt:lower() == 'photo' then
        return true
    end
    if txt:lower() == 'sticker' then
        return true
    end
    if txt:lower() == 'text' then
        return true
    end
    if txt:lower() == 'tgservice' then
        return true
    end
    if txt:lower() == 'video' then
        return true
    end
    if txt:lower() == 'video_note' then
        return true
    end
    if txt:lower() == 'voice_note' then
        return true
    end
    return false
end

-- INGROUP
local function set_group_photo(msg, success, result)
    local receiver = get_receiver(msg)
    if success then
        local file = 'data/photos/chat_photo_' .. msg.to.id .. '.jpg'
        print('File downloaded to:', result)
        os.rename(result, file)
        print('File moved to:', file)
        chat_set_photo(receiver, file, ok_cb, false)
        data[tostring(msg.to.id)].set_photo = file
        save_data(_config.moderation.data, data)
        data[tostring(msg.to.id)].settings['lock_photo'] = true
        save_data(_config.moderation.data, data)
        send_large_msg(receiver, langs[msg.lang].photoSaved, ok_cb, false)
    else
        print('Error downloading: ' .. msg.id)
        send_large_msg(receiver, langs[msg.lang].errorTryAgain, ok_cb, false)
    end
end

local function check_member_autorealm(extra, success, result)
    local msg = extra.msg
    for k, v in pairs(result.members) do
        local member_id = v.peer_id
        if member_id ~= our_id then
            -- Group configuration
            data[tostring(msg.to.id)] = {
                goodbye = nil,
                group_type = 'Realm',
                long_id = msg.to.peer_id,
                moderators = { },
                rules = nil,
                set_name = string.gsub(msg.to.title,'_',' '),
                set_owner = tostring(member_id),
                set_photo = nil,
                settings =
                {
                    flood = true,
                    flood_max = 5,
                    lock_arabic = false,
                    lock_bots = false,
                    lock_group_link = true,
                    lock_leave = false,
                    lock_link = false,
                    lock_member = false,
                    lock_name = true,
                    lock_photo = false,
                    lock_rtl = false,
                    lock_spam = false,
                    mutes =
                    {
                        all = false,
                        audio = false,
                        contact = false,
                        document = false,
                        gif = false,
                        location = false,
                        photo = false,
                        sticker = false,
                        text = false,
                        tgservice = false,
                        video = false,
                        video_note = false,
                        voice_note = false,
                    },
                    strict = false,
                    warn_max = 3,
                },
                welcome = nil,
                welcomemembers = 0,
            }
            save_data(_config.moderation.data, data)
            local realms = 'realms'
            if not data[tostring(realms)] then
                data[tostring(realms)] = { }
                save_data(_config.moderation.data, data)
            end
            data[tostring(realms)][tostring(msg.to.id)] = msg.to.id
            save_data(_config.moderation.data, data)
            send_large_msg(extra.receiver, langs[msg.lang].welcomeNewRealm)
            return
        end
    end
end

local function check_member_realm_add(extra, success, result)
    local msg = extra.msg
    for k, v in pairs(result.members) do
        local member_id = v.peer_id
        if member_id ~= our_id then
            -- Group configuration
            data[tostring(msg.to.id)] = {
                goodbye = nil,
                group_type = 'Realm',
                long_id = msg.to.peer_id,
                moderators = { },
                rules = nil,
                set_name = string.gsub(msg.to.title,'_',' '),
                set_owner = tostring(member_id),
                set_photo = nil,
                settings =
                {
                    flood = true,
                    flood_max = 5,
                    lock_arabic = false,
                    lock_bots = false,
                    lock_group_link = true,
                    lock_leave = false,
                    lock_link = false,
                    lock_member = false,
                    lock_name = true,
                    lock_photo = false,
                    lock_rtl = false,
                    lock_spam = false,
                    mutes =
                    {
                        all = false,
                        audio = false,
                        contact = false,
                        document = false,
                        gif = false,
                        location = false,
                        photo = false,
                        sticker = false,
                        text = false,
                        tgservice = false,
                        video = false,
                        video_note = false,
                        voice_note = false,
                    },
                    strict = false,
                    warn_max = 3,
                },
                welcome = nil,
                welcomemembers = 0,
            }
            save_data(_config.moderation.data, data)
            local realms = 'realms'
            if not data[tostring(realms)] then
                data[tostring(realms)] = { }
                save_data(_config.moderation.data, data)
            end
            data[tostring(realms)][tostring(msg.to.id)] = msg.to.id
            save_data(_config.moderation.data, data)
            send_large_msg(extra.receiver, langs[msg.lang].realmAdded)
            return
        end
    end
end

function check_member_group(extra, success, result)
    local msg = extra.msg
    for k, v in pairs(result.members) do
        local member_id = v.peer_id
        if member_id ~= our_id then
            -- Group configuration
            data[tostring(msg.to.id)] = {
                goodbye = nil,
                group_type = 'Group',
                long_id = msg.to.peer_id,
                moderators = { },
                rules = nil,
                set_name = string.gsub(msg.to.title,'_',' '),
                set_owner = tostring(member_id),
                set_photo = nil,
                settings =
                {
                    flood = true,
                    flood_max = 5,
                    lock_arabic = false,
                    lock_bots = false,
                    lock_group_link = true,
                    lock_leave = false,
                    lock_link = false,
                    lock_member = false,
                    lock_name = true,
                    lock_photo = false,
                    lock_rtl = false,
                    lock_spam = false,
                    mutes =
                    {
                        all = false,
                        audio = false,
                        contact = false,
                        document = false,
                        gif = false,
                        location = false,
                        photo = false,
                        sticker = false,
                        text = false,
                        tgservice = false,
                        video = false,
                        video_note = false,
                        voice_note = false,
                    },
                    strict = false,
                    warn_max = 3,
                },
                welcome = nil,
                welcomemembers = 0,
            }
            save_data(_config.moderation.data, data)
            local groups = 'groups'
            if not data[tostring(groups)] then
                data[tostring(groups)] = { }
                save_data(_config.moderation.data, data)
            end
            data[tostring(groups)][tostring(msg.to.id)] = msg.to.id
            save_data(_config.moderation.data, data)
            send_large_msg(extra.receiver, langs[msg.lang].promotedOwner)
            return
        end
    end
end

local function check_member_modadd(extra, success, result)
    local msg = extra.msg
    for k, v in pairs(result.members) do
        local member_id = v.peer_id
        if member_id ~= our_id then
            -- Group configuration
            data[tostring(msg.to.id)] = {
                goodbye = nil,
                group_type = 'Group',
                long_id = msg.to.peer_id,
                moderators = { },
                rules = nil,
                set_name = string.gsub(msg.to.title,'_',' '),
                set_owner = tostring(member_id),
                set_photo = nil,
                settings =
                {
                    flood = true,
                    flood_max = 5,
                    lock_arabic = false,
                    lock_bots = false,
                    lock_group_link = true,
                    lock_leave = false,
                    lock_link = false,
                    lock_member = false,
                    lock_name = true,
                    lock_photo = false,
                    lock_rtl = false,
                    lock_spam = false,
                    mutes =
                    {
                        all = false,
                        audio = false,
                        contact = false,
                        document = false,
                        gif = false,
                        location = false,
                        photo = false,
                        sticker = false,
                        text = false,
                        tgservice = false,
                        video = false,
                        video_note = false,
                        voice_note = false,
                    },
                    strict = false,
                    warn_max = 3,
                },
                welcome = nil,
                welcomemembers = 0,
            }
            save_data(_config.moderation.data, data)
            local groups = 'groups'
            if not data[tostring(groups)] then
                data[tostring(groups)] = { }
                save_data(_config.moderation.data, data)
            end
            data[tostring(groups)][tostring(msg.to.id)] = msg.to.id
            save_data(_config.moderation.data, data)
            send_large_msg(extra.receiver, langs[msg.lang].groupAddedOwner)
            return
        end
    end
end

local function modadd(msg)
    if is_group(msg) then
        return langs[msg.lang].groupAlreadyAdded
    end
    chat_info(get_receiver(msg), check_member_modadd, { receiver = get_receiver(msg), msg = msg })
end

local function realmadd(msg)
    if is_realm(msg) then
        return langs[msg.lang].realmAlreadyAdded
    end
    chat_info(get_receiver(msg), check_member_realm_add, { receiver = get_receiver(msg), msg = msg })
end

local function automodadd(msg)
    if msg.action.type == 'chat_created' then
        chat_info(get_receiver(msg), check_member_group, { receiver = get_receiver(msg), msg = msg })
    end
end

local function autorealmadd(msg)
    if msg.action.type == 'chat_created' then
        chat_info(get_receiver(msg), check_member_autorealm, { receiver = get_receiver(msg), msg = msg })
    end
end

local function promote(receiver, member_username, member_id)
    local lang = get_lang(string.match(receiver, '%d+'))
    local group = string.gsub(receiver, 'chat#id', '')
    if not data[group] then
        send_large_msg(receiver, langs[lang].groupNotAdded)
        return
    end
    if data[group]['moderators'][tostring(member_id)] then
        send_large_msg(receiver, member_username .. langs[lang].alreadyMod)
        return
    end
    data[group]['moderators'][tostring(member_id)] = member_username
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, member_username .. langs[lang].promoteMod)
end

local function demote(receiver, member_username, member_id)
    local lang = get_lang(string.match(receiver, '%d+'))
    local group = string.gsub(receiver, 'chat#id', '')
    if not data[group] then
        send_large_msg(receiver, langs[lang].groupNotAdded)
        return
    end
    if not data[group]['moderators'][tostring(member_id)] then
        send_large_msg(receiver, member_username .. langs[lang].notMod)
        return
    end
    data[group]['moderators'][tostring(member_id)] = nil
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, member_username .. langs[lang].demoteMod)
end

local function promote2(receiver, member_username, user_id)
    local lang = get_lang(string.match(receiver, '%d+'))
    local group = string.gsub(receiver, 'channel#id', '')
    local member_tag_username = member_username
    if not data[group] then
        send_large_msg(receiver, langs[lang].supergroupNotAdded)
        return
    end
    if data[group]['moderators'][tostring(user_id)] then
        send_large_msg(receiver, member_username .. langs[lang].alreadyMod)
        return
    end
    data[group]['moderators'][tostring(user_id)] = member_tag_username
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, member_username .. langs[lang].promoteMod)
end

local function demote2(receiver, member_username, user_id)
    local lang = get_lang(string.match(receiver, '%d+'))
    local group = string.gsub(receiver, 'channel#id', '')
    if not data[group] then
        send_large_msg(receiver, langs[lang].supergroupNotAdded)
        return
    end
    if not data[group]['moderators'][tostring(user_id)] then
        send_large_msg(receiver, member_username .. langs[lang].notMod)
        return
    end
    data[group]['moderators'][tostring(user_id)] = nil
    save_data(_config.moderation.data, data)
    send_large_msg(receiver, member_username .. langs[lang].demoteMod)
end

local function chat_promote_by_username(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if success == 0 then
        send_large_msg(extra.receiver, langs[lang].noUsernameFound)
        return
    end
    return promote(extra.receiver, '@' .. result.username, result.peer_id)
end

local function chat_demote_by_username(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if success == 0 then
        send_large_msg(extra.receiver, langs[lang].noUsernameFound)
        return
    end
    return demote(extra.receiver, '@' .. result.username, result.peer_id)
end

local function promote_by_reply(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if get_reply_receiver(result) == extra.receiver then
        local msg = result
        local full_name =(msg.from.first_name or '') .. ' ' ..(msg.from.last_name or '')
        if msg.from.username then
            member_username = '@' .. msg.from.username
        else
            member_username = full_name
        end
        local member_id = msg.from.peer_id
        if msg.to.peer_type == 'chat' then
            return promote('chat#id' .. result.to.peer_id, member_username, member_id)
        end
    else
        send_large_msg(extra.receiver, langs[lang].oldMessage)
    end
end

local function demote_by_reply(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if get_reply_receiver(result) == extra.receiver then
        local msg = result
        local full_name =(msg.from.first_name or '') .. ' ' ..(msg.from.last_name or '')
        if msg.from.username then
            member_username = '@' .. msg.from.username
        else
            member_username = full_name
        end
        local member_id = msg.from.peer_id
        if msg.to.peer_type == 'chat' then
            return demote('chat#id' .. result.to.peer_id, member_username, member_id)
        end
    else
        send_large_msg(extra.receiver, langs[lang].oldMessage)
    end
end

local function modlist(msg)
    local groups = "groups"
    if not data[tostring(groups)][tostring(msg.to.id)] then
        return langs[msg.lang].groupNotAdded
    end
    -- determine if table is empty
    if next(data[tostring(msg.to.id)]['moderators']) == nil then
        -- fix way
        return langs[msg.lang].noGroupMods
    end
    local i = 1
    local message = langs[msg.lang].modListStart .. string.gsub(msg.to.print_name, '_', ' ') .. ':\n'
    for k, v in pairs(data[tostring(msg.to.id)]['moderators']) do
        message = message .. i .. '. ' .. v .. ' - ' .. k .. '\n'
        i = i + 1
    end
    return message
end

local function setowner_by_reply(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if get_reply_receiver(result) == extra.receiver then
        local msg = result
        local lang = get_lang(msg.to.id)
        local name_log = msg.from.print_name:gsub("_", " ")
        data[tostring(msg.to.id)]['set_owner'] = tostring(msg.from.id)
        save_data(_config.moderation.data, data)
        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set [" .. msg.from.id .. "] as owner")
        send_large_msg(get_receiver(msg), msg.from.print_name:gsub("_", " ") .. langs[lang].setOwner)
    else
        send_large_msg(extra.receiver, langs[lang].oldMessage)
    end
end

local function chat_setowner_by_username(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if success == 0 then
        send_large_msg(extra.receiver, langs[lang].noUsernameFound)
        return
    end
    data[tostring(string.match(extra.receiver, '%d+'))]['set_owner'] = tostring(result.peer_id)
    save_data(_config.moderation.data, data)
    send_large_msg(extra.receiver, result.peer_id .. langs[lang].setOwner)
end

local function cleanmember(extra, success, result)
    for k, v in pairs(result.members) do
        kick_user(v.id, result.peer_id)
    end
end

-- SUPERGROUP
-- Check members #Add supergroup
local function check_member_super(extra, success, result)
    local receiver = extra.receiver
    local msg = extra.msg
    if success == 0 then
        send_large_msg(receiver, langs[msg.lang].promoteBotAdmin)
    end
    for k, v in pairs(result) do
        local member_id = v.peer_id
        if member_id ~= our_id then
            -- SuperGroup configuration
            data[tostring(msg.to.id)] = {
                goodbye = nil,
                group_type = 'SuperGroup',
                long_id = msg.to.peer_id,
                moderators = { },
                rules = nil,
                set_name = string.gsub(msg.to.title,'_',' '),
                set_owner = tostring(member_id),
                set_photo = nil,
                settings =
                {
                    flood = true,
                    flood_max = 5,
                    lock_arabic = false,
                    lock_bots = false,
                    lock_group_link = true,
                    lock_leave = false,
                    lock_link = false,
                    lock_member = false,
                    lock_name = true,
                    lock_photo = false,
                    lock_rtl = false,
                    lock_spam = false,
                    mutes =
                    {
                        all = false,
                        audio = false,
                        contact = false,
                        document = false,
                        gif = false,
                        location = false,
                        photo = false,
                        sticker = false,
                        text = false,
                        tgservice = false,
                        video = false,
                        video_note = false,
                        voice_note = false,
                    },
                    strict = false,
                    warn_max = 3,
                },
                welcome = nil,
                welcomemembers = 0,
            }
            save_data(_config.moderation.data, data)
            local groups = 'groups'
            if not data[tostring(groups)] then
                data[tostring(groups)] = { }
                save_data(_config.moderation.data, data)
            end
            data[tostring(groups)][tostring(msg.to.id)] = msg.to.id
            save_data(_config.moderation.data, data)
            local text = langs[msg.lang].supergroupAdded
            reply_msg(msg.id, text, ok_cb, false)
            return
        end
    end
end

-- Function to Add supergroup
local function superadd(msg)
    local receiver = get_receiver(msg)
    channel_get_users(receiver, check_member_super, { receiver = receiver, msg = msg })
end

-- Get and output admins and bots in supergroup
local function callback(extra, success, result)
    local i = 1
    local chat_name = string.gsub(extra.msg.to.print_name, "_", " ")
    local member_type = extra.member_type
    local text = member_type .. " " .. chat_name .. ":\n"
    for k, v in pairsByKeys(result) do
        if not v.first_name then
            name = " "
        else
            vname = v.first_name:gsub("?", "")
            name = vname:gsub("_", " ")
        end
        text = text .. "\n" .. i .. ". " .. name .. " " .. v.peer_id
        i = i + 1
    end
    send_large_msg(extra.receiver, text)
end

local function callback_updategroupinfo(extra, success, result)
    local chat_id = tostring(string.match(extra.receiver, '%d+'))
    local lang = get_lang(chat_id)
    for k, v in pairsByKeys(result) do
        if v.first_name then
            data[chat_id]['moderators'][tostring(v.peer_id)] = v.username or v.first_name
        end
    end
    save_data(_config.moderation.data, data)
    send_large_msg(extra.receiver, langs[lang].groupInfoUpdated)
end

local function callback_syncmodlist(extra, success, result)
    local chat_id = tostring(string.match(extra.receiver, '%d+'))
    local lang = get_lang(chat_id)
    data[chat_id]['moderators'] = { }
    for k, v in pairsByKeys(result) do
        if v.first_name then
            data[chat_id]['moderators'][tostring(v.peer_id)] = v.username or v.first_name
        end
    end
    save_data(_config.moderation.data, data)
    send_large_msg(extra.receiver, langs[lang].modListSynced)
end

local function check_admin_success(extra, success, result)
    if success then
        send_large_msg(extra.receiver, extra.text)
    else
        send_large_msg(extra.receiver, langs[get_lang(string.match(extra.receiver, '%d+'))].errorPromoteDemoteAdmin)
    end
end

-- Start by reply actions
local function get_message_callback(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if get_reply_receiver(result) == get_receiver(extra.msg) then
        local text = ''
        local get_cmd = extra.get_cmd
        local msg = extra.msg
        local print_name = user_print_name(msg.from):gsub("?", "")
        local name_log = print_name:gsub("_", " ")
        if get_cmd == "promoteadmin" then
            local user_id = result.from.peer_id
            local channel_id = "channel#id" .. result.to.peer_id
            if result.from.username then
                text = "@" .. result.from.username .. langs[msg.lang].promoteSupergroupMod
            else
                text = user_id .. langs[msg.lang].promoteSupergroupMod
            end
            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] promoted: [" .. user_id .. "] as admin by reply")
            channel_set_admin(channel_id, "user#id" .. user_id, check_admin_success, { receiver = channel_id, text = text })
        elseif get_cmd == "demoteadmin" then
            local user_id = result.from.peer_id
            local channel_id = "channel#id" .. result.to.peer_id
            if is_admin2(result.from.peer_id) then
                send_large_msg(channel_id, langs[msg.lang].cantDemoteOtherAdmin)
                return
            end
            if result.from.username then
                text = "@" .. result.from.username .. langs[msg.lang].demoteSupergroupMod
            else
                text = user_id .. langs[msg.lang].demoteSupergroupMod
            end
            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted: [" .. user_id .. "] as admin by reply")
            channel_demote(channel_id, "user#id" .. user_id, check_admin_success, { receiver = channel_id, text = text })
        elseif get_cmd == "setowner" then
            local group_owner = data[tostring(result.to.peer_id)]['set_owner']
            if group_owner then
                local channel_id = 'channel#id' .. result.to.peer_id
                if not is_admin2(tonumber(group_owner)) then
                    local user = "user#id" .. group_owner
                    channel_demote(channel_id, user, ok_cb, false)
                end
                local user_id = "user#id" .. result.from.peer_id
                if result.from.username then
                    text = "@" .. result.from.username .. " " .. result.from.peer_id .. langs[msg.lang].setOwner
                else
                    text = result.from.peer_id .. langs[msg.lang].setOwner
                end
                channel_set_admin(channel_id, user_id, check_admin_success, { receiver = channel_id, text = text })
                data[tostring(result.to.peer_id)]['set_owner'] = tostring(result.from.peer_id)
                save_data(_config.moderation.data, data)
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set: [" .. result.from.peer_id .. "] as owner by reply")
            end
        elseif get_cmd == "promote" then
            local receiver = result.to.peer_id
            local full_name =(result.from.first_name or '') .. ' ' ..(result.from.last_name or '')
            local member_name = full_name:gsub("?", "")
            local member_username = member_name:gsub("_", " ")
            if result.from.username then
                member_username = '@' .. result.from.username
            end
            local member_id = result.from.peer_id
            if result.to.peer_type == 'channel' then
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] promoted mod: @" .. member_username .. "[" .. result.from.peer_id .. "] by reply")
                promote2("channel#id" .. result.to.peer_id, member_username, member_id)
                -- channel_set_mod(channel_id, user, ok_cb, false)
            end
        elseif get_cmd == "demote" then
            local full_name =(result.from.first_name or '') .. ' ' ..(result.from.last_name or '')
            local member_name = full_name:gsub("?", "")
            local member_username = member_name:gsub("_", " ")
            if result.from.username then
                member_username = '@' .. result.from.username
            end
            local member_id = result.from.peer_id
            -- local user = "user#id"..result.peer_id
            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted mod: @" .. member_username .. "[" .. result.from.peer_id .. "] by reply")
            demote2("channel#id" .. result.to.peer_id, member_username, member_id)
            -- channel_demote(channel_id, user, ok_cb, false)
        end
    else
        send_large_msg(extra.receiver, langs[lang].oldMessage)
    end
end
-- End by reply actions

-- Begin non-channel_invite username actions
local function promote_telegram_admin_by_username(extra, success, result)
    local lang = get_lang(string.match(extra.receiver, '%d+'))
    if success == 0 then
        send_large_msg(extra.receiver, langs[lang].noUsernameFound)
        return
    end
    channel_set_admin(extra.receiver, 'user#id' .. result.peer_id, check_admin_success, { receiver = extra.receiver, text = "@" .. result.username .. " " .. result.peer_id .. langs[lang].promoteSupergroupMod })
end
-- End non-channel_invite username actions

-- Begin resolve username actions
local function callbackres(extra, success, result)
    local lang
    if extra.receiver then
        lang = get_lang(string.match(extra.receiver, '%d+'))
    end
    if extra.channel then
        lang = get_lang(string.match(extra.channel, '%d+'))
    end
    if success == 0 then
        return send_large_msg(extra.receiver, langs[lang].noUsernameFound)
    end
    local text = ''
    local member_id = result.peer_id
    local member_username = "@" .. result.username
    local get_cmd = extra.get_cmd
    if get_cmd == "promote" then
        local receiver = extra.channel
        local user_id = result.peer_id
        -- local user = "user#id"..result.peer_id
        promote2(receiver, member_username, user_id)
        -- channel_set_mod(receiver, user, ok_cb, false)
    elseif get_cmd == "demote" then
        local receiver = extra.channel
        local user_id = result.peer_id
        local user = "user#id" .. result.peer_id
        demote2(receiver, member_username, user_id)
    elseif get_cmd == "demoteadmin" then
        local user_id = "user#id" .. result.peer_id
        local channel_id = extra.channel
        if is_admin2(result.peer_id) then
            send_large_msg(channel_id, langs[lang].cantDemoteOtherAdmin)
            return
        end
        if result.username then
            text = "@" .. result.username .. langs[lang].demoteSupergroupMod
        else
            text = result.peer_id .. langs[lang].demoteSupergroupMod
        end
        channel_demote(channel_id, user_id, check_admin_success, { receiver = channel_id, text = text })
    end
end

local function setowner_by_username(extra, success, result)
    local lang = get_lang(extra.chat_id)
    if success == 0 then
        send_large_msg(extra.receiver, langs[lang].noUsernameFound)
        return
    end
    data[tostring(extra.chat_id)]['set_owner'] = tostring(result.peer_id)
    save_data(_config.moderation.data, data)
    savelog(extra.chat_id, result.print_name .. " [" .. result.peer_id .. "] set as owner")
    send_large_msg(extra.receiver, result.peer_id .. langs[lang].setOwner)
end
-- End resolve username actions

-- 'Set supergroup photo' function
local function set_supergroup_photo(msg, success, result)
    if not data[tostring(msg.to.id)] then
        return
    end
    local receiver = get_receiver(msg)
    if success then
        local file = 'data/photos/channel_photo_' .. msg.to.id .. '.jpg'
        print('File downloaded to:', result)
        os.rename(result, file)
        print('File moved to:', file)
        channel_set_photo(receiver, file, ok_cb, false)
        data[tostring(msg.to.id)].set_photo = file
        save_data(_config.moderation.data, data)
        send_large_msg(receiver, langs[msg.lang].photoSaved, ok_cb, false)
    else
        print('Error downloading: ' .. msg.id)
        send_large_msg(receiver, langs[msg.lang].errorTryAgain, ok_cb, false)
    end
end

local function callback_clean_bots(extra, success, result)
    local msg = extra.msg
    local receiver = 'channel#id' .. msg.to.id
    local channel_id = msg.to.id
    for k, v in pairs(result) do
        local bot_id = v.peer_id
        kick_user(bot_id, channel_id)
    end
end

local function contact_mods_callback(extra, success, result)
    local already_contacted = { }
    local msg = extra.msg

    local text = langs[msg.lang].receiver .. msg.to.print_name:gsub("_", " ") .. ' [' .. msg.to.id .. ']\n' .. langs[msg.lang].sender
    if msg.from.username then
        text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
    else
        text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
    end
    text = text .. langs[msg.lang].msgText .. msg.text

    -- telegram admins
    for k, v in pairsByKeys(result) do
        local rnd = math.random(1000)
        if tonumber(v.peer_id) ~= tonumber(our_id) then
            if v.print_name then
                if not already_contacted[tonumber(v.peer_id)] then
                    already_contacted[tonumber(v.peer_id)] = v.peer_id
                    local tmpmsgs = tonumber(redis:get('msgs:' .. v.peer_id .. ':' .. our_id) or 0)
                    if tmpmsgs ~= 0 then
                        if msg.reply_id then
                            local function post_fwd()
                                fwd_msg('user#id' .. v.peer_id, msg.reply_id, ok_cb, false)
                            end
                            postpone(post_fwd, false, math.fmod(rnd, 10) + 1)
                        end
                        local function post_msg()
                            send_large_msg('user#id' .. v.peer_id, text)
                        end
                        postpone(post_msg, false, math.fmod(rnd, 10) + 1)
                    else
                        local function post_msg()
                            send_large_msg(get_receiver(msg), langs[msg.lang].cantContact .. v.peer_id)
                        end
                        postpone(post_msg, false, math.fmod(rnd, 10) + 1)
                    end
                end
            end
        end
    end

    -- owner
    local owner = data[tostring(msg.to.id)]['set_owner']
    if owner then
        local rnd = math.random(1000)
        if not already_contacted[tonumber(owner)] then
            already_contacted[tonumber(owner)] = owner
            local tmpmsgs = tonumber(redis:get('msgs:' .. owner .. ':' .. our_id) or 0)
            if tmpmsgs ~= 0 then
                if msg.reply_id then
                    local function post_fwd()
                        fwd_msg('user#id' .. owner, msg.reply_id, ok_cb, false)
                    end
                    postpone(post_fwd, false, math.fmod(rnd, 10) + 1)
                end
                local function post_msg()
                    send_large_msg('user#id' .. owner, text)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            else
                local function post_msg()
                    send_large_msg(get_receiver(msg), langs[msg.lang].cantContact .. owner)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            end
        end
    end

    local groups = "groups"
    -- determine if table is empty
    if next(data[tostring(msg.to.id)]['moderators']) == nil then
        -- fix way
        return langs[msg.lang].noGroupMods
    end
    for k, v in pairs(data[tostring(msg.to.id)]['moderators']) do
        local rnd = math.random(1000)
        if not already_contacted[tonumber(k)] then
            already_contacted[tonumber(k)] = k
            local tmpmsgs = tonumber(redis:get('msgs:' .. k .. ':' .. our_id) or 0)
            if tmpmsgs ~= 0 then
                if msg.reply_id then
                    local function post_fwd()
                        fwd_msg('user#id' .. k, msg.reply_id, ok_cb, false)
                    end
                    postpone(post_fwd, false, math.fmod(rnd, 10) + 1)
                end
                local function post_msg()
                    send_large_msg('user#id' .. k, text)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            else
                local function post_msg()
                    send_large_msg(get_receiver(msg), langs[msg.lang].cantContact .. v)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            end
        end
    end
end

local function contact_mods(msg)
    local already_contacted = { }

    local text = langs[msg.lang].receiver .. msg.to.print_name:gsub("_", " ") .. ' [' .. msg.to.id .. ']\n' .. langs[msg.lang].sender
    if msg.from.username then
        text = text .. '@' .. msg.from.username .. ' [' .. msg.from.id .. ']\n'
    else
        text = text .. msg.from.print_name:gsub("_", " ") .. ' [' .. msg.from.id .. ']\n'
    end
    text = text .. langs[msg.lang].msgText .. msg.text

    -- owner
    local owner = data[tostring(msg.to.id)]['set_owner']
    if owner then
        local rnd = math.random(1000)
        if not already_contacted[tonumber(owner)] then
            already_contacted[tonumber(owner)] = owner
            local tmpmsgs = tonumber(redis:get('msgs:' .. owner .. ':' .. our_id) or 0)
            if tmpmsgs ~= 0 then
                if msg.reply_id then
                    local function post_fwd()
                        fwd_msg('user#id' .. owner, msg.reply_id, ok_cb, false)
                    end
                    postpone(post_fwd, false, math.fmod(rnd, 10) + 1)
                end
                local function post_msg()
                    send_large_msg('user#id' .. owner, text)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            else
                local function post_msg()
                    send_large_msg(get_receiver(msg), langs[msg.lang].cantContact .. owner)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            end
        end
    end

    local groups = "groups"
    -- determine if table is empty
    if next(data[tostring(msg.to.id)]['moderators']) == nil then
        -- fix way
        return langs[msg.lang].noGroupMods
    end
    for k, v in pairs(data[tostring(msg.to.id)]['moderators']) do
        local rnd = math.random(1000)
        if not already_contacted[tonumber(k)] then
            already_contacted[tonumber(k)] = k
            local tmpmsgs = tonumber(redis:get('msgs:' .. k .. ':' .. our_id) or 0)
            if tmpmsgs ~= 0 then
                if msg.reply_id then
                    local function post_fwd()
                        fwd_msg('user#id' .. k, msg.reply_id, ok_cb, false)
                    end
                    postpone(post_fwd, false, math.fmod(rnd, 10) + 1)
                end
                local function post_msg()
                    send_large_msg('user#id' .. k, text)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            else
                local function post_msg()
                    send_large_msg(get_receiver(msg), langs[msg.lang].cantContact .. v)
                end
                postpone(post_msg, false, math.fmod(rnd, 10) + 1)
            end
        end
    end
end

local function run(msg, matches)
    local name_log = user_print_name(msg.from)
    if not msg.api_patch then
        if matches[1]:lower() == 'type' then
            if is_momod(msg) then
                if data[tostring(msg.to.id)] then
                    if not data[tostring(msg.to.id)]['group_type'] then
                        if msg.to.type == 'chat' and not is_realm(msg) then
                            data[tostring(msg.to.id)]['group_type'] = 'Group'
                            save_data(_config.moderation.data, data)
                        elseif msg.to.type == 'channel' then
                            data[tostring(msg.to.id)]['group_type'] = 'SuperGroup'
                            save_data(_config.moderation.data, data)
                        end
                    end
                    return data[tostring(msg.to.id)]['group_type']
                else
                    return langs[msg.lang].chatTypeNotFound
                end
            else
                return langs[msg.lang].require_mod
            end
        end
        if matches[1]:lower() == 'log' then
            if is_owner(msg) then
                savelog(msg.to.id, "log file created by owner/admin")
                send_document(get_receiver(msg), "./groups/logs/" .. msg.to.id .. "log.txt", ok_cb, false)
                return
            else
                return langs[msg.lang].require_owner
            end
        end
        if matches[1]:lower() == 'admin' or matches[1]:lower() == 'admins' then
            send_large_msg(get_receiver(msg), langs[msg.lang].useAISashaAPI)
            --[[if msg.to.type == 'channel' then
                return channel_get_admins(get_receiver(msg), contact_mods_callback, { msg = msg })
            elseif msg.to.type == 'chat' then
                return contact_mods(msg)
            end]]
        end
    end

    -- INPM
    -- TODO: add lock and unlock join
    if is_sudo(msg) or msg.to.type == 'user' then
        if not msg.api_patch then
            if matches[1]:lower() == 'join' or matches[1]:lower() == 'inviteme' or matches[1]:lower() == 'sasha invitami' or matches[1]:lower() == 'invitami' then
                if is_admin1(msg) then
                    if string.match(matches[2], '^%d+$') then
                        if not data[tostring(matches[2])] then
                            return langs[msg.lang].chatNotFound
                        end
                        chat_add_user('chat#id' .. matches[2], 'user#id' .. msg.from.id, ok_cb, false)
                        channel_invite('channel#id' .. matches[2], 'user#id' .. msg.from.id, ok_cb, false)
                        return langs[msg.lang].ok
                    else
                        local hash = 'groupalias'
                        local value = redis:hget(hash, matches[2]:lower())
                        if value then
                            chat_add_user('chat#id' .. value, 'user#id' .. msg.from.id, ok_cb, false)
                            channel_invite('channel#id' .. value, 'user#id' .. msg.from.id, ok_cb, false)
                            return langs[msg.lang].ok
                        else
                            return langs[msg.lang].noAliasFound
                        end
                    end
                else
                    return langs[msg.lang].require_admin
                end
            end

            if matches[1]:lower() == 'allchats' then
                if is_admin1(msg) then
                    return all_chats(msg)
                else
                    return langs[msg.lang].require_admin
                end
            end

            if matches[1]:lower() == 'allchatslist' then
                if is_admin1(msg) then
                    all_chats(msg)
                    send_document("chat#id" .. msg.to.id, "./groups/lists/all_listed_groups.txt", ok_cb, false)
                    send_document("channel#id" .. msg.to.id, "./groups/lists/all_listed_groups.txt", ok_cb, false)
                else
                    return langs[msg.lang].require_admin
                end
            end
        end

        if matches[1]:lower() == 'setalias' then
            if is_sudo(msg) then
                return set_alias(msg, matches[2]:gsub('_', ' '), matches[3])
            else
                return langs[msg.lang].require_sudo
            end
        end

        if matches[1]:lower() == 'unsetalias' then
            if is_sudo(msg) then
                return unset_alias(msg, matches[2])
            else
                return langs[msg.lang].require_sudo
            end
        end

        if matches[1]:lower() == 'getaliaslist' then
            if is_admin1(msg) then
                local hash = 'groupalias'
                local names = redis:hkeys(hash)
                local ids = redis:hvals(hash)
                local text = ''
                for i = 1, #names do
                    text = text .. names[i] .. ' - ' .. ids[i] .. '\n'
                end
                return text
            else
                return langs[msg.lang].require_admin
            end
        end
    end

    -- INREALM
    if is_realm(msg) then
        if (matches[1]:lower() == 'creategroup' or matches[1]:lower() == 'sasha crea gruppo') and matches[2] then
            if is_admin1(msg) then
                group_type = 'group'
                return create_group(msg.from.print_name, matches[2], msg.lang)
            else
                return langs[msg.lang].require_admin
            end
        end
        if (matches[1]:lower() == 'createsuper' or matches[1]:lower() == 'sasha crea supergruppo') and matches[2] then
            if is_admin1(msg) then
                group_type = 'supergroup'
                return create_group(msg.from.print_name, matches[2], msg.lang)
            else
                return langs[msg.lang].require_admin
            end
        end
        if (matches[1]:lower() == 'createrealm' or matches[1]:lower() == 'sasha crea regno') and matches[2] then
            if is_sudo(msg) then
                group_type = 'realm'
                return create_group(msg.from.print_name, matches[2], msg.lang)
            else
                return langs[msg.lang].require_sudo
            end
        end
        if matches[1]:lower() == 'kill' then
            if is_admin1(msg) then
                if matches[2]:lower() == 'group' and matches[3] then
                    print("Closing Group: " .. 'chat#id' .. matches[3])
                    chat_del_user('chat#id' .. matches[3], 'user#id' .. our_id, ok_cb, true)
                    data[tostring(matches[3])] = nil
                    data.groups[tostring(matches[3])] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].groupRemoved, ok_cb, false)
                    return
                end
                if matches[2]:lower() == 'supergroup' and matches[3] then
                    print("Closing Supergroup: " .. 'channel#id' .. matches[3])
                    leave_channel('channel#id' .. matches[3], ok_cb, false)
                    data[tostring(matches[3])] = nil
                    data.groups[tostring(matches[3])] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].supergroupRemoved, ok_cb, false)
                    return
                end
                if matches[2]:lower() == 'realm' and matches[3] then
                    print("Closing Realm: " .. 'chat#id' .. matches[3])
                    chat_del_user('chat#id' .. matches[3], 'user#id' .. our_id, ok_cb, true)
                    data[tostring(matches[3])] = nil
                    data.groups[tostring(matches[3])] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].realmRemoved, ok_cb, false)
                    return
                end
            else
                return langs[msg.lang].require_admin
            end
        end
        if not msg.api_patch then
            if matches[1]:lower() == 'rem' and matches[2] then
                if is_admin1(msg) then
                    -- Group configuration removal
                    data[tostring(msg.to.id)] = nil
                    data.groups[tostring(msg.to.id)] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].realmRemoved, ok_cb, false)
                    chat_del_user('chat#id' .. msg.to.id, 'user#id' .. our_id, ok_cb, true)
                    return
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'setgpowner' and matches[2] and matches[3] then
                if is_admin1(msg) then
                    if data[tostring(matches[2])] then
                        data[tostring(matches[2])]['set_owner'] = matches[3]
                        save_data(_config.moderation.data, data)
                        local lang = get_lang(matches[2])
                        local text = matches[3] .. langs[msg.lang].setOwner
                        send_large_msg("chat#id" .. matches[2], text)
                        send_large_msg("channel#id" .. matches[2], text)
                        return text
                    end
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1] == 'chat_add_user' then
                if msg.service and msg.action then
                    if msg.action.user then
                        if msg.action.user.id ~= 283058260 then
                            -- if not admin and not bot then
                            if not is_admin1(msg) and not msg.from.id == our_id then
                                return kick_user(msg.action.user.id, msg.to.id)
                            end
                        end
                    end
                end
            end
            if (matches[1]:lower() == 'lock' or matches[1]:lower() == 'sasha blocca' or matches[1]:lower() == 'blocca') and matches[2] and matches[3] then
                if is_admin1(msg) then
                    if checkMatchesLockUnlock(matches[3]) then
                        return lockSetting(matches[2], matches[3]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_admin
                end
            end
            if (matches[1]:lower() == 'unlock' or matches[1]:lower() == 'sasha sblocca' or matches[1]:lower() == 'sblocca') and matches[2] and matches[3] then
                if is_admin1(msg) then
                    if checkMatchesLockUnlock(matches[3]) then
                        return unlockSetting(matches[2], matches[3]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'settings' then
                if matches[2] then
                    if data[tostring(matches[2])].settings then
                        if is_admin1(msg) then
                            return showSettings(matches[2], msg.lang)
                        else
                            return langs[msg.lang].require_admin
                        end
                    end
                else
                    return showSettings(msg.to.id, msg.lang)
                end
            end
            if matches[1]:lower() == 'setgprules' then
                if is_admin1(msg) then
                    data[tostring(matches[2])]['rules'] = matches[3]
                    save_data(_config.moderation.data, data)
                    return langs[msg.lang].newRules .. matches[3]
                else
                    return langs[msg.lang].require_admin
                end
            end
        end
        if matches[1]:lower() == 'setgroupabout' and matches[2] and matches[3] then
            if is_admin1(msg) then
                data[tostring(matches[2])]['description'] = matches[3]
                save_data(_config.moderation.data, data)
                return langs[msg.lang].newDescription .. matches[3]
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'setsupergroupabout' and matches[2] and matches[3] then
            if is_admin1(msg) then
                channel_set_about('channel#id' .. matches[2], matches[3], ok_cb, false)
                data[tostring(target)]['description'] = matches[3]
                save_data(_config.moderation.data, data)
                return langs[msg.lang].descriptionSet .. matches[2]
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'setgpname' then
            if is_admin1(msg) then
                data[tostring(matches[2])].set_name = string.gsub(matches[3], '_', ' ')
                save_data(_config.moderation.data, data)
                rename_chat('chat#id' .. matches[2], data[tostring(matches[2])].set_name, ok_cb, false)
                rename_channel('channel#id' .. matches[2], data[tostring(matches[2])].set_name, ok_cb, false)
                return savelog(matches[3], "Group { " .. data[tostring(matches[2])].set_name .. " }  name changed to [ " .. string.gsub(matches[3], '_', ' ') .. " ] by " .. name_log .. " [" .. msg.from.id .. "]")
            else
                return langs[msg.lang].require_admin
            end
        end
        if matches[1]:lower() == 'setname' then
            if is_admin1(msg) then
                data[tostring(msg.to.id)].set_name = string.gsub(matches[2], '_', ' ')
                save_data(_config.moderation.data, data)
                rename_chat('chat#id' .. msg.to.id, data[tostring(msg.to.id)].set_name, ok_cb, false)
                return savelog(msg.to.id, "Realm { " .. msg.to.print_name .. " }  name changed to [ " .. string.gsub(matches[3], '_', ' ') .. " ] by " .. name_log .. " [" .. msg.from.id .. "]")
            else
                return langs[msg.lang].require_admin
            end
        end
    end

    -- INGROUP
    if msg.to.type == 'chat' then
        if matches[1]:lower() == 'tosuper' then
            if is_admin1(msg) then
                chat_upgrade(get_receiver(msg), ok_cb, false)
                return
            else
                return langs[msg.lang].require_admin
            end
        end
        if msg.media then
            if msg.media.type == 'photo' and data[tostring(msg.to.id)] and data[tostring(msg.to.id)].set_photo == 'waiting' and is_chat_msg(msg) and is_momod(msg) then
                load_photo(msg.id, set_group_photo, msg)
                return
            end
        end
        if matches[1] == 'chat_created' and msg.from.id == 0 and group_type == "group" then
            return automodadd(msg)
        end
        if matches[1] == 'chat_created' and msg.from.id == 0 and group_type == "realm" then
            return autorealmadd(msg)
        end
        if not msg.api_patch then
            if matches[1]:lower() == 'add' and not matches[2] then
                if is_admin1(msg) then
                    if is_realm(msg) then
                        return langs[msg.lang].errorAlreadyRealm
                    end
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] added group [ " .. msg.to.id .. " ]")
                    print("group " .. msg.to.print_name .. "(" .. msg.to.id .. ") added")
                    return modadd(msg)
                else
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] attempted to add group [ " .. msg.to.id .. " ]")
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'add' and matches[2]:lower() == 'realm' then
                if is_sudo(msg) then
                    if is_group(msg) then
                        return langs[msg.lang].errorAlreadyGroup
                    end
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] added realm [ " .. msg.to.id .. " ]")
                    print("group " .. msg.to.print_name .. "(" .. msg.to.id .. ") added as a realm")
                    return realmadd(msg)
                else
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] attempted to add realm [ " .. msg.to.id .. " ]")
                    return langs[msg.lang].require_sudo
                end
            end
            if matches[1]:lower() == 'rem' and not matches[2] then
                if is_admin1(msg) then
                    if not is_group(msg) then
                        return langs[msg.lang].errorNotGroup
                    end
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] removed group [ " .. msg.to.id .. " ]")
                    print("group " .. msg.to.print_name .. "(" .. msg.to.id .. ") removed")
                    data[tostring(msg.to.id)] = nil
                    data.groups[tostring(msg.to.id)] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].groupRemoved, ok_cb, false)
                    chat_del_user('chat#id' .. msg.to.id, 'user#id' .. our_id, ok_cb, true)
                    return
                else
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] attempted to remove group [ " .. msg.to.id .. " ]")
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'rem' and matches[2]:lower() == 'realm' then
                if is_sudo(msg) then
                    if not is_realm(msg) then
                        return langs[msg.lang].errorNotRealm
                    end
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] removed realm [ " .. msg.to.id .. " ]")
                    print("group " .. msg.to.print_name .. "(" .. msg.to.id .. ") removed as a realm")
                    data[tostring(msg.to.id)] = nil
                    data.groups[tostring(msg.to.id)] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].realmRemoved, ok_cb, false)
                    chat_del_user('chat#id' .. msg.to.id, 'user#id' .. our_id, ok_cb, true)
                    return
                else
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] attempted to remove realm [ " .. msg.to.id .. " ]")
                    return langs[msg.lang].require_sudo
                end
            end
        end
        if data[tostring(msg.to.id)] then
            local settings = data[tostring(msg.to.id)].settings
            if not msg.service then
                if matches[1] == 'chat_add_user' then
                    if settings.lock_member and not is_owner2(msg.action.user.id, msg.to.id) then
                        chat_del_user('chat#id' .. msg.to.id, 'user#id' .. msg.action.user.id, ok_cb, true)
                        return
                    elseif settings.lock_member and tonumber(msg.from.id) == tonumber(our_id) then
                        return
                    elseif settings.lock_member then
                        return
                    end
                end
                if matches[1] == 'chat_del_user' then
                    return savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] deleted user  " .. 'user#id' .. msg.action.user.id)
                end
                if matches[1] == 'chat_delete_photo' then
                    if settings.lock_photo then
                        local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                        redis:incr(picturehash)
                        local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                        local picprotectionredis = redis:get(picturehash)
                        if picprotectionredis then
                            if tonumber(picprotectionredis) == 4 and not is_owner(msg) then
                                kick_user(msg.from.id, msg.to.id)
                            end
                            if tonumber(picprotectionredis) == 8 and not is_owner(msg) then
                                ban_user(msg.from.id, msg.to.id)
                                local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                                redis:set(picturehash, 0)
                            end
                        end

                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] tried to delete picture but failed  ")
                        chat_set_photo(get_receiver(msg), data[tostring(msg.to.id)].set_photo, ok_cb, false)
                        return
                    elseif settings.lock_photo then
                        return
                    end
                end
                if matches[1] == 'chat_change_photo' and msg.from.id ~= 0 then
                    if settings.lock_photo then
                        local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                        redis:incr(picturehash)
                        -- -
                        local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                        local picprotectionredis = redis:get(picturehash)
                        if picprotectionredis then
                            if tonumber(picprotectionredis) == 4 and not is_owner(msg) then
                                kick_user(msg.from.id, msg.to.id)
                            end
                            if tonumber(picprotectionredis) == 8 and not is_owner(msg) then
                                ban_user(msg.from.id, msg.to.id)
                                local picturehash = 'picture:changed:' .. msg.to.id .. ':' .. msg.from.id
                                redis:set(picturehash, 0)
                            end
                        end

                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] tried to change picture but failed  ")
                        chat_set_photo(get_receiver(msg), data[tostring(msg.to.id)].set_photo, ok_cb, false)
                        return
                    elseif settings.lock_photo then
                        return
                    end
                end
                if matches[1] == 'chat_rename' then
                    if settings.lock_name then
                        if data[tostring(msg.to.id)].set_name ~= tostring(msg.to.print_name) then
                            local namehash = 'name:changed:' .. msg.to.id .. ':' .. msg.from.id
                            redis:incr(namehash)
                            local namehash = 'name:changed:' .. msg.to.id .. ':' .. msg.from.id
                            local nameprotectionredis = redis:get(namehash)
                            if nameprotectionredis then
                                if tonumber(nameprotectionredis) == 4 and not is_owner(msg) then
                                    kick_user(msg.from.id, msg.to.id)
                                end
                                if tonumber(nameprotectionredis) == 8 and not is_owner(msg) then
                                    ban_user(msg.from.id, msg.to.id)
                                    local namehash = 'name:changed:' .. msg.to.id .. ':' .. msg.from.id
                                    redis:set(namehash, 0)
                                end
                            end
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] tried to change name but failed  ")
                            rename_chat('chat#id' .. msg.to.id, data[tostring(msg.to.id)].set_name, ok_cb, false)
                            return
                        end
                    elseif settings.lock_name then
                        return
                    end
                end
            end
            if not msg.api_patch then
                if matches[1]:lower() == 'setname' and is_group(msg) then
                    if is_momod(msg) then
                        data[tostring(msg.to.id)].set_name = string.gsub(matches[2], '_', ' ')
                        save_data(_config.moderation.data, data)
                        rename_chat('chat#id' .. msg.to.id, data[tostring(msg.to.id)].set_name, ok_cb, false)
                        return savelog(msg.to.id, "Group { " .. msg.to.print_name .. " }  name changed to [ " .. string.gsub(matches[2], '_', ' ') .. " ] by " .. name_log .. " [" .. msg.from.id .. "]")
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'setphoto' then
                    if is_momod(msg) then
                        data[tostring(msg.to.id)].set_photo = 'waiting'
                        save_data(_config.moderation.data, data)
                        return langs[msg.lang].sendNewGroupPic
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'promote' or matches[1]:lower() == 'sasha promuovi' or matches[1]:lower() == 'promuovi' then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            get_message(msg.reply_id, promote_by_reply, { receiver = get_receiver(msg) })
                            return
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                promote(get_receiver(msg), 'NONAME', matches[2])
                                return
                            else
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] promoted @" .. string.gsub(matches[2], '@', ''))
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), chat_promote_by_username, { receiver = get_receiver(msg) })
                                return
                            end
                        end
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'demote' or matches[1]:lower() == 'sasha degrada' or matches[1]:lower() == 'degrada' then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            get_message(msg.reply_id, demote_by_reply, { receiver = get_receiver(msg) })
                            return
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                demote(get_receiver(msg), 'NONAME', matches[2])
                                return
                            else
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted @" .. string.gsub(matches[2], '@', ''))
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), chat_demote_by_username, { receiver = get_receiver(msg) })
                                return
                            end
                        end
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'modlist' or matches[1]:lower() == 'sasha lista mod' or matches[1]:lower() == 'lista mod' then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group modlist")
                    return modlist(msg)
                end
            end
            if matches[1]:lower() == 'about' or matches[1]:lower() == 'sasha descrizione' then
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group description")
                if not data[tostring(msg.to.id)]['description'] then
                    return langs[msg.lang].noDescription
                end
                return langs[msg.lang].description .. string.gsub(msg.to.print_name, "_", " ") .. ':\n\n' .. about
            end
            if not msg.api_patch then
                if matches[1]:lower() == 'rules' or matches[1]:lower() == 'sasha regole' then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group rules")
                    if not data[tostring(msg.to.id)]['rules'] then
                        return langs[msg.lang].noRules
                    end
                    return langs[msg.lang].rules .. data[tostring(msg.to.id)]['rules']
                end
                if matches[1]:lower() == 'setrules' or matches[1]:lower() == 'sasha imposta regole' then
                    if is_momod(msg) then
                        data[tostring(msg.to.id)]['rules'] = matches[2]
                        save_data(_config.moderation.data, data)
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] has changed group rules to [" .. matches[2] .. "]")
                        return langs[msg.lang].newRules .. matches[2]
                    else
                        return langs[msg.lang].require_mod
                    end
                end
            end
            if matches[1]:lower() == 'setabout' or matches[1]:lower() == 'sasha imposta descrizione' then
                if is_momod(msg) then
                    data[tostring(msg.to.id)]['description'] = matches[2]
                    save_data(_config.moderation.data, data)
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] has changed group description to [" .. matches[2] .. "]")
                    return langs[msg.lang].newDescription .. matches[2]
                else
                    return langs[msg.lang].require_mod
                end
            end
        end
        if not msg.api_patch then
            if matches[1]:lower() == 'lock' or matches[1]:lower() == 'sasha blocca' or matches[1]:lower() == 'blocca' then
                if is_momod(msg) then
                    if checkMatchesLockUnlock(matches[2]) then
                        return lockSetting(msg.to.id, matches[2]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'unlock' or matches[1]:lower() == 'sasha sblocca' or matches[1]:lower() == 'sblocca' then
                if is_momod(msg) then
                    if checkMatchesLockUnlock(matches[2]) then
                        return unlockSetting(msg.to.id, matches[2]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'settings' then
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group settings ")
                return showSettings(msg.to.id, msg.lang)
            end
            if matches[1]:lower() == 'mute' or matches[1]:lower() == 'silenzia' then
                if is_owner(msg) then
                    if checkMatchesMuteUnmute(matches[2]) then
                        return mute(msg.to.id, matches[2]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'unmute' or matches[1]:lower() == 'ripristina' then
                if is_owner(msg) then
                    if checkMatchesMuteUnmute(matches[2]) then
                        return unmute(msg.to.id, matches[2]:lower())
                    end
                    return
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == "muteslist" or matches[1]:lower() == "lista muti" then
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup muteslist")
                return mutes_list(msg.to.id, msg.to.print_name)
            end
            if matches[1]:lower() == 'newlink' and not is_realm(msg) then
                if is_momod(msg) then
                    local function callback(extra, success, result)
                        local receiver = 'chat#' .. msg.to.id
                        if success == 0 then
                            send_large_msg(receiver, langs[msg.lang].errorCreateLink)
                            return
                        end
                        send_large_msg(receiver, langs[msg.lang].linkCreated)
                        data[tostring(msg.to.id)].settings['set_link'] = result
                        save_data(_config.moderation.data, data)
                    end
                    local receiver = 'chat#' .. msg.to.id
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] revoked group link ")
                    export_chat_link(receiver, callback, true)
                    return
                else
                    return langs[msg.lang].require_mod
                end
            end
            if (matches[1]:lower() == 'setlink' or matches[1]:lower() == "sasha imposta link") and matches[2] then
                if is_owner(msg) then
                    data[tostring(msg.to.id)].settings['set_link'] = matches[2]
                    save_data(_config.moderation.data, data)
                    return langs[msg.lang].linkSaved
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'unsetlink' or matches[1]:lower() == "sasha elimina link" then
                if is_owner(msg) then
                    data[tostring(msg.to.id)].settings['set_link'] = nil
                    save_data(_config.moderation.data, data)
                    return langs[msg.lang].linkDeleted
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'link' or matches[1]:lower() == 'sasha link' then
                if data[tostring(msg.to.id)].settings.set_link then
                    if data[tostring(msg.to.id)].settings.lock_group_link then
                        if is_momod(msg) then
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group link [" .. data[tostring(msg.to.id)].settings.set_link .. "]")
                            return msg.to.title .. '\n' .. data[tostring(msg.to.id)].settings.set_link
                        else
                            return langs[msg.lang].require_mod
                        end
                    else
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group link [" .. data[tostring(msg.to.id)].settings.set_link .. "]")
                        return msg.to.title .. '\n' .. data[tostring(msg.to.id)].settings.set_link
                    end
                else
                    return langs[msg.lang].sendMeLink
                end
            end
            if matches[1]:lower() == 'owner' then
                local group_owner = data[tostring(msg.to.id)]['set_owner']
                if not group_owner then
                    return langs[msg.lang].noOwnerCallAdmin
                end
                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] used /owner")
                return langs[msg.lang].ownerIs .. group_owner
            end
            if matches[1]:lower() == 'setowner' then
                if is_owner(msg) then
                    if type(msg.reply_id) ~= "nil" then
                        get_message(msg.reply_id, setowner_by_reply, { receiver = get_receiver(msg) })
                    elseif matches[2] and matches[2] ~= '' then
                        if string.match(matches[2], '^%d+$') then
                            data[tostring(msg.to.id)]['set_owner'] = tostring(matches[2])
                            save_data(_config.moderation.data, data)
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set [" .. matches[2] .. "] as owner")
                            return matches[2] .. langs[msg.lang].setOwner
                        else
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set @" .. string.gsub(matches[2], '@', '') .. " as owner")
                            resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), chat_setowner_by_username, { receiver = get_receiver(msg) })
                            return
                        end
                    end
                else
                    return langs[msg.lang].require_owner
                end
            end
            if matches[1]:lower() == 'setflood' then
                if is_momod(msg) then
                    if tonumber(matches[2]) < 3 or tonumber(matches[2]) > 20 then
                        return langs[msg.lang].errorFloodRange
                    end
                    data[tostring(msg.to.id)].settings['flood_max'] = matches[2]
                    save_data(_config.moderation.data, data)
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set flood to [" .. matches[2] .. "]")
                    return langs[msg.lang].floodSet .. matches[2]
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'setwarn' and matches[2] then
                if is_momod(msg) then
                    local txt = set_warn(msg.from.id, msg.to.id, matches[2])
                    if matches[2] == '0' then
                        return langs[msg.lang].neverWarn
                    else
                        return txt
                    end
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'getwarn' then
                return get_warn(msg.to.id)
            end
        end
        if matches[1]:lower() == 'clean' then
            if is_owner(msg) then
                if matches[2]:lower() == 'member' then
                    chat_info(get_receiver(msg), cleanmember, false)
                end
                if not msg.api_patch then
                    if matches[2]:lower() == 'modlist' then
                        if next(data[tostring(msg.to.id)]['moderators']) == nil then
                            -- fix way
                            return langs[msg.lang].noGroupMods
                        end
                        local message = langs[msg.lang].modListStart .. string.gsub(msg.to.print_name, '_', ' ') .. ':\n'
                        for k, v in pairs(data[tostring(msg.to.id)]['moderators']) do
                            data[tostring(msg.to.id)]['moderators'][tostring(k)] = nil
                            save_data(_config.moderation.data, data)
                        end
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned modlist")
                    end
                    if matches[2]:lower() == 'rules' then
                        data[tostring(msg.to.id)]['rules'] = nil
                        save_data(_config.moderation.data, data)
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned rules")
                    end
                end
                if matches[2]:lower() == 'about' then
                    data[tostring(msg.to.id)]['description'] = nil
                    save_data(_config.moderation.data, data)
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned about")
                end
            else
                return langs[msg.lang].require_owner
            end
        end
        if matches[1]:lower() == 'kill' then
            if matches[2]:lower() == 'group' then
                if is_admin1(msg) then
                    if is_group(msg) then
                        print("Closing Group: " .. get_receiver(msg))
                        data[tostring(msg.to.id)] = nil
                        data.groups[tostring(msg.to.id)] = nil
                        save_data(_config.moderation.data, data)
                        reply_msg(msg.id, langs[msg.lang].groupRemoved, ok_cb, false)
                        chat_del_user('chat#id' .. msg.to.id, 'user#id' .. our_id, ok_cb, true)
                        return
                    else
                        return langs[msg.lang].realmIs
                    end
                else
                    return langs[msg.lang].require_admin
                end
            elseif matches[2]:lower() == 'realm' then
                if is_sudo(msg) then
                    if is_realm(msg) then
                        print("Closing realm: " .. get_receiver(msg))
                        data[tostring(msg.to.id)] = nil
                        data.groups[tostring(msg.to.id)] = nil
                        save_data(_config.moderation.data, data)
                        reply_msg(msg.id, langs[msg.lang].realmRemoved, ok_cb, false)
                        chat_del_user('chat#id' .. msg.to.id, 'user#id' .. our_id, ok_cb, true)
                        return
                    else
                        return langs[msg.lang].groupIs
                    end
                else
                    return langs[msg.lang].require_sudo
                end
            end
        end
    end

    -- SUPERGROUP
    if msg.to.type == 'channel' then
        if matches[1]:lower() == 'tosuper' then
            if is_admin1(msg) then
                return langs[msg.lang].errorAlreadySupergroup
            else
                return langs[msg.lang].require_admin
            end
        end
        if not msg.api_patch then
            if matches[1]:lower() == 'add' and not matches[2] then
                if is_admin1(msg) then
                    if is_super_group(msg) then
                        reply_msg(msg.id, langs[msg.lang].supergroupAlreadyAdded, ok_cb, false)
                        return
                    end
                    print("SuperGroup " .. msg.to.print_name .. "(" .. msg.to.id .. ") added")
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] added SuperGroup")
                    superadd(msg)
                    channel_set_admin(get_receiver(msg), 'user#id' .. msg.from.id, ok_cb, false)
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'rem' and is_admin1(msg) and not matches[2] then
                if is_admin1(msg) then
                    if not is_super_group(msg) then
                        reply_msg(msg.id, langs[msg.lang].supergroupRemoved, ok_cb, false)
                        return
                    end
                    print("SuperGroup " .. msg.to.print_name .. "(" .. msg.to.id .. ") removed")
                    data[tostring(msg.to.id)] = nil
                    data.groups[tostring(msg.to.id)] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].supergroupRemoved, ok_cb, false)
                    leave_channel('channel#id' .. msg.to.id, ok_cb, false)
                    return
                else
                    return langs[msg.lang].require_admin
                end
            end
        end
        if data[tostring(msg.to.id)] then
            if not msg.api_patch then
                if matches[1]:lower() == "getadmins" or matches[1]:lower() == "sasha lista admin" or matches[1]:lower() == "lista admin" then
                    if is_owner(msg) then
                        member_type = 'Admins'
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup Admins list")
                        channel_get_admins(get_receiver(msg), callback, { receiver = get_receiver(msg), msg = msg, member_type = member_type })
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == "updategroupinfo" then
                    if is_momod(msg) then
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] updated group name and modlist")
                        channel_get_admins(get_receiver(msg), callback_updategroupinfo, { receiver = get_receiver(msg) })
                        return
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == "syncmodlist" then
                    if is_owner(msg) then
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] synced modlist")
                        channel_get_admins(get_receiver(msg), callback_syncmodlist, { receiver = get_receiver(msg) })
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == "owner" then
                    if not data[tostring(msg.to.id)]['set_owner'] then
                        return langs[msg.lang].noOwnerCallAdmin
                    end
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] used /owner")
                    return langs[msg.lang].ownerIs .. data[tostring(msg.to.id)]['set_owner']
                end
                if matches[1]:lower() == "modlist" or matches[1]:lower() == "sasha lista mod" or matches[1]:lower() == "lista mod" then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group modlist")
                    return modlist(msg)
                end
                if matches[1]:lower() == 'del' then
                    if is_momod(msg) or tostring(msg.from.id) == '283058260' then
                        if type(msg.reply_id) ~= "nil" then
                            delete_msg(msg.id, ok_cb, false)
                            delete_msg(msg.reply_id, ok_cb, false)
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] deleted a message by reply")
                        end
                    else
                        return langs[msg.lang].require_mod
                    end
                end
            end
            if matches[1]:lower() == "bots" or matches[1]:lower() == "sasha lista bot" or matches[1]:lower() == "lista bot" then
                if is_momod(msg) then
                    member_type = 'Bots'
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup bots list")
                    channel_get_bots(get_receiver(msg), callback, { receiver = get_receiver(msg), msg = msg, member_type = member_type })
                else
                    return langs[msg.lang].require_mod
                end
            end
            if not msg.api_patch then
                if matches[1]:lower() == 'newlink' or matches[1]:lower() == "sasha crea link" then
                    if is_momod(msg) then
                        local function callback_link(extra, success, result)
                            local receiver = get_receiver(msg)
                            if success == 0 then
                                send_large_msg(get_receiver(msg), langs[msg.lang].errorCreateLink)
                                data[tostring(msg.to.id)].settings['set_link'] = nil
                                save_data(_config.moderation.data, data)
                            else
                                send_large_msg(get_receiver(msg), langs[msg.lang].linkCreated)
                                data[tostring(msg.to.id)].settings['set_link'] = result
                                save_data(_config.moderation.data, data)
                            end
                        end
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] attempted to create a new SuperGroup link")
                        export_channel_link(get_receiver(msg), callback_link, false)
                        return
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if (matches[1]:lower() == 'setlink' or matches[1]:lower() == "sasha imposta link") and matches[2] then
                    if is_owner(msg) then
                        data[tostring(msg.to.id)].settings['set_link'] = matches[2]
                        save_data(_config.moderation.data, data)
                        return langs[msg.lang].linkSaved
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'unsetlink' or matches[1]:lower() == "sasha elimina link" then
                    if is_owner(msg) then
                        data[tostring(msg.to.id)].settings['set_link'] = nil
                        save_data(_config.moderation.data, data)
                        return langs[msg.lang].linkDeleted
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'link' or matches[1]:lower() == "sasha link" then
                    if data[tostring(msg.to.id)].settings.set_link then
                        if data[tostring(msg.to.id)].settings.lock_group_link then
                            if is_momod(msg) then
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group link [" .. data[tostring(msg.to.id)].settings.set_link .. "]")
                                return msg.to.title .. '\n' .. data[tostring(msg.to.id)].settings.set_link
                            else
                                return langs[msg.lang].require_mod
                            end
                        else
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group link [" .. data[tostring(msg.to.id)].settings.set_link .. "]")
                            return msg.to.title .. '\n' .. data[tostring(msg.to.id)].settings.set_link
                        end
                    else
                        return langs[msg.lang].sendMeLink
                    end
                end
                if matches[1]:lower() == 'promoteadmin' then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            local cbreply_extra = {
                                get_cmd = 'promoteadmin',
                                msg = msg
                            }
                            get_message(msg.reply_id, get_message_callback, cbreply_extra)
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                channel_set_admin(get_receiver(msg), 'user#id' .. matches[2], check_admin_success, { receiver = get_receiver(msg), text = matches[2] .. langs[msg.lang].promoteSupergroupMod })
                            else
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), promote_telegram_admin_by_username, { executer = msg.from.id, chat_id = msg.to.id, receiver = get_receiver(msg) })
                            end
                        end
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'demoteadmin' then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            local cbreply_extra = {
                                get_cmd = 'demoteadmin',
                                msg = msg
                            }
                            get_message(msg.reply_id, get_message_callback, cbreply_extra)
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                local receiver = get_receiver(msg)
                                local user_id = "user#id" .. matches[2]
                                local get_cmd = 'demoteadmin'
                                if compare_ranks(msg.from.id, matches[2], msg.to.id) then
                                    channel_demote(get_receiver(msg), user_id, check_admin_success, { receiver = get_receiver(msg), text = result.peer_id .. langs[msg.lang].demoteSupergroupMod })
                                    return
                                else
                                    send_large_msg(get_receiver(msg), langs[msg.lang].cantDemoteOtherAdmin)
                                    return
                                end
                            else
                                local cbres_extra = {
                                    channel = get_receiver(msg),
                                    get_cmd = 'demoteadmin'
                                }
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted admin @" .. string.gsub(matches[2], '@', ''))
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), callbackres, cbres_extra)
                                return
                            end
                        end
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'setowner' then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            local cbreply_extra = {
                                get_cmd = 'setowner',
                                msg = msg
                            }
                            get_message(msg.reply_id, get_message_callback, cbreply_extra)
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                data[tostring(msg.to.id)]['set_owner'] = tostring(matches[2])
                                save_data(_config.moderation.data, data)
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set [" .. matches[2] .. "] as owner")
                                return matches[2] .. langs[msg.lang].setOwner
                            else
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), setowner_by_username, { receiver = get_receiver(msg), chat_id = msg.to.id })
                                return
                            end
                        end
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'promote' or matches[1]:lower() == "sasha promuovi" or matches[1]:lower() == "promuovi" then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            local cbreply_extra = {
                                get_cmd = 'promote',
                                msg = msg
                            }
                            get_message(msg.reply_id, get_message_callback, cbreply_extra)
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] promoted user#id" .. matches[2])
                                promote2(get_receiver(msg), 'NONAME', user_id)
                            else
                                local cbres_extra = {
                                    channel = get_receiver(msg),
                                    get_cmd = 'promote',
                                }
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] promoted @" .. string.gsub(matches[2], '@', ''))
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), callbackres, cbres_extra)
                                return
                            end
                        end
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'demote' or matches[1]:lower() == "sasha degrada" or matches[1]:lower() == "degrada" then
                    if is_owner(msg) then
                        if type(msg.reply_id) ~= "nil" then
                            local cbreply_extra = {
                                get_cmd = 'demote',
                                msg = msg
                            }
                            get_message(msg.reply_id, get_message_callback, cbreply_extra)
                        elseif matches[2] and matches[2] ~= '' then
                            if string.match(matches[2], '^%d+$') then
                                local get_cmd = 'demote'
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted user#id" .. matches[2])
                                demote2(get_receiver(msg), matches[2], matches[2])
                            else
                                local cbres_extra = {
                                    channel = get_receiver(msg),
                                    get_cmd = 'demote'
                                }
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] demoted @" .. string.gsub(matches[2], '@', ''))
                                resolve_username(string.match(matches[2], '^[^%s]+'):gsub('@', ''), callbackres, cbres_extra)
                                return
                            end
                        end
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
            end
            if matches[1]:lower() == "setname" then
                if is_momod(msg) then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] renamed SuperGroup to: " .. string.gsub(matches[2], '_', ''))
                    rename_channel(get_receiver(msg), string.gsub(matches[2], '_', ''), ok_cb, false)
                else
                    return langs[msg.lang].require_mod
                end
            end
            if msg.service then
                if msg.action then
                    if msg.action.type == 'chat_rename' then
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] renamed SuperGroup to: " .. msg.to.title)
                        data[tostring(msg.to.id)].set_name = msg.to.title
                        save_data(_config.moderation.data, data)
                    end
                end
            end
            if matches[1]:lower() == "setabout" or matches[1]:lower() == "sasha imposta descrizione" then
                if is_momod(msg) then
                    data[tostring(msg.to.id)]['description'] = matches[2]
                    save_data(_config.moderation.data, data)
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set SuperGroup description to: " .. matches[2])
                    channel_set_about(get_receiver(msg), matches[2], ok_cb, false)
                    return langs[msg.lang].newDescription .. matches[2]
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == "setusername" then
                if is_admin1(msg) then
                    local function ok_username_cb(extra, success, result)
                        if success == 1 then
                            send_large_msg(extra.receiver, langs[msg.lang].supergroupUsernameChanged)
                        elseif success == 0 then
                            send_large_msg(extra.receiver, langs[msg.lang].errorChangeUsername)
                        end
                    end
                    channel_set_username(get_receiver(msg), string.gsub(matches[2], '@', ''), ok_username_cb, { receiver = get_receiver(msg) })
                else
                    return langs[msg.lang].require_admin
                end
            end
            if not msg.api_patch then
                if matches[1]:lower() == 'setrules' or matches[1]:lower() == "sasha imposta regole" then
                    if is_momod(msg) then
                        data[tostring(msg.to.id)]['rules'] = matches[2]
                        save_data(_config.moderation.data, data)
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] has changed group rules to [" .. matches[2] .. "]")
                        return langs[msg.lang].newRules .. matches[2]
                    else
                        return langs[msg.lang].require_mod
                    end
                end
            end
            if msg.media then
                if data[tostring(msg.to.id)].set_photo then
                    if msg.media.type == 'photo' and data[tostring(msg.to.id)].set_photo == 'waiting' and is_momod(msg) then
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set new SuperGroup photo")
                        load_photo(msg.id, set_supergroup_photo, msg)
                        return
                    end
                end
            end
            if matches[1]:lower() == 'setphoto' then
                if is_momod(msg) then
                    data[tostring(msg.to.id)].set_photo = 'waiting'
                    save_data(_config.moderation.data, data)
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] started setting new SuperGroup photo")
                    return langs[msg.lang].sendNewGroupPic
                else
                    return langs[msg.lang].require_mod
                end
            end
            if matches[1]:lower() == 'clean' then
                if is_owner(msg) then
                    if not msg.api_patch then
                        if matches[2]:lower() == 'modlist' then
                            if next(data[tostring(msg.to.id)]['moderators']) == nil then
                                return langs[msg.lang].noGroupMods
                            end
                            for k, v in pairs(data[tostring(msg.to.id)]['moderators']) do
                                data[tostring(msg.to.id)]['moderators'][tostring(k)] = nil
                                save_data(_config.moderation.data, data)
                            end
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned modlist")
                            return langs[msg.lang].modlistCleaned
                        end
                        if matches[2]:lower() == 'rules' then
                            local data_cat = 'rules'
                            if data[tostring(msg.to.id)][data_cat] == nil then
                                return langs[msg.lang].noRules
                            end
                            data[tostring(msg.to.id)][data_cat] = nil
                            save_data(_config.moderation.data, data)
                            savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned rules")
                            return langs[msg.lang].rulesCleaned
                        end
                    end
                    if matches[2]:lower() == 'about' then
                        local receiver = get_receiver(msg)
                        local about_text = ' '
                        local data_cat = 'description'
                        if data[tostring(msg.to.id)][data_cat] == nil then
                            return langs[msg.lang].noDescription
                        end
                        data[tostring(msg.to.id)][data_cat] = nil
                        save_data(_config.moderation.data, data)
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] cleaned about")
                        channel_set_about(get_receiver(msg), about_text, ok_cb, false)
                        return langs[msg.lang].descriptionCleaned
                    end
                    if not msg.api_patch then
                        if matches[2]:lower() == 'mutelist' then
                            chat_id = msg.to.id
                            local hash = 'mute_user:' .. chat_id
                            redis:del(hash)
                            return langs[msg.lang].mutelistCleaned
                        end
                    end
                    if matches[2]:lower() == 'username' then
                        if is_admin1(msg) then
                            local function ok_username_cb(extra, success, result)
                                if success == 1 then
                                    send_large_msg(extra.receiver, langs[msg.lang].usernameCleaned)
                                elseif success == 0 then
                                    send_large_msg(extra.receiver, langs[msg.lang].errorCleanUsername)
                                end
                            end
                            local username = ""
                            channel_set_username(get_receiver(msg), username, ok_username_cb, { receiver = get_receiver(msg) })
                        else
                            return langs[msg.lang].require_admin
                        end
                    end
                    if matches[2] == "bots" then
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] kicked all SuperGroup bots")
                        channel_get_bots(get_receiver(msg), callback_clean_bots, { msg = msg })
                    end
                else
                    return langs[msg.lang].require_owner
                end
            end
            if not msg.api_patch then
                if matches[1]:lower() == 'lock' or matches[1]:lower() == "sasha blocca" or matches[1]:lower() == "blocca" then
                    if is_momod(msg) then
                        if checkMatchesLockUnlock(matches[2]) then
                            return lockSetting(msg.to.id, matches[2]:lower())
                        end
                        return
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'unlock' or matches[1]:lower() == "sasha sblocca" or matches[1]:lower() == "sblocca" then
                    if is_momod(msg) then
                        if checkMatchesLockUnlock(matches[2]) then
                            return unlockSetting(msg.to.id, matches[2]:lower())
                        end
                        return
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'setflood' then
                    if is_momod(msg) then
                        if tonumber(matches[2]) < 3 or tonumber(matches[2]) > 20 then
                            return langs[msg.lang].errorFloodRange
                        end
                        data[tostring(msg.to.id)].settings['flood_max'] = matches[2]
                        save_data(_config.moderation.data, data)
                        savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] set flood to [" .. matches[2] .. "]")
                        return langs[msg.lang].floodSet .. matches[2]
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'setwarn' and matches[2] then
                    if is_momod(msg) then
                        local txt = set_warn(msg.from.id, msg.to.id, matches[2])
                        if matches[2] == '0' then
                            return langs[msg.lang].neverWarn
                        else
                            return txt
                        end
                    else
                        return langs[msg.lang].require_mod
                    end
                end
                if matches[1]:lower() == 'getwarn' then
                    return get_warn(msg.to.id)
                end
                if matches[1]:lower() == 'mute' or matches[1]:lower() == 'silenzia' then
                    if is_owner(msg) then
                        if checkMatchesMuteUnmute(matches[2]) then
                            return mute(msg.to.id, matches[2]:lower())
                        end
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == 'unmute' or matches[1]:lower() == 'ripristina' then
                    if is_owner(msg) then
                        if checkMatchesMuteUnmute(matches[2]) then
                            return unmute(msg.to.id, matches[2]:lower())
                        end
                        return
                    else
                        return langs[msg.lang].require_owner
                    end
                end
                if matches[1]:lower() == "muteslist" or matches[1]:lower() == "lista muti" then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup muteslist")
                    return mutes_list(msg.to.id, msg.to.print_name)
                end
                if matches[1]:lower() == 'settings' then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested SuperGroup settings ")
                    return showSettings(msg.to.id, msg.lang)
                end
                if matches[1]:lower() == 'rules' or matches[1]:lower() == "sasha regole" then
                    savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] requested group rules")
                    if not data[tostring(msg.to.id)]['rules'] then
                        return langs[msg.lang].noRules
                    end
                    return data[tostring(msg.to.id)].set_name .. ' ' .. langs[msg.lang].rules .. '\n\n' .. data[tostring(msg.to.id)]['rules']
                end
            end
            if matches[1]:lower() == 'kill' and matches[2]:lower() == 'supergroup' then
                if is_super_group(msg) then
                    print("Closing Group: " .. get_receiver(msg))
                    data[tostring(msg.to.id)] = nil
                    data.groups[tostring(msg.to.id)] = nil
                    save_data(_config.moderation.data, data)
                    reply_msg(msg.id, langs[msg.lang].supergroupRemoved, ok_cb, false)
                    leave_channel('channel#id' .. msg.to.id, ok_cb, false)
                    return
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'peer_id' then
                if is_admin1(msg) then
                    text = msg.to.peer_id
                    reply_msg(msg.id, text, ok_cb, false)
                    post_large_msg(get_receiver(msg), text)
                else
                    return langs[msg.lang].require_admin
                end
            end
            if matches[1]:lower() == 'msg.to.id' then
                if is_admin1(msg) then
                    text = msg.to.id
                    reply_msg(msg.id, text, ok_cb, false)
                    post_large_msg(get_receiver(msg), text)
                else
                    return langs[msg.lang].require_admin
                end
            end
            -- Admin Join Service Message
            if msg.service then
                if msg.action then
                    if not msg.api_patch then
                        if msg.action.type == 'chat_add_user_link' then
                            if is_owner2(msg.from.id) then
                                local receiver = get_receiver(msg)
                                local user = "user#id" .. msg.from.id
                                savelog(msg.to.id, name_log .. " Admin [" .. msg.from.id .. "] joined the SuperGroup via link")
                                channel_set_admin(get_receiver(msg), user, ok_cb, false)
                            end
                        end
                        if msg.action.type == 'chat_add_user' then
                            if is_owner2(msg.action.user.id) then
                                local receiver = get_receiver(msg)
                                local user = "user#id" .. msg.action.user.id
                                savelog(msg.to.id, name_log .. " Admin [" .. msg.action.user.id .. "] added to the SuperGroup by [ " .. msg.from.id .. " ]")
                                channel_set_admin(get_receiver(msg), user, ok_cb, false)
                            end
                        end
                    end
                end
            end
            if matches[1]:lower() == 'msg.to.peer_id' then
                post_large_msg(get_receiver(msg), msg.to.peer_id)
            end
        end
    end
end

return {
    description = "GROUP_MANAGEMENT",
    patterns =
    {
        -- INPM
        "^[#!/]([Cc][Hh][Aa][Tt][Ss])$",
        "^[#!/]([Cc][Hh][Aa][Tt][Ll][Ii][Ss][Tt])$",
        "^[#!/]([Jj][Oo][Ii][Nn]) (%d+)$",
        "^[#!/]([Aa][Ll][Ll][Cc][Hh][Aa][Tt][Ss])$",
        "^[#!/]([Aa][Ll][Ll][Cc][Hh][Aa][Tt][Ss][Ll][Ii][Ss][Tt])$",
        "^[#!/]([Ss][Ee][Tt][Aa][Ll][Ii][Aa][Ss]) ([^%s]+) (%d+)$",
        "^[#!/]([Uu][Nn][Ss][Ee][Tt][Aa][Ll][Ii][Aa][Ss]) ([^%s]+)$",
        "^[#!/]([Gg][Ee][Tt][Aa][Ll][Ii][Aa][Ss][Ll][Ii][Ss][Tt])$",
        -- join
        "^[#!/]([Jj][Oo][Ii][Nn]) (.*)$",
        "^[#!/]([Ii][Nn][Vv][Ii][Tt][Ee][Mm][Ee]) (.*)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Nn][Vv][Ii][Tt][Aa][Mm][Ii]) (.*)$",
        "^([Ii][Nn][Vv][Ii][Tt][Aa][Mm][Ii]) (.*)$",

        -- INREALM
        "^[#!/]([Cc][Rr][Ee][Aa][Tt][Ee][Gg][Rr][Oo][Uu][Pp]) (.*)$",
        "^[#!/]([Cc][Rr][Ee][Aa][Tt][Ee][Ss][Uu][Pp][Ee][Rr]) (.*)$",
        "^[#!/]([Cc][Rr][Ee][Aa][Tt][Ee][Rr][Ee][Aa][Ll][Mm]) (.*)$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Gg][Rr][Oo][Uu][Pp]) (%d+)$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Ss][Uu][Pp][Ee][Rr][Gg][Rr][Oo][Uu][Pp]) (%d+)$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Rr][Ee][Aa][Ll][Mm]) (%d+)$",
        "^[#!/]([Rr][Ee][Mm]) (%d+)$",
        "^[#!/]([Aa][Dd][Dd][Aa][Dd][Mm][Ii][Nn]) ([^%s]+)$",
        "^[#!/]([Rr][Ee][Mm][Oo][Vv][Ee][Aa][Dd][Mm][Ii][Nn]) ([^%s]+)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Oo][Ww][Nn][Ee][Rr]) (%d+) (%d+)$",-- (group id) (owner id)
        "^[#!/]([Ll][Ii][Ss][Tt]) ([^%s]+)$",
        "^[#!/]([Ll][Oo][Cc][Kk]) (%d+) ([^%s]+)$",
        "^[#!/]([Uu][Nn][Ll][Oo][Cc][Kk]) (%d+) ([^%s]+)$",
        "^[#!/]([Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss]) (%d+)$",
        "^[#!/]([Ss][Uu][Pp][Ee][Rr][Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss]) (%d+)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Rr][Uu][Ll][Ee][Ss]) (%d+) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Ss][Uu][Pp][Ee][Rr][Gg][Rr][Oo][Uu][Pp][Aa][Bb][Oo][Uu][Tt]) (%d+) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Rr][Oo][Uu][Pp][Aa][Bb][Oo][Uu][Tt]) (%d+) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Gg][Pp][Nn][Aa][Mm][Ee]) (%d+) (.*)$",
        -- creategroup
        "^([Ss][Aa][Ss][Hh][Aa] [Cc][Rr][Ee][Aa] [Gg][Rr][Uu][Pp][Pp][Oo]) (.*)$",
        -- createsuper
        "^([Ss][Aa][Ss][Hh][Aa] [Cc][Rr][Ee][Aa] [Ss][Uu][Pp][Ee][Rr][Gg][Rr][Uu][Pp][Pp][Oo]) (.*)$",
        -- createrealm
        "^([Ss][Aa][Ss][Hh][Aa] [Cc][Rr][Ee][Aa] [Rr][Ee][Gg][Nn][Oo]) (.*)$",
        -- lock
        "^([Ss][Aa][Ss][Hh][Aa] [Bb][Ll][Oo][Cc][Cc][Aa]) (%d+) ([^%s]+)$",
        "^([Bb][Ll][Oo][Cc][Cc][Aa]) (%d+) ([^%s]+)$",
        -- unlock
        "^([Ss][Aa][Ss][Hh][Aa] [Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (%d+) ([^%s]+)$",
        "^([Ss][Bb][Ll][Oo][Cc][Cc][Aa]) (%d+) ([^%s]+)$",

        -- INGROUP
        "^[#!/]([Aa][Dd][Dd]) ([Rr][Ee][Aa][Ll][Mm])$",
        "^[#!/]([Rr][Ee][Mm]) ([Rr][Ee][Aa][Ll][Mm])$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Gg][Rr][Oo][Uu][Pp])$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Rr][Ee][Aa][Ll][Mm])$",

        -- SUPERGROUP
        "^[#!/]([Gg][Ee][Tt][Aa][Dd][Mm][Ii][Nn][Ss])$",
        "^[#!/]([Bb][Oo][Tt][Ss])$",
        "^[#!/]([Tt][Oo][Ss][Uu][Pp][Ee][Rr])$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee][Aa][Dd][Mm][Ii][Nn]) ([^%s]+)$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee][Aa][Dd][Mm][Ii][Nn])",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee][Aa][Dd][Mm][Ii][Nn]) ([^%s]+)$",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee][Aa][Dd][Mm][Ii][Nn])",
        "^[#!/]([Ss][Ee][Tt][Uu][Ss][Ee][Rr][Nn][Aa][Mm][Ee]) (.*)$",
        "^[#!/]([Uu][Pp][Dd][Aa][Tt][Ee][Gg][Rr][Oo][Uu][Pp][Ii][Nn][Ff][Oo])$",
        "^[#!/]([Ss][Yy][Nn][Cc][Mm][Oo][Dd][Ll][Ii][Ss][Tt])$",
        "^[#!/]([Dd][Ee][Ll])$",
        "^[#!/]([Kk][Ii][Ll][Ll]) ([Ss][Uu][Pp][Ee][Rr][Gg][Rr][Oo][Uu][Pp])$",
        "^([Pp][Ee][Ee][Rr]_[Ii][Dd])$",
        "^([Mm][Ss][Gg].[Tt][Oo].[Ii][Dd])$",
        "^([Mm][Ss][Gg].[Tt][Oo].[Pp][Ee][Ee][Rr]_[Ii][Dd])$",
        -- getadmins
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Aa][Dd][Mm][Ii][Nn])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Aa][Dd][Mm][Ii][Nn])$",
        -- bots
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Bb][Oo][Tt])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Bb][Oo][Tt])$",

        -- COMMON
        "^[#!/]([Tt][Yy][Pp][Ee])$",
        "^[#!/]([Ll][Oo][Gg])$",
        "^[#!/@]([Aa][Dd][Mm][Ii][Nn][Ss]?)",
        "^[#!/]([Aa][Dd][Dd])$",
        "^[#!/]([Rr][Ee][Mm])$",
        "^[#!/]([Rr][Uu][Ll][Ee][Ss])$",
        "^[#!/]([Aa][Bb][Oo][Uu][Tt])$",
        "^[#!/]([Ss][Ee][Tt][Ff][Ll][Oo][Oo][Dd]) (%d+)$",
        "^[#!/]([Ss][Ee][Tt][Ww][Aa][Rr][Nn]) (%d+)$",
        "^[#!/]([Gg][Ee][Tt][Ww][Aa][Rr][Nn])$",
        "^[#!/]([Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss])$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee]) ([^%s]+)$",
        "^[#!/]([Pp][Rr][Oo][Mm][Oo][Tt][Ee])",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee]) ([^%s]+)$",
        "^[#!/]([Dd][Ee][Mm][Oo][Tt][Ee])",
        "^[#!/]([Mm][Uu][Tt][Ee][Ss][Ll][Ii][Ss][Tt])",
        "^[#!/]([Uu][Nn][Mm][Uu][Tt][Ee]) ([^%s]+)",
        "^[#!/]([Mm][Uu][Tt][Ee]) ([^%s]+)",
        "^[#!/]([Ss][Ee][Tt][Nn][Aa][Mm][Ee]) (.*)$",
        "^[#!/]([Nn][Ee][Ww][Ll][Ii][Nn][Kk])$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm]%.[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Ss][Ee][Tt][Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^[#!/]([Uu][Nn][Ss][Ee][Tt][Ll][Ii][Nn][Kk])$",
        "^[#!/]([Ll][Ii][Nn][Kk])$",
        "^[#!/]([Ss][Ee][Tt][Rr][Uu][Ll][Ee][Ss]) (.*)$",
        "^[#!/]([Ss][Ee][Tt][Aa][Bb][Oo][Uu][Tt]) (.*)$",
        "^[#!/]([Oo][Ww][Nn][Ee][Rr])$",
        "^[#!/]([Ll][Oo][Cc][Kk]) ([^%s]+)$",
        "^[#!/]([Uu][Nn][Ll][Oo][Cc][Kk]) ([^%s]+)$",
        "^[#!/]([Mm][Oo][Dd][Ll][Ii][Ss][Tt])$",
        "^[#!/]([Cc][Ll][Ee][Aa][Nn]) ([^%s]+)$",
        "^[#!/]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr]) ([^%s]+)$",
        "^[#!/]([Ss][Ee][Tt][Oo][Ww][Nn][Ee][Rr])$",
        "^[#!/]([Ss][Ee][Tt][Pp][Hh][Oo][Tt][Oo])$",
        "%[(photo)%]",
        "^!!tgservice (.+)$",
        -- rules
        "^([Ss][Aa][Ss][Hh][Aa] [Rr][Ee][Gg][Oo][Ll][Ee])$",
        -- about
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Ee][Ss][Cc][Rr][Ii][Zz][Ii][Oo][Nn][Ee])$",
        -- promote
        "^([Ss][Aa][Ss][Hh][Aa] [Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii]) ([^%s]+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii])$",
        "^([Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii]) ([^%s]+)$",
        "^([Pp][Rr][Oo][Mm][Uu][Oo][Vv][Ii])$",
        -- demote
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Ee][Gg][Rr][Aa][Dd][Aa]) ([^%s]+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Dd][Ee][Gg][Rr][Aa][Dd][Aa])$",
        "^([Dd][Ee][Gg][Rr][Aa][Dd][Aa]) ([^%s]+)$",
        "^([Dd][Ee][Gg][Rr][Aa][Dd][Aa])$",
        -- setrules
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Rr][Ee][Gg][Oo][Ll][Ee]) (.*)$",
        -- setabout
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Dd][Ee][Ss][Cc][Rr][Ii][Zz][Ii][Oo][Nn][Ee]) (.*)$",
        -- lock
        "^([Ss][Aa][Ss][Hh][Aa] [Bb][Ll][Oo][Cc][Cc][Aa]) ([^%s]+)$",
        "^([Bb][Ll][Oo][Cc][Cc][Aa]) ([^%s]+)$",
        -- unlock
        "^([Ss][Aa][Ss][Hh][Aa] [Ss][Bb][Ll][Oo][Cc][Cc][Aa]) ([^%s]+)$",
        "^([Ss][Bb][Ll][Oo][Cc][Cc][Aa]) ([^%s]+)$",
        -- modlist
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Ss][Tt][Aa] [Mm][Oo][Dd])$",
        "^([Ll][Ii][Ss][Tt][Aa] [Mm][Oo][Dd])$",
        -- newlink
        "^([Ss][Aa][Ss][Hh][Aa] [Cc][Rr][Ee][Aa] [Ll][Ii][Nn][Kk])$",
        -- link
        "^([Ss][Aa][Ss][Hh][Aa] [Ll][Ii][Nn][Kk])$",
        -- setlink
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt][Ll][Gg][Rr][Mm]%.[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Ii][Mm][Pp][Oo][Ss][Tt][Aa] [Ll][Ii][Nn][Kk]) ([Hh][Tt][Tt][Pp][Ss]://[Tt]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/%S+)$",
        -- unsetlink
        "^([Ss][Aa][Ss][Hh][Aa] [Ee][Ll][Ii][Mm][Ii][Nn][Aa] [Ll][Ii][Nn][Kk])$",
        -- mute
        "^([Ss][Ii][Ll][Ee][Nn][Zz][Ii][Aa]) ([^%s]+)$",
        -- unmute
        "^([Rr][Ii][Pp][Rr][Ii][Ss][Tt][Ii][Nn][Aa]) ([^%s]+)$",
        -- muteslist
        "^([Ll][Ii][Ss][Tt][Aa] [Mm][Uu][Tt][Ii])$",
    },
    run = run,
    min_rank = 1,
    syntax =
    {
        "USER",
        "#getwarn",
        "(#rules|sasha regole)",
        "(#about|sasha descrizione)",
        "(#modlist|[sasha] lista mod)",
        "#owner",
        "#admins [<reply>|<text>]",
        "(#link|sasha link)",
        "#settings",
        "(#muteslist|lista muti)",
        "MOD",
        "#type",
        "#setname <group_name>",
        "#setphoto",
        "(#setrules|sasha imposta regole) <text>",
        "(#setabout|sasha imposta descrizione) <text>",
        "(#newlink|sasha crea link)",
        "#setflood <value>",
        "#setwarn <value>",
        "(#lock|[sasha] blocca) arabic|bots|flood|grouplink|leave|link|member|name|photo|rtl|spam|strict",
        "(#unlock|[sasha] sblocca) arabic|bots|flood|grouplink|leave|link|member|name|photo|rtl|spam|strict",
        "SUPERGROUPS",
        "(#bots|[sasha] lista bot)",
        "#updategroupinfo",
        "#del <reply>",
        "OWNER",
        "#log",
        "(#setlink|sasha imposta link) <link>",
        "(#unsetlink|sasha elimina link)",
        "(#promote|[sasha] promuovi) <username>|<reply>",
        "(#demote|[sasha] degrada) <username>|<reply>",
        "#mute|silenzia all|audio|contact|document|gif|location|photo|sticker|text|tgservice|video|video_note|voice_note",
        "#unmute|ripristina all|audio|contact|document|gif|location|photo|sticker|text|tgservice|video|video_note|voice_note",
        "#setowner <id>|<username>|<reply>",
        "GROUPS",
        "#clean modlist|rules|about",
        "SUPERGROUPS",
        "(#getadmins|[sasha] lista admin)",
        "#syncmodlist",
        "#promoteadmin <id>|<username>|<reply>",
        "#demoteadmin <id>|<username>|<reply>",
        "#clean rules|about|modlist|mutelist",
        "ADMIN",
        "#add",
        "#rem",
        "ex INGROUP.LUA",
        "#add realm",
        "#rem realm",
        "#kill group|realm",
        "ex INPM.LUA",
        "(#join|#inviteme|[sasha] invitami) <chat_id>|<alias>",
        "#getaliaslist",
        "#allchats",
        "#allchatlist",
        "#setalias <alias> <group_id>",
        "#unsetalias <alias>",
        "SUPERGROUPS",
        "#tosuper",
        "#setusername <text>",
        "#kill supergroup",
        "peer_id",
        "msg.to.id",
        "msg.to.peer_id",
        "REALMS",
        "#setgpowner <group_id> <user_id>",
        "(#creategroup|sasha crea gruppo) <group_name>",
        "(#createsuper|sasha crea supergruppo) <group_name>",
        "(#createrealm|sasha crea regno) <realm_name>",
        "(#setabout|sasha imposta descrizione) <group_id> <text>",
        "(#setrules|sasha imposta regole) <group_id> <text>",
        "#setname <realm_name>",
        "#setname|#setgpname <group_id> <group_name>",
        "(#lock|[sasha] blocca) <group_id> arabic|bots|flood|grouplink|leave|link|member|name|photo|rtl|spam|strict",
        "(#unlock|[sasha] sblocca) <group_id> arabic|bots|flood|grouplink|leave|link|member|name|photo|rtl|spam|strict",
        "#settings <group_id>",
        "#type",
        "#kill group|supergroup|realm <group_id>",
        "#rem <group_id>",
    },
}
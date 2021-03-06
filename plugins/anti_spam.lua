-- An empty table for solving multiple kicking problem(thanks to @topkecleon )
kicktable = { }

local TIME_CHECK = 2
-- seconds
-- Save stats, ban user
local function pre_process(msg)
    if msg then
        -- Ignore service msg
        if msg.service then
            return msg
        end
        if msg.from.id == our_id then
            return msg
        end

        -- Save user on Redis
        if msg.from.type == 'user' then
            local hash = 'user:' .. msg.from.id
            print('Saving user', hash)
            if msg.from.print_name then
                redis:hset(hash, 'print_name', msg.from.print_name)
            end
            if msg.from.first_name then
                redis:hset(hash, 'first_name', msg.from.first_name)
            end
            if msg.from.last_name then
                redis:hset(hash, 'last_name', msg.from.last_name)
            end
        end

        if msg.to.type == 'user' then
            -- User is on chat
            local hash = 'PM:' .. msg.from.id
            redis:sadd(hash, msg.from.id)
        end

        -- Save stats on Redis
        if msg.to.type == 'chat' then
            -- User is on chat
            local hash = 'chat:' .. msg.to.id .. ':users'
            redis:sadd(hash, msg.from.id)
        end

        -- Save stats on Redis
        if msg.to.type == 'channel' then
            -- User is on channel
            local hash = 'channel:' .. msg.to.id .. ':users'
            redis:sadd(hash, msg.from.id)
        end

        -- Total user msgs
        local hash = 'msgs:' .. msg.from.id .. ':' .. msg.to.id
        redis:incr(hash)

        -- Load moderation data
        if data[tostring(msg.to.id)] then
            -- Check if flood is on or off
            if not data[tostring(msg.to.id)].settings.flood then
                return msg
            end
        end

        -- Check flood
        if msg.from.type == 'user' then
            local hash = 'cli:user:' .. msg.from.id .. ':msgs'
            local msgs = tonumber(redis:get(hash) or 0)

            if msg.to.type == 'user' then
                local max_msg = 7 * 1
                print(msgs)
                if msgs >= max_msg then
                    print("Pass2")
                    send_large_msg("user#id" .. msg.from.id, langs[msg.lang].user .. "[" .. msg.from.id .. "]" .. langs[msg.lang].blockedForSpam)
                    -- log
                    send_large_msg("channel#id1043389864", langs[msg.lang].user .. "[" .. msg.from.id .. "]" .. langs[msg.lang].blockedForSpam)
                    savelog(msg.from.id .. " PM", "User [" .. msg.from.id .. "] blocked for spam.")
                    -- block_user("user#id" .. msg.from.id, ok_cb, false)
                    -- Block user if spammed in private
                end
            else
                local continue = false
                if not msg.api_patch then
                    continue = true
                elseif msg.from.username then
                    if string.sub(msg.from.username:lower(), -3) == 'bot' then
                        continue = true
                    end
                end
                if continue then
                    local NUM_MSG_MAX = 5
                    if data[tostring(msg.to.id)] then
                        if data[tostring(msg.to.id)]['settings'] then
                            if data[tostring(msg.to.id)]['settings']['flood_max'] then
                                NUM_MSG_MAX = tonumber(data[tostring(msg.to.id)]['settings']['flood_max'])
                                -- Obtain group flood sensitivity
                            end
                        end
                    end
                    local max_msg = NUM_MSG_MAX * 1
                    if msgs >= max_msg then
                        local user = msg.from.id
                        local chat = msg.to.id
                        local whitelist = "whitelist"
                        local is_whitelisted = redis:sismember(whitelist, user)
                        -- Ignore mods,owner and admins
                        if is_momod(msg) then
                            return msg
                        end
                        if is_whitelisted == true then
                            return msg
                        end
                        local receiver = get_receiver(msg)
                        if kicktable[tostring(user)] == true then
                            return
                        end
                        delete_msg(msg.id, ok_cb, false)
                        local function post_kick()
                            kick_user(user, chat)
                        end
                        postpone(post_kick, false, 3)
                        local username = msg.from.username
                        local print_name = user_print_name(msg.from):gsub("‮", "")
                        local name_log = print_name:gsub("_", "")
                        if msg.to.type == 'chat' or msg.to.type == 'channel' then
                            if username then
                                savelog(msg.to.id, name_log .. " @" .. username .. " [" .. msg.from.id .. "] kicked for #spam")
                                send_large_msg(receiver, langs[msg.lang].floodNotAdmitted .. "@" .. username .. "[" .. msg.from.id .. "]\n" .. langs[msg.lang].statusRemoved .. " (SPAM)")
                            else
                                savelog(msg.to.id, name_log .. " [" .. msg.from.id .. "] kicked for #spam")
                                send_large_msg(receiver, langs[msg.lang].floodNotAdmitted .. langs[msg.lang].name .. name_log .. "[" .. msg.from.id .. "]\n" .. langs[msg.lang].statusRemoved .. " (SPAM)")
                            end
                        end
                        -- incr it on redis
                        local gbanspam = 'gban:spam' .. msg.from.id
                        redis:incr(gbanspam)
                        local gbanspam = 'gban:spam' .. msg.from.id
                        local gbanspamonredis = redis:get(gbanspam)
                        -- Check if user has spammed is group more than 4 times
                        if gbanspamonredis then
                            if tonumber(gbanspamonredis) == 4 and not is_owner(msg) then
                                -- Global ban that user
                                banall_user(msg.from.id)
                                local gbanspam = 'gban:spam' .. msg.from.id
                                -- reset the counter
                                redis:set(gbanspam, 0)
                                if msg.from.username ~= nil then
                                    username = msg.from.username
                                else
                                    username = "---"
                                end
                                local print_name = user_print_name(msg.from):gsub("‮", "")
                                local name = print_name:gsub("_", "")
                                -- Send this to that chat
                                send_large_msg("chat#id" .. msg.to.id, langs[msg.lang].user .. "[ " .. name .. " ]" .. msg.from.id .. langs[msg.lang].gbanned .. " (SPAM)")
                                send_large_msg("channel#id" .. msg.to.id, langs[msg.lang].user .. "[ " .. name .. " ]" .. msg.from.id .. langs[msg.lang].gbanned .. " (SPAM)")
                                local GBan_log = 'GBan_log'
                                local GBan_log = data[tostring(GBan_log)]
                                for k, v in pairs(GBan_log) do
                                    log_SuperGroup = v
                                    gban_text = langs[msg.lang].user .. "[ " .. name .. " ] ( @" .. username .. " )" .. msg.from.id .. langs[msg.lang].gbannedFrom .. "( " .. msg.to.print_name .. " ) [ " .. msg.to.id .. " ] (SPAM)"
                                    -- send it to log group/channel
                                    send_large_msg(log_SuperGroup, gban_text)
                                end
                            end
                        end
                        kicktable[tostring(user)] = true
                        msg = nil
                    end
                end
            end
            redis:setex(hash, TIME_CHECK, msgs + 1)
        end
        return msg
    end
end

local function cron()
    -- clear that table on the top of the plugin
    kicktable = { }
end

return {
    description = "ANTI_SPAM",
    cron = cron,
    patterns = { },
    pre_process = pre_process,
    min_rank = 6,
}
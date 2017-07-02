﻿-- Will leave the group if be added
local function run(msg, matches)
    if matches[1]:lower() == 'leave' or matches[1]:lower() == 'sasha abbandona' then
        if not msg.api_patch then
            if is_admin1(msg) then
                if not matches[2] then
                    chat_del_user(get_receiver(msg), 'user#id' .. our_id, ok_cb, false)
                    leave_channel(get_receiver(msg), ok_cb, false)
                else
                    chat_del_user("chat#id" .. matches[2], 'user#id' .. our_id, ok_cb, false)
                    leave_channel("channel#id" .. matches[2], ok_cb, false)
                end

            else
                return langs[msg.lang].require_admin
            end
        end
    elseif matches[1]:lower() == 'rebootapi' then
        if is_reboot_allowed(msg) then
            io.popen('kill -9 $(pgrep lua)'):read('*all')
            send_large_msg_SUDOERS(langs[msg.lang].apiReboot .. msg.from.print_name:gsub('_', ' ') .. ' ' .. msg.from.id)
            return langs[msg.lang].apiReboot .. msg.from.print_name:gsub('_', ' ') .. ' ' .. msg.from.id
        else
            return langs[msg.lang].require_authorized_or_sudo
        end
    elseif msg.service and msg.action.type == "chat_add_user" and msg.action.user.id == tonumber(our_id) and not is_admin1(msg) then
        chat_del_user(get_receiver(msg), 'user#id' .. our_id, ok_cb, false)
        leave_channel(get_receiver(msg), ok_cb, false)
        return langs[msg.lang].notMyGroup
    end
end

return {
    description = "ONSERVICE",
    patterns =
    {
        "^[#!/]([Ll][Ee][Aa][Vv][Ee]) (%d+)$",
        "^[#!/]([Ll][Ee][Aa][Vv][Ee])$",
        "^[#!/]([Rr][Ee][Bb][Oo][Oo][Tt][Aa][Pp][Ii])$",
        -- leave
        "^([Ss][Aa][Ss][Hh][Aa] [Aa][Bb][Bb][Aa][Nn][Dd][Oo][Nn][Aa]) (%d+)$",
        "^([Ss][Aa][Ss][Hh][Aa] [Aa][Bb][Bb][Aa][Nn][Dd][Oo][Nn][Aa])$",
        "^!!tgservice (.+)$",
    },
    run = run,
    min_rank = 3,
    syntax =
    {
        "ADMIN",
        "(#leave|sasha abbandona) [<group_id>]",
        "SUDO",
        "#rebootapi",
    },
}
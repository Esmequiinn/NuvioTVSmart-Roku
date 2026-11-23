function Iptv_PrefDefaults() as object
    return { size: "normal", nums: true, logos: true, names: true, twoLine: false, times: true, preview: true, nowLine: true, markPlaying: true, lastGroup: true, startLast: false, reverseZap: false, barSecs: 6, reconnect: true, backup: true, epgShift: 0, listHours: 12, epgHours: 6, rememberTracks: true, tmdbArt: true, pin: "" }
end function

function Iptv_Prefs() as object
    d = Iptv_PrefDefaults()
    p = St_Get("iptvPrefs_" + Str_Of(St_ActiveProfile().id), invalid)
    if type(p) = "roAssociativeArray"
        for each k in p
            d[k] = p[k]
        end for
    end if
    return d
end function

sub Iptv_SetPref(name as string, value as dynamic)
    key = "iptvPrefs_" + Str_Of(St_ActiveProfile().id)
    p = St_Get(key, invalid)
    if type(p) <> "roAssociativeArray" then p = {}
    p[name] = value
    St_Set(key, p)
end sub

function Iptv_Store(kind as string) as object
    v = St_Get("iptv" + kind + "_" + Str_Of(St_ActiveProfile().id), invalid)
    if type(v) = "roAssociativeArray" then return v
    return {}
end function

sub Iptv_SaveStore(kind as string, v as object)
    St_Set("iptv" + kind + "_" + Str_Of(St_ActiveProfile().id), v)
end sub

function Iptv_SizeSpec(size as string) as object
    if size = "compact" then return { step: 64, h: 58, title: 22, time: 19, name: 22, num: 22, logoW: 80, logoH: 44, nameW: 220 }
    if size = "large" then return { step: 102, h: 94, title: 30, time: 24, name: 28, num: 28, logoW: 128, logoH: 72, nameW: 280 }
    return { step: 80, h: 72, title: 25, time: 21, name: 24, num: 24, logoW: 104, logoH: 56, nameW: 250 }
end function

sub Iptv_SetFont(label as object, size as integer, bold as boolean)
    if bold then label.font = "font:MediumBoldSystemFont" else label.font = "font:MediumSystemFont"
    label.font.size = size
end sub

sub Iptv_FontSizes(root as object, sizes as object)
    for each id in sizes
        n = root.findNode(id)
        if n <> invalid and n.font <> invalid then n.font.size = sizes[id]
    end for
end sub

function Iptv_Reminders() as object
    v = St_Get("iptvReminders_" + Str_Of(St_ActiveProfile().id), invalid)
    if type(v) = "roArray" then return v
    return []
end function

sub Iptv_SaveReminders(list as object)
    St_Set("iptvReminders_" + Str_Of(St_ActiveProfile().id), list)
end sub

function Iptv_ReminderMap() as object
    out = {}
    for each r in Iptv_Reminders()
        out[Str_Of(r.k) + "|" + ToInt(r.a, 0).ToStr()] = true
    end for
    return out
end function

function Iptv_All() as object
    out = []
    list = St_Get("iptvLists", invalid)
    if type(list) = "roArray"
        for each it in list
            if type(it) = "roAssociativeArray" and Str_Of(it.id) <> "" then out.Push(it)
        end for
    end if
    return out
end function

function Iptv_Pid() as string
    return Str_Of(St_ActiveProfile().id)
end function

function Iptv_Visible(lst as object, pid as string) as boolean
    owner = Str_Of(lst.owner)
    return owner = "" or owner = pid or Bool_Of(lst.shared, false)
end function

function Iptv_Mine(lst as object) as boolean
    owner = Str_Of(lst.owner)
    return owner = "" or owner = Iptv_Pid()
end function

function Iptv_Lists() as object
    pid = Iptv_Pid()
    out = []
    for each lst in Iptv_All()
        if Iptv_Visible(lst, pid) then out.Push(lst)
    end for
    return out
end function

sub Iptv_SaveLists(list as object)
    pid = Iptv_Pid()
    out = []
    for each lst in Iptv_All()
        if not Iptv_Visible(lst, pid) then out.Push(lst)
    end for
    for each lst in list
        if Str_Of(lst.owner) = "" then lst.owner = pid
        out.Push(lst)
    end for
    St_Set("iptvLists", out)
end sub

function Iptv_OwnerName(lst as object) as string
    owner = Str_Of(lst.owner)
    if owner = "" then return ""
    for each p in St_Profiles()
        if Str_Of(p.id) = owner then return Str_Of(p.name)
    end for
    return ""
end function

function Iptv_GuideUrls(lst as object, info as dynamic) as object
    out = []
    custom = Iptv_EpgList(Str_Of(lst.epg))
    for each u in custom
        out.Push(u)
    end for
    if custom.Count() = 0 or Bool_Of(lst.epgAdd, false)
        listed = invalid
        if type(info) = "roAssociativeArray" then listed = info.list
        if type(listed) <> "roArray" and type(info) = "roAssociativeArray" and not Bool_Of(info.custom, false) then listed = info.urls
        if type(listed) = "roArray"
            for each u in listed
                dup = false
                for each prev in out
                    if prev = u then dup = true
                end for
                if not dup then out.Push(u)
            end for
        end if
    end if
    return out
end function

function Iptv_EpgList(text as string) as object
    out = []
    flat = text.Replace(chr(10), ",").Replace(chr(13), ",").Replace(" ", ",").Replace(";", ",")
    for each part in flat.Split(",")
        u = part.Trim()
        if u <> "" then out.Push(u)
    end for
    return out
end function

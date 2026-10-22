function St_Section() as object
    return CreateObject("roRegistrySection", "nuviotv")
end function

function St_Get(key as string, fallback as dynamic) as dynamic
    sec = St_Section()
    if not sec.Exists(key) then return fallback
    raw = sec.Read(key)
    if raw = "" then return fallback
    data = ParseJson(raw)
    if data = invalid then return fallback
    return data
end function

sub St_Set(key as string, value as dynamic)
    sec = St_Section()
    sec.Write(key, FormatJson(value))
    sec.Flush()
end sub

sub St_Remove(key as string)
    sec = St_Section()
    if sec.Exists(key)
        sec.Delete(key)
        sec.Flush()
    end if
end sub

function St_Colors() as object
    return [
        { name: L("Morado"), hex: "7C5CFF" }
        { name: L("Azul"), hex: "3D8BFF" }
        { name: L("Turquesa"), hex: "19C3B1" }
        { name: L("Verde"), hex: "3CCB6C" }
        { name: L("Naranja"), hex: "FF9A1F" }
        { name: L("Rojo"), hex: "FF4D5E" }
        { name: L("Rosa"), hex: "FF5CA8" }
    ]
end function

function St_ColorName(hex as string) as string
    for each c in St_Colors()
        if c.hex = UCase(hex) then return c.name
    end for
    return "#" + hex
end function

function St_RowSizes() as object
    return [20, 40, 60, 100]
end function

function St_Settings() as object
    s = St_Get("settings", invalid)
    if type(s) <> "roAssociativeArray" then s = {}
    if not IsBool(s.shared) then s.shared = true
    if not IsStr(s.active) then s.active = ""
    return s
end function

sub St_SaveSettings(s as object)
    St_Set("settings", s)
end sub

function St_Profiles() as object
    list = St_Get("profiles", invalid)
    clean = []
    if type(list) = "roArray"
        for each p in list
            if type(p) = "roAssociativeArray" and IsStr(p.id) and IsStr(p.name)
                clean.Push({ id: p.id, name: p.name, color: Str_Of(p.color), remote: ToInt(p.remote, 0), avatar: Str_Of(p.avatar) })
            end if
        end for
    end if
    if clean.Count() = 0
        clean.Push({ id: "p1", name: L("Principal") })
        St_Set("profiles", clean)
    end if
    return clean
end function

function St_ProfileIndex(profiles as object, pid as string) as integer
    for i = 0 to profiles.Count() - 1
        if profiles[i].id = pid then return i
    end for
    return -1
end function

function St_ActiveProfile() as object
    profiles = St_Profiles()
    idx = St_ProfileIndex(profiles, St_Settings().active)
    if idx < 0 then idx = 0
    return profiles[idx]
end function

function St_SetActiveProfile(pid as string) as boolean
    if St_ProfileIndex(St_Profiles(), pid) < 0 then return false
    s = St_Settings()
    s.active = pid
    St_SaveSettings(s)
    return true
end function

function St_AddProfile(name as string) as dynamic
    clean = name.Trim()
    if clean = "" then return invalid
    profiles = St_Profiles()
    if profiles.Count() >= 8 then return invalid
    stamp = CreateObject("roDateTime").AsSeconds()
    pid = "p" + stamp.ToStr() + Rnd(999).ToStr()
    profile = { id: pid, name: Left(clean, 24) }
    profiles.Push(profile)
    St_Set("profiles", profiles)
    return profile
end function

function St_RenameProfile(pid as string, name as string) as boolean
    clean = name.Trim()
    if clean = "" then return false
    profiles = St_Profiles()
    idx = St_ProfileIndex(profiles, pid)
    if idx < 0 then return false
    profiles[idx].name = Left(clean, 24)
    St_Set("profiles", profiles)
    return true
end function

function St_DeleteProfile(pid as string) as boolean
    profiles = St_Profiles()
    if profiles.Count() <= 1 then return false
    idx = St_ProfileIndex(profiles, pid)
    if idx < 0 then return false
    profiles.Delete(idx)
    St_Set("profiles", profiles)
    St_Remove("addons_" + pid)
    St_Remove("prefs_" + pid)
    St_Remove("progress_" + pid)
    St_Remove("library_" + pid)
    s = St_Settings()
    if s.active = pid
        s.active = profiles[0].id
        St_SaveSettings(s)
    end if
    return true
end function

sub St_SetShared(value as boolean)
    s = St_Settings()
    if s.shared = value then return
    current = St_Addons()
    s.shared = value
    St_SaveSettings(s)
    if St_Addons().Count() = 0 and current.Count() > 0 then St_SaveAddons(current)
end sub

function St_AddonsKey() as string
    if St_Settings().shared then return "addons"
    return "addons_" + St_ActiveProfile().id
end function

function St_Addons() as object
    list = St_Get(St_AddonsKey(), invalid)
    clean = []
    if type(list) = "roArray"
        for each u in list
            if IsStr(u) and u <> "" then clean.Push(u)
        end for
    end if
    return clean
end function

sub St_SaveAddons(list as object)
    St_Set(St_AddonsKey(), list)
    St_MarkDirty("addons")
end sub

function St_NormalizeUrl(raw as dynamic) as string
    if not IsStr(raw) then return ""
    url = raw.Trim()
    if LCase(Left(url, 10)) = "stremio://" then url = "https://" + Mid(url, 11)
    if LCase(Right(url, 14)) = "/manifest.json" then url = Left(url, Len(url) - 14)
    while Len(url) > 0 and Right(url, 1) = "/"
        url = Left(url, Len(url) - 1)
    end while
    if url <> "" and Instr(1, url, "://") = 0 then url = "https://" + url
    return url
end function

function St_AddAddon(raw as dynamic) as boolean
    url = St_NormalizeUrl(raw)
    valid = CreateObject("roRegex", "^https?://([^/\s:@]+\.[^/\s:@]+|localhost)(:\d+)?(/|$)", "i")
    if not valid.IsMatch(url) then return false
    list = St_Addons()
    for each u in list
        if LCase(u) = LCase(url) then return false
    end for
    list.Push(url)
    St_SaveAddons(list)
    return true
end function

function St_RemoveAddon(index as integer) as boolean
    list = St_Addons()
    if index < 0 or index >= list.Count() then return false
    list.Delete(index)
    St_SaveAddons(list)
    return true
end function

function St_MoveAddon(index as integer, delta as integer) as integer
    list = St_Addons()
    target = index + delta
    if index < 0 or index >= list.Count() or target < 0 or target >= list.Count() then return index
    tmp = list[index]
    list[index] = list[target]
    list[target] = tmp
    St_SaveAddons(list)
    return target
end function

function St_PrefsKey() as string
    return "prefs_" + St_ActiveProfile().id
end function

function St_Prefs() as object
    p = St_Get(St_PrefsKey(), invalid)
    if type(p) <> "roAssociativeArray" then p = {}
    if not IsStr(p.accent) then p.accent = "7C5CFF"
    p.rowSize = ToInt(p.rowSize, 40)
    if p.rowSize < 10 then p.rowSize = 40
    if not IsBool(p.continueWatching) then p.continueWatching = true
    if not IsBool(p.captions) then p.captions = false
    if type(p.order) <> "roArray" then p.order = []
    if type(p.hidden) <> "roAssociativeArray" then p.hidden = {}
    return p
end function

sub St_SavePrefs(p as object)
    St_Set(St_PrefsKey(), p)
    St_MarkDirty("settings")
    St_MarkDirty("catalogs")
end sub

sub St_MarkDirty(kind as string)
    pid = St_ActiveProfile().id
    d = St_Get("syncdirty_" + pid, invalid)
    if type(d) <> "roAssociativeArray" then d = {}
    d[kind] = true
    St_Set("syncdirty_" + pid, d)
    if m.global <> invalid
        if m.global.hasField("syncDirty") then m.global.syncDirty = m.global.syncDirty + 1
    end if
end sub

function St_SyncDirty(pid as string) as object
    d = St_Get("syncdirty_" + pid, invalid)
    if type(d) <> "roAssociativeArray" then d = {}
    return d
end function

sub St_ClearDirty(pid as string, kinds as object)
    d = St_SyncDirty(pid)
    for each k in kinds
        if d.DoesExist(k) then d.Delete(k)
    end for
    St_Set("syncdirty_" + pid, d)
end sub

sub St_LibraryOp(op as string, entry as object)
    pid = St_ActiveProfile().id
    ops = St_Get("libops_" + pid, invalid)
    if type(ops) <> "roArray" then ops = []
    out = []
    for each o in ops
        if type(o) = "roAssociativeArray" and Str_Of(o.id) <> entry.id then out.Push(o)
    end for
    out.Push({ op: op, id: entry.id, kind: Str_Of(entry.kind), name: Left(Str_Of(entry.name), 80), poster: Str_Of(entry.poster) })
    while out.Count() > 30
        out.Shift()
    end while
    St_Set("libops_" + pid, out)
    St_MarkDirty("library")
end sub

function St_ClientId() as string
    id = Str_Of(St_Get("clientId", ""))
    if Len(id) >= 16 then return id
    chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    id = "roku"
    for i = 1 to 28
        id = id + Mid(chars, Rnd(Len(chars)), 1)
    end for
    St_Set("clientId", id)
    return id
end function

function St_SetAccent(hex as string) as boolean
    for each c in St_Colors()
        if c.hex = UCase(hex)
            p = St_Prefs()
            p.accent = c.hex
            St_SavePrefs(p)
            return true
        end if
    end for
    return false
end function

function St_SetRowSize(size as integer) as boolean
    for each s in St_RowSizes()
        if s = size
            p = St_Prefs()
            p.rowSize = size
            St_SavePrefs(p)
            return true
        end if
    end for
    return false
end function

sub St_SetFlag(name as string, value as boolean)
    p = St_Prefs()
    p[name] = value
    St_SavePrefs(p)
end sub

function St_CatalogKey(manifest as object, base as string, cat as object) as string
    prefix = Str_Of(manifest.id)
    if prefix = "" then prefix = base
    return prefix + "|" + Str_Of(cat["type"]) + "|" + Str_Of(cat.id)
end function

function St_ApplyOrder(all as object, order as object) as object
    byKey = {}
    for each c in all
        byKey[c.key] = c
    end for
    result = []
    used = {}
    if type(order) = "roArray"
        for each k in order
            if IsStr(k)
                if byKey.DoesExist(k) and not used.DoesExist(k)
                    result.Push(byKey[k])
                    used[k] = true
                end if
            end if
        end for
    end if
    for each c in all
        if not used.DoesExist(c.key)
            result.Push(c)
            used[c.key] = true
        end if
    end for
    return result
end function

sub St_SetCatalogHidden(catalogs as object, key as string, hidden as boolean)
    p = St_Prefs()
    if hidden
        p.hidden[key] = true
    else if p.hidden.DoesExist(key)
        p.hidden.Delete(key)
    end if
    St_SavePrefs(p)
    for each c in catalogs
        if c.key = key then c.hidden = hidden
    end for
end sub

function St_MoveCatalog(catalogs as object, key as string, delta as integer) as boolean
    idx = -1
    for i = 0 to catalogs.Count() - 1
        if catalogs[i].key = key
            idx = i
            exit for
        end if
    end for
    target = idx + delta
    if idx < 0 or target < 0 or target >= catalogs.Count() then return false
    tmp = catalogs[idx]
    catalogs[idx] = catalogs[target]
    catalogs[target] = tmp
    keys = []
    for each c in catalogs
        keys.Push(c.key)
    end for
    p = St_Prefs()
    p.order = keys
    St_SavePrefs(p)
    return true
end function

function St_ProgressKey() as string
    return "progress_" + St_ActiveProfile().id
end function

function St_Progress() as object
    list = St_Get(St_ProgressKey(), invalid)
    clean = []
    if type(list) = "roArray"
        for each e in list
            if type(e) = "roAssociativeArray" and IsStr(e.metaId) and IsStr(e.videoId)
                clean.Push(e)
            end if
        end for
    end if
    return clean
end function

sub St_SaveProgress(entry as object)
    if entry.updated = invalid then entry.updated = CreateObject("roDateTime").AsSeconds()
    out = [entry]
    for each e in St_Progress()
        if e.metaId <> entry.metaId and out.Count() < 12 then out.Push(e)
    end for
    St_Set(St_ProgressKey(), out)
    St_MarkDirty("progress")
end sub

function St_ResumeFor(videoId as string) as integer
    for each e in St_Progress()
        if e.videoId = videoId then return ToInt(e.position, 0)
    end for
    return 0
end function

sub St_RemoveProgress(metaId as string)
    out = []
    found = false
    for each e in St_Progress()
        if e.metaId = metaId
            found = true
        else
            out.Push(e)
        end if
    end for
    if found then St_Set(St_ProgressKey(), out)
end sub

sub St_ClearProgress()
    St_Remove(St_ProgressKey())
end sub

function St_ProfileColors() as object
    return ["7C4DFF", "2F80ED", "27AE60", "F2994A", "EB5757", "E056FD", "16A085", "F2C94C"]
end function

function St_ProfileColor(index as integer) as string
    profiles = St_Profiles()
    if index >= 0 and index < profiles.Count()
        if profiles[index].color <> "" then return UCase(profiles[index].color)
    end if
    colors = St_ProfileColors()
    if index < 0 then index = 0
    return colors[index mod colors.Count()]
end function

function St_ActiveProfileIndex() as integer
    profiles = St_Profiles()
    idx = St_ProfileIndex(profiles, St_Settings().active)
    if idx < 0 then idx = 0
    return idx
end function

function St_LibraryKey() as string
    return "library_" + St_ActiveProfile().id
end function

function St_Library() as object
    list = St_Get(St_LibraryKey(), invalid)
    clean = []
    if type(list) = "roArray"
        for each e in list
            if type(e) = "roAssociativeArray" and IsStr(e.id) then clean.Push(e)
        end for
    end if
    return clean
end function

function St_InLibrary(id as string) as boolean
    for each e in St_Library()
        if e.id = id then return true
    end for
    return false
end function

function St_ToggleLibrary(entry as object) as boolean
    list = St_Library()
    out = []
    found = false
    for each e in list
        if e.id = entry.id
            found = true
        else
            out.Push(e)
        end if
    end for
    if not found
        out.Unshift({ id: entry.id, kind: Str_Of(entry.kind), name: Left(Str_Of(entry.name), 80), poster: Str_Of(entry.poster) })
        while out.Count() > 40
            out.Pop()
        end while
    end if
    St_Set(St_LibraryKey(), out)
    if found then St_LibraryOp("remove", entry) else St_LibraryOp("add", entry)
    return not found
end function

function Key_Tmdb(integ as object) as string
    if Str_Of(integ.tmdbKey) <> "" then return integ.tmdbKey
    return Config_TmdbKey()
end function

function Key_TraktId(integ as object) as string
    if Config_TraktClientId() <> "" then return Config_TraktClientId()
    return Str_Of(integ.traktClientId)
end function

function Key_TraktSecret(integ as object) as string
    if Config_TraktClientSecret() <> "" then return Config_TraktClientSecret()
    return Str_Of(integ.traktSecret)
end function

function Key_SimklId(integ as object) as string
    if Config_SimklClientId() <> "" then return Config_SimklClientId()
    return Str_Of(integ.simklClientId)
end function

function St_Integrations() as object
    s = St_Get("integrations", invalid)
    if type(s) <> "roAssociativeArray" then s = {}
    defaults = {
        tmdbKey: ""
        tmdbEnabled: false
        tmdbArtwork: true
        mdbKey: ""
        mdbEnabled: false
        mdbShow: { imdb: true, tomatoes: true, audience: true, metacritic: true, letterboxd: true, tmdb: false, trakt: false }
        traktClientId: ""
        traktSecret: ""
        traktToken: ""
        traktRefresh: ""
        traktUser: ""
        simklClientId: ""
        simklToken: ""
        simklUser: ""
        scrobble: true
        nuvioUrl: Config_NuvioServer()
        nuvioKey: ""
        nuvioAccess: ""
        nuvioRefresh: ""
        nuvioEmail: ""
        nuvioLastSync: ""
    }
    for each k in defaults
        if s[k] = invalid then s[k] = defaults[k]
    end for
    if type(s.mdbShow) <> "roAssociativeArray" then s.mdbShow = defaults.mdbShow
    if Str_Of(s["nuvioUrl"]) = "" then s["nuvioUrl"] = defaults.nuvioUrl
    return s
end function

sub St_SaveIntegrations(s as object)
    St_Set("integrations", s)
end sub

sub St_SetIntegration(name as string, value as dynamic)
    s = St_Integrations()
    s[name] = value
    St_SaveIntegrations(s)
end sub

function St_PlayerDefaults() as object
    return {
        cwStyle: "landscape"
        audioLang: "system"
        audioLang2: "none"
        subLang: "spa"
        subLang2: "off"
        forcedSubs: false
        openSubs: true
        pauseOverlay: true
        autoNext: true
        clock: true
        tmdbLanguage: "es-MX"
        showAddonName: false
        showTypeSuffix: true
        autoplayMode: "manual"
        autoplayRegex: ""
        autoplayScope: "all"
        autoplayAddons: []
        autoplayTimeout: 3
        reuseLink: false
        reuseHours: 24
        bingeNext: true
        bingeReuse: false
        expandPoster: true
        expandDelay: 3
        expandTrailer: false
        expandMuted: true
        trailerTarget: "hero"
        trailerButton: true
        trailerAutoplay: false
        trailerDelay: 7
        customPoster: ""
        posterScreens: "home,continue_watching,library,search,details"
        sizeBadges: true
        addonLogo: true
        badgePlace: "bottom"
        fusionBadges: true
    }
end function

function St_FilePaths(name as string) as object
    return ["cachefs:/" + name + ".json", "tmp:/" + name + ".json"]
end function

function St_ReadFile(name as string) as dynamic
    fs = CreateObject("roFileSystem")
    for each path in St_FilePaths(name)
        text = ""
        if fs = invalid
            text = ReadAsciiFile(path)
        else if fs.Exists(path)
            text = ReadAsciiFile(path)
        end if
        if text <> ""
            parsed = ParseJson(text)
            if parsed <> invalid then return parsed
        end if
    end for
    return invalid
end function

sub St_WriteFile(name as string, value as dynamic)
    text = FormatJson(value)
    for each path in St_FilePaths(name)
        if WriteAsciiFile(path, text) then return
    end for
end sub

function St_LinksKey() as string
    return "links_" + St_ActiveProfile().id
end function

function St_Links() as object
    links = St_ReadFile(St_LinksKey())
    if type(links) <> "roAssociativeArray" then links = {}
    return links
end function

function St_Now() as integer
    dt = CreateObject("roDateTime")
    return dt.AsSeconds()
end function

sub St_SaveLink(key as string, entry as object)
    links = St_Links()
    entry.at = St_Now()
    links[key] = entry
    while links.Count() > 14
        oldest = ""
        oldestAt = 2147483647
        for each k in links
            at = ToInt(links[k].at, 0)
            if at < oldestAt
                oldestAt = at
                oldest = k
            end if
        end for
        if oldest = "" then exit while
        links.Delete(oldest)
    end while
    St_WriteFile(St_LinksKey(), links)
end sub

function St_Link(key as string, maxAgeSeconds as integer) as dynamic
    entry = St_Links()[key]
    if type(entry) <> "roAssociativeArray" then return invalid
    if maxAgeSeconds > 0 and St_Now() - ToInt(entry.at, 0) > maxAgeSeconds then return invalid
    return entry
end function

sub St_SaveBadges(pid as string, rules as object)
    St_WriteFile("badges_" + pid, rules)
end sub

function St_Badges(pid as string) as object
    rules = St_ReadFile("badges_" + pid)
    if type(rules) = "roArray" then return rules
    return []
end function

sub St_ClearBadges(pid as string)
    fs = CreateObject("roFileSystem")
    for each path in St_FilePaths("badges_" + pid)
        if fs = invalid
            WriteAsciiFile(path, "")
        else
            fs.Delete(path)
        end if
    end for
end sub

function St_Pref(name as string) as dynamic
    p = St_Prefs()
    if p[name] <> invalid then return p[name]
    return St_PlayerDefaults()[name]
end function

sub St_SetPref(name as string, value as dynamic)
    p = St_Prefs()
    p[name] = value
    St_SavePrefs(p)
end sub

sub St_SetProfileColor(pid as string, hex as string)
    profiles = St_Profiles()
    idx = St_ProfileIndex(profiles, pid)
    if idx < 0 then return
    profiles[idx].color = hex
    St_Set("profiles", profiles)
end sub

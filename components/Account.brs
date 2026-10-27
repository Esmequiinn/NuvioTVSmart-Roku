function Trakt_Headers(integ as object, withAuth as boolean) as object
    h = { "trakt-api-version": "2", "trakt-api-key": Key_TraktId(integ) }
    if withAuth and integ.traktToken <> "" then h["Authorization"] = "Bearer " + integ.traktToken
    return h
end function

function Trakt_Code() as object
    integ = St_Integrations()
    if Key_TraktId(integ) = "" or Key_TraktSecret(integ) = "" then return { ok: false, error: L("Trakt no está disponible en esta versión del canal.") }
    r = Http_Request("POST", "https://api.trakt.tv/oauth/device/code", Trakt_Headers(integ, false), { client_id: Key_TraktId(integ) }, 15000)
    if r.code <> 200 or type(r.json) <> "roAssociativeArray" then return { ok: false, error: L("Trakt respondió con error ") + r.code.ToStr() + "." }
    return { ok: true, userCode: Str_Of(r.json.user_code), deviceCode: Str_Of(r.json.device_code), url: Str_Of(r.json.verification_url), interval: ToInt(r.json.interval, 5), expires: ToInt(r.json.expires_in, 600) }
end function

function Trakt_Poll(deviceCode as string) as object
    integ = St_Integrations()
    body = { code: deviceCode, client_id: Key_TraktId(integ), client_secret: Key_TraktSecret(integ) }
    r = Http_Request("POST", "https://api.trakt.tv/oauth/device/token", Trakt_Headers(integ, false), body, 15000)
    if r.code = 200 and type(r.json) = "roAssociativeArray"
        integ.traktToken = Str_Of(r.json.access_token)
        integ.traktRefresh = Str_Of(r.json.refresh_token)
        St_SaveIntegrations(integ)
        me = Http_Request("GET", "https://api.trakt.tv/users/settings", Trakt_Headers(integ, true), invalid, 10000)
        if type(me.json) = "roAssociativeArray" and type(me.json.user) = "roAssociativeArray"
            integ.traktUser = Str_Of(me.json.user.username)
            St_SaveIntegrations(integ)
        end if
        return { ok: true, status: "approved" }
    end if
    if r.code = 400 then return { ok: true, status: "pending" }
    if r.code = 429 then return { ok: true, status: "slow" }
    return { ok: false, status: "failed", error: L("El código expiró o fue rechazado.") }
end function

function Simkl_Url(path as string, integ as object) as string
    sep = "?"
    if Instr(1, path, "?") > 0 then sep = "&"
    return "https://api.simkl.com" + path + sep + "client_id=" + Key_SimklId(integ) + "&app-name=nuviotv-roku&app-version=2.1"
end function

function Simkl_Pin() as object
    integ = St_Integrations()
    if Key_SimklId(integ) = "" then return { ok: false, error: L("Simkl no está disponible en esta versión del canal.") }
    r = Http_Request("GET", Simkl_Url("/oauth/pin", integ), {}, invalid, 15000)
    if r.code <> 200 or type(r.json) <> "roAssociativeArray" then return { ok: false, error: L("Simkl respondió con error ") + r.code.ToStr() + "." }
    url = Str_Of(r.json.verification_url)
    if url = "" then url = Str_Of(r.json.verification_uri)
    return { ok: true, userCode: Str_Of(r.json.user_code), url: url, interval: ToInt(r.json.interval, 5), expires: ToInt(r.json.expires_in, 900) }
end function

function Simkl_Poll(userCode as string) as object
    integ = St_Integrations()
    r = Http_Request("GET", Simkl_Url("/oauth/pin/" + userCode, integ), {}, invalid, 15000)
    if type(r.json) = "roAssociativeArray"
        token = Str_Of(r.json.access_token)
        if token <> ""
            integ.simklToken = token
            St_SaveIntegrations(integ)
            me = Http_Request("POST", Simkl_Url("/users/settings", integ), { Authorization: "Bearer " + token }, {}, 10000)
            if type(me.json) = "roAssociativeArray" and type(me.json.user) = "roAssociativeArray"
                integ.simklUser = Str_Of(me.json.user.name)
                St_SaveIntegrations(integ)
            end if
            return { ok: true, status: "approved" }
        end if
        return { ok: true, status: "pending" }
    end if
    return { ok: true, status: "pending" }
end function

sub Scrobble_Send(action as string, p as object)
    integ = St_Integrations()
    if not integ.scrobble then return
    imdb = Str_Of(p.imdb)
    if imdb = "" then return
    progress = 0.0 + p.progress
    isShow = Bool_Of(p.isShow, false)
    season = ToInt(p.season, -1)
    episode = ToInt(p.episode, -1)
    if isShow and (season < 0 or episode < 0) then return
    body = { progress: progress }
    if isShow
        body.show = { ids: { imdb: imdb } }
        body.episode = { season: season, number: episode }
    else
        body.movie = { ids: { imdb: imdb } }
    end if
    if integ.traktToken <> ""
        Http_Request("POST", "https://api.trakt.tv/scrobble/" + action, Trakt_Headers(integ, true), body, 10000)
    end if
    if integ.simklToken <> ""
        Http_Request("POST", Simkl_Url("/scrobble/" + action, integ), { Authorization: "Bearer " + integ.simklToken }, body, 10000)
    end if
end sub

function Nuvio_Headers(integ as object, withSession as boolean) as object
    bearer = integ.nuvioKey
    if withSession and integ.nuvioAccess <> "" then bearer = integ.nuvioAccess
    return { apikey: integ.nuvioKey, Authorization: "Bearer " + bearer }
end function

function Nuvio_Configured(integ as object) as boolean
    return integ.nuvioUrl <> "" and integ.nuvioKey <> ""
end function

function Nuvio_Ensure() as boolean
    integ = St_Integrations()
    if Nuvio_Configured(integ) then return true
    if integ.nuvioUrl = "" then return false
    return Nuvio_Discover(integ.nuvioUrl, true).ok
end function

function Nuvio_Discover(raw as string, keepSession = false as boolean) as object
    url = raw.Trim()
    if url = "" then return { ok: false, error: L("Escribe la dirección del servidor.") }
    if Instr(1, url, "://") = 0 then url = "https://" + url
    while Right(url, 1) = "/"
        url = Left(url, Len(url) - 1)
    end while
    if Instr(1, url, "/.well-known/nuvio") = 0 then url = url + "/.well-known/nuvio"
    r = Http_Request("GET", url, {}, invalid, 15000)
    d = r.json
    if type(d) <> "roAssociativeArray" or LCase(Str_Of(d.service)) <> "nuvio" then return { ok: false, error: L("Esa dirección no tiene un servidor de Nuvio.") }
    backend = Str_Of(d.backend_url)
    key = Str_Of(d.publishable_key)
    if backend = "" or key = "" then return { ok: false, error: L("El servidor no publica su configuración completa.") }
    integ = St_Integrations()
    integ.nuvioUrl = backend
    integ.nuvioKey = key
    integ.nuvioAvatarBase = Str_Of(d.avatar_public_base_url)
    if not keepSession
        integ.nuvioAccess = ""
        integ.nuvioRefresh = ""
    end if
    St_SaveIntegrations(integ)
    return { ok: true }
end function

function Nuvio_SaveTokens(json as dynamic) as boolean
    if type(json) <> "roAssociativeArray" then return false
    access = Str_Of(json.access_token)
    refresh = Str_Of(json.refresh_token)
    if access = "" and type(json.session) = "roAssociativeArray"
        access = Str_Of(json.session.access_token)
        refresh = Str_Of(json.session.refresh_token)
    end if
    if access = "" then return false
    integ = St_Integrations()
    integ.nuvioAccess = access
    integ.nuvioRefresh = refresh
    if type(json.user) = "roAssociativeArray" and Str_Of(json.user.email) <> "" then integ.nuvioEmail = json.user.email
    St_SaveIntegrations(integ)
    return true
end function

function Nuvio_EmailLogin(email as string, password as string) as object
    if St_Integrations().nuvioUrl = "" then return { ok: false, error: L("No hay un servidor de Nuvio configurado. Agrégalo desde el celular (pestaña Cuenta).") }
    if not Nuvio_Ensure() then return { ok: false, error: L("No se pudo conectar con el servidor de Nuvio. Revisa la conexión a internet del Roku.") }
    integ = St_Integrations()
    r = Http_Request("POST", integ.nuvioUrl + "/auth/v1/token?grant_type=password", { apikey: integ.nuvioKey }, { email: email, password: password }, 15000)
    if r.code = 200 and Nuvio_SaveTokens(r.json)
        St_SetIntegration("nuvioEmail", email)
        return { ok: true }
    end if
    return { ok: false, error: L("Correo o contraseña incorrectos.") }
end function

function Nuvio_Refresh() as boolean
    integ = St_Integrations()
    if integ.nuvioRefresh = "" then return false
    r = Http_Request("POST", integ.nuvioUrl + "/auth/v1/token?grant_type=refresh_token", { apikey: integ.nuvioKey }, { refresh_token: integ.nuvioRefresh }, 15000)
    if r.code = 200 then return Nuvio_SaveTokens(r.json)
    return false
end function

function Nuvio_Anonymous() as boolean
    integ = St_Integrations()
    r = Http_Request("POST", integ.nuvioUrl + "/auth/v1/signup", Nuvio_Headers(integ, false), { data: { tv_client: "roku" } }, 15000)
    if r.code <> 200
        r = Http_Request("POST", integ.nuvioUrl + "/auth/v1/token?grant_type=anonymous", Nuvio_Headers(integ, false), {}, 15000)
    end if
    if r.code <> 200 then return false
    access = ""
    if type(r.json) = "roAssociativeArray" then access = Str_Of(r.json.access_token)
    if access = "" then return false
    m.anonAccess = access
    return true
end function

function Nuvio_Nonce() as string
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    out = ""
    for i = 1 to 32
        out = out + Mid(chars, Rnd(Len(chars)), 1)
    end for
    return out
end function

function Nuvio_QrStart() as object
    if St_Integrations().nuvioUrl = "" then return { ok: false, error: L("No hay un servidor de Nuvio configurado. Agrégalo desde el celular (pestaña Cuenta).") }
    if not Nuvio_Ensure() then return { ok: false, error: L("No se pudo conectar con el servidor de Nuvio. Revisa la conexión a internet del Roku.") }
    integ = St_Integrations()
    if not Nuvio_Anonymous() then return { ok: false, error: L("El servidor no permitió iniciar la sesión del televisor.") }
    nonce = Nuvio_Nonce()
    headers = { apikey: integ.nuvioKey, Authorization: "Bearer " + m.anonAccess }
    body = { p_device_nonce: nonce, p_redirect_base_url: Config_NuvioWeb() + "/link", p_device_type: "tv", p_device_name: "Roku" }
    r = Http_Request("POST", integ.nuvioUrl + "/rest/v1/rpc/start_device_login_session", headers, body, 15000)
    row = invalid
    if type(r.json) = "roArray" and r.json.Count() > 0 then row = r.json[0]
    if type(row) <> "roAssociativeArray"
        body = { p_device_nonce: nonce, p_redirect_base_url: Config_NuvioWeb() + "/tv-login", p_device_name: "Roku" }
        r = Http_Request("POST", integ.nuvioUrl + "/rest/v1/rpc/start_tv_login_session", headers, body, 15000)
        if type(r.json) = "roArray" and r.json.Count() > 0 then row = r.json[0]
        if type(r.json) = "roAssociativeArray" then row = r.json
    end if
    if type(row) <> "roAssociativeArray" then return { ok: false, error: L("El servidor no soporta el inicio de sesión con QR (") + r.code.ToStr() + ")." }
    code = Str_Of(row.device_code)
    if code = "" then code = Str_Of(row.code)
    userCode = Str_Of(row.user_code)
    if userCode = "" then userCode = code
    url = Str_Of(row.verification_uri_complete)
    if url = "" then url = Str_Of(row.qr_content)
    if url = "" then url = Str_Of(row.web_url)
    return { ok: true, code: code, userCode: userCode, url: url, nonce: nonce, anon: m.anonAccess, interval: ToInt(row.poll_interval_seconds, 3) }
end function

function Nuvio_QrPoll(code as string, nonce as string) as object
    integ = St_Integrations()
    anon = Str_Of(m.top.params.anon)
    headers = { apikey: integ.nuvioKey, Authorization: "Bearer " + anon }
    r = Http_Request("POST", integ.nuvioUrl + "/rest/v1/rpc/poll_tv_login_session", headers, { p_code: code, p_device_nonce: nonce }, 15000)
    status = ""
    if type(r.json) = "roArray" and r.json.Count() > 0 then status = LCase(Str_Of(r.json[0].status))
    if status = "approved" or status = "completed" or status = "confirmed"
        x = Http_Request("POST", integ.nuvioUrl + "/functions/v1/tv-logins-exchange", headers, { code: code, device_nonce: nonce }, 15000)
        if x.code = 200 and Nuvio_SaveTokens(x.json) then return { ok: true, status: "approved" }
        return { ok: false, status: "failed", error: L("No se pudo completar el inicio de sesión.") }
    end if
    if status = "expired" or status = "cancelled" or status = "rejected" then return { ok: false, status: "failed", error: L("El código expiró.") }
    return { ok: true, status: "pending" }
end function

function Nuvio_Call(method as string, path as string, body as dynamic) as object
    integ = St_Integrations()
    r = Http_Request(method, integ.nuvioUrl + path, Nuvio_Headers(integ, true), body, 20000)
    if r.code = 401 and Nuvio_Refresh()
        integ = St_Integrations()
        r = Http_Request(method, integ.nuvioUrl + path, Nuvio_Headers(integ, true), body, 20000)
    end if
    return r
end function

function Nuvio_Rpc(name as string, args as object) as dynamic
    r = Nuvio_Call("POST", "/rest/v1/rpc/" + name, args)
    if r.code >= 200 and r.code < 300 then return r.json
    return invalid
end function

function Nuvio_Select(table as string, query as string) as dynamic
    r = Nuvio_Call("GET", "/rest/v1/" + table + "?" + query, invalid)
    if r.code >= 200 and r.code < 300 and type(r.json) = "roArray" then return r.json
    return invalid
end function

function Nuvio_Owner() as string
    r = Nuvio_Call("POST", "/rest/v1/rpc/get_sync_owner", {})
    if r.code >= 200 and r.code < 300
        v = r.json
        if type(v) = "roArray" and v.Count() > 0 then v = v[0]
        if IsStr(v) and v.Trim() <> "" then return v.Trim()
        if type(v) = "roAssociativeArray"
            for each k in ["get_sync_owner", "owner_id", "user_id", "id"]
                if IsStr(v[k]) and v[k] <> "" then return v[k]
            end for
        end if
        if IsStr(r.body)
            t = r.body.Trim().Replace(chr(34), "")
            if Len(t) >= 32 and Instr(1, t, "{") = 0 and Instr(1, t, "[") = 0 then return t
        end if
    end if
    u = Nuvio_Call("GET", "/auth/v1/user", invalid)
    if type(u.json) = "roAssociativeArray" and IsStr(u.json.id) then return u.json.id
    return ""
end function

function Nuvio_Sync() as object
    Nuvio_Ensure()
    integ = St_Integrations()
    if not Nuvio_Configured(integ) or integ.nuvioAccess = "" then return { ok: false, error: L("No has iniciado sesión en Nuvio.") }
    if St_SyncDirty(St_ActiveProfile().id).Count() > 0 then Nuvio_Push()
    rows = Nuvio_Rpc("sync_pull_profiles", {})
    if type(rows) <> "roArray" then return { ok: false, error: L("No se pudieron leer tus perfiles de Nuvio.") }
    profiles = []
    usesPrimary = {}
    avatars = Nuvio_Avatars()
    for each row in rows
        if type(row) = "roAssociativeArray"
            index = ToInt(row.profile_index, ToInt(row.id, 0))
            if index > 0
                name = Str_Of(row.name)
                if name = "" then name = L("Perfil ") + index.ToStr()
                color = Str_Of(row.avatar_color_hex)
                if Left(color, 1) = "#" then color = Mid(color, 2)
                avatar = Str_Of(row.avatar_url).Trim()
                avatarId = Str_Any(row.avatar_id)
                if avatar = "" and avatarId <> "" and IsStr(avatars[avatarId]) then avatar = avatars[avatarId]
                profiles.Push({ id: "n" + index.ToStr(), name: Left(name, 24), color: UCase(Left(color, 6)), remote: index, avatar: avatar, primaryAddons: Bool_Of(row.uses_primary_addons, false) and index <> 1 })
                usesPrimary["n" + index.ToStr()] = Bool_Of(row.uses_primary_addons, false)
            end if
        end if
    end for
    if profiles.Count() = 0 then return { ok: false, error: L("Tu cuenta de Nuvio no tiene perfiles.") }
    St_Set("profiles", profiles)
    s = St_Settings()
    s.shared = false
    if St_ProfileIndex(profiles, s.active) < 0 then s.active = profiles[0].id
    St_SaveSettings(s)
    owner = Nuvio_Owner()
    counts = { addons: 0, library: 0, progress: 0 }
    for each p in profiles
        addonProfile = p.remote
        if usesPrimary[p.id] then addonProfile = 1
        addons = Nuvio_PullAddons(owner, addonProfile)
        if addons <> invalid
            St_Set("addons_" + p.id, addons)
            counts.addons = counts.addons + addons.Count()
        end if
        lib = Nuvio_PullLibrary(p.remote)
        if lib <> invalid
            St_Set("library_" + p.id, lib)
            counts.library = counts.library + lib.Count()
        end if
        progress = Nuvio_PullProgress(p.remote)
        if progress <> invalid
            pendingDel = St_ReadFile("progdel_" + p.id)
            if type(pendingDel) = "roArray" and pendingDel.Count() > 0
                skip = {}
                for each id in pendingDel
                    if IsStr(id) then skip[id] = true
                end for
                kept = []
                for each e in progress
                    if not skip.DoesExist(Str_Of(e.metaId)) then kept.Push(e)
                end for
                progress = kept
            end if
            progress = Nuvio_MergeProgress(p.id, progress)
            St_Set("progress_" + p.id, progress)
            counts.progress = counts.progress + progress.Count()
        end if
        Nuvio_PullSettings(p.id, p.remote, p.id = s.active)
        Nuvio_PullCollections(p.id, p.remote)
        Nuvio_PullWatched(p.id, p.remote)
    end for
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    St_SetIntegration("nuvioLastSync", now.AsDateString("short-month-short-weekday") + " " + Fmt_Clock(now))
    return { ok: true, profiles: profiles.Count(), addons: counts.addons, library: counts.library, progress: counts.progress }
end function

function Nuvio_Avatars() as object
    out = {}
    rows = Nuvio_Rpc("get_avatar_catalog", {})
    if type(rows) <> "roArray" then return out
    integ = St_Integrations()
    base = Str_Of(integ.nuvioAvatarBase)
    if base = "" then base = integ.nuvioUrl + "/storage/v1/object/public/avatars"
    while Right(base, 1) = "/"
        base = Left(base, Len(base) - 1)
    end while
    for each row in rows
        if type(row) = "roAssociativeArray"
            id = Str_Any(row.id)
            path = Str_Of(row.storage_path).Trim()
            while Left(path, 1) = "/"
                path = Mid(path, 2)
            end while
            if id <> "" and path <> "" then out[id] = base + "/" + path
        end if
    end for
    return out
end function

sub Nuvio_PullCollections(pid as string, index as integer)
    resp = Nuvio_Rpc("sync_pull_collections", { p_profile_id: index })
    if resp = invalid then return
    row = resp
    if type(resp) = "roArray"
        row = invalid
        if resp.Count() > 0 then row = resp[0]
    end if
    raw = row
    if type(row) = "roAssociativeArray" and row.collections_json <> invalid then raw = row.collections_json
    if IsStr(raw) then raw = ParseJson(raw)
    if type(raw) = "roAssociativeArray" and type(raw.collections) = "roArray" then raw = raw.collections
    out = []
    if type(raw) = "roArray"
        for each col in raw
            if type(col) = "roAssociativeArray" and Str_Any(col.id) <> "" and Str_Of(col.title) <> ""
                folders = []
                if type(col.folders) = "roArray"
                    for each folder in col.folders
                        if type(folder) = "roAssociativeArray" and Str_Any(folder.id) <> "" and Str_Of(folder.title) <> ""
                            sources = []
                            list = folder.sources
                            if type(list) <> "roArray" or list.Count() = 0 then list = folder.catalogSources
                            if type(list) = "roArray"
                                for each src in list
                                    if type(src) = "roAssociativeArray"
                                        provider = LCase(Str_Of(src.provider))
                                        if provider = "" or provider = "addon"
                                            base = Str_Of(src.addonBaseUrl)
                                            if base = "" then base = Str_Of(src.addon_base_url)
                                            addonId = Str_Of(src.addonId)
                                            if addonId = "" then addonId = Str_Of(src.addon_id)
                                            kind = LCase(Str_Of(src["type"]))
                                            catId = Str_Of(src.catalogId)
                                            if catId = "" then catId = Str_Of(src.catalog_id)
                                            title = Str_Of(src.title)
                                            if title = "" then title = Str_Of(src.catalogName)
                                            if (addonId <> "" or base <> "") and kind <> "" and catId <> "" then sources.Push({ provider: "addon", base: base, addonId: addonId, type: kind, catalogId: catId, title: title, genre: Str_Of(src.genre) })
                                        else if provider = "tmdb" and Str_Of(src.tmdbSourceType) <> ""
                                            sources.Push({ provider: "tmdb", tmdbSourceType: UCase(Str_Of(src.tmdbSourceType)), title: Str_Of(src.title), tmdbId: Str_Any(src.tmdbId), mediaType: UCase(Str_Of(src.mediaType)), sortBy: Str_Of(src.sortBy), filters: src.filters })
                                        else if provider = "trakt" and Str_Any(src.traktListId) <> ""
                                            sources.Push({ provider: "trakt", title: Str_Of(src.title), traktListId: Str_Any(src.traktListId), mediaType: UCase(Str_Of(src.mediaType)), sortBy: Str_Of(src.sortBy), sortHow: Str_Of(src.sortHow) })
                                        else if provider = "mdblist" and Str_Any(src.listId) <> ""
                                            sources.Push({ provider: "mdblist", title: Str_Of(src.title), listId: Str_Any(src.listId), mediaType: UCase(Str_Of(src.mediaType)) })
                                        end if
                                    end if
                                end for
                            end if
                            shape = LCase(Str_Of(folder.tileShape))
                            if shape = "wide" then shape = "landscape"
                            if shape <> "landscape" and shape <> "poster" then shape = "square"
                            gif = ""
                            if Bool_Of(folder.focusGifEnabled, true) then gif = Str_Of(folder.focusGifUrl)
                            folders.Push({ id: Str_Any(folder.id), title: Str_Of(folder.title), cover: Img_Fix(Str_Of(folder.coverImageUrl)), gif: Img_Fix(gif), emoji: Str_Of(folder.coverEmoji), hideTitle: Bool_Of(folder.hideTitle, false), logo: Img_Fix(Str_Of(folder.titleLogoUrl)), backdrop: Img_Fix(Str_Of(folder.heroBackdropUrl)), video: Str_Of(folder.heroVideoUrl), shape: shape, sources: sources })
                        end if
                    end for
                end if
                out.Push({ id: Str_Any(col.id), title: Str_Of(col.title), pin: Bool_Of(col.pinToTop, false), backdrop: Str_Of(col.backdropImageUrl), folders: folders })
            end if
        end for
    end if
    St_WriteFile("collections_" + pid, out)
end sub

function Nuvio_PullAddons(owner as string, index as integer) as dynamic
    rows = invalid
    if owner <> ""
        rows = Nuvio_Select("addons", "user_id=eq." + owner + "&profile_id=eq." + index.ToStr() + "&select=*&order=sort_order.asc")
        if rows = invalid or rows.Count() = 0
            tv = Nuvio_Select("tv_addons", "owner_id=eq." + owner + "&select=*&order=position.asc")
            if tv <> invalid and tv.Count() > 0 then rows = tv
        end if
    end if
    if rows = invalid or rows.Count() = 0
        rpc = Nuvio_Rpc("sync_pull_addons", { p_profile_id: index })
        if type(rpc) = "roArray" then rows = rpc
    end if
    if rows = invalid then return invalid
    items = []
    seen = {}
    for each row in rows
        if type(row) = "roAssociativeArray"
            url = Str_Of(row.url)
            if url = "" then url = Str_Of(row.base_url)
            enabled = Bool_Of(row.enabled, true)
            if url <> "" and enabled
                clean = St_NormalizeUrl(url)
                if not seen.DoesExist(clean)
                    seen[clean] = true
                    items.Push({ url: clean, order: ToInt(row.sort_order, ToInt(row.position, items.Count())) })
                end if
            end if
        end if
    end for
    if items.Count() = 0 then return invalid
    sorted = []
    while items.Count() > 0
        best = 0
        for i = 1 to items.Count() - 1
            if items[i].order < items[best].order then best = i
        end for
        sorted.Push(items[best].url)
        items.Delete(best)
    end while
    return sorted
end function

sub Nuvio_PullCatalogs(prefs as object, index as integer)
    resp = Nuvio_Rpc("sync_pull_home_catalog_settings", { p_profile_id: index, p_platform: "home_catalog_shared" })
    row = resp
    if type(resp) = "roArray"
        if resp.Count() = 0 then return
        row = resp[0]
    end if
    if type(row) <> "roAssociativeArray" then return
    data = row
    if row.settings_json <> invalid then data = row.settings_json
    if IsStr(data) then data = ParseJson(data)
    if type(data) <> "roAssociativeArray" or type(data.items) <> "roArray" then return
    entries = []
    for each item in data.items
        if type(item) = "roAssociativeArray"
            addonId = Str_Of(item.addon_id)
            kind = LCase(Str_Of(item["type"]))
            catId = Str_Of(item.catalog_id)
            colId = Str_Any(item.collection_id)
            if Bool_Of(item.is_collection, false) and colId <> ""
                entries.Push({ key: "col:" + colId, order: ToInt(item.order, entries.Count()), enabled: Bool_Of(item.enabled, true), title: "" })
            else if addonId <> "" and kind <> "" and catId <> ""
                entries.Push({ key: addonId + "|" + kind + "|" + catId, order: ToInt(item.order, entries.Count()), enabled: Bool_Of(item.enabled, true), title: Str_Of(item.custom_title).Trim() })
            end if
        end if
    end for
    if entries.Count() = 0 then return
    order = []
    hidden = {}
    titles = {}
    while entries.Count() > 0
        best = 0
        for i = 1 to entries.Count() - 1
            if entries[i].order < entries[best].order then best = i
        end for
        e = entries[best]
        order.Push(e.key)
        if not e.enabled then hidden[e.key] = true
        if e.title <> "" then titles[e.key] = e.title
        entries.Delete(best)
    end while
    prefs["order"] = order
    prefs["hidden"] = hidden
    prefs["titles"] = titles
end sub

function Nuvio_PullLibrary(index as integer) as dynamic
    rows = Nuvio_Rpc("sync_pull_library", { p_profile_id: index, p_limit: 100, p_offset: 0 })
    if type(rows) <> "roArray" then return invalid
    out = []
    for each row in rows
        if type(row) = "roAssociativeArray" and out.Count() < 40
            id = Str_Of(row.content_id)
            if id <> "" then out.Push({ id: id, kind: Str_Of(row.content_type), name: Left(Str_Of(row.name), 80), poster: Str_Of(row.poster) })
        end if
    end for
    return out
end function

function Nuvio_Ms(v as dynamic) as dynamic
    if v = invalid then return 0&
    if IsStr(v)
        t = v.Trim()
        if t = "" then return 0&
        if CreateObject("roRegex", "^[0-9]+$", "").IsMatch(t)
            n = ParseJson(t)
            if n <> invalid then return 0& + n
            return 0&
        end if
        dt = CreateObject("roDateTime")
        dt.FromISO8601String(t)
        return dt.AsSeconds() * 1000&
    end if
    return 0& + v
end function

function Nuvio_MergeProgress(pid as string, remote as object) as object
    local = St_Get("progress_" + pid, invalid)
    if type(local) <> "roArray" then local = []
    dirty = Bool_Of(St_SyncDirty(pid).progress, false)
    byId = {}
    for each e in local
        if type(e) = "roAssociativeArray" and IsStr(e.metaId) then byId[e.metaId] = e
    end for
    out = []
    seen = {}
    for each e in remote
        mine = byId[e.metaId]
        if mine <> invalid
            for each k in ["title", "poster", "background", "thumb"]
                if Str_Of(e[k]) = "" and Str_Of(mine[k]) <> "" then e[k] = mine[k]
            end for
            mineMs = Nuvio_Ms(mine.updatedMs)
            if mineMs = 0 and mine.updated <> invalid then mineMs = ToInt(mine.updated, 0) * 1000&
            if dirty and mineMs > Nuvio_Ms(e.updatedMs) then e = mine
        end if
        seen[e.metaId] = true
        out.Push(e)
    end for
    for each e in local
        if type(e) = "roAssociativeArray" and IsStr(e.metaId) and Bool_Of(e.nextUp, false) and not seen.DoesExist(e.metaId)
            seen[e.metaId] = true
            out.Push(e)
        end if
    end for
    if dirty
        for each e in local
            if type(e) = "roAssociativeArray" and IsStr(e.metaId) and not seen.DoesExist(e.metaId)
                seen[e.metaId] = true
                out.Push(e)
            end if
        end for
    end if
    sorted = []
    while out.Count() > 0 and sorted.Count() < 20
        best = 0
        bestMs = -1&
        for i = 0 to out.Count() - 1
            ms = Nuvio_Ms(out[i].updatedMs)
            if ms = 0 and out[i].updated <> invalid then ms = ToInt(out[i].updated, 0) * 1000&
            if ms > bestMs
                bestMs = ms
                best = i
            end if
        end for
        sorted.Push(out[best])
        out.Delete(best)
    end while
    return sorted
end function

function Nuvio_PullProgress(index as integer) as dynamic
    rows = Nuvio_Rpc("sync_pull_watch_progress", { p_profile_id: index })
    if type(rows) <> "roArray" then return invalid
    out = []
    latest = {}
    for each row in rows
        if type(row) = "roAssociativeArray"
            id = Str_Of(row.content_id)
            ms = Nuvio_Ms(row.last_watched)
            if id <> "" and (not latest.DoesExist(id) or ms > latest[id]) then latest[id] = ms
        end if
    end for
    taken = {}
    for each row in rows
        newest = false
        if type(row) = "roAssociativeArray" and not taken.DoesExist(Str_Of(row.content_id))
            top = latest[Str_Of(row.content_id)]
            newest = top = invalid or Nuvio_Ms(row.last_watched) >= top
        end if
        if newest
            id = Str_Of(row.content_id)
            kind = Str_Of(row.content_type)
            video = Str_Of(row.video_id)
            if video = "" or Left(video, 18) = "__nuvio_episode__:" then video = id
            secs = ToInt(row.position, 0)
            if row.position_ms <> invalid then secs = Int(ToInt(row.position_ms, 0) / 1000)
            dur = ToInt(row.duration, 0)
            if row.duration_ms <> invalid then dur = Int(ToInt(row.duration_ms, 0) / 1000)
            if secs > 86400 then secs = Int(secs / 1000)
            if dur > 86400 then dur = Int(dur / 1000)
            season = ToInt(row.season, -1)
            episode = ToInt(row.episode, -1)
            label = ""
            if season >= 0 and episode >= 0
                label = L("T") + season.ToStr() + ":E" + episode.ToStr()
                if video = id then video = id + ":" + season.ToStr() + ":" + episode.ToStr()
            end if
            if id <> "" and secs > 0 and (dur = 0 or secs < dur * 0.95)
                taken[id] = true
                out.Push({ metaId: id, videoId: video, kind: kind, title: Str_Of(row.name), poster: Str_Of(row.poster), background: Str_Of(row.background), episode: label, position: secs, duration: dur, season: season, ep: episode, updatedMs: Nuvio_Ms(row.last_watched) })
            end if
        end if
    end for
    return out
end function

function Nuvio_AudioPref(v as dynamic) as string
    c = Str_Of(v).Trim()
    if c = "" then return ""
    u = UCase(c)
    if u = "DEVICE" or u = "SYSTEM" then return "system"
    if u = "ORIGINAL" then return "original"
    if u = "DEFAULT" or u = "NONE" or u = "OFF" then return "none"
    return LCase(c)
end function

function Nuvio_SubPref(v as dynamic) as string
    c = LCase(Str_Of(v).Trim())
    if c = "" then return ""
    if c = "none" then return "off"
    if c = "force" or c = "forc" then return "forced"
    if c = "pt_br" or c = "br" or c = "pob" then return "pt-br"
    if c = "pt_pt" or c = "por" then return "pt"
    return c
end function

function Nuvio_ThemeAccent(th as object) as string
    name = UCase(Str_Of(th.selected_theme))
    if name = "CUSTOM"
        colors = th.custom_theme_colors
        if IsStr(colors) then colors = colors.Split(",")
        if type(colors) = "roAssociativeArray" then colors = [colors.first, colors.second, colors.third]
        if type(colors) = "roArray" and colors.Count() > 1 then return Nuvio_Hex(colors[1])
        return ""
    end if
    map = { WHITE: "F5F5F5", CRIMSON: "E53935", OCEAN: "1E88E5", VIOLET: "8E24AA", EMERALD: "43A047", AMBER: "FB8C00", ROSE: "D81B60", GOLD: "E8A91C", JADE: "22D37C", ROSE_GOLD: "EC70A9", ARCTIC_BLUE: "3185F5", GRAPHITE: "AAB2BE" }
    if map.DoesExist(name) then return map[name]
    return ""
end function

function Nuvio_Hex(v as dynamic) as string
    if IsStr(v)
        t = v.Trim()
        if Left(t, 1) = "#" then t = Mid(t, 2)
        if Len(t) = 8 then t = Mid(t, 3)
        if Len(t) = 6 and CreateObject("roRegex", "^[0-9a-fA-F]{6}$", "").IsMatch(t) then return UCase(t)
        if CreateObject("roRegex", "^-?[0-9]+$", "").IsMatch(t) then v = t.ToFloat() else return ""
    end if
    if v = invalid then return ""
    n = 0.0 + v
    if n < 0 then n = n + 4294967296.0
    rgb = n - Int(n / 16777216.0) * 16777216.0
    out = ""
    for each shift in [65536.0, 256.0, 1.0]
        part = Int(rgb / shift)
        rgb = rgb - part * shift
        out = out + Right("0" + LCase(StrI(part, 16)), 2)
    end for
    return UCase(out)
end function

sub Nuvio_SetBool(prefs as object, name as string, v as dynamic)
    if IsBool(v) then prefs[name] = v
end sub

sub Nuvio_PullSettings(pid as string, index as integer, primary as boolean)
    resp = Nuvio_Rpc("sync_pull_profile_settings_blob", { p_profile_id: index, p_platform: "tv" })
    row = resp
    if type(resp) = "roArray" and resp.Count() > 0 then row = resp[0]
    f = invalid
    if type(row) = "roAssociativeArray"
        blob = row.settings_json
        if IsStr(blob) then blob = ParseJson(blob)
        if type(blob) = "roAssociativeArray" and type(blob.features) = "roAssociativeArray" then f = Nuvio_Decode(blob.features)
    end if
    integ = St_Integrations()
    before = FormatJson(integ)
    found = invalid
    if primary
        found = Nuvio_MdbCredential(index)
        integ["mdbDiag"] = Str_Of(m.credDiag)
        if m.credTmdb <> invalid
            if m.credTmdb <> ""
                integ["tmdbKey"] = m.credTmdb
                integ["tmdbEnabled"] = true
                integ["tmdbFrom"] = "account"
            else if Str_Of(integ.tmdbFrom) = "account"
                integ["tmdbKey"] = ""
                integ["tmdbFrom"] = ""
            end if
        end if
    end if
    if found <> invalid
        if found <> ""
            integ["mdbKey"] = found
            integ["mdbEnabled"] = true
            integ["mdbFrom"] = "account"
        else if Str_Of(integ.mdbFrom) = "account"
            integ["mdbKey"] = ""
            linked = St_Integrations()
            integ["mdbEnabled"] = (Str_Of(linked.mdbRefresh) <> "" or Str_Of(linked.mdbAccess) <> "") and Bool_Of(integ.mdbEnabled, false)
            integ["mdbFrom"] = ""
        end if
    end if
    prefs = St_Get("prefs_" + pid, invalid)
    if type(prefs) <> "roAssociativeArray" then prefs = {}
    prefs = St_CaseFix(prefs, St_PlayerDefaults(), true)
    Nuvio_PullCatalogs(prefs, index)
    if f = invalid
        St_Set("prefs_" + pid, prefs)
        Nuvio_SaveIntegChanges(ParseJson(before), integ)
        return
    end if

    Nuvio_MapFeatures(prefs, f, integ, pid, primary, true)
    St_Set("prefs_" + pid, prefs)
    Nuvio_SaveIntegChanges(ParseJson(before), integ)
end sub

sub Nuvio_SaveIntegChanges(before as dynamic, after as object)
    if type(before) <> "roAssociativeArray" then before = {}
    fresh = St_Integrations()
    for each k in after
        if FormatJson([after[k]]) <> FormatJson([before[k]]) then fresh[k] = after[k]
    end for
    St_SaveIntegrations(fresh)
end sub

sub Nuvio_MapFeatures(prefs as object, f as object, integ as object, pid as string, primary as boolean, apply as boolean)
    pl = f.player_settings
    if type(pl) = "roAssociativeArray"
        a1 = Nuvio_AudioPref(pl.preferred_audio_language)
        if a1 <> "" then prefs["audioLang"] = a1
        a2 = Nuvio_AudioPref(pl.secondary_preferred_audio_language)
        if a2 = "" then a2 = "none"
        prefs["audioLang2"] = a2
        s1 = Nuvio_SubPref(pl.subtitle_preferred_language)
        s2 = Nuvio_SubPref(pl.subtitle_secondary_language)
        forced = pl.subtitle_use_forced_subtitles
        if s1 = "forced"
            forced = true
            if s2 <> "" and s2 <> "forced" and s2 <> "off" then s1 = s2 else s1 = "en"
            s2 = "off"
        end if
        if s2 = "forced"
            forced = true
            s2 = "off"
        end if
        if s1 <> "" then prefs["subLang"] = s1
        if s2 <> "" then prefs["subLang2"] = s2
        Nuvio_SetBool(prefs, "forcedSubs", forced)
        Nuvio_SetBool(prefs, "pauseOverlay", pl.pause_overlay_enabled)
        Nuvio_SetBool(prefs, "clock", pl.osd_clock_enabled)
        Nuvio_SetBool(prefs, "autoNext", pl.stream_auto_play_next_episode_enabled)
        Nuvio_SetBool(prefs, "bingeNext", pl.stream_auto_play_prefer_bingegroup_next_episode)
        Nuvio_SetBool(prefs, "bingeReuse", pl.stream_auto_play_reuse_binge_group)
        Nuvio_SetBool(prefs, "reuseLink", pl.stream_reuse_last_link_enabled)
        if pl.stream_reuse_last_link_cache_hours <> invalid then prefs["reuseHours"] = ToInt(pl.stream_reuse_last_link_cache_hours, 24)
        mode = UCase(Str_Of(pl.stream_auto_play_mode))
        if mode = "MANUAL" then prefs["autoplayMode"] = "manual"
        if mode = "FIRST_STREAM" then prefs["autoplayMode"] = "first"
        if mode = "REGEX_MATCH" then prefs["autoplayMode"] = "regex"
        scope = UCase(Str_Of(pl.stream_auto_play_source))
        if scope = "ALL_SOURCES" then prefs["autoplayScope"] = "all"
        if scope = "INSTALLED_ADDONS_ONLY" then prefs["autoplayScope"] = "addons"
        if scope = "ENABLED_PLUGINS_ONLY" then prefs["autoplayScope"] = "plugins"
        if IsStr(pl.stream_auto_play_regex) then prefs["autoplayRegex"] = pl.stream_auto_play_regex
        if type(pl.stream_auto_play_selected_addons) = "roArray"
            names = []
            for each n in pl.stream_auto_play_selected_addons
                if IsStr(n) and n.Trim() <> "" then names.Push(n.Trim())
            end for
            prefs["autoplayAddons"] = names
        end if
        Nuvio_SetBool(prefs, "skipIntro", pl.skip_intro_enabled)
        if type(pl.auto_skip_segment_types) = "roArray"
            types = {}
            for each t in pl.auto_skip_segment_types
                if IsStr(t) then types[LCase(t)] = true
            end for
            prefs["autoSkipIntro"] = types.DoesExist("intro")
            prefs["autoSkipRecap"] = types.DoesExist("recap")
            prefs["autoSkipOutro"] = types.DoesExist("outro")
            prefs["autoSkipCredits"] = types.DoesExist("movie-credits")
        end if
        Nuvio_SetBool(prefs, "preloadNext", pl.preload_next_episode_sources)
        Nuvio_SetBool(prefs, "bingeFallback", pl.stream_auto_play_next_episode_fallback_enabled)
        Nuvio_SetBool(prefs, "stillWatching", pl.still_watching_enabled)
        if pl.still_watching_episode_threshold <> invalid then prefs["stillCount"] = ToInt(pl.still_watching_episode_threshold, 3)
        tmode = UCase(Str_Of(pl.next_episode_threshold_mode))
        if tmode = "PERCENTAGE" then prefs["nextMode"] = "pct"
        if tmode = "MINUTES_BEFORE_END" then prefs["nextMode"] = "min"
        if pl.next_episode_threshold_percent_v2 <> invalid then prefs["nextPct"] = ToInt(pl.next_episode_threshold_percent_v2, 99)
        if pl.next_episode_threshold_minutes_before_end_v2 <> invalid then prefs["nextMin"] = ToInt(pl.next_episode_threshold_minutes_before_end_v2, 2)
        Nuvio_SetBool(prefs, "postPlay", pl.post_play_recommendations_enabled)
        if pl.post_play_movie_threshold_percent <> invalid then prefs["postPct"] = ToInt(pl.post_play_movie_threshold_percent, 96)
        Nuvio_SetBool(prefs, "parentalGuide", pl.parental_guide_enabled)
        Nuvio_SetBool(prefs, "stripSdh", pl.subtitle_strip_sdh)
        Nuvio_SetBool(prefs, "onlyPrefSubs", pl.subtitle_show_only_preferred_languages)
        if pl.stream_auto_play_timeout_seconds <> invalid
            t = ToInt(pl.stream_auto_play_timeout_seconds, 3)
            if t > 600 then t = -1
            prefs["autoplayTimeout"] = t
        end if
    end if

    ly = f.layout_settings
    if type(ly) = "roAssociativeArray"
        style = LCase(Str_Of(ly.continue_watching_card_style))
        if style = "poster" then prefs["cwStyle"] = "poster"
        if style = "card" or style = "wide" then prefs["cwStyle"] = "landscape"
        if IsStr(ly.custom_poster_url_pattern) then prefs["customPoster"] = ly.custom_poster_url_pattern.Trim()
        if IsStr(ly.custom_poster_enabled_screens)
            screens = ly.custom_poster_enabled_screens.Trim()
            if screens = "none" then screens = ""
            prefs["posterScreens"] = screens
        end if
        Nuvio_SetBool(prefs, "expandPoster", ly.focused_poster_backdrop_expand_enabled)
        if ly.focused_poster_backdrop_expand_delay_seconds <> invalid then prefs["expandDelay"] = ToInt(ly.focused_poster_backdrop_expand_delay_seconds, 3)
        Nuvio_SetBool(prefs, "expandTrailer", ly.focused_poster_backdrop_trailer_enabled)
        Nuvio_SetBool(prefs, "expandMuted", ly.focused_poster_backdrop_trailer_muted)
        target = LCase(Str_Of(ly.focused_poster_backdrop_trailer_playback_target))
        if target = "expanded_card" then prefs["trailerTarget"] = "card"
        if target = "hero_media" then prefs["trailerTarget"] = "hero"
        Nuvio_SetBool(prefs, "trailerButton", ly.detail_page_trailer_button_enabled)
        loc = UCase(Str_Of(ly.discover_location))
        if loc = "IN_SEARCH"
            prefs["discoverLocation"] = "search"
        else if loc = "IN_SIDEBAR"
            prefs["discoverLocation"] = "sidebar"
        else if loc = "OFF"
            prefs["discoverLocation"] = "off"
        else if IsBool(ly.search_discover_enabled)
            if ly.search_discover_enabled then prefs["discoverLocation"] = "search" else prefs["discoverLocation"] = "off"
        end if
    end if

    Nuvio_SetBool(prefs, "showAddonName", Nuvio_Get(f, "layout_settings", "catalog_addon_name_enabled"))
    Nuvio_SetBool(prefs, "showTypeSuffix", Nuvio_Get(f, "layout_settings", "catalog_type_suffix_enabled"))
    if type(pl) = "roAssociativeArray" then Nuvio_MapSubStyle(prefs, pl)

    tr = f.trailer_settings
    if type(tr) = "roAssociativeArray"
        Nuvio_SetBool(prefs, "trailerAutoplay", tr.trailer_enabled)
        if tr.trailer_delay_seconds <> invalid then prefs["trailerDelay"] = ToInt(tr.trailer_delay_seconds, 7)
    end if

    tm = f.tmdb_settings
    if type(tm) = "roAssociativeArray"
        lang = Str_Of(tm.tmdb_language)
        if lang <> "" then prefs["tmdbLanguage"] = lang
        if primary
            if IsBool(tm.tmdb_enabled) and Key_Tmdb(integ) <> "" then integ["tmdbEnabled"] = tm.tmdb_enabled
            if IsBool(tm.tmdb_use_artwork) then integ["tmdbArtwork"] = tm.tmdb_use_artwork
        end if
    end if

    md = f.mdblist_settings
    if primary and type(md) = "roAssociativeArray"
        key = Str_Of(md.mdblist_api_key).Trim()
        if key <> ""
            integ["mdbKey"] = key
            integ["mdbFrom"] = "account"
        end if
        if IsBool(md.mdblist_enabled) and key <> "" then integ["mdbEnabled"] = md.mdblist_enabled
        flags = { imdb: "mdblist_show_imdb", tomatoes: "mdblist_show_tomatoes", audience: "mdblist_show_audience", metacritic: "mdblist_show_metacritic", letterboxd: "mdblist_show_letterboxd", tmdb: "mdblist_show_tmdb", trakt: "mdblist_show_trakt" }
        for each k in flags
            if IsBool(md[flags[k]]) then integ.mdbShow[k] = md[flags[k]]
        end for
    end if

    th = f.theme_settings
    if type(th) = "roAssociativeArray"
        accent = Nuvio_ThemeAccent(th)
        if accent <> "" then prefs["accent"] = accent
    end if

    sb = f.stream_badge_settings
    if type(sb) = "roAssociativeArray"
        Nuvio_SetBool(prefs, "sizeBadges", sb.show_file_size_badges)
        Nuvio_SetBool(prefs, "addonLogo", sb.show_addon_logo)
        if UCase(Str_Of(sb.stream_badge_placement)) = "TOP" then prefs["badgePlace"] = "top" else prefs["badgePlace"] = "bottom"
        rules = Badge_Compact(sb.stream_badge_rules)
        if apply
            if rules.Count() > 0
                St_SaveBadges(pid, rules)
            else
                St_ClearBadges(pid)
            end if
        end if
    end if

end sub

function Nuvio_NowMs() as dynamic
    return CreateObject("roDateTime").AsSeconds() * 1000&
end function

function Nuvio_Push() as object
    Nuvio_Ensure()
    integ = St_Integrations()
    if not Nuvio_Configured(integ) or integ.nuvioAccess = "" then return { ok: false, error: L("No has iniciado sesión en Nuvio.") }
    profile = St_ActiveProfile()
    index = ToInt(profile.remote, 0)
    if index <= 0 then return { ok: false, error: L("Este perfil no está vinculado a Nuvio.") }
    pid = profile.id
    dirty = St_SyncDirty(pid)
    done = []
    if Bool_Of(dirty.addons, false)
        if Bool_Of(profile.primaryAddons, false) or Nuvio_PushAddons(index)
            done.Push("addons")
        end if
    end if
    if Bool_Of(dirty.library, false) and Nuvio_PushLibrary(pid, index) then done.Push("library")
    if Bool_Of(dirty.progress, false) and Nuvio_PushProgress(index) then done.Push("progress")
    if Bool_Of(dirty.watched, false) and Nuvio_PushWatched(pid, index) then done.Push("watched")
    if Bool_Of(dirty.settings, false) and Nuvio_PushSettings(pid, index) then done.Push("settings")
    if Bool_Of(dirty.catalogs, false) and Nuvio_PushCatalogs(pid, index) then done.Push("catalogs")
    St_ClearDirty(pid, done)
    return { ok: true, pushed: done }
end function

function Nuvio_PushAddons(index as integer) as boolean
    owner = Nuvio_Owner()
    remote = invalid
    if owner <> "" then remote = Nuvio_Select("addons", "user_id=eq." + owner + "&profile_id=eq." + index.ToStr() + "&select=*&order=sort_order.asc")
    if remote = invalid
        rpc = Nuvio_Rpc("sync_pull_addons", { p_profile_id: index })
        if type(rpc) = "roArray" then remote = rpc
    end if
    if remote = invalid then return false
    byUrl = {}
    for each row in remote
        if type(row) = "roAssociativeArray"
            url = Str_Of(row.url)
            if url = "" then url = Str_Of(row.base_url)
            if url <> "" then byUrl[St_NormalizeUrl(url)] = row
        end if
    end for
    items = []
    used = {}
    for each url in St_Addons()
        clean = St_NormalizeUrl(url)
        if not used.DoesExist(clean)
            used[clean] = true
            entry = { url: Addon_Url(clean, "/manifest.json"), sort_order: items.Count(), enabled: true }
            row = byUrl[clean]
            if row <> invalid
                if Str_Of(row.url) <> "" then entry.url = row.url
                if Str_Of(row.name) <> "" then entry.name = row.name
            end if
            items.Push(entry)
        end if
    end for
    for each clean in byUrl
        row = byUrl[clean]
        if not used.DoesExist(clean) and not Bool_Of(row.enabled, true)
            entry = { url: Str_Of(row.url), sort_order: items.Count(), enabled: false }
            if entry.url = "" then entry.url = Addon_Url(clean, "/manifest.json")
            if Str_Of(row.name) <> "" then entry.name = row.name
            items.Push(entry)
        end if
    end for
    r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_addons", { p_profile_id: index, p_addons: items, p_origin_client_id: St_ClientId() })
    return r.code >= 200 and r.code < 300
end function

function Nuvio_PushLibrary(pid as string, index as integer) as boolean
    ops = St_Get("libops_" + pid, invalid)
    if type(ops) <> "roArray" or ops.Count() = 0 then return true
    remote = Nuvio_Rpc("sync_pull_library", { p_profile_id: index, p_limit: 1000, p_offset: 0 })
    if type(remote) <> "roArray" then return false
    items = []
    for each row in remote
        if type(row) = "roAssociativeArray" and Str_Of(row.content_id) <> ""
            items.Push(Nuvio_LibraryRow(row))
        end if
    end for
    for each o in ops
        if type(o) = "roAssociativeArray"
            id = Str_Of(o.id)
            kept = []
            for each it in items
                if it.content_id <> id then kept.Push(it)
            end for
            items = kept
            if o.op = "add"
                kind = Str_Of(o.kind)
                if kind = "" then kind = "movie"
                name = Str_Of(o.name)
                if name = "" then name = "Untitled"
                items.Unshift({ content_id: id, content_type: kind, name: name, poster: Str_Of(o.poster), poster_shape: "POSTER", background: invalid, description: "", release_info: "", imdb_rating: invalid, genres: [], addon_base_url: invalid, added_at: Nuvio_NowMs() })
            end if
        end if
    end for
    r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_library", { p_profile_id: index, p_items: items })
    if r.code < 200 or r.code >= 300 then return false
    St_Set("libops_" + pid, [])
    return true
end function

function Nuvio_LibraryRow(row as object) as object
    added = row.added_at
    if added = invalid then added = row.updated_at
    if IsStr(added)
        dt = CreateObject("roDateTime")
        dt.FromISO8601String(added)
        added = dt.AsSeconds() * 1000&
    end if
    if added = invalid then added = Nuvio_NowMs()
    shape = UCase(Str_Of(row.poster_shape))
    if shape <> "LANDSCAPE" and shape <> "SQUARE" then shape = "POSTER"
    genres = row.genres
    if type(genres) <> "roArray" then genres = []
    name = Str_Of(row.name)
    if name = "" then name = "Untitled"
    kind = Str_Of(row.content_type)
    if kind = "" then kind = "movie"
    return { content_id: row.content_id, content_type: kind, name: name, poster: row.poster, poster_shape: shape, background: row.background, description: Str_Of(row.description), release_info: Str_Of(row.release_info), imdb_rating: row.imdb_rating, genres: genres, addon_base_url: row.addon_base_url, added_at: added }
end function

function Nuvio_DeleteProgress(index as integer) as boolean
    pid = St_ActiveProfile().id
    pending = St_ReadFile("progdel_" + pid)
    if type(pending) <> "roArray" or pending.Count() = 0 then return true
    ids = {}
    for each id in pending
        if IsStr(id) then ids[id] = true
    end for
    remote = Nuvio_Rpc("sync_pull_watch_progress", { p_profile_id: index })
    if type(remote) <> "roArray" then return false
    keys = []
    for each row in remote
        if type(row) = "roAssociativeArray" and ids.DoesExist(Str_Of(row.content_id))
            key = Str_Of(row.progress_key)
            if key = "" then key = Str_Of(row.content_id)
            keys.Push(key)
        end if
    end for
    if keys.Count() > 0
        r = Nuvio_Call("POST", "/rest/v1/rpc/sync_delete_watch_progress", { p_profile_id: index, p_keys: keys, p_origin_client_id: St_ClientId() })
        if r.code < 200 or r.code >= 300 then return false
    end if
    St_WriteFile("progdel_" + pid, [])
    return true
end function

function Nuvio_PushWatched(pid as string, index as integer) as boolean
    ops = St_ReadFile("watchops_" + pid)
    if type(ops) <> "roArray" or ops.Count() = 0 then return true
    adds = []
    dels = []
    for each o in ops
        if type(o) = "roAssociativeArray"
            season = invalid
            episode = invalid
            if ToInt(o.season, -1) >= 0 and ToInt(o.episode, -1) > 0
                season = ToInt(o.season, 0)
                episode = ToInt(o.episode, 0)
            end if
            if o.op = "add"
                kind = Str_Of(o.kind)
                if kind = "" then kind = "movie"
                adds.Push({ content_id: Str_Of(o.id), content_type: kind, title: Str_Of(o.title), season: season, episode: episode, watched_at: ToInt(o.at, 0) * 1000& })
            else
                key = { content_id: Str_Of(o.id) }
                if season <> invalid
                    key.season = season
                    key.episode = episode
                end if
                dels.Push(key)
            end if
        end if
    end for
    if dels.Count() > 0
        r = Nuvio_Call("POST", "/rest/v1/rpc/sync_delete_watched_items", { p_profile_id: index, p_keys: dels })
        if r.code < 200 or r.code >= 300 then return false
    end if
    if adds.Count() > 0
        r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_watched_items", { p_profile_id: index, p_items: adds })
        if r.code < 200 or r.code >= 300 then return false
    end if
    St_WriteFile("watchops_" + pid, [])
    return true
end function

sub Nuvio_PullWatched(pid as string, index as integer)
    all = {}
    page = 1
    while page <= 6
        rows = Nuvio_Rpc("sync_pull_watched_items", { p_profile_id: index, p_page: page, p_page_size: 900 })
        if type(rows) <> "roArray" then return
        for each row in rows
            if type(row) = "roAssociativeArray" and Str_Of(row.content_id) <> ""
                key = St_WatchedKey(row.content_id, row.season, row.episode)
                all[key] = { k: Str_Of(row.content_type), t: "", at: 0 }
            end if
        end for
        if rows.Count() < 900 then exit while
        page = page + 1
    end while
    ops = St_ReadFile("watchops_" + pid)
    if type(ops) = "roArray"
        for each o in ops
            if type(o) = "roAssociativeArray"
                key = St_WatchedKey(Str_Of(o.id), o.season, o.episode)
                if o.op = "add" then all[key] = { k: Str_Of(o.kind), t: "", at: 0 } else all.Delete(key)
            end if
        end for
    end if
    St_WriteFile("watched_" + pid, all)
    m.watchedCache = invalid
end sub

function Nuvio_PushProgress(index as integer) as boolean
    if not Nuvio_DeleteProgress(index) then return false
    rows = []
    for each e in St_Progress()
        id = Str_Of(e.metaId)
        if Bool_Of(e.nextUp, false) then id = ""
        if id <> ""
            season = ToInt(e.season, -1)
            episode = ToInt(e.ep, -1)
            video = Str_Of(e.videoId)
            parts = video.Split(":")
            if (season < 0 or episode < 0) and parts.Count() >= 3
                season = parts[parts.Count() - 2].ToInt()
                episode = parts[parts.Count() - 1].ToInt()
            end if
            if video = "" then video = id
            key = id
            entry = { content_id: id, content_type: Str_Of(e.kind), video_id: video, season: invalid, episode: invalid }
            if entry.content_type = "" then entry.content_type = "movie"
            if season >= 0 and episode > 0
                entry.season = season
                entry.episode = episode
                key = id + "_s" + season.ToStr() + "e" + episode.ToStr()
            end if
            entry.position = ToInt(e.position, 0) * 1000&
            entry.duration = ToInt(e.duration, 0) * 1000&
            last = e.updatedMs
            if last = invalid and e.updated <> invalid then last = ToInt(e.updated, 0) * 1000&
            if last = invalid then last = Nuvio_NowMs()
            entry.last_watched = last
            entry.progress_key = key
            rows.Push(entry)
        end if
    end for
    if rows.Count() = 0 then return true
    r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_watch_progress", { p_profile_id: index, p_entries: rows, p_origin_client_id: St_ClientId() })
    return r.code >= 200 and r.code < 300
end function

function Nuvio_PushCatalogs(pid as string, index as integer) as boolean
    prefs = St_Get("prefs_" + pid, invalid)
    if type(prefs) <> "roAssociativeArray" then return true
    order = prefs.order
    if type(order) <> "roArray" or order.Count() = 0 then return true
    hidden = prefs.hidden
    if type(hidden) <> "roAssociativeArray" then hidden = {}
    resp = Nuvio_Rpc("sync_pull_home_catalog_settings", { p_profile_id: index, p_platform: "home_catalog_shared" })
    if resp = invalid then return false
    row = resp
    if type(resp) = "roArray"
        row = invalid
        if resp.Count() > 0 then row = resp[0]
    end if
    data = invalid
    if type(row) = "roAssociativeArray"
        data = row
        if row.settings_json <> invalid then data = row.settings_json
        if IsStr(data) then data = ParseJson(data)
    end if
    if type(data) <> "roAssociativeArray" then data = {}
    remoteItems = data.items
    if type(remoteItems) <> "roArray" then remoteItems = []
    byKey = {}
    for each item in remoteItems
        if type(item) = "roAssociativeArray"
            if Bool_Of(item.is_collection, false)
                byKey["col:" + Str_Any(item.collection_id)] = item
            else
                byKey[Str_Of(item.addon_id) + "|" + LCase(Str_Of(item["type"])) + "|" + Str_Of(item.catalog_id)] = item
            end if
        end if
    end for
    items = []
    used = {}
    for each key in order
        if IsStr(key) and not used.DoesExist(key)
            item = byKey[key]
            if item <> invalid
                used[key] = true
                item.enabled = not hidden.DoesExist(key)
                item.order = items.Count()
                items.Push(item)
            end if
        end if
    end for
    for each key in byKey
        if not used.DoesExist(key)
            item = byKey[key]
            item.order = items.Count()
            items.Push(item)
        end if
    end for
    if remoteItems.Count() = 0 then return true
    data.items = items
    r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_home_catalog_settings", { p_profile_id: index, p_platform: "home_catalog_shared", p_settings_json: data })
    return r.code >= 200 and r.code < 300
end function

function Nuvio_PushSettings(pid as string, index as integer) as boolean
    local = St_Get("prefs_" + pid, invalid)
    if type(local) <> "roAssociativeArray" then return true
    resp = Nuvio_Rpc("sync_pull_profile_settings_blob", { p_profile_id: index, p_platform: "tv" })
    row = resp
    if type(resp) = "roArray"
        row = invalid
        if resp.Count() > 0 then row = resp[0]
    end if
    if type(row) <> "roAssociativeArray" then return false
    blob = row.settings_json
    if IsStr(blob) then blob = ParseJson(blob)
    if type(blob) <> "roAssociativeArray" or type(blob.features) <> "roAssociativeArray" then return false
    raw = blob.features
    f = Nuvio_Decode(raw)
    orig = Nuvio_Decode(raw)
    remote = {}
    Nuvio_MapFeatures(remote, f, St_Integrations(), pid, false, false)
    touched = St_Touched(pid)
    changed = false
    for each k in Nuvio_PushKeys()
        if touched.DoesExist(k) and local[k] <> invalid and remote[k] <> invalid and not Nuvio_Same(local[k], remote[k])
            if Nuvio_WriteSetting(f, k, local) then changed = true
        end if
    end for
    if changed then Nuvio_Encode(raw, f, orig)
    if changed
        r = Nuvio_Call("POST", "/rest/v1/rpc/sync_push_profile_settings_blob", { p_profile_id: index, p_settings_json: blob, p_platform: "tv" })
        if r.code < 200 or r.code >= 300 then return false
    end if
    St_Set("touched_" + pid, {})
    return true
end function

function Nuvio_PushKeys() as object
    return ["audioLang", "audioLang2", "subLang", "subLang2", "forcedSubs", "pauseOverlay", "clock", "autoNext", "bingeNext", "bingeReuse", "reuseLink", "reuseHours", "autoplayMode", "autoplayRegex", "autoplayTimeout", "cwStyle", "customPoster", "posterScreens", "expandPoster", "expandDelay", "expandTrailer", "expandMuted", "trailerTarget", "trailerButton", "trailerAutoplay", "trailerDelay", "tmdbLanguage", "sizeBadges", "addonLogo", "badgePlace", "accent", "skipIntro", "autoSkipIntro", "autoSkipRecap", "autoSkipOutro", "autoSkipCredits", "preloadNext", "bingeFallback", "stillWatching", "stillCount", "nextMode", "nextPct", "nextMin", "postPlay", "postPct", "parentalGuide", "stripSdh", "onlyPrefSubs", "discoverLocation"]
end function

function Nuvio_Same(a as dynamic, b as dynamic) as boolean
    if a = invalid or b = invalid then return a = invalid and b = invalid
    ta = type(a)
    tb = type(b)
    if GetInterface(a, "ifString") <> invalid or GetInterface(b, "ifString") <> invalid
        return Str_Of(a) = Str_Of(b) and GetInterface(a, "ifString") <> invalid and GetInterface(b, "ifString") <> invalid
    end if
    if GetInterface(a, "ifBoolean") <> invalid or GetInterface(b, "ifBoolean") <> invalid
        return IsBool(a) and IsBool(b) and a = b
    end if
    if ta = "roArray" or tb = "roArray" then return true
    return ToInt(a, -99999) = ToInt(b, -99998)
end function

function Nuvio_Feature(f as object, name as string) as object
    if type(f[name]) <> "roAssociativeArray" then f[name] = {}
    return f[name]
end function

function Nuvio_WriteSetting(f as object, k as string, p as object) as boolean
    v = p[k]
    pl = invalid
    if k = "audioLang"
        a = Str_Of(v)
        out = a
        if a = "system" then out = "DEVICE"
        if a = "original" then out = "ORIGINAL"
        if a = "none" then out = "DEFAULT"
        Nuvio_Feature(f, "player_settings").preferred_audio_language = out
    else if k = "audioLang2"
        a = Str_Of(v)
        pl = Nuvio_Feature(f, "player_settings")
        if a = "none" or a = "" or a = "system"
            pl.secondary_preferred_audio_language = invalid
        else if a = "original"
            pl.secondary_preferred_audio_language = "ORIGINAL"
        else
            pl.secondary_preferred_audio_language = a
        end if
    else if k = "subLang" or k = "subLang2"
        a = Str_Of(v)
        if a = "off" or a = "" then a = "none"
        if k = "subLang" then Nuvio_Feature(f, "player_settings").subtitle_preferred_language = a else Nuvio_Feature(f, "player_settings").subtitle_secondary_language = a
    else if k = "forcedSubs"
        Nuvio_Feature(f, "player_settings").subtitle_use_forced_subtitles = Bool_Of(v, false)
    else if k = "pauseOverlay"
        Nuvio_Feature(f, "player_settings").pause_overlay_enabled = Bool_Of(v, true)
    else if k = "clock"
        Nuvio_Feature(f, "player_settings").osd_clock_enabled = Bool_Of(v, true)
    else if k = "autoNext"
        Nuvio_Feature(f, "player_settings").stream_auto_play_next_episode_enabled = Bool_Of(v, true)
    else if k = "bingeNext"
        Nuvio_Feature(f, "player_settings").stream_auto_play_prefer_bingegroup_next_episode = Bool_Of(v, true)
    else if k = "bingeReuse"
        Nuvio_Feature(f, "player_settings").stream_auto_play_reuse_binge_group = Bool_Of(v, false)
    else if k = "reuseLink"
        Nuvio_Feature(f, "player_settings").stream_reuse_last_link_enabled = Bool_Of(v, false)
    else if k = "reuseHours"
        Nuvio_Feature(f, "player_settings").stream_reuse_last_link_cache_hours = ToInt(v, 24)
    else if k = "skipIntro"
        Nuvio_Feature(f, "player_settings").skip_intro_enabled = Bool_Of(v, true)
    else if k = "autoSkipIntro" or k = "autoSkipRecap" or k = "autoSkipOutro" or k = "autoSkipCredits"
        types = []
        if Bool_Of(p["autoSkipIntro"], false) then types.Push("intro")
        if Bool_Of(p["autoSkipRecap"], false) then types.Push("recap")
        if Bool_Of(p["autoSkipOutro"], false) then types.Push("outro")
        if Bool_Of(p["autoSkipCredits"], false) then types.Push("movie-credits")
        Nuvio_Feature(f, "player_settings").auto_skip_segment_types = types
    else if k = "preloadNext"
        Nuvio_Feature(f, "player_settings").preload_next_episode_sources = Bool_Of(v, false)
    else if k = "bingeFallback"
        Nuvio_Feature(f, "player_settings").stream_auto_play_next_episode_fallback_enabled = Bool_Of(v, true)
    else if k = "stillWatching"
        Nuvio_Feature(f, "player_settings").still_watching_enabled = Bool_Of(v, true)
    else if k = "stillCount"
        Nuvio_Feature(f, "player_settings").still_watching_episode_threshold = ToInt(v, 3)
    else if k = "nextMode"
        if Str_Of(v) = "min" then Nuvio_Feature(f, "player_settings").next_episode_threshold_mode = "MINUTES_BEFORE_END" else Nuvio_Feature(f, "player_settings").next_episode_threshold_mode = "PERCENTAGE"
    else if k = "nextPct"
        Nuvio_Feature(f, "player_settings").next_episode_threshold_percent_v2 = 0.0 + ToInt(v, 99)
    else if k = "nextMin"
        Nuvio_Feature(f, "player_settings").next_episode_threshold_minutes_before_end_v2 = 0.0 + ToInt(v, 2)
    else if k = "postPlay"
        Nuvio_Feature(f, "player_settings").post_play_recommendations_enabled = Bool_Of(v, true)
    else if k = "postPct"
        Nuvio_Feature(f, "player_settings").post_play_movie_threshold_percent = ToInt(v, 96)
    else if k = "parentalGuide"
        Nuvio_Feature(f, "player_settings").parental_guide_enabled = Bool_Of(v, true)
    else if k = "stripSdh"
        Nuvio_Feature(f, "player_settings").subtitle_strip_sdh = Bool_Of(v, false)
    else if k = "onlyPrefSubs"
        Nuvio_Feature(f, "player_settings").subtitle_show_only_preferred_languages = Bool_Of(v, false)
    else if k = "autoplayMode"
        modes = { manual: "MANUAL", first: "FIRST_STREAM", regex: "REGEX_MATCH" }
        if not modes.DoesExist(Str_Of(v)) then return false
        Nuvio_Feature(f, "player_settings").stream_auto_play_mode = modes[Str_Of(v)]
    else if k = "autoplayRegex"
        Nuvio_Feature(f, "player_settings").stream_auto_play_regex = Str_Of(v)
    else if k = "autoplayTimeout"
        t = ToInt(v, 3)
        if t < 0 then t = 2147483647
        Nuvio_Feature(f, "player_settings").stream_auto_play_timeout_seconds = t
    else if k = "cwStyle"
        if Str_Of(v) = "poster" then Nuvio_Feature(f, "layout_settings").continue_watching_card_style = "POSTER" else Nuvio_Feature(f, "layout_settings").continue_watching_card_style = "CARD"
    else if k = "customPoster"
        Nuvio_Feature(f, "layout_settings").custom_poster_url_pattern = Str_Of(v)
    else if k = "posterScreens"
        screens = Str_Of(v)
        if screens = "" then screens = "none"
        Nuvio_Feature(f, "layout_settings").custom_poster_enabled_screens = screens
    else if k = "expandPoster"
        Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_expand_enabled = Bool_Of(v, true)
    else if k = "expandDelay"
        Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_expand_delay_seconds = ToInt(v, 3)
    else if k = "expandTrailer"
        Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_trailer_enabled = Bool_Of(v, false)
    else if k = "expandMuted"
        Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_trailer_muted = Bool_Of(v, true)
    else if k = "trailerTarget"
        if Str_Of(v) = "card" then Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_trailer_playback_target = "EXPANDED_CARD" else Nuvio_Feature(f, "layout_settings").focused_poster_backdrop_trailer_playback_target = "HERO_MEDIA"
    else if k = "trailerButton"
        Nuvio_Feature(f, "layout_settings").detail_page_trailer_button_enabled = Bool_Of(v, true)
    else if k = "discoverLocation"
        loc = Str_Of(v)
        ly = Nuvio_Feature(f, "layout_settings")
        if loc = "sidebar"
            ly.discover_location = "IN_SIDEBAR"
        else if loc = "off"
            ly.discover_location = "OFF"
        else
            ly.discover_location = "IN_SEARCH"
        end if
        ly.search_discover_enabled = loc <> "off"
    else if k = "trailerAutoplay"
        Nuvio_Feature(f, "trailer_settings").trailer_enabled = Bool_Of(v, false)
    else if k = "trailerDelay"
        Nuvio_Feature(f, "trailer_settings").trailer_delay_seconds = ToInt(v, 7)
    else if k = "tmdbLanguage"
        Nuvio_Feature(f, "tmdb_settings").tmdb_language = Str_Of(v)
    else if k = "sizeBadges"
        Nuvio_Feature(f, "stream_badge_settings").show_file_size_badges = Bool_Of(v, true)
    else if k = "addonLogo"
        Nuvio_Feature(f, "stream_badge_settings").show_addon_logo = Bool_Of(v, true)
    else if k = "badgePlace"
        if Str_Of(v) = "top" then Nuvio_Feature(f, "stream_badge_settings").stream_badge_placement = "TOP" else Nuvio_Feature(f, "stream_badge_settings").stream_badge_placement = "BOTTOM"
    else if k = "accent"
        hex = UCase(Str_Of(v))
        names = { F5F5F5: "WHITE", E53935: "CRIMSON", "1E88E5": "OCEAN", "8E24AA": "VIOLET", "43A047": "EMERALD", FB8C00: "AMBER", D81B60: "ROSE", E8A91C: "GOLD", "22D37C": "JADE", EC70A9: "ROSE_GOLD", "3185F5": "ARCTIC_BLUE", AAB2BE: "GRAPHITE" }
        if not names.DoesExist(hex) then return false
        Nuvio_Feature(f, "theme_settings").selected_theme = names[hex]
    else
        return false
    end if
    return true
end function

function Nuvio_Get(f as object, feature as string, key as string) as dynamic
    if type(f[feature]) <> "roAssociativeArray" then return invalid
    return f[feature][key]
end function

function Nuvio_IsEncoded(v as dynamic) as boolean
    return type(v) = "roAssociativeArray" and IsStr(v["type"]) and v.DoesExist("value")
end function

function Nuvio_Decode(features as dynamic) as object
    out = {}
    if type(features) <> "roAssociativeArray" then return out
    for each name in features
        feat = features[name]
        if type(feat) = "roAssociativeArray"
            d = {}
            for each k in feat
                v = feat[k]
                if Nuvio_IsEncoded(v) then d[k] = v["value"] else d[k] = v
            end for
            out[name] = d
        else
            out[name] = feat
        end if
    end for
    return out
end function

function Nuvio_Json(v as dynamic) as string
    return FormatJson([v])
end function

function Nuvio_TypeOf(v as dynamic) as string
    if IsBool(v) then return "boolean"
    if IsStr(v) then return "string"
    if type(v) = "roArray" then return "string_set"
    if GetInterface(v, "ifInt") <> invalid then return "int"
    if GetInterface(v, "ifLongInt") <> invalid then return "long"
    if GetInterface(v, "ifDouble") <> invalid then return "double"
    return "float"
end function

sub Nuvio_Encode(raw as object, d as object, orig as object)
    encoded = false
    for each name in raw
        feat = raw[name]
        if type(feat) = "roAssociativeArray"
            for each k in feat
                if Nuvio_IsEncoded(feat[k])
                    encoded = true
                    exit for
                end if
            end for
        end if
        if encoded then exit for
    end for
    for each name in d
        feat = d[name]
        if type(feat) = "roAssociativeArray"
            if type(raw[name]) <> "roAssociativeArray" then raw[name] = {}
            target = raw[name]
            before = orig[name]
            if type(before) <> "roAssociativeArray" then before = {}
            for each k in feat
                nv = feat[k]
                if Nuvio_Json(nv) <> Nuvio_Json(before[k])
                    if nv = invalid
                        target.Delete(k)
                    else if encoded
                        kind = Nuvio_TypeOf(nv)
                        if Nuvio_IsEncoded(target[k]) then kind = target[k]["type"]
                        target[k] = { "type": kind, "value": nv }
                    else
                        target[k] = nv
                    end if
                end if
            end for
        end if
    end for
end sub

function Nuvio_ColorParts(v as dynamic) as dynamic
    if v = invalid or IsBool(v) or IsStr(v) then return invalid
    k16 = CDbl(65536)
    k24 = k16 * CDbl(256)
    c = CDbl(v)
    if c < 0 then c = c + k16 * k16
    a = Int(c / k24)
    rest = c - a * k24
    r = Int(rest / k16)
    g = Int((rest - r * k16) / 256)
    b = Int(rest - r * k16 - g * 256)
    return { a: a, r: r, g: g, b: b }
end function

sub Nuvio_MapSubStyle(prefs as object, pl as object)
    size = pl.subtitle_size
    if size <> invalid and not IsBool(size) and not IsStr(size)
        n = ToInt(size, 100)
        if n < 90
            prefs["subSize"] = "small"
        else if n < 115
            prefs["subSize"] = "normal"
        else if n < 145
            prefs["subSize"] = "large"
        else
            prefs["subSize"] = "xlarge"
        end if
    end if
    Nuvio_SetBool(prefs, "subBold", pl.subtitle_bold)
    if IsBool(pl.subtitle_outline_enabled)
        if pl.subtitle_outline_enabled then prefs["subEdge"] = "shadow" else prefs["subEdge"] = "none"
    end if
    bg = Nuvio_ColorParts(pl.subtitle_background_color)
    if bg <> invalid
        if bg.a < 16
            prefs["subBg"] = "none"
        else if bg.a < 200
            prefs["subBg"] = "soft"
        else
            prefs["subBg"] = "solid"
        end if
    end if
    tc = Nuvio_ColorParts(pl.subtitle_text_color)
    if tc <> invalid
        names = [["white", 255, 255, 255], ["yellow", 255, 235, 59], ["cyan", 0, 229, 255], ["green", 118, 255, 3], ["gray", 158, 158, 158]]
        best = "white"
        bestD = 999999
        for each c in names
            dist = (tc.r - c[1]) * (tc.r - c[1]) + (tc.g - c[2]) * (tc.g - c[2]) + (tc.b - c[3]) * (tc.b - c[3])
            if dist < bestD
                bestD = dist
                best = c[0]
            end if
        end for
        prefs["subColor"] = best
    end if
end sub

function Nuvio_MdbCredential(index as integer) as dynamic
    r = Nuvio_Call("POST", "/rest/v1/rpc/sync_pull_provider_credentials", { p_profile_id: index })
    credentials = invalid
    if r.code >= 200 and r.code < 300 then credentials = r.json
    m.credTmdb = invalid
    found = ""
    seen = false
    count = 0
    if type(credentials) = "roArray"
        m.credTmdb = ""
        for each c in credentials
            if type(c) = "roAssociativeArray"
                count = count + 1
                provider = LCase(Str_Of(c.provider))
                cj = c.credential_json
                if IsStr(cj) then cj = ParseJson(cj)
                if type(cj) <> "roAssociativeArray" then cj = {}
                key = Str_Any(cj.api_key).Trim()
                if key = "" then key = Str_Any(cj.apiKey).Trim()
                if provider = "tmdb" then m.credTmdb = key
                if provider = "mdblist"
                    seen = true
                    if key <> "" then found = key
                end if
            end if
        end for
    end if
    mdb = L("no aparece en la cuenta")
    if seen then mdb = L("vacía en la cuenta")
    if found <> "" then mdb = L("recibida") + " (…" + Right(found, 4) + ")"
    m.credDiag = L("Perfil ") + index.ToStr() + "  ·  HTTP " + r.code.ToStr() + "  ·  " + L("clave de MDBList: ") + mdb + "  ·  " + count.ToStr() + " " + L("claves")
    if type(credentials) <> "roArray" then return invalid
    return found
end function

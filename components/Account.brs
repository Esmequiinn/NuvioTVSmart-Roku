function Trakt_Headers(integ as object, withAuth as boolean) as object
    h = { "trakt-api-version": "2", "trakt-api-key": integ.traktClientId }
    if withAuth and integ.traktToken <> "" then h["Authorization"] = "Bearer " + integ.traktToken
    return h
end function

function Trakt_Code() as object
    integ = St_Integrations()
    if integ.traktClientId = "" or integ.traktSecret = "" then return { ok: false, error: L("Falta el Client ID y el Client Secret de Trakt. Agrégalos desde el celular.") }
    r = Http_Request("POST", "https://api.trakt.tv/oauth/device/code", Trakt_Headers(integ, false), { client_id: integ.traktClientId }, 15000)
    if r.code <> 200 or type(r.json) <> "roAssociativeArray" then return { ok: false, error: L("Trakt respondió con error ") + r.code.ToStr() + "." }
    return { ok: true, userCode: Str_Of(r.json.user_code), deviceCode: Str_Of(r.json.device_code), url: Str_Of(r.json.verification_url), interval: ToInt(r.json.interval, 5), expires: ToInt(r.json.expires_in, 600) }
end function

function Trakt_Poll(deviceCode as string) as object
    integ = St_Integrations()
    body = { code: deviceCode, client_id: integ.traktClientId, client_secret: integ.traktSecret }
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
    return "https://api.simkl.com" + path + sep + "client_id=" + integ.simklClientId + "&app-name=nuviotv-roku&app-version=2.1"
end function

function Simkl_Pin() as object
    integ = St_Integrations()
    if integ.simklClientId = "" then return { ok: false, error: L("Falta el Client ID de Simkl. Agrégalo desde el celular.") }
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

function Nuvio_Rpc(name as string, args as object) as dynamic
    integ = St_Integrations()
    r = Http_Request("POST", integ.nuvioUrl + "/rest/v1/rpc/" + name, Nuvio_Headers(integ, true), args, 20000)
    if r.code = 401 and Nuvio_Refresh()
        integ = St_Integrations()
        r = Http_Request("POST", integ.nuvioUrl + "/rest/v1/rpc/" + name, Nuvio_Headers(integ, true), args, 20000)
    end if
    if r.code >= 200 and r.code < 300 then return r.json
    return invalid
end function

function Nuvio_Sync() as object
    Nuvio_Ensure()
    integ = St_Integrations()
    if not Nuvio_Configured(integ) or integ.nuvioAccess = "" then return { ok: false, error: L("No has iniciado sesión en Nuvio.") }
    rows = Nuvio_Rpc("sync_pull_profiles", {})
    if type(rows) <> "roArray" then return { ok: false, error: L("No se pudieron leer tus perfiles de Nuvio.") }
    profiles = []
    usesPrimary = {}
    for each row in rows
        if type(row) = "roAssociativeArray"
            index = ToInt(row.profile_index, ToInt(row.id, 0))
            if index > 0
                name = Str_Of(row.name)
                if name = "" then name = L("Perfil ") + index.ToStr()
                color = Str_Of(row.avatar_color_hex)
                if Left(color, 1) = "#" then color = Mid(color, 2)
                profiles.Push({ id: "n" + index.ToStr(), name: Left(name, 24), color: UCase(Left(color, 6)), remote: index })
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
    primaryAddons = invalid
    counts = { addons: 0, library: 0, progress: 0 }
    for each p in profiles
        addons = Nuvio_PullAddons(p.remote)
        if p.remote = 1 then primaryAddons = addons
        if usesPrimary[p.id] and primaryAddons <> invalid then addons = primaryAddons
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
            St_Set("progress_" + p.id, progress)
            counts.progress = counts.progress + progress.Count()
        end if
        Nuvio_PullSettings(p.id, p.remote, p.id = s.active)
    end for
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    St_SetIntegration("nuvioLastSync", now.AsDateString("short-month-short-weekday") + " " + Fmt_Clock(now))
    return { ok: true, profiles: profiles.Count(), addons: counts.addons, library: counts.library, progress: counts.progress }
end function

function Nuvio_PullAddons(index as integer) as dynamic
    rows = Nuvio_Rpc("sync_pull_addons", { p_profile_id: index })
    if type(rows) <> "roArray" then return invalid
    items = []
    for each row in rows
        if type(row) = "roAssociativeArray"
            url = Str_Of(row.url)
            if url = "" then url = Str_Of(row.base_url)
            enabled = Bool_Of(row.enabled, true)
            if url <> "" and enabled then items.Push({ url: St_NormalizeUrl(url), order: ToInt(row.sort_order, ToInt(row.position, items.Count())) })
        end if
    end for
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

function Nuvio_PullProgress(index as integer) as dynamic
    rows = Nuvio_Rpc("sync_pull_watch_progress", { p_profile_id: index })
    if type(rows) <> "roArray" then return invalid
    out = []
    for each row in rows
        if type(row) = "roAssociativeArray" and out.Count() < 12
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
            if id <> "" and secs > 0 and (dur = 0 or secs < dur * 0.95) then out.Push({ metaId: id, videoId: video, kind: kind, title: "", poster: "", background: "", episode: label, position: secs, duration: dur })
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
        if type(blob) = "roAssociativeArray" and type(blob.features) = "roAssociativeArray" then f = blob.features
    end if
    integ = St_Integrations()
    credentials = Nuvio_Rpc("sync_pull_provider_credentials", { p_profile_id: index })
    if primary and type(credentials) = "roArray"
        for each c in credentials
            if type(c) = "roAssociativeArray" and LCase(Str_Of(c.provider)) = "mdblist"
                cj = c.credential_json
                if IsStr(cj) then cj = ParseJson(cj)
                if type(cj) = "roAssociativeArray" and Str_Of(cj.api_key).Trim() <> ""
                    integ["mdbKey"] = cj.api_key.Trim()
                    integ["mdbEnabled"] = true
                end if
            end if
        end for
    end if
    if f = invalid
        if primary then St_SaveIntegrations(integ)
        return
    end if
    prefs = St_Get("prefs_" + pid, invalid)
    if type(prefs) <> "roAssociativeArray" then prefs = {}

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
        Nuvio_SetBool(prefs, "trailerButton", ly.detail_page_trailer_button_enabled)
    end if

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
            if IsBool(tm.tmdb_enabled) and integ.tmdbKey <> "" then integ["tmdbEnabled"] = tm.tmdb_enabled
            if IsBool(tm.tmdb_use_artwork) then integ["tmdbArtwork"] = tm.tmdb_use_artwork
        end if
    end if

    md = f.mdblist_settings
    if primary and type(md) = "roAssociativeArray"
        key = Str_Of(md.mdblist_api_key).Trim()
        if key <> "" then integ["mdbKey"] = key
        if IsBool(md.mdblist_enabled) and integ.mdbKey <> "" then integ["mdbEnabled"] = md.mdblist_enabled
        flags = { imdb: "mdblist_show_imdb", tomatoes: "mdblist_show_tomatoes", audience: "mdblist_show_audience", metacritic: "mdblist_show_metacritic", letterboxd: "mdblist_show_letterboxd", tmdb: "mdblist_show_tmdb", trakt: "mdblist_show_trakt" }
        for each k in flags
            if IsBool(md[flags[k]]) then integ.mdbShow[k] = md[flags[k]]
        end for
    end if

    sb = f.stream_badge_settings
    if type(sb) = "roAssociativeArray"
        Nuvio_SetBool(prefs, "sizeBadges", sb.show_file_size_badges)
        Nuvio_SetBool(prefs, "addonLogo", sb.show_addon_logo)
        if UCase(Str_Of(sb.stream_badge_placement)) = "TOP" then prefs["badgePlace"] = "top" else prefs["badgePlace"] = "bottom"
        rules = Badge_Compact(sb.stream_badge_rules)
        if rules.Count() > 0
            St_SaveBadges(pid, rules)
        else
            St_ClearBadges(pid)
        end if
    end if

    St_Set("prefs_" + pid, prefs)
    if primary then St_SaveIntegrations(integ)
end sub

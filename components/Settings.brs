function Set_Row(id as string, label as string, desc as string, value as string) as object
    return { id: id, label: label, desc: desc, value: value, kind: "value" }
end function

function Set_Toggle(id as string, label as string, desc as string, on as boolean) as object
    return { id: id, label: label, desc: desc, on: on, kind: "toggle" }
end function

function Set_Info(id as string, label as string, desc as string, value as string) as object
    return { id: id, label: label, desc: desc, value: value, kind: "info" }
end function

function Set_LangName(code as string) as string
    if code = "system" then return L("Del sistema")
    if code = "original" then return "Original"
    if code = "none" then return L("Ninguno")
    if code = "off" or code = "" then return L("Desactivados")
    return Lang_Name(code)
end function

function Set_AudioLangs() as object
    return ["system", "original", "spa", "eng", "jpn", "por", "fre", "ita", "ger", "kor"]
end function

function Set_Audio2Langs() as object
    return ["none", "spa", "eng", "original", "jpn", "por", "fre", "ita", "ger", "kor"]
end function

function Set_SubLangs() as object
    return ["off", "spa", "eng", "por", "fre", "ita", "ger", "jpn"]
end function

function Set_Toggles() as object
    return { forcedSubs: true, openSubs: true, autoNext: true, pauseOverlay: true, clock: true, reuseLink: true, bingeNext: true, bingeReuse: true, sizeBadges: true, addonLogo: true, fusionBadges: true, expandPoster: true, expandTrailer: true, expandMuted: true, trailerButton: true, trailerAutoplay: true }
end function

function Set_Seconds(v as integer) as string
    if v < 0 then return L("Sin límite")
    if v = 0 then return L("Instantáneo")
    return v.ToStr() + " s"
end function

function Set_Hours(v as integer) as string
    if v >= 24 and v mod 24 = 0
        days = Int(v / 24)
        if days = 1 then return L("1 día")
        return days.ToStr() + L(" días")
    end if
    return v.ToStr() + " h"
end function

function Set_Short(text as string, size as integer) as string
    if Len(text) <= size then return text
    return Left(text, size - 1) + "…"
end function

function Set_TmdbLangs() as object
    return [
        { code: "es-MX", name: L("Español (México)") }
        { code: "es-ES", name: L("Español (España)") }
        { code: "en-US", name: L("Inglés") }
        { code: "pt-BR", name: L("Portugués (Brasil)") }
        { code: "fr-FR", name: L("Francés") }
        { code: "it-IT", name: L("Italiano") }
        { code: "de-DE", name: L("Alemán") }
        { code: "ja-JP", name: L("Japonés") }
    ]
end function

function Set_Cycle(list as object, current as dynamic) as dynamic
    idx = -1
    for i = 0 to list.Count() - 1
        if list[i] = current then idx = i
    end for
    return list[(idx + 1) mod list.Count()]
end function

function Set_Pref(prefs as object, defaults as object, name as string) as dynamic
    if prefs[name] <> invalid then return prefs[name]
    return defaults[name]
end function

function Err_Text(e as object) as string
    text = Str_Of(e.message)
    if text = "" then text = L("Error desconocido")
    if e.number <> invalid then text = text + " (" + Str_Any(e.number) + ")"
    if type(e.backtrace) = "roArray"
        spots = []
        for each b in e.backtrace
            if type(b) = "roAssociativeArray" and spots.Count() < 3
                file = Str_Of(b.filename)
                cut = file.Split("/")
                file = cut[cut.Count() - 1]
                spots.Push(file + ":" + Str_Any(b.line_number) + " " + Str_Of(b.function))
            end if
        end for
        if spots.Count() > 0 then text = text + chr(10) + spots.Join(chr(10))
    end if
    return text
end function

function Settings_Model() as object
    integ = St_Integrations()
    prefs = St_Prefs()
    defaults = St_PlayerDefaults()
    profile = St_ActiveProfile()
    url = Net_ServerUrl()
    host = L("No configurado")
    if integ.nuvioUrl <> ""
        re = CreateObject("roRegex", "^https?://([^/]+)", "i")
        found = re.Match(integ.nuvioUrl)
        if found.Count() > 1 then host = found[1]
        if integ.nuvioUrl = Config_NuvioServer() then host = L("Oficial") + " (" + host + ")"
    end if
    logged = integ.nuvioAccess <> ""

    account = { id: "account", label: L("Cuenta"), subtitle: L("Conecta tu cuenta de Nuvio para traer tus perfiles, addons, biblioteca, progreso y ajustes."), rows: [] }
    if logged
        email = integ.nuvioEmail
        if email = "" then email = L("Sesión iniciada")
        account.rows.Push(Set_Info("nuvioUser", L("Cuenta de Nuvio"), L("Conectada."), email))
        lastSync = integ.nuvioLastSync
        if lastSync = "" then lastSync = L("Nunca")
        account.rows.Push(Set_Row("nuvioSync", L("Sincronizar ahora"), L("Vuelve a traer perfiles, addons, biblioteca, progreso y ajustes."), lastSync))
        account.rows.Push(Set_Row("nuvioLogout", L("Cerrar sesión"), L("Tus datos locales se conservan."), ""))
    else
        account.rows.Push(Set_Row("nuvioLogin", L("Iniciar sesión con QR"), L("Escanea el código con tu celular y aprueba el acceso a este Roku."), ""))
        account.rows.Push(Set_Row("nuvioEmailHelp", L("Iniciar sesión con correo"), L("Se hace desde el celular, en la página de configuración."), ""))
    end if
    account.rows.Push(Set_Row("nuvioServer", L("Servidor de Nuvio"), L("Usa el servidor oficial. Desde el celular puedes cambiarlo por uno propio."), host))
    account.rows.Push(Set_Row("phone", L("Configurar desde el celular"), L("Abre esta dirección en un celular conectado al mismo wifi."), url))

    profilesSection = { id: "profiles", label: L("Perfiles"), subtitle: L("Cada perfil tiene su propia lista, progreso y ajustes."), rows: [] }
    for each p in St_Profiles()
        value = ""
        if p.id = profile.id then value = L("En uso")
        profilesSection.rows.Push(Set_Row("profile:" + p.id, p.name, "", value))
    end for
    profilesSection.rows.Push(Set_Row("newProfile", L("Nuevo perfil"), "", ""))
    profilesSection.rows.Push(Set_Row("profileColor", L("Color del perfil"), L("Fondo del círculo del perfil cuando no tiene foto, y color de la pantalla de perfiles."), St_ColorName(St_ProfileColor(St_ActiveProfileIndex()))))
    profilesSection.rows.Push(Set_Toggle("shared", L("Addons compartidos"), L("Todos los perfiles usan la misma lista de addons."), St_Settings().shared))

    appearance = { id: "appearance", label: L("Apariencia"), subtitle: L("Colores e idioma del canal."), rows: [] }
    appearance.rows.Push(Set_Row("accent", L("Color de acento"), L("Se usa en el foco, barras de progreso y botones."), St_ColorName(prefs.accent)))
    langs = { auto: L("Automático"), es: "Español", en: "English" }
    uiLang = Str_Of(St_Settings()["uiLang"])
    if not langs.DoesExist(uiLang) then uiLang = "auto"
    appearance.rows.Push(Set_Row("uiLang", L("Idioma de la interfaz"), L("El idioma del canal. Automático usa el idioma de tu Roku."), langs[uiLang]))

    layout = { id: "layout", label: L("Diseño"), subtitle: L("Cómo se ve la pantalla de inicio."), rows: [] }
    layout.rows.Push(Set_Toggle("cw", L("Seguir viendo"), L("Muestra la fila de lo que estás viendo."), prefs.continueWatching))
    style = L("Horizontal")
    if Set_Pref(prefs, defaults, "cwStyle") = "poster" then style = L("Póster")
    layout.rows.Push(Set_Row("cwStyle", L("Estilo de Seguir viendo"), L("Horizontal muestra una imagen del episodio o película."), style))
    layout.rows.Push(Set_Row("rowSize", L("Títulos por fila"), L("Menos títulos hace que el inicio cargue más rápido."), prefs.rowSize.ToStr()))
    layout.rows.Push(Set_Toggle("expandPoster", L("Expandir póster enfocado"), L("Después de unos segundos el póster se convierte en una vista horizontal."), Bool_Of(Set_Pref(prefs, defaults, "expandPoster"), true)))
    layout.rows.Push(Set_Row("expandDelay", L("Espera para expandir"), "", Set_Seconds(ToInt(Set_Pref(prefs, defaults, "expandDelay"), 3))))
    layout.rows.Push(Set_Toggle("expandTrailer", L("Tráiler del póster enfocado"), L("Reproduce el tráiler después de unos segundos en un póster."), Bool_Of(Set_Pref(prefs, defaults, "expandTrailer"), false)))
    target = L("Portada")
    if Set_Pref(prefs, defaults, "trailerTarget") = "card" then target = L("Tarjeta expandida")
    layout.rows.Push(Set_Row("trailerTarget", L("Dónde se reproduce el tráiler"), L("Portada usa la imagen grande de arriba, como Nuvio."), target))
    layout.rows.Push(Set_Toggle("expandMuted", L("Tráiler del póster sin sonido"), "", Bool_Of(Set_Pref(prefs, defaults, "expandMuted"), true)))
    poster = Str_Of(Set_Pref(prefs, defaults, "customPoster"))
    posterValue = L("Sin patrón")
    if poster <> "" then posterValue = L("Activo")
    layout.rows.Push(Set_Row("customPoster", L("Póster personalizado"), L("Patrón de URL de un servicio de pósters, como RPDB. Mejor pégalo desde el celular."), posterValue))

    content = { id: "content", label: L("Contenido"), subtitle: L("Addons, catálogos y colecciones."), rows: [] }
    content.rows.Push(Set_Row("addons", "Addons", L("Agrega, ordena o elimina addons."), St_Addons().Count().ToStr()))
    content.rows.Push(Set_Row("catalogs", L("Catálogos"), L("Muestra, oculta y reordena las filas del inicio."), m.catalogs.Count().ToStr()))
    content.rows.Push(Set_Row("collection", L("Importar colección"), L("Dirección de un .json con una lista de addons."), ""))
    content.rows.Push(Set_Row("reload", L("Recargar catálogos"), "", ""))

    integration = { id: "integration", label: L("Integraciones"), subtitle: L("TMDB para metadata en tu idioma y MDBList para calificaciones."), rows: [] }
    tmdbKey = L("Falta")
    if Config_TmdbKey() <> "" then tmdbKey = L("Incluida")
    if integ.tmdbKey <> "" then tmdbKey = L("Configurada")
    integration.rows.Push(Set_Toggle("tmdbEnabled", L("Usar TMDB"), L("Títulos, sinopsis, logos, fondos y episodios en tu idioma."), integ.tmdbEnabled))
    integration.rows.Push(Set_Row("tmdbKey", L("Clave de TMDB"), L("Se pega desde el celular. Es gratis en themoviedb.org."), tmdbKey))
    langName = Set_Pref(prefs, defaults, "tmdbLanguage")
    for each entry in Set_TmdbLangs()
        if entry.code = Set_Pref(prefs, defaults, "tmdbLanguage") then langName = entry.name
    end for
    integration.rows.Push(Set_Row("tmdbLanguage", L("Idioma de la metadata"), L("Para este perfil."), langName))
    integration.rows.Push(Set_Toggle("tmdbArtwork", L("Imágenes de TMDB"), L("Usa logos y fondos de TMDB."), integ.tmdbArtwork))
    mdbKey = L("Falta")
    if integ.mdbKey <> "" then mdbKey = L("Configurada")
    integration.rows.Push(Set_Toggle("mdbEnabled", L("Calificaciones de MDBList"), L("Muestra calificaciones de varias fuentes en la portada y la ficha."), integ.mdbEnabled))
    integration.rows.Push(Set_Row("mdbKey", L("Clave de MDBList"), L("Se pega desde el celular. Es gratis en mdblist.com."), mdbKey))
    names = { imdb: "IMDb", tomatoes: "Rotten Tomatoes", audience: L("Audiencia (RT)"), metacritic: "Metacritic", letterboxd: "Letterboxd", tmdb: "TMDB", trakt: "Trakt" }
    for each k in ["imdb", "tomatoes", "audience", "metacritic", "letterboxd", "tmdb", "trakt"]
        integration.rows.Push(Set_Toggle("mdb:" + k, L("Mostrar ") + names[k], "", Bool_Of(integ.mdbShow[k], false)))
    end for

    playback = { id: "playback", label: L("Reproducción"), subtitle: L("Audio, subtítulos y comportamiento del reproductor."), rows: [] }
    playback.rows.Push(Set_Row("audioLang", L("Idioma de audio preferido"), L("Se elige solo si la fuente tiene varias pistas. Original necesita TMDB."), Set_LangName(Str_Of(Set_Pref(prefs, defaults, "audioLang")))))
    playback.rows.Push(Set_Row("audioLang2", L("Idioma de audio secundario"), L("Se usa si la fuente no tiene el preferido."), Set_LangName(Str_Of(Set_Pref(prefs, defaults, "audioLang2")))))
    playback.rows.Push(Set_Row("subLang", L("Subtítulos preferidos"), L("Se activan solos cuando hay subtítulos en ese idioma."), Set_LangName(Str_Of(Set_Pref(prefs, defaults, "subLang")))))
    playback.rows.Push(Set_Row("subLang2", L("Subtítulos secundarios"), L("Se usan si no hay subtítulos en el idioma preferido."), Set_LangName(Str_Of(Set_Pref(prefs, defaults, "subLang2")))))
    playback.rows.Push(Set_Toggle("forcedSubs", L("Subtítulos forzados"), L("Si el audio está en el idioma de unos subtítulos forzados, los activa."), Bool_Of(Set_Pref(prefs, defaults, "forcedSubs"), false)))
    playback.rows.Push(Set_Toggle("openSubs", L("Subtítulos de OpenSubtitles"), L("Busca subtítulos aunque no tengas un addon de subtítulos."), Bool_Of(Set_Pref(prefs, defaults, "openSubs"), true)))
    playback.rows.Push(Set_Toggle("autoNext", L("Siguiente episodio automático"), L("Al terminar un episodio empieza el siguiente."), Bool_Of(Set_Pref(prefs, defaults, "autoNext"), true)))
    playback.rows.Push(Set_Toggle("pauseOverlay", L("Pantalla de pausa"), L("Aparece después de unos segundos en pausa."), Bool_Of(Set_Pref(prefs, defaults, "pauseOverlay"), true)))
    playback.rows.Push(Set_Toggle("clock", L("Reloj en el reproductor"), "", Bool_Of(Set_Pref(prefs, defaults, "clock"), true)))

    sources = { id: "sources", label: L("Fuentes"), subtitle: L("Cómo se elige el enlace al reproducir. Usa los mismos ajustes que Nuvio TV."), rows: [] }
    modes = { manual: L("Manual"), first: L("Primera fuente"), regex: L("Coincidencia regex") }
    mode = Str_Of(Set_Pref(prefs, defaults, "autoplayMode"))
    if not modes.DoesExist(mode) then mode = "manual"
    sources.rows.Push(Set_Row("autoplayMode", L("Selección automática"), L("Manual siempre muestra la lista de fuentes."), modes[mode]))
    regex = Str_Of(Set_Pref(prefs, defaults, "autoplayRegex"))
    regexValue = L("Sin patrón")
    if regex <> "" then regexValue = Set_Short(regex, 26)
    sources.rows.Push(Set_Row("autoplayRegex", L("Patrón regex"), L("Se compara con el addon, nombre, título, descripción y URL de cada fuente."), regexValue))
    presetName = L("Elegir")
    for each p in Autoplay_Presets()
        if p.p = regex then presetName = p.name
    end for
    sources.rows.Push(Set_Row("regexPreset", L("Preajustes de regex"), L("Cada vez que lo eliges cambia al siguiente."), presetName))
    sources.rows.Push(Set_Row("autoplayTimeout", L("Tiempo de espera"), L("Cuánto esperar a los addons antes de elegir."), Set_Seconds(ToInt(Set_Pref(prefs, defaults, "autoplayTimeout"), 3))))
    allowed = Set_Pref(prefs, defaults, "autoplayAddons")
    allowedText = L("Todos")
    if type(allowed) = "roArray" and allowed.Count() > 0 then allowedText = Set_Short(allowed.Join(", "), 26)
    sources.rows.Push(Set_Info("autoplayAddons", L("Addons permitidos"), L("Se toma de tu cuenta de Nuvio."), allowedText))
    sources.rows.Push(Set_Toggle("reuseLink", L("Reusar último enlace"), L("Reproduce directo el último enlace que funcionó para ese título."), Bool_Of(Set_Pref(prefs, defaults, "reuseLink"), false)))
    sources.rows.Push(Set_Row("reuseHours", L("Guardar el enlace por"), "", Set_Hours(ToInt(Set_Pref(prefs, defaults, "reuseHours"), 24))))
    sources.rows.Push(Set_Toggle("bingeNext", L("Misma fuente en el siguiente episodio"), L("Prefiere el mismo addon y calidad que el episodio anterior."), Bool_Of(Set_Pref(prefs, defaults, "bingeNext"), true)))
    sources.rows.Push(Set_Toggle("bingeReuse", L("Recordar la fuente de cada serie"), L("También al volver desde Seguir viendo o la ficha."), Bool_Of(Set_Pref(prefs, defaults, "bingeReuse"), false)))
    sources.rows.Push(Set_Toggle("sizeBadges", L("Badges de tamaño"), "", Bool_Of(Set_Pref(prefs, defaults, "sizeBadges"), true)))
    sources.rows.Push(Set_Toggle("addonLogo", L("Logo del addon"), "", Bool_Of(Set_Pref(prefs, defaults, "addonLogo"), true)))
    place = L("Abajo")
    if Set_Pref(prefs, defaults, "badgePlace") = "top" then place = L("Arriba")
    sources.rows.Push(Set_Row("badgePlace", L("Posición de los badges"), "", place))
    rulesCount = St_Badges(St_ActiveProfile().id).Count()
    fusionDesc = L("No tienes reglas importadas. Se traen de tu cuenta de Nuvio o desde el celular.")
    if rulesCount > 0 then fusionDesc = rulesCount.ToStr() + L(" reglas importadas.")
    sources.rows.Push(Set_Toggle("fusionBadges", L("Badges Fusion"), fusionDesc, Bool_Of(Set_Pref(prefs, defaults, "fusionBadges"), true)))

    trailers = { id: "trailers", label: L("Tráilers"), subtitle: L("Tráilers de IMDb o YouTube."), rows: [] }
    trailers.rows.Push(Set_Toggle("trailerButton", L("Botón de tráiler"), L("Aparece en la ficha cuando hay tráiler."), Bool_Of(Set_Pref(prefs, defaults, "trailerButton"), true)))
    trailers.rows.Push(Set_Toggle("trailerAutoplay", L("Reproducir tráiler en la ficha"), L("Empieza solo después de unos segundos en la ficha."), Bool_Of(Set_Pref(prefs, defaults, "trailerAutoplay"), false)))
    trailers.rows.Push(Set_Row("trailerDelay", L("Espera del tráiler"), "", Set_Seconds(ToInt(Set_Pref(prefs, defaults, "trailerDelay"), 7))))

    tracking = { id: "tracking", label: L("Seguimiento"), subtitle: L("Registra lo que ves en Trakt y Simkl."), rows: [] }
    traktValue = L("Conectar")
    if integ.traktToken <> ""
        traktValue = integ.traktUser
        if traktValue = "" then traktValue = L("Conectado")
    end if
    tracking.rows.Push(Set_Row("trakt", "Trakt", L("Vincula tu cuenta de Trakt con un código."), traktValue))
    simklValue = L("Conectar")
    if integ.simklToken <> ""
        simklValue = integ.simklUser
        if simklValue = "" then simklValue = L("Conectado")
    end if
    tracking.rows.Push(Set_Row("simkl", "Simkl", L("Vincula tu cuenta de Simkl con un código."), simklValue))
    tracking.rows.Push(Set_Toggle("scrobble", L("Registrar lo que veo"), L("Envía inicio, pausa y fin de cada título."), integ.scrobble))

    advanced = { id: "advanced", label: L("Avanzado"), subtitle: "", rows: [] }
    advanced.rows.Push(Set_Row("clearHistory", L("Borrar historial de Seguir viendo"), L("Solo de este perfil."), ""))
    advanced.rows.Push(Set_Row("phone", L("Configurar desde el celular"), "", url))

    about = { id: "about", label: L("Acerca de"), subtitle: "", rows: [] }
    about.rows.Push(Set_Info("version", L("Nuvio TV para Roku"), L("Fork no oficial de Nuvio, con permiso de sus desarrolladores."), "2.2.1"))
    about.rows.Push(Set_Info("license", L("Licencia"), L("Basado en Nuvio, licencia GPL-3.0."), "GPL-3.0"))

    return { sections: [account, profilesSection, appearance, layout, content, integration, playback, sources, trailers, tracking, advanced, about] }
end function

sub openSettings()
    hideExpanded()
    model = invalid
    try
        model = Settings_Model()
    catch e
        showMessage(L("No se pudieron abrir los ajustes"), Err_Text(e))
        return
    end try
    m.settingsOpen = true
    m.settings.visible = true
    m.settings.reset = true
    m.settings.model = model
    m.settings.setFocus(true)
end sub

sub refreshSettings()
    if not m.settingsOpen then return
    try
        m.settings.model = Settings_Model()
    catch e
        showMessage(L("No se pudieron abrir los ajustes"), Err_Text(e))
    end try
end sub

sub closeSettings()
    m.settingsOpen = false
    m.settings.visible = false
    if m.needsReload
        m.area = "page"
        showPage("home")
        return
    end if
    m.area = "nav"
    focusCurrent()
end sub

sub onSettingsBack()
    closeSettings()
end sub

sub onSettingsEvent()
    ev = m.settings.event
    if ev = invalid or m.busy then return
    row = Str_Of(ev.row)
    integ = St_Integrations()
    if Left(row, 8) = "profile:"
        openMenu("profile", { id: Mid(row, 9) })
        return
    end if
    if Left(row, 4) = "mdb:"
        k = Mid(row, 5)
        integ.mdbShow[k] = not Bool_Of(integ.mdbShow[k], false)
        St_SaveIntegrations(integ)
        m.metaCache = {}
        refreshSettings()
        return
    end if
    if row = "nuvioLogin"
        startLogin("nuvio")
    else if row = "nuvioEmailHelp" or row = "nuvioServer" or row = "phone"
        openMenu("phone", {})
    else if row = "nuvioSync"
        startNuvioSync()
    else if row = "nuvioLogout"
        integ.nuvioAccess = ""
        integ.nuvioRefresh = ""
        integ.nuvioEmail = ""
        St_SaveIntegrations(integ)
        refreshSettings()
    else if row = "newProfile"
        showKeyboard("newProfile", L("Nombre del perfil"), "", {})
    else if row = "profileColor"
        p = St_ActiveProfile()
        St_SetProfileColor(p.id, Set_Cycle(St_ProfileColors(), St_ProfileColor(St_ActiveProfileIndex())))
        applyTheme()
        refreshSettings()
    else if row = "shared"
        St_SetShared(not St_Settings().shared)
        m.needsReload = true
        refreshSettings()
    else if row = "uiLang"
        s = St_Settings()
        current = Str_Of(s["uiLang"])
        if current = "" then current = "auto"
        s["uiLang"] = Set_Cycle(["auto", "es", "en"], current)
        St_SaveSettings(s)
        refreshSettings()
        m.exitAfterDialog = true
        showMessage(L("Idioma cambiado"), L("El canal se cerrará para aplicar el nuevo idioma. Ábrelo de nuevo."))
    else if row = "accent"
        colors = St_Colors()
        hexes = []
        for each c in colors
            hexes.Push(c.hex)
        end for
        St_SetAccent(Set_Cycle(hexes, UCase(m.prefs.accent)))
        applyTheme()
        m.settings.accent = m.accent
        refreshSettings()
    else if row = "cw"
        St_SetFlag("continueWatching", not m.prefs.continueWatching)
        applyTheme()
        m.needsReload = true
        refreshSettings()
    else if row = "cwStyle"
        if St_Pref("cwStyle") = "poster"
            St_SetPref("cwStyle", "landscape")
        else
            St_SetPref("cwStyle", "poster")
        end if
        refreshContinueRow()
        refreshSettings()
    else if row = "rowSize"
        St_SetRowSize(Set_Cycle(St_RowSizes(), m.prefs.rowSize))
        applyTheme()
        m.needsReload = true
        refreshSettings()
    else if row = "addons"
        openMenu("addons", {})
    else if row = "catalogs"
        openMenu("catalogs", {})
    else if row = "collection"
        showKeyboard("collection", L("Dirección del .json de la colección"), "https://", {})
    else if row = "reload" 
        m.needsReload = true
        closeSettings()
    else if row = "tmdbEnabled"
        if Key_Tmdb(integ) = "" and not integ.tmdbEnabled
            showMessage(L("Falta la clave de TMDB"), L("Pega tu clave de API de TMDB desde la página de configuración del celular (pestaña Cuenta)."))
            return
        end if
        integ.tmdbEnabled = not integ.tmdbEnabled
        St_SaveIntegrations(integ)
        m.metaCache = {}
        refreshSettings()
    else if row = "tmdbKey" or row = "mdbKey"
        openMenu("phone", {})
    else if row = "tmdbLanguage"
        codes = []
        for each entry in Set_TmdbLangs()
            codes.Push(entry.code)
        end for
        St_SetPref("tmdbLanguage", Set_Cycle(codes, St_Pref("tmdbLanguage")))
        m.metaCache = {}
        refreshSettings()
    else if row = "tmdbArtwork"
        integ.tmdbArtwork = not integ.tmdbArtwork
        St_SaveIntegrations(integ)
        m.metaCache = {}
        refreshSettings()
    else if row = "mdbEnabled"
        if integ.mdbKey = "" and not integ.mdbEnabled
            showMessage(L("Falta la clave de MDBList"), L("Pega tu clave de API de MDBList desde la página de configuración del celular (pestaña Cuenta)."))
            return
        end if
        integ.mdbEnabled = not integ.mdbEnabled
        St_SaveIntegrations(integ)
        m.metaCache = {}
        refreshSettings()
    else if row = "audioLang"
        St_SetPref("audioLang", Set_Cycle(Set_AudioLangs(), Str_Of(St_Pref("audioLang"))))
        refreshSettings()
    else if row = "audioLang2"
        St_SetPref("audioLang2", Set_Cycle(Set_Audio2Langs(), Str_Of(St_Pref("audioLang2"))))
        refreshSettings()
    else if row = "subLang"
        St_SetPref("subLang", Set_Cycle(Set_SubLangs(), Str_Of(St_Pref("subLang"))))
        refreshSettings()
    else if row = "subLang2"
        St_SetPref("subLang2", Set_Cycle(Set_SubLangs(), Str_Of(St_Pref("subLang2"))))
        refreshSettings()
    else if Set_Toggles().DoesExist(row)
        St_SetPref(row, not Bool_Of(St_Pref(row), Bool_Of(St_PlayerDefaults()[row], false)))
        applyTheme()
        refreshSettings()
    else if row = "autoplayMode"
        St_SetPref("autoplayMode", Set_Cycle(["manual", "first", "regex"], Str_Of(St_Pref("autoplayMode"))))
        refreshSettings()
    else if row = "autoplayRegex"
        showKeyboard("regex", L("Patrón regex (vacío para quitarlo)"), Str_Of(St_Pref("autoplayRegex")), {})
    else if row = "regexPreset"
        presets = Autoplay_Presets()
        current = -1
        for i = 0 to presets.Count() - 1
            if presets[i].p = Str_Of(St_Pref("autoplayRegex")) then current = i
        end for
        chosen = presets[(current + 1) mod presets.Count()]
        St_SetPref("autoplayRegex", chosen.p)
        St_SetPref("autoplayMode", "regex")
        refreshSettings()
    else if row = "autoplayTimeout"
        St_SetPref("autoplayTimeout", Set_Cycle([0, 1, 2, 3, 5, 7, 10, 15, 20, 30, -1], ToInt(St_Pref("autoplayTimeout"), 3)))
        refreshSettings()
    else if row = "reuseHours"
        St_SetPref("reuseHours", Set_Cycle([1, 3, 6, 12, 24, 48, 72, 168], ToInt(St_Pref("reuseHours"), 24)))
        refreshSettings()
    else if row = "trailerTarget"
        if St_Pref("trailerTarget") = "card" then St_SetPref("trailerTarget", "hero") else St_SetPref("trailerTarget", "card")
        applyTheme()
        refreshSettings()
    else if row = "badgePlace"
        if St_Pref("badgePlace") = "top" then St_SetPref("badgePlace", "bottom") else St_SetPref("badgePlace", "top")
        refreshSettings()
    else if row = "expandDelay"
        St_SetPref("expandDelay", Set_Cycle([1, 2, 3, 4, 5, 7, 10], ToInt(St_Pref("expandDelay"), 3)))
        applyTheme()
        refreshSettings()
    else if row = "trailerDelay"
        St_SetPref("trailerDelay", Set_Cycle([3, 5, 7, 10, 15], ToInt(St_Pref("trailerDelay"), 7)))
        refreshSettings()
    else if row = "customPoster"
        showKeyboard("customPoster", L("Patrón del póster (vacío para quitarlo)"), Str_Of(St_Pref("customPoster")), {})
    else if row = "trakt"
        if integ.traktToken <> ""
            integ.traktToken = ""
            integ.traktRefresh = ""
            integ.traktUser = ""
            St_SaveIntegrations(integ)
            refreshSettings()
        else
            startLogin("trakt")
        end if
    else if row = "simkl"
        if integ.simklToken <> ""
            integ.simklToken = ""
            integ.simklUser = ""
            St_SaveIntegrations(integ)
            refreshSettings()
        else
            startLogin("simkl")
        end if
    else if row = "scrobble"
        integ.scrobble = not integ.scrobble
        St_SaveIntegrations(integ)
        refreshSettings()
    else if row = "clearHistory"
        St_ClearProgress()
        refreshContinueRow()
        showMessage(L("Listo"), L("Se borró el historial de Seguir viendo de este perfil."))
    end if
end sub

sub startLogin(service as string)
    m.login = { service: service }
    mode = "nuvioQrStart"
    if service = "trakt" then mode = "traktCode"
    if service = "simkl" then mode = "simklPin"
    showBusy(L("Preparando el inicio de sesión..."))
    m.accountTask = CreateObject("roSGNode", "AccountTask")
    m.accountTask.mode = mode
    m.accountTask.observeField("result", "onLoginStarted")
    m.accountTask.control = "RUN"
end sub

sub onLoginStarted(event as object)
    task = event.getRoSGNode()
    if m.accountTask = invalid or not task.isSameNode(m.accountTask) then return
    m.accountTask = invalid
    hideBusy()
    r = task.result
    if not Bool_Of(r.ok, false)
        showMessage(L("No se pudo iniciar sesión"), Str_Of(r.error))
        return
    end if
    m.login.code = Str_Of(r.code)
    m.login.deviceCode = Str_Of(r.deviceCode)
    m.login.userCode = Str_Of(r.userCode)
    m.login.nonce = Str_Of(r.nonce)
    m.login.anon = Str_Of(r.anon)
    m.login.url = Str_Of(r.url)
    interval = ToInt(r.interval, 5)
    if interval < 3 then interval = 3
    m.loginTimer.duration = interval
    m.loginTimer.control = "start"
    openMenu("login", {})
end sub

function menuLogin() as object
    lg = m.login
    names = { nuvio: "Nuvio", trakt: "Trakt", simkl: "Simkl" }
    title = L("Conectar ") + names[lg.service]
    url = lg.url
    showUrl = url
    if lg.service <> "nuvio" then showUrl = url + L("  ·  código: ") + lg.userCode
    menu = menuOf(title, L("Escanea el código o entra a ") + showUrl + L(" desde tu celular y aprueba el acceso. Esta pantalla se cierra sola al terminar."))
    qr = url
    if lg.service = "trakt" then qr = url + "/" + lg.userCode
    menu.poster = Net_QrUri(qr)
    addEntry(menu, L("Código:  ") + lg.userCode, "", { act: "noop" })
    addEntry(menu, L("Cancelar"), "", { act: "cancelLogin" })
    return menu
end function

sub onLoginTimer()
    if m.login = invalid or m.loginPoll <> invalid then return
    mode = "nuvioQrPoll"
    if m.login.service = "trakt" then mode = "traktPoll"
    if m.login.service = "simkl" then mode = "simklPoll"
    m.loginPoll = CreateObject("roSGNode", "AccountTask")
    m.loginPoll.mode = mode
    m.loginPoll.params = { code: m.login.code, nonce: m.login.nonce, anon: m.login.anon, deviceCode: m.login.deviceCode, userCode: m.login.userCode }
    m.loginPoll.observeField("result", "onLoginPolled")
    m.loginPoll.control = "RUN"
end sub

sub onLoginPolled(event as object)
    task = event.getRoSGNode()
    if m.loginPoll = invalid or not task.isSameNode(m.loginPoll) then return
    m.loginPoll = invalid
    if m.login = invalid then return
    r = task.result
    status = Str_Of(r.status)
    if status = "approved"
        service = m.login.service
        cancelLogin()
        refreshSettings()
        if service = "nuvio"
            startNuvioSync()
        else
            showMessage(L("Conectado"), L("Tu cuenta quedó conectada."))
        end if
    else if status = "failed"
        cancelLogin()
        showMessage(L("No se pudo iniciar sesión"), Str_Of(r.error))
    else
        m.loginTimer.control = "start"
    end if
end sub

sub cancelLogin()
    m.loginTimer.control = "stop"
    m.login = invalid
    m.loginPoll = invalid
    if m.stack.Count() > 0
        if m.stack.Peek().id = "login" then closeMenu()
    end if
end sub

sub startNuvioSync()
    m.quietSync = false
    showBusy(L("Sincronizando con Nuvio..."))
    runNuvioSync()
end sub

sub startQuietSync()
    if St_Integrations().nuvioAccess = "" or m.accountTask <> invalid then return
    m.quietSync = true
    runNuvioSync()
end sub

sub runNuvioSync()
    m.accountTask = CreateObject("roSGNode", "AccountTask")
    m.accountTask.mode = "nuvioSync"
    m.accountTask.observeField("result", "onNuvioSynced")
    m.accountTask.control = "RUN"
end sub

sub onNuvioSynced(event as object)
    task = event.getRoSGNode()
    if m.accountTask = invalid or not task.isSameNode(m.accountTask) then return
    m.accountTask = invalid
    quiet = Bool_Of(m.quietSync, false)
    m.quietSync = false
    if not quiet then hideBusy()
    r = task.result
    if not Bool_Of(r.ok, false)
        if not quiet then showMessage(L("No se pudo sincronizar"), Str_Of(r.error))
        return
    end if
    m.needsReload = true
    m.metaCache = {}
    applyTheme()
    refreshSettings()
    if m.profiles.visible
        showProfiles()
        return
    end if
    if not m.settingsOpen and m.stack.Count() = 0 then reloadWhenIdle()
    if quiet then return
    text = L("Perfiles: ") + ToInt(r.profiles, 0).ToStr() + chr(10) + "Addons: " + ToInt(r.addons, 0).ToStr() + chr(10) + L("Títulos en biblioteca: ") + ToInt(r.library, 0).ToStr() + chr(10) + L("En progreso: ") + ToInt(r.progress, 0).ToStr()
    showMessage(L("Sincronizado con Nuvio"), text)
end sub

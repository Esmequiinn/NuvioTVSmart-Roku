function Live_On() as boolean
    return App_Edition() = "iptv"
end function

sub Live_Setup()
    m.livePage = m.top.findNode("livePage")
    if m.livePage = invalid then return
    if not Live_On()
        m.livePage.getParent().removeChild(m.livePage)
        m.livePage = invalid
        return
    end if
    m.nav.live = true
    m.livePage.observeField("event", "onLiveEvent")
    m.reminderCard = m.top.findNode("reminderCard")
    m.remindTimer = m.top.findNode("remindTimer")
    if m.remindTimer <> invalid
        m.remindTimer.observeField("fire", "Live_CheckReminders")
        m.remindTimer.control = "start"
    end if
    if Live_Lists().Count() > 0 then m.livePage.reload = true
end sub

function Live_Lists() as object
    return Iptv_Lists()
end function

sub Live_SaveLists(list as object)
    Iptv_SaveLists(list)
    if m.livePage <> invalid then m.livePage.reload = true
end sub

sub Live_ShowPage(visible as boolean)
    if m.livePage = invalid then return
    m.livePage.visible = visible
    if m.livePage.active <> visible then m.livePage.active = visible
end sub

sub onLiveEvent()
    ev = m.livePage.event
    if ev = invalid then return
    action = Str_Of(ev.action)
    if action = "nav"
        focusNav()
    else if action = "toast"
        Toast_Show(Str_Of(ev.text))
    else if action = "channels"
        Live_HomeRefresh()
        if m.settingsOpen then refreshSettings()
    else if action = "epg"
        if m.settingsOpen then refreshSettings()
    else if action = "watch"
        m.liveWatchOn = Bool_Of(ev.on, false)
        m.nav.visible = not (Bool_Of(m.liveWatchOn, false) or Bool_Of(m.livePanelOn, false))
        if m.liveWatchOn and m.livePage.visible and not m.settingsOpen then m.livePage.setFocus(true)
    else if action = "panel"
        m.livePanelOn = Bool_Of(ev.on, false)
        m.nav.visible = not (Bool_Of(m.liveWatchOn, false) or Bool_Of(m.livePanelOn, false))
    else if action = "options"
        Live_OptionsSheet(ev)
    else if action = "remind"
        Live_RemindSheet(ev)
    else if action = "groupOptions"
        Live_GroupSheet(ev)
    else if action = "pin"
        Live_PinAsk(Str_Of(ev.group))
    end if
end sub

sub Live_GroupSheet(ev as object)
    items = []
    if Bool_Of(ev.fav, false) then items.Push({ id: "fav", label: L("Quitar de grupos favoritos") }) else items.Push({ id: "fav", label: L("Agregar a grupos favoritos") })
    items.Push({ id: "hide", label: L("Ocultar grupo") })
    if Bool_Of(ev.locked, false)
        items.Push({ id: "lock", label: L("Quitar el bloqueo con PIN") })
    else
        items.Push({ id: "lock", label: L("Bloquear con PIN") })
    end if
    items.Push({ id: "close", label: L("Cerrar") })
    Sheet_Open({ title: Str_Of(ev.group), items: items }, "liveGroup", ev)
end sub

sub Live_PinAsk(group as string)
    if Str_Of(Iptv_Prefs().pin) = ""
        m.livePage.command = { action: "unlock", group: group }
        return
    end if
    m.pinMode = "iptv"
    m.pinGroup = group
    m.pinPad.name = group
    m.pinPad.error = ""
    m.pinPad.working = false
    m.pinPad.visible = true
    m.pinPad.setFocus(true)
end sub

function Live_PinEntered() as boolean
    if Str_Of(m.pinMode) <> "iptv" then return false
    if m.pinPad.pin = "" then return true
    if m.pinPad.pin = Str_Of(Iptv_Prefs().pin)
        m.pinPad.visible = false
        m.pinMode = ""
        Live_FocusBack()
        m.livePage.command = { action: "unlock", group: Str_Of(m.pinGroup) }
    else
        m.pinPad.error = L("PIN incorrecto. Intenta de nuevo.")
    end if
    return true
end function

function Live_PinCancel() as boolean
    if Str_Of(m.pinMode) <> "iptv" then return false
    m.pinPad.visible = false
    m.pinMode = ""
    Live_FocusBack()
    return true
end function

sub Live_OptionsSheet(ev as object)
    key = Str_Of(ev.key)
    items = []
    if key <> ""
        if Bool_Of(ev.fav, false)
            items.Push({ id: "fav", label: L("Quitar de favoritos") })
        else
            items.Push({ id: "fav", label: L("Agregar a favoritos") })
        end if
    end if
    if Bool_Of(ev.watch, false)
        if type(ev.audio) = "roArray" and ev.audio.Count() > 1 then items.Push({ id: "audio", label: L("Audio") })
        items.Push({ id: "subs", label: L("Subtítulos") })
        if Bool_Of(ev.prev, false) then items.Push({ id: "prev", label: L("Canal anterior") })
    end if
    if key <> ""
        items.Push({ id: "rename", label: L("Renombrar canal") })
        items.Push({ id: "hide", label: L("Ocultar canal") })
    end if
    items.Push({ id: "refresh", label: L("Actualizar canales y guía") })
    items.Push({ id: "close", label: L("Cerrar") })
    Sheet_Open({ title: Str_Of(ev.name), items: items }, "liveOpts", ev)
end sub

sub Live_FocusBack()
    if m.livePage <> invalid and m.page = "live" and not overlayOpen()
        m.area = "page"
        m.livePage.setFocus(true)
    else
        focusCurrent()
    end if
end sub

function Live_Sheet(handler as string, choice as string, data as dynamic) as boolean
    if handler = "liveOpts"
        if choice = "fav"
            m.livePage.command = { action: "fav", key: Str_Of(data.key) }
            if Bool_Of(data.fav, false) then Toast_Show(L("Quitado de favoritos.")) else Toast_Show(L("Agregado a favoritos."))
        else if choice = "refresh"
            m.livePage.command = { action: "refresh" }
        else if choice = "prev"
            m.livePage.command = { action: "previous" }
        else if choice = "rename"
            cur = Str_Of(data.name)
            showKeyboard("liveRename", L("Nombre del canal (déjalo vacío para usar el original: {n})").Replace("{n}", Str_Of(data.original)), cur, { key: Str_Of(data.key) })
            return true
        else if choice = "hide"
            m.livePage.command = { action: "hide", key: Str_Of(data.key) }
            Toast_Show(L("Canal oculto. Puedes volver a mostrarlo en Ajustes → TV en vivo."))
        else if choice = "audio"
            items = []
            for each a in data.audio
                items.Push({ id: Str_Of(a.id), label: Str_Of(a.label) })
            end for
            Sheet_Open({ title: L("Audio"), items: items }, "liveAudio", data)
            return true
        else if choice = "subs"
            items = [{ id: "off", label: L("Desactivados"), checked: Str_Of(data.captions) = "Off" or Str_Of(data.captions) = "" }]
            if type(data.subs) = "roArray"
                for each sb in data.subs
                    items.Push({ id: "t:" + Str_Of(sb.id), label: Str_Of(sb.label) })
                end for
            end if
            if items.Count() = 1 then items.Push({ id: "on", label: L("Activados") })
            Sheet_Open({ title: L("Subtítulos"), items: items }, "liveSubs", data)
            return true
        end if
        Live_FocusBack()
        return true
    end if
    if handler = "liveHome"
        key = Str_Of(data.key)
        pid = Str_Of(St_ActiveProfile().id)
        if choice = "watch"
            Live_Select(m.liveHomeItem)
            return true
        else if choice = "unrecent"
            out = []
            v = St_Get("iptvRecent_" + pid, invalid)
            if type(v) = "roArray"
                for each k in v
                    if k <> key then out.Push(k)
                end for
            end if
            St_Set("iptvRecent_" + pid, out)
            Toast_Show(L("Quitado de canales recientes."))
        else if choice = "fav"
            if m.livePage <> invalid then m.livePage.command = { action: "fav", key: key }
        end if
        Live_HomeRefresh()
        focusCurrent()
        return true
    end if
    if handler = "liveRemind"
        if choice = "set"
            list = Iptv_Reminders()
            list.Push({ k: Str_Of(data.key), t: Str_Of(data.title), a: ToInt(data.a, 0), ch: Str_Of(data.channel), l: Str_Of(data.logo) })
            Iptv_SaveReminders(list)
            m.livePage.command = { action: "reminders" }
            Toast_Show(L("Listo. Te avisaremos cuando esté por empezar."))
        else if choice = "unset"
            out = []
            for each r in Iptv_Reminders()
                if not (Str_Of(r.k) = Str_Of(data.key) and ToInt(r.a, 0) = ToInt(data.a, 0)) then out.Push(r)
            end for
            Iptv_SaveReminders(out)
            m.livePage.command = { action: "reminders" }
            Toast_Show(L("Recordatorio quitado."))
        else if choice = "watch"
            Live_FocusBack()
            m.livePage.command = { action: "play", key: Str_Of(data.key) }
            return true
        end if
        Live_FocusBack()
        return true
    end if
    if handler = "liveGroup"
        label = Str_Of(data.group)
        if choice = "fav" or choice = "hide"
            m.livePage.command = { action: "group", what: choice, group: label }
            if choice = "hide" then Toast_Show(L("Grupo oculto. Puedes volver a mostrarlo en Ajustes → TV en vivo."))
        else if choice = "lock"
            if Str_Of(Iptv_Prefs().pin) = ""
                Toast_Show(L("Primero pon un PIN en Ajustes → TV en vivo → PIN."))
            else
                m.livePage.command = { action: "group", what: "lock", group: label }
            end if
        end if
        Live_FocusBack()
        return true
    end if
    if handler = "liveAudio"
        if choice <> "" then m.livePage.command = { action: "audio", track: choice }
        Live_FocusBack()
        return true
    end if
    if handler = "liveSubs"
        if choice = "off"
            m.livePage.command = { action: "captions", mode: "Off" }
        else if choice = "on"
            m.livePage.command = { action: "captions", mode: "On" }
        else if Left(choice, 2) = "t:"
            m.livePage.command = { action: "captions", mode: "On", track: Mid(choice, 3) }
        end if
        Live_FocusBack()
        return true
    end if
    if handler = "liveEpg"
        id = Str_Of(data.id)
        lists = Live_Lists()
        for each lst in lists
            if lst.id = id
                slots = Live_EpgList(Str_Of(lst.epg))
                if choice = "g1" or choice = "g2"
                    slot = 0
                    if choice = "g2" then slot = 1
                    cur = ""
                    if slots.Count() > slot then cur = slots[slot]
                    if cur = "" then cur = "http://"
                    title = L("Guía {n} (XMLTV, .xml o .xml.gz)").Replace("{n}", (slot + 1).ToStr())
                    showKeyboard("liveEpgEdit", title, cur, { id: id, slot: slot })
                    return true
                else if choice = "rm1" or choice = "rm2"
                    keep = []
                    for k = 0 to slots.Count() - 1
                        if not ((choice = "rm1" and k = 0) or (choice = "rm2" and k = 1)) then keep.Push(slots[k])
                    end for
                    lst.epg = keep.Join(",")
                else if choice = "add"
                    lst.epgAdd = not Bool_Of(lst.epgAdd, false)
                else if choice = "auto"
                    lst.epg = ""
                    lst.epgAdd = false
                end if
            end if
        end for
        if choice <> "close" and choice <> ""
            Live_SaveLists(lists)
            refreshSettings()
        end if
        focusCurrent()
        return true
    end if
    if handler = "liveList"
        id = Str_Of(data.id)
        lists = Live_Lists()
        out = []
        for each lst in lists
            if lst.id = id
                if choice = "toggle"
                    lst.on = lst.on = false
                    out.Push(lst)
                else if choice = "auto"
                    lst.epg = ""
                    out.Push(lst)
                else if choice = "share"
                    lst.shared = not Bool_Of(lst.shared, false)
                    out.Push(lst)
                else if choice = "epg"
                    out.Push(lst)
                    Live_EpgSheet(lst)
                else if choice <> "remove"
                    out.Push(lst)
                end if
            else
                out.Push(lst)
            end if
        end for
        if choice = "toggle" or choice = "remove" or choice = "share" or choice = "auto"
            Live_SaveLists(out)
            refreshSettings()
            focusCurrent()
        else if choice <> "epg"
            focusCurrent()
        end if
        return true
    end if
    return false
end function

function Live_Sections() as object
    sec = { id: "live", label: L("TV en vivo"), subtitle: L("Listas M3U y cuentas Xtream"), rows: [] }
    sec.rows.Push(Set_Header(L("Listas")))
    lists = Live_Lists()
    if lists.Count() = 0 then sec.rows.Push(Set_Info("liveNone", L("Todavía no hay listas."), L("Agrega una lista M3U o una cuenta Xtream para ver canales en vivo con su guía."), ""))
    for each lst in lists
        kind = "M3U"
        if Str_Of(lst.type) = "xtream" then kind = "Xtream"
        status = L("Activada")
        if lst.on = false then status = L("Desactivada")
        desc = kind + "  ·  " + Str_Of(lst.url) + Str_Of(lst.server)
        if not Iptv_Mine(lst)
            desc = desc + chr(10) + L("Compartida por {p}").Replace("{p}", Iptv_OwnerName(lst))
        else if Bool_Of(lst.shared, false)
            desc = desc + chr(10) + L("Compartida con los otros perfiles")
        end if
        if Str_Of(lst.epg) <> "" then desc = desc + chr(10) + L("Guía: {u}").Replace("{u}", Str_Of(lst.epg))
        sec.rows.Push(Set_Row("liveList:" + lst.id, Str_Of(lst.name), desc, status))
    end for
    sec.rows.Push(Set_Header(L("Agregar")))
    sec.rows.Push(Set_Row("liveAdd:m3u", L("Lista M3U"), L("Escribe la dirección de tu lista .m3u o .m3u8. Si trae guía, se usa sola."), ""))
    sec.rows.Push(Set_Row("liveAdd:xtream", L("Cuenta Xtream"), L("Servidor, usuario y contraseña de tu proveedor. La guía se carga sola."), ""))
    sec.rows.Push(Set_Header(L("Guía (EPG)")))
    epgs = ParseJson(ReadAsciiFile("cachefs:/iptv_epgs_" + Iptv_Pid() + ".json"))
    if type(epgs) <> "roAssociativeArray" then epgs = {}
    stat = ParseJson(ReadAsciiFile("cachefs:/iptv_epgstat_" + Iptv_Pid() + ".json"))
    stats = {}
    if type(stat) = "roAssociativeArray" and type(stat.stats) = "roAssociativeArray" then stats = stat.stats
    for each lst in lists
        info = epgs[lst.id]
        urls = Iptv_GuideUrls(lst, info)
        slots = Live_EpgList(Str_Of(lst.epg))
        lines = []
        status = ""
        if urls.Count() = 0
            if type(info) = "roAssociativeArray" then lines.Push(L("Esta lista no trae guía. Puedes poner la dirección de una guía XMLTV.")) else lines.Push(L("Se ve cuando se carguen los canales."))
            status = L("Sin guía")
        else
            if slots.Count() = 0
                status = L("De la lista")
            else if Bool_Of(lst.epgAdd, false)
                status = L("Personalizada + de la lista")
            else
                status = L("Personalizada")
            end if
            k = 0
            for each u in urls
                k = k + 1
                line = k.ToStr() + ". " + Live_GuideName(u)
                st = stats[u]
                if type(st) = "roAssociativeArray"
                    if ToInt(st.n, -1) < 0
                        line = line + "  ·  " + L("No se pudo cargar esta guía.")
                    else
                        line = line + "  ·  " + L("{n} programas cargados en {c} canales").Replace("{n}", ToInt(st.n, 0).ToStr()).Replace("{c}", ToInt(st.ch, 0).ToStr())
                        if Bool_Of(st.cut, false) then line = line + "  ·  " + L("llegó incompleta")
                    end if
                end if
                lines.Push(line)
            end for
        end if
        sec.rows.Push(Set_Row("liveEpg:" + lst.id, L("Guía de {n}").Replace("{n}", Str_Of(lst.name)), lines.Join(chr(10)), status))
    end for
    sec.rows.Push(Set_Row("liveRefresh", L("Actualizar canales y guía"), L("Vuelve a descargar las listas y la guía ahora."), ""))
    pr = Iptv_Prefs()
    sec.rows.Push(Set_Header(L("Cómo se ve la guía")))
    sec.rows.Push(Set_Row("liveSet:size", L("Tamaño de la guía"), L("Compacta muestra más canales a la vez; Grande, letras más grandes."), Live_SizeName(Str_Of(pr.size))))
    sec.rows.Push(Set_Toggle("liveSet:nums", L("Números de canal"), "", Bool_Of(pr.nums, true)))
    sec.rows.Push(Set_Toggle("liveSet:logos", L("Logos de los canales"), "", Bool_Of(pr.logos, true)))
    sec.rows.Push(Set_Toggle("liveSet:names", L("Nombres de los canales"), "", Bool_Of(pr.names, true)))
    sec.rows.Push(Set_Toggle("liveSet:twoLine", L("Nombres en dos líneas"), L("Para nombres largos."), Bool_Of(pr.twoLine, false)))
    sec.rows.Push(Set_Toggle("liveSet:times", L("Horario en cada programa"), "", Bool_Of(pr.times, true)))
    sec.rows.Push(Set_Toggle("liveSet:nowLine", L("Línea de la hora actual"), "", Bool_Of(pr.nowLine, true)))
    sec.rows.Push(Set_Toggle("liveSet:markPlaying", L("Marcar el canal que se está viendo"), L("Un borde rojo en el canal que suena."), Bool_Of(pr.markPlaying, true)))
    sec.rows.Push(Set_Toggle("liveSet:tmdbArt", L("Imágenes de películas y series"), L("Si la guía no trae imagen, la busca en TMDB por el título del programa. Necesita tu clave de TMDB."), Bool_Of(pr.tmdbArt, true)))
    sec.rows.Push(Set_Toggle("liveSet:preview", L("Vista previa"), L("Reproduce el canal en la esquina al quedarte en él."), Bool_Of(pr.preview, true)))
    sec.rows.Push(Set_Header(L("Al abrir TV en vivo")))
    sec.rows.Push(Set_Toggle("liveSet:lastGroup", L("Abrir en el último grupo"), "", Bool_Of(pr.lastGroup, true)))
    sec.rows.Push(Set_Toggle("liveSet:startLast", L("Empezar en el último canal"), L("Abre directo en pantalla completa el último canal que viste."), Bool_Of(pr.startLast, false)))
    sec.rows.Push(Set_Header(L("Reproducción")))
    sec.rows.Push(Set_Toggle("liveSet:reconnect", L("Reconectar solo"), L("Si el canal se corta o se congela, vuelve a conectarse."), Bool_Of(pr.reconnect, true)))
    sec.rows.Push(Set_Toggle("liveSet:backup", L("Cambiar a otra opción si falla"), L("Si el canal tiene varias opciones y una no funciona, pasa sola a la siguiente."), Bool_Of(pr.backup, true)))
    sec.rows.Push(Set_Toggle("liveSet:rememberTracks", L("Recordar audio y subtítulos de cada canal"), "", Bool_Of(pr.rememberTracks, true)))
    sec.rows.Push(Set_Toggle("liveSet:reverseZap", L("Invertir Arriba y Abajo"), L("Arriba baja de canal y Abajo sube."), Bool_Of(pr.reverseZap, false)))
    sec.rows.Push(Set_Row("liveSet:barSecs", L("Tiempo de la barra del canal"), L("Cuánto se queda la información al cambiar de canal."), ToInt(pr.barSecs, 6).ToStr() + " s"))
    sec.rows.Push(Set_Header(L("Actualización y hora")))
    sec.rows.Push(Set_Row("liveSet:listHours", L("Actualizar las listas cada"), "", ToInt(pr.listHours, 12).ToStr() + " h"))
    sec.rows.Push(Set_Row("liveSet:epgHours", L("Actualizar la guía cada"), "", ToInt(pr.epgHours, 6).ToStr() + " h"))
    sec.rows.Push(Set_Row("liveSet:epgShift", L("Ajustar la hora de la guía"), L("Si los programas salen adelantados o atrasados."), Live_ShiftName(ToInt(pr.epgShift, 0))))
    sec.rows.Push(Set_Header(L("Canales")))
    hid = Iptv_Store("Hidden").Count() + Iptv_Store("HiddenGroups").Count()
    sec.rows.Push(Set_Row("liveUnhide", L("Canales y grupos ocultos"), L("Elige para volver a mostrarlos todos. Para ocultar, presiona * en un canal o en un grupo."), hid.ToStr()))
    pinState = L("Sin PIN")
    if Str_Of(pr.pin) <> "" then pinState = L("Activado")
    sec.rows.Push(Set_Row("livePin", L("PIN"), L("Para bloquear grupos. En la lista de grupos, presiona * en un grupo y elige Bloquear con PIN."), pinState))
    return sec
end function

function Live_SizeName(v as string) as string
    if v = "compact" then return L("Compacta")
    if v = "large" then return L("Grande")
    return L("Normal")
end function

function Live_ShiftName(mins as integer) as string
    if mins = 0 then return L("Sin cambio")
    sign = "+"
    if mins < 0 then sign = "-"
    a = Abs(mins)
    h = Int(a / 60)
    mm = a mod 60
    txt = sign + h.ToStr() + " h"
    if mm > 0 then txt = txt + " " + mm.ToStr() + " min"
    return txt
end function

sub Live_PrefsChanged()
    if m.livePage <> invalid then m.livePage.command = { action: "prefs" }
    refreshSettings()
end sub

function Live_Cycle(list as object, cur as dynamic) as dynamic
    for i = 0 to list.Count() - 1
        if Str_Of(list[i]) = Str_Of(cur) then return list[(i + 1) mod list.Count()]
    end for
    return list[0]
end function

function Live_Row(row as string) as boolean
    if Left(row, 8) = "liveSet:"
        name = Mid(row, 9)
        pr = Iptv_Prefs()
        if name = "size"
            Iptv_SetPref(name, Live_Cycle(["compact", "normal", "large"], pr.size))
        else if name = "barSecs"
            Iptv_SetPref(name, Live_Cycle([3, 6, 10, 15], ToInt(pr.barSecs, 6)))
        else if name = "listHours"
            Iptv_SetPref(name, Live_Cycle([6, 12, 24, 48], ToInt(pr.listHours, 12)))
        else if name = "epgHours"
            Iptv_SetPref(name, Live_Cycle([3, 6, 12, 24], ToInt(pr.epgHours, 6)))
        else if name = "epgShift"
            Iptv_SetPref(name, Live_Cycle([0, 30, 60, 90, 120, 180, -180, -120, -90, -60, -30], ToInt(pr.epgShift, 0)))
        else
            Iptv_SetPref(name, not Bool_Of(pr[name], Bool_Of(Iptv_PrefDefaults()[name], false)))
        end if
        Live_PrefsChanged()
        return true
    end if
    if row = "liveUnhide"
        if m.livePage <> invalid then m.livePage.command = { action: "unhideAll" } else Iptv_SaveStore("Hidden", {})
        Toast_Show(L("Se muestran otra vez todos los canales y grupos."))
        refreshSettings()
        return true
    end if
    if row = "livePin"
        showKeyboard("livePinSet", L("PIN de 4 a 8 números (déjalo vacío para quitarlo)"), "", {})
        return true
    end if
    if Left(row, 8) = "liveAdd:"
        kind = Mid(row, 9)
        m.liveForm = { type: kind }
        if kind = "xtream"
            showKeyboard("liveServer", L("Servidor (por ejemplo http://proveedor.com:8080)"), "http://", {})
        else
            showKeyboard("liveUrl", L("Dirección de la lista M3U"), "http://", {})
        end if
        return true
    end if
    if Left(row, 9) = "liveList:"
        id = Mid(row, 10)
        for each lst in Live_Lists()
            if lst.id = id
                if Iptv_Mine(lst)
                    toggle = L("Desactivar")
                    if lst.on = false then toggle = L("Activar")
                    share = L("Compartir con los otros perfiles")
                    if Bool_Of(lst.shared, false) then share = L("Dejar de compartir con los otros perfiles")
                    items = [{ id: "toggle", label: toggle }, { id: "share", label: share }, { id: "epg", label: L("Cambiar guía (XMLTV)") }, { id: "remove", label: L("Quitar lista"), danger: true }, { id: "close", label: L("Cerrar") }]
                    Sheet_Open({ title: Str_Of(lst.name), items: items }, "liveList", { id: id })
                else
                    Sheet_Open({ title: Str_Of(lst.name), subtitle: L("Compartida por {p}").Replace("{p}", Iptv_OwnerName(lst)) + chr(10) + L("Solo ese perfil puede cambiarla."), items: [{ id: "close", label: L("Cerrar") }] }, "liveList", { id: id })
                end if
            end if
        end for
        return true
    end if
    if Left(row, 8) = "liveEpg:"
        id = Mid(row, 9)
        for each lst in Live_Lists()
            if lst.id = id
                if Iptv_Mine(lst)
                    Live_EpgSheet(lst)
                else
                    showMessage(L("Guía (EPG)"), L("Solo ese perfil puede cambiarla."))
                end if
            end if
        end for
        return true
    end if
    if row = "liveRefresh"
        if m.livePage <> invalid then m.livePage.command = { action: "refresh" }
        Toast_Show(L("Actualizando canales y guía..."))
        return true
    end if
    return false
end function

function Live_Host(url as string) as string
    a = url
    p = Instr(1, a, "://")
    if p > 0 then a = Mid(a, p + 3)
    s = Instr(1, a, "/")
    if s > 0 then a = Left(a, s - 1)
    c = Instr(1, a, "@")
    if c > 0 then a = Mid(a, c + 1)
    return a
end function

function Live_Keyboard(kind as string, text as string, data as dynamic) as boolean
    if kind = "liveRename"
        m.livePage.command = { action: "rename", key: Str_Of(data.key), name: text }
        Live_FocusBack()
        return true
    end if
    if kind = "livePinSet"
        pin = text.Trim()
        ok = Len(pin) >= 4 and Len(pin) <= 8
        for i = 1 to Len(pin)
            ch = Mid(pin, i, 1)
            if ch < "0" or ch > "9" then ok = false
        end for
        if pin = ""
            Iptv_SetPref("pin", "")
            Toast_Show(L("PIN quitado."))
        else if ok
            Iptv_SetPref("pin", pin)
            Toast_Show(L("PIN guardado."))
        else
            Toast_Show(L("El PIN debe tener de 4 a 8 números."))
        end if
        Live_PrefsChanged()
        return true
    end if
    if kind = "liveUrl"
        m.liveForm.url = text.Trim()
        showKeyboard("liveName", L("Nombre de la lista"), Live_Host(m.liveForm.url), {})
        return true
    end if
    if kind = "liveServer"
        m.liveForm.server = text.Trim()
        showKeyboard("liveUser", L("Usuario"), "", {})
        return true
    end if
    if kind = "liveUser"
        m.liveForm.user = text.Trim()
        showKeyboard("livePass", L("Contraseña"), "", {})
        return true
    end if
    if kind = "livePass"
        m.liveForm.pass = text.Trim()
        showKeyboard("liveName", L("Nombre de la lista"), Live_Host(Str_Of(m.liveForm.server)), {})
        return true
    end if
    if kind = "liveName"
        f = m.liveForm
        if f = invalid then return true
        name = text.Trim()
        if name = "" then name = L("Mi lista")
        entry = { id: CreateObject("roDeviceInfo").GetRandomUUID(), type: Str_Of(f.type), name: name, url: Str_Of(f.url), server: Str_Of(f.server), user: Str_Of(f.user), pass: Str_Of(f.pass), epg: "", on: true, owner: Iptv_Pid(), shared: false }
        if (entry.type = "xtream" and (entry.server = "" or entry.user = "")) or (entry.type <> "xtream" and entry.url = "")
            showMessage(L("TV en vivo"), L("Faltan datos de la lista."))
            return true
        end if
        lists = Live_Lists()
        lists.Push(entry)
        Live_SaveLists(lists)
        m.liveForm = invalid
        refreshSettings()
        Toast_Show(L("Lista agregada. Cargando canales..."))
        focusCurrent()
        return true
    end if
    if kind = "liveEpgEdit"
        id = Str_Of(data.id)
        slot = ToInt(data.slot, -1)
        url = text.Trim()
        if LCase(url) = "http://" or LCase(url) = "https://" then url = ""
        lists = Live_Lists()
        for each lst in lists
            if lst.id = id
                if slot < 0
                    lst.epg = url
                else
                    slots = Live_EpgList(Str_Of(lst.epg))
                    while slots.Count() <= slot
                        slots.Push("")
                    end while
                    slots[slot] = url
                    keep = []
                    for each u in slots
                        if u <> "" then keep.Push(u)
                    end for
                    lst.epg = keep.Join(",")
                end if
            end if
        end for
        Live_SaveLists(lists)
        refreshSettings()
        focusCurrent()
        return true
    end if
    return false
end function

function Live_HomeRows() as object
    out = []
    if m.livePage = invalid then return out
    data = m.livePage.callFunc("Live_HomeData", invalid)
    if type(data) <> "roAssociativeArray" then return out
    if type(data.favs) = "roArray" and data.favs.Count() > 0 then out.Push(Live_HomeRowOf(L("Canales favoritos"), data.favs))
    if type(data.recent) = "roArray" and data.recent.Count() > 0 then out.Push(Live_HomeRowOf(L("Canales recientes"), data.recent))
    return out
end function

function Live_HomeRowOf(title as string, list as object) as object
    row = CreateObject("roSGNode", "ContentNode")
    row.title = title
    row.addFields({ shape: "landscape", key: "live" })
    for each c in list
        it = row.createChild("ContentNode")
        name = Str_Of(c.n)
        it.title = name
        it.HDPosterUrl = Str_Of(c.l)
        line = L("TV en vivo")
        if Str_Of(c.g) <> "" then line = line + "  ·  " + Str_Of(c.g)
        desc = ""
        if Str_Of(c.now) <> ""
            desc = L("Ahora") + ": " + Str_Of(c.now)
            if Str_Of(c.left) <> "" then desc = desc + "  ·  " + Str_Of(c.left)
            if Str_Of(c.next) <> "" then desc = desc + "  ·  " + L("Sigue") + ": " + Str_Of(c.next)
            if Str_Of(c.d) <> "" then desc = desc + chr(10) + Str_Of(c.d)
        else
            desc = L("Canal en vivo") + " — " + name + "."
        end if
        bg = Str_Of(c.backdrop)
        pct = ToInt(c.pct, -1)
        progress = 0.0
        if pct > 0 then progress = pct / 100.0
        it.addFields({ itemType: "folder", channelKey: Str_Of(c.k), background: bg, logo: Str_Of(c.l), metaLine: line, heroDescription: desc, hideTitle: false, progress: progress })
    end for
    return row
end function

sub Live_HomeInsert(content as object)
    if m.livePage = invalid or content = invalid then return
    for i = content.getChildCount() - 1 to 0 step -1
        rw = content.getChild(i)
        if rw.hasField("key") and Str_Of(rw.key) = "live" then content.removeChildIndex(i)
    end for
    rows = Live_HomeRows()
    if rows.Count() = 0 then return
    at = 0
    for i = 0 to content.getChildCount() - 1
        rw = content.getChild(i)
        if Cw_IsRow(rw) or (rw.hasField("shape") and rw.shape = "hero") then at = i + 1 else exit for
    end for
    for each row in rows
        content.insertChild(row, at)
        at = at + 1
    end for
end sub

function Live_HomeOnly() as boolean
    if m.livePage = invalid then return false
    rows = Live_HomeRows()
    if rows.Count() = 0 then return false
    content = CreateObject("roSGNode", "ContentNode")
    Home_Show(content)
    return true
end function

sub Live_HomeRefresh()
    if m.livePage = invalid or m.homeRows = invalid then return
    content = m.homeRows.content
    if content = invalid or content.getChildCount() = 0
        if m.emptyState.visible then Live_HomeOnly()
        return
    end if
    focus = m.homeRows.rowItemFocused
    had = false
    for i = 0 to content.getChildCount() - 1
        rw = content.getChild(i)
        if rw.hasField("key") and Str_Of(rw.key) = "live" then had = true
    end for
    if Live_HomeRows().Count() = 0 and not had then return
    Live_HomeInsert(content)
    applyRowSizes(m.homeRows)
    if type(focus) = "roArray" and focus.Count() >= 2 and m.homeRows.isInFocusChain() then m.homeRows.jumpToRowItem = focus
end sub

function Live_Select(item as object) as boolean
    if m.livePage = invalid or not item.hasField("channelKey") then return false
    key = Str_Of(item.channelKey)
    if key = "" then return false
    m.area = "page"
    showPage("live")
    m.livePage.command = { action: "play", key: key }
    return true
end function

function Live_EpgList(text as string) as object
    out = []
    flat = text.Replace(chr(10), ",").Replace(chr(13), ",").Replace(" ", ",").Replace(";", ",")
    for each part in flat.Split(",")
        u = part.Trim()
        if u <> "" then out.Push(u)
    end for
    return out
end function

sub Live_EpgSheet(lst as object)
    slots = Live_EpgList(Str_Of(lst.epg))
    items = []
    if slots.Count() > 0
        items.Push({ id: "g1", label: L("Guía 1") + ":  " + Live_GuideName(slots[0]) })
    else
        items.Push({ id: "g1", label: L("Poner guía 1") })
    end if
    if slots.Count() > 1
        items.Push({ id: "g2", label: L("Guía 2") + ":  " + Live_GuideName(slots[1]) })
        items.Push({ id: "rm2", label: L("Quitar guía 2"), danger: true })
    else if slots.Count() = 1
        items.Push({ id: "g2", label: L("Agregar guía 2") })
        items.Push({ id: "rm1", label: L("Quitar guía 1"), danger: true })
    end if
    if slots.Count() > 0
        items.Push({ id: "add", label: L("Usar también la guía de la lista"), checked: Bool_Of(lst.epgAdd, false) })
        items.Push({ id: "auto", label: L("Usar solo la guía de la lista") })
    end if
    items.Push({ id: "close", label: L("Cerrar") })
    sub1 = L("Puedes usar dos guías a la vez. Los canales toman sus programas de la guía que los tenga.")
    Sheet_Open({ title: L("Guía de {n}").Replace("{n}", Str_Of(lst.name)), subtitle: sub1, items: items }, "liveEpg", { id: lst.id })
end sub

function Live_GuideName(url as string) as string
    host = Live_Host(url)
    path = url
    q = Instr(1, path, "?")
    if q > 0 then path = Left(path, q - 1)
    parts = path.Split("/")
    last = ""
    if parts.Count() > 3 then last = parts[parts.Count() - 1]
    if last = "" then return host
    return host + "  ·  " + last
end function

sub Live_RemindSheet(ev as object)
    items = []
    if Bool_Of(ev.set, false) then items.Push({ id: "unset", label: L("Quitar recordatorio") }) else items.Push({ id: "set", label: L("Recordarme cuando empiece") })
    items.Push({ id: "watch", label: L("Ver el canal ahora") })
    items.Push({ id: "close", label: L("Cerrar") })
    sub1 = Str_Of(ev.channel) + "  ·  " + Live_ClockAt(ToInt(ev.a, 0))
    Sheet_Open({ title: Str_Of(ev.title), subtitle: sub1, items: items }, "liveRemind", ev)
end sub

function Live_ClockAt(t as integer) as string
    d = CreateObject("roDateTime")
    d.FromSeconds(t)
    d.ToLocalTime()
    return Fmt_Clock(d)
end function

sub Live_CheckReminders()
    list = Iptv_Reminders()
    if list.Count() = 0 then return
    now = CreateObject("roDateTime").AsSeconds()
    keep = []
    changed = false
    for each r in list
        a = ToInt(r.a, 0)
        if now >= a - 90
            changed = true
            if now < a + 600 and m.reminderCard <> invalid
                m.reminderCard.show = { head: L("Está por comenzar"), title: Str_Of(r.t), line: Str_Of(r.ch) + "  ·  " + Live_ClockAt(a), logo: Str_Of(r.l) }
            end if
        else
            keep.Push(r)
        end if
    end for
    if changed
        Iptv_SaveReminders(keep)
        if m.livePage <> invalid then m.livePage.command = { action: "reminders" }
    end if
end sub

function Live_HomeSheet(item as object) as boolean
    key = Str_Of(item.channelKey)
    m.liveHomeItem = item
    pid = Str_Of(St_ActiveProfile().id)
    isFav = false
    v = St_Get("iptvFavs_" + pid, invalid)
    if type(v) = "roArray"
        for each k in v
            if k = key then isFav = true
        end for
    end if
    inRecent = false
    v = St_Get("iptvRecent_" + pid, invalid)
    if type(v) = "roArray"
        for each k in v
            if k = key then inRecent = true
        end for
    end if
    items = [{ id: "watch", label: L("Ver el canal ahora") }]
    if isFav then items.Push({ id: "fav", label: L("Quitar de favoritos") }) else items.Push({ id: "fav", label: L("Agregar a favoritos") })
    if inRecent then items.Push({ id: "unrecent", label: L("Quitar de canales recientes") })
    items.Push({ id: "close", label: L("Cerrar") })
    Sheet_Open({ title: Str_Of(item.title), items: items, style: "tv" }, "liveHome", { key: key })
    return true
end function


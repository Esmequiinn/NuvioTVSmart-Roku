function Conn_Sections(integ as object) as object
    debrid = { id: "debrid", label: L("Servicios conectados"), subtitle: L("Conecta cuentas para obtener enlaces"), rows: [] }
    debrid.rows.Push(Set_Info("debNote", L("Experimental"), L("Estas integraciones son experimentales y podrían cambiar o quitarse más adelante."), ""))
    debrid.rows.Push(Set_Header(L("Cuentas")))
    for each p in Deb_Providers()
        key = Deb_Key(integ, p.id)
        value = L("Sin configurar")
        if key <> "" then value = L("Conectada")
        desc = L("Conecta tu cuenta de {p}.").Replace("{p}", p.name)
        if p.id = "torbox" then desc = L("Vincula tu cuenta de TorBox en el navegador con un código QR, o escribe tu clave de API.")
        if p.id = "premiumize" then desc = L("Escribe tu clave de API de premiumize.me (Cuenta → Clave de API).")
        if Str_Of(integ[p.id + "From"]) = "account" and key <> "" then desc = desc + chr(10) + L("Viene de tu cuenta de Nuvio.")
        debrid.rows.Push(Set_Row("deb:" + p.id, p.name, desc, value))
    end for
    debrid.rows.Push(Set_Header(L("Enlaces")))
    debrid.rows.Push(Set_Toggle("debridOn", L("Resolver enlaces reproducibles"), L("Pide al servicio conectado un enlace reproducible cuando un resultado lo necesita (torrents en caché). Puede agregar el título a ese servicio."), Bool_Of(integ.debridOn, false)))
    connected = Deb_Connected(integ)
    if connected.Count() > 1
        active = Deb_Active(integ)
        name = connected[0].name
        if active <> invalid then name = active.name
        debrid.rows.Push(Set_Row("debridPick", L("Resolver con"), L("Elige qué cuenta conectada prepara los enlaces."), name))
    end if

    servers = { id: "servers", label: L("Servidores multimedia"), subtitle: L("Conecta Jellyfin o Emby"), rows: [] }
    servers.rows.Push(Set_Header(L("Servidores")))
    list = Srv_List()
    if list.Count() = 0 then servers.rows.Push(Set_Info("srvNone", L("Todavía no hay servidores conectados."), L("Conecta Jellyfin o Emby para ver tu propia biblioteca en el inicio y como fuente al reproducir."), ""))
    for each sv in list
        on = 0
        if type(sv.libs) = "roArray"
            for each lb in sv.libs
                if lb.on <> false then on = on + 1
            end for
        end if
        status = L("Activado")
        if sv.on = false then status = L("Desactivado")
        desc = Srv_KindName(Str_Of(sv.kind)) + "  ·  " + Str_Of(sv.userName) + "  ·  " + on.ToStr() + " " + L("bibliotecas")
        servers.rows.Push(Set_Row("srv:" + sv.id, Str_Of(sv.name), desc, status))
    end for
    servers.rows.Push(Set_Header(L("Agregar servidor")))
    for each k in Srv_Kinds()
        servers.rows.Push(Set_Row("srvAdd:" + k.id, k.name, L("Inicia sesión con la dirección de tu servidor y un usuario de {p}.").Replace("{p}", k.name), ""))
    end for
    return [debrid, servers]
end function

function Conn_Row(row as string) as boolean
    integ = St_Integrations()
    if Left(row, 4) = "deb:"
        id = Mid(row, 5)
        name = Deb_Name(id)
        items = []
        if Deb_Key(integ, id) <> ""
            items.Push({ id: "key", label: L("Cambiar clave de API") })
            items.Push({ id: "off", label: L("Desconectar"), danger: true })
        else
            if id = "torbox" then items.Push({ id: "qr", label: L("Vincular con código QR") })
            items.Push({ id: "key", label: L("Escribir clave de API") })
        end if
        items.Push({ id: "close", label: L("Cerrar") })
        Sheet_Open({ title: name, subtitle: L("Conecta tu cuenta de {p}.").Replace("{p}", name), items: items }, "debAcc", { id: id })
        return true
    end if
    if row = "debridOn"
        if Deb_Connected(integ).Count() = 0 and not Bool_Of(integ.debridOn, false)
            showMessage(L("Servicios conectados"), L("Primero conecta una cuenta."))
            return true
        end if
        integ["debridOn"] = not Bool_Of(integ.debridOn, false)
        St_SaveIntegrations(integ)
        refreshSettings()
        return true
    end if
    if row = "debridPick"
        items = []
        for each c in Deb_Connected(integ)
            items.Push({ id: c.id, label: c.name })
        end for
        Sheet_Open({ title: L("Resolver con"), items: items }, "debPick", invalid)
        return true
    end if
    if Left(row, 7) = "srvAdd:"
        kind = Mid(row, 8)
        m.srvForm = { kind: kind }
        showKeyboard("srvAddr", L("Dirección del servidor") + " (" + Srv_KindName(kind) + ")", "http://", { kind: kind })
        return true
    end if
    if Left(row, 4) = "srv:"
        Conn_ServerMenu(Mid(row, 5))
        return true
    end if
    return false
end function

sub Conn_ServerMenu(id as string)
    sv = Srv_Find(id)
    if sv = invalid then return
    toggle = L("Desactivar")
    if sv.on = false then toggle = L("Activar")
    items = [{ id: "toggle", label: toggle }, { id: "libs", label: L("Bibliotecas") }, { id: "refresh", label: L("Actualizar bibliotecas") }, { id: "again", label: L("Volver a iniciar sesión") }, { id: "remove", label: L("Quitar servidor"), danger: true }, { id: "close", label: L("Cerrar") }]
    text = Srv_KindName(Str_Of(sv.kind)) + "  ·  " + Str_Of(sv.address) + chr(10) + L("Conectado como {u}").Replace("{u}", Str_Of(sv.userName))
    Sheet_Open({ title: Str_Of(sv.name), subtitle: text, items: items }, "srvMenu", { id: id })
end sub

sub Conn_LibMenu(id as string)
    sv = Srv_Find(id)
    if sv = invalid then return
    items = []
    if type(sv.libs) = "roArray"
        for each lb in sv.libs
            items.Push({ id: Str_Of(lb.id), label: Str_Of(lb.name) + "  ·  " + TypePlural(Str_Of(lb.kind)), checked: lb.on <> false })
        end for
    end if
    if items.Count() = 0 then items.Push({ id: "", label: L("Este usuario no tiene bibliotecas de películas o series.") })
    items.Push({ id: "close", label: L("Listo") })
    Sheet_Open({ title: L("Bibliotecas"), subtitle: L("Las bibliotecas elegidas aparecen en el inicio y en las fuentes."), items: items }, "srvLibs", { id: id })
end sub

function Conn_Sheet(handler as string, choice as string, data as dynamic) as boolean
    if handler = "debAcc"
        id = Str_Of(data.id)
        if choice = "qr"
            startLogin("torbox")
        else if choice = "key"
            integ = St_Integrations()
            showKeyboard("debKey", L("Clave de API de {p}").Replace("{p}", Deb_Name(id)), Deb_Key(integ, id), { id: id })
        else if choice = "off"
            integ = St_Integrations()
            integ[id + "Key"] = ""
            integ[id + "From"] = ""
            if Deb_Connected(integ).Count() = 0 then integ["debridOn"] = false
            St_SaveIntegrations(integ)
            refreshSettings()
            focusCurrent()
        else
            focusCurrent()
        end if
        return true
    end if
    if handler = "debPick"
        if choice <> ""
            integ = St_Integrations()
            integ["debridPick"] = choice
            St_SaveIntegrations(integ)
            refreshSettings()
        end if
        focusCurrent()
        return true
    end if
    if handler = "srvMenu"
        id = Str_Of(data.id)
        sv = Srv_Find(id)
        if sv = invalid
            focusCurrent()
            return true
        end if
        if choice = "toggle"
            sv.on = sv.on = false
            Srv_Put(sv)
            m.needsReload = true
            refreshSettings()
            focusCurrent()
        else if choice = "libs"
            Conn_LibMenu(id)
        else if choice = "refresh"
            Conn_Run("srvRefresh", { id: id }, L("Actualizando bibliotecas..."))
        else if choice = "again"
            m.srvForm = { kind: Str_Of(sv.kind), address: Str_Of(sv.address), user: Str_Of(sv.userName) }
            showKeyboard("srvPass", L("Contraseña de {u}").Replace("{u}", Str_Of(sv.userName)), "", { kind: Str_Of(sv.kind) })
        else if choice = "remove"
            Srv_Remove(id)
            m.needsReload = true
            refreshSettings()
            focusCurrent()
        else
            focusCurrent()
        end if
        return true
    end if
    if handler = "srvLibs"
        id = Str_Of(data.id)
        if choice = "close" or choice = ""
            focusCurrent()
            return true
        end if
        sv = Srv_Find(id)
        if sv <> invalid and type(sv.libs) = "roArray"
            for each lb in sv.libs
                if Str_Of(lb.id) = choice then lb.on = lb.on = false
            end for
            Srv_Put(sv)
            m.needsReload = true
            refreshSettings()
        end if
        Conn_LibMenu(id)
        return true
    end if
    return false
end function

function Conn_Keyboard(kind as string, text as string, data as dynamic) as boolean
    if kind = "debKey"
        Conn_Run("debKey", { id: Str_Of(data.id), key: text.Trim() }, L("Revisando la clave..."))
        return true
    end if
    if kind = "srvAddr"
        m.srvForm.address = text.Trim()
        showKeyboard("srvUser", L("Usuario"), "", data)
        return true
    end if
    if kind = "srvUser"
        m.srvForm.user = text.Trim()
        showKeyboard("srvPass", L("Contraseña"), "", data)
        return true
    end if
    if kind = "srvPass"
        f = m.srvForm
        if f = invalid then return true
        Conn_Run("srvSignIn", { kind: Str_Of(f.kind), address: Str_Of(f.address), user: Str_Of(f.user), pass: text }, L("Conectando..."))
        return true
    end if
    return false
end function

sub Conn_Run(mode as string, params as object, busyText as string)
    showBusy(busyText)
    m.connTask = CreateObject("roSGNode", "AccountTask")
    m.connTask.mode = mode
    m.connTask.params = params
    m.connTask.observeField("result", "onConnDone")
    m.connTask.control = "RUN"
end sub

sub onConnDone(event as object)
    task = event.getRoSGNode()
    if m.connTask = invalid or not task.isSameNode(m.connTask) then return
    m.connTask = invalid
    hideBusy()
    r = task.result
    if r = invalid then r = {}
    mode = Str_Of(r.mode)
    if not Bool_Of(r.ok, false)
        showMessage(L("No se pudo conectar"), Str_Of(r.error))
        return
    end if
    refreshSettings()
    if mode = "srvSignIn" or mode = "srvRefresh"
        m.needsReload = true
        m.srvForm = invalid
        Toast_Show(L("Servidor conectado."))
    else if mode = "debKey"
        if Str_Of(r.key) = "" then Toast_Show(L("Clave quitada.")) else Toast_Show(L("Tu cuenta quedó conectada."))
    end if
    focusCurrent()
end sub

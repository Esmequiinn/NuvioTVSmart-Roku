sub VodUi_FixStart(item as object)
    kind = LCase(Str_Of(item.itemType))
    if kind = "tv" then kind = "series"
    showKeyboard("vodFix", L("Escribe el nombre como aparece en TMDB (puedes agregar el año). Déjalo vacío para volver a automático."), Str_Of(item.title), { ref: Str_Of(item.metaId), kind: kind, title: Str_Of(item.title) })
end sub

function VodUi_Keyboard(kind as string, text as string, data as dynamic) as boolean
    if kind <> "vodFix" then return false
    if type(data) <> "roAssociativeArray" then return true
    if text.Trim() = ""
        VodUi_Run("vodFix", { ref: Str_Of(data.ref), id: "" }, data)
        return true
    end if
    showBusy(L("Buscando..."))
    VodUi_Run("vodCandidates", { query: text.Trim(), kind: Str_Of(data.kind) }, data)
    return true
end function

sub VodUi_Run(mode as string, params as object, data as object)
    task = CreateObject("roSGNode", "IptvTask")
    task.mode = mode
    task.params = params
    task.observeField("result", "onVodUiResult")
    task.control = "RUN"
    m.vodUiTask = task
    m.vodUiData = data
end sub

sub onVodUiResult(event as object)
    task = event.getRoSGNode()
    if m.vodUiTask = invalid or not task.isSameNode(m.vodUiTask) then return
    m.vodUiTask = invalid
    hideBusy()
    r = task.result
    data = m.vodUiData
    if type(r) <> "roAssociativeArray" or type(data) <> "roAssociativeArray" then return
    if r.mode = "vodCandidates"
        items = []
        if type(r.list) = "roArray"
            for each c in r.list
                label = Str_Of(c.name)
                if Str_Of(c.year) <> "" then label = label + "  (" + Str_Of(c.year) + ")"
                items.Push({ id: Str_Of(c.id), label: label })
            end for
        end if
        if items.Count() = 0
            showMessage(L("Corregir coincidencia"), L("No se encontró ningún título con ese nombre."))
            return
        end if
        items.Push({ id: "auto", label: L("Volver a automático") })
        Sheet_Open({ title: L("Corregir coincidencia"), subtitle: Str_Of(data.title), items: items, style: "tv" }, "vodFix", data)
    else if r.mode = "vodFix"
        ref = Str_Of(data.ref)
        if m.metaCache <> invalid and m.metaCache.DoesExist(ref) then m.metaCache.Delete(ref)
        if Str_Of(r.id) = "" then Toast_Show(L("Volvió a la coincidencia automática.")) else Toast_Show(L("Listo. Desde ahora se usará ese título."))
        focusCurrent()
    end if
end sub

function VodUi_Sheet(handler as string, choice as string, data as dynamic) as boolean
    if handler <> "vodFix" then return false
    if choice = "" or type(data) <> "roAssociativeArray"
        focusCurrent()
        return true
    end if
    id = choice
    if id = "auto" then id = ""
    VodUi_Run("vodFix", { ref: Str_Of(data.ref), id: id }, data)
    return true
end function

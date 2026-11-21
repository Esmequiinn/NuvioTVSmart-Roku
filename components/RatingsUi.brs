sub Rate_Refresh(force as boolean)
    if Rate_Source(St_Integrations()) = "" then return
    if m.rateLoadTask <> invalid then return
    m.rateLoadTask = CreateObject("roSGNode", "AccountTask")
    m.rateLoadTask.mode = "rateLoad"
    m.rateLoadTask.params = { force: force }
    m.rateLoadTask.observeField("result", "onRateLoaded")
    m.rateLoadTask.control = "RUN"
end sub

sub onRateLoaded(event as object)
    task = event.getRoSGNode()
    if m.rateLoadTask = invalid or not task.isSameNode(m.rateLoadTask) then return
    m.rateLoadTask = invalid
    r = task.result
    if r = invalid or not Bool_Of(r.changed, false) then return
    Rate_Repaint()
end sub

sub Rate_Repaint()
    if not m.detailsOpen or m.ctx = invalid then return
    renderDetailButtons()
    if m.ctx.meta <> invalid
        Details_Extra()
        ex = m.details.extra
        ex.keep = true
        m.details.extra = ex
    end if
end sub

sub Rate_Open(kind as string, metaId as string, season as integer, episode as integer, title as string)
    source = Rate_Source(St_Integrations())
    if source = "" then return
    mine = Rate_Get(kind, metaId, season, episode)
    extra = ""
    name = title
    cut = Instr(1, title, "  ·  ")
    if cut > 0
        name = Left(title, cut - 1)
        extra = Mid(title, cut + 5)
    end if
    m.rateData = { kind: kind, metaId: metaId, season: season, episode: episode }
    m.rateFocus = invalid
    m.ratePanel.data = { kicker: L("Tu calificación"), title: name, subtitle: extra, value: mine, provider: Rate_Name(source) }
    m.ratePanel.visible = true
    m.ratePanel.setFocus(true)
end sub

sub onRatePanel()
    r = m.ratePanel.result
    m.ratePanel.visible = false
    data = m.rateData
    if type(r) <> "roAssociativeArray" or type(data) <> "roAssociativeArray" or r.action = "cancel"
        focusCurrent()
        return
    end if
    rating = ToInt(r.value, 0)
    if r.action = "remove" then rating = 0
    Rate_Choose(rating.ToStr(), data)
end sub

sub Rate_Choose(choice as string, data as dynamic)
    if choice = "" or type(data) <> "roAssociativeArray"
        focusCurrent()
        return
    end if
    rating = choice.ToInt()
    params = { kind: data.kind, metaId: data.metaId, season: data.season, episode: data.episode, rating: rating }
    m.rateTask = CreateObject("roSGNode", "AccountTask")
    m.rateTask.mode = "rateSend"
    m.rateTask.params = params
    m.rateTask.observeField("result", "onRateSent")
    m.rateTask.control = "RUN"
    focusCurrent()
end sub

sub onRateSent(event as object)
    task = event.getRoSGNode()
    if m.rateTask = invalid or not task.isSameNode(m.rateTask) then return
    m.rateTask = invalid
    r = task.result
    if r = invalid then r = {}
    if not Bool_Of(r.ok, false)
        Toast_Show(Str_Of(r.error))
        return
    end if
    if ToInt(r.rating, 0) > 0 then Toast_Show(L("Calificación guardada.")) else Toast_Show(L("Calificación quitada."))
    Rate_Repaint()
end sub

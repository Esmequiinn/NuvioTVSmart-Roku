sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    mode = m.top.mode
    p = m.top.params
    if p = invalid then p = {}
    if mode = "load"
        force = Bool_Of(p.force, false)
        r = Iptv_Load(force)
        m.top.channels = r
        wanted = {}
        for each c in r.channels
            e = Str_Of(c.e)
            if e = "" then e = Str_Of(c.n)
            if e <> "" then wanted[LCase(e)] = true
        end for
        epgs = r.epgs
        if type(epgs) <> "roArray" then epgs = []
        if epgs.Count() = 0
            m.top.result = { mode: "epg", ok: true, count: 0, none: true }
            return
        end if
        res = Iptv_Epg(force or Bool_Of(p.forceEpg, false), epgs, wanted)
        res.mode = "epg"
        m.top.result = res
    else if mode = "guide"
        ids = p.ids
        if type(ids) <> "roArray" then ids = []
        m.top.result = { mode: "guide", ok: true, guide: Iptv_Guide(ids, ToInt(p.shift, 0)), token: Str_Of(p.token) }
    else if mode = "art"
        titles = p.titles
        if type(titles) <> "roArray" then titles = []
        m.top.result = { mode: "art", art: Iptv_Art(titles) }
    end if
end sub

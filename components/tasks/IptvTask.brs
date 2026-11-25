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
        if Bool_Of(r.vodChanged, false) then m.top.vod = { changed: true }
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
        else
            res = Iptv_Epg(force or Bool_Of(p.forceEpg, false), epgs, wanted)
            res.mode = "epg"
            m.top.result = res
        end if
        wanted = invalid
        r = invalid
        if Vod_Building()
            if Vod_Finish() then m.top.vod = { changed: true }
        end if
    else if mode = "guide"
        ids = p.ids
        if type(ids) <> "roArray" then ids = []
        m.top.result = { mode: "guide", ok: true, guide: Iptv_Guide(ids, ToInt(p.shift, 0)), token: Str_Of(p.token) }
    else if mode = "vodCandidates"
        m.top.result = { mode: "vodCandidates", list: Vod_Candidates(Str_Of(p.query), Str_Of(p.kind)) }
    else if mode = "vodFix"
        Vod_Fix(Str_Of(p.ref), Str_Of(p.id))
        m.top.result = { mode: "vodFix", id: Str_Of(p.id) }
    else if mode = "art"
        titles = p.titles
        if type(titles) <> "roArray" then titles = []
        m.top.result = { mode: "art", art: Iptv_Art(titles) }
    end if
end sub

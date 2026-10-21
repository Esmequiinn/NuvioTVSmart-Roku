sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    query = m.top.query.Trim()
    jobs = []
    for each entry in m.top.manifests
        if type(entry.search) = "roArray"
            for each c in entry.search
                url = entry.base + "/catalog/" + c.kind.EncodeUriComponent() + "/" + c.id.EncodeUriComponent() + "/search=" + query.EncodeUriComponent() + ".json"
                jobs.Push({ kind: c.kind, addon: entry.name, url: url })
            end for
        end if
    end for
    m.top.searchable = jobs.Count()
    limit = m.top.limit
    if limit <= 0 then limit = 40
    m.pattern = Poster_Pattern("search")

    port = CreateObject("roMessagePort")
    active = {}
    nextIndex = 0
    total = 0
    clock = CreateObject("roTimespan")
    while true
        while active.Count() < 6 and nextIndex < jobs.Count()
            t = Http_Transfer(jobs[nextIndex].url, port)
            if t.AsyncGetToString()
                active[t.GetIdentity().ToStr()] = { transfer: t, index: nextIndex, started: clock.TotalMilliseconds() }
            end if
            nextIndex = nextIndex + 1
        end while
        if active.Count() = 0 then exit while
        msg = wait(500, port)
        if type(msg) = "roUrlEvent" and msg.GetInt() = 1
            key = msg.GetSourceIdentity().ToStr()
            job = active[key]
            if job <> invalid
                active.Delete(key)
                if msg.GetResponseCode() = 200
                    parsed = ParseJson(msg.GetString())
                    if parsed <> invalid
                        parsed = Http_TrimMetas(parsed, limit)
                        row = Search_Row(parsed, jobs[job.index])
                        if row <> invalid
                            total = total + row.getChildCount()
                            m.top.row = row
                        end if
                    end if
                end if
            end if
        end if
        now = clock.TotalMilliseconds()
        for each key in active.Keys()
            if now - active[key].started > 60000
                active[key].transfer.AsyncCancel()
                active.Delete(key)
            end if
        end for
    end while
    m.top.total = total
    m.top.done = true
end sub

function Search_Row(parsed as object, job as object) as dynamic
    if type(parsed.metas) <> "roArray" or parsed.metas.Count() = 0 then return invalid
    row = CreateObject("roSGNode", "ContentNode")
    row.title = job.addon + "  ·  " + TypePlural(job.kind)
    for each meta in parsed.metas
        if type(meta) = "roAssociativeArray" and IsStr(meta.id)
            Content_Item(row, Catalog_ItemData(meta, job.kind, m.pattern))
        end if
    end for
    if row.getChildCount() = 0 then return invalid
    return row
end function

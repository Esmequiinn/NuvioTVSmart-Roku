sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    kind = m.top.kind
    ids = m.top.videoIds
    if type(ids) <> "roArray" then ids = []
    targets = []
    urls = []
    order = 0
    for each entry in m.top.manifests
        for each vid in ids
            if Addon_Supports(entry.manifest, "stream", kind, vid)
                logo = ""
                if type(entry.manifest) = "roAssociativeArray" then logo = Str_Of(entry.manifest.logo)
                targets.Push({ name: entry.name, logo: logo, order: order })
                urls.Push(Addon_ResourceUrl(entry.base, "stream", kind, vid))
                exit for
            end if
        end for
        order = order + 1
    end for

    rules = []
    if Bool_Of(St_Pref("fusionBadges"), true) then rules = Badge_Compile(St_Badges(St_ActiveProfile().id))
    sizeBadges = Bool_Of(St_Pref("sizeBadges"), true)

    buckets = []
    for i = 0 to targets.Count() - 1
        buckets.Push([])
    end for
    seen = {}
    skipped = 0
    port = CreateObject("roMessagePort")
    active = {}
    nextIndex = 0
    clock = CreateObject("roTimespan")
    while true
        while active.Count() < 6 and nextIndex < urls.Count()
            t = Http_Transfer(urls[nextIndex], port)
            if t.AsyncGetToString() then active[t.GetIdentity().ToStr()] = { transfer: t, index: nextIndex, started: clock.TotalMilliseconds() }
            nextIndex = nextIndex + 1
        end while
        if active.Count() = 0 then exit while
        msg = wait(400, port)
        if type(msg) = "roUrlEvent" and msg.GetInt() = 1
            key = msg.GetSourceIdentity().ToStr()
            job = active[key]
            if job <> invalid
                active.Delete(key)
                data = invalid
                if msg.GetResponseCode() = 200 and msg.GetString() <> "" then data = ParseJson(msg.GetString())
                added = []
                if type(data) = "roAssociativeArray" and type(data.streams) = "roArray"
                    target = targets[job.index]
                    for each s in data.streams
                        if type(s) = "roAssociativeArray"
                            url = Str_Of(s.url)
                            if LCase(Left(url, 4)) = "http"
                                if not seen.DoesExist(url)
                                    seen[url] = true
                                    added.Push(Stream_Build(s, url, target, rules, sizeBadges))
                                end if
                            else
                                skipped = skipped + 1
                            end if
                        end if
                    end for
                end if
                buckets[job.index] = added
                m.top.batch = { addon: job.index, count: added.Count(), streams: added, pending: active.Count() + urls.Count() - nextIndex }
            end if
        end if
        now = clock.TotalMilliseconds()
        for each key in active.Keys()
            if now - active[key].started > 25000
                active[key].transfer.AsyncCancel()
                active.Delete(key)
            end if
        end for
    end while
    out = []
    for each b in buckets
        for each s in b
            out.Push(s)
        end for
    end for
    m.top.skipped = skipped
    m.top.streams = out
end sub

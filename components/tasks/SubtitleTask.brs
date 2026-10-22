sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    kind = m.top.kind
    ids = m.top.videoIds
    if type(ids) <> "roArray" then ids = []
    names = []
    urls = []
    for each entry in m.top.manifests
        for each vid in ids
            if Addon_Supports(entry.manifest, "subtitles", kind, vid)
                names.Push(entry.name)
                urls.Push(Addon_ResourceUrl(entry.base, "subtitles", kind, vid))
                exit for
            end if
        end for
    end for
    if Bool_Of(St_Pref("openSubs"), true)
        base = "https://opensubtitles-v3.strem.io"
        already = false
        for each entry in m.top.manifests
            if LCase(entry.base) = base then already = true
        end for
        if not already
            for each vid in ids
                if Left(vid, 2) = "tt"
                    names.Push("OpenSubtitles")
                    urls.Push(Addon_ResourceUrl(base, "subtitles", kind, vid))
                    exit for
                end if
            end for
        end if
    end if
    results = Http_FetchJsonAll(urls, 15000)
    buckets = [[], [], []]
    seen = {}
    for i = 0 to results.Count() - 1
        data = results[i]
        if type(data) = "roAssociativeArray" and type(data.subtitles) = "roArray"
            for each s in data.subtitles
                if type(s) = "roAssociativeArray" and IsStr(s.url)
                    if not seen.DoesExist(s.url)
                        seen[s.url] = true
                        lang = Str_Of(s.lang)
                        buckets[Lang_Rank(lang)].Push({ url: s.url, lang: lang, label: Lang_Name(lang) + "  ·  " + names[i] })
                    end if
                end if
            end for
        end if
    end for
    out = []
    for each bucket in buckets
        for each s in bucket
            if out.Count() < 30 then out.Push(s)
        end for
    end for
    m.top.subs = out
end sub

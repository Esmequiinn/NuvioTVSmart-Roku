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
    origLang = Str_Of(m.top.originalLang)
    pref1 = Lang_Resolve(Str_Of(St_Pref("subLang")), origLang)
    pref2 = Lang_Resolve(Str_Of(St_Pref("subLang2")), origLang)
    audio1 = Lang_Resolve(Str_Of(St_Pref("audioLang")), origLang)
    uiLang = Lang_UiCode()
    preferForced = Bool_Of(St_Pref("forcedSubs"), false)
    items = []
    byUrl = {}
    for i = 0 to results.Count() - 1
        data = results[i]
        if type(data) = "roAssociativeArray" and type(data.subtitles) = "roArray"
            for each s in data.subtitles
                item = Sub_NormalizeTrack(s, names[i], "addon")
                if item <> invalid
                    key = Sub_UrlKey(item.url)
                    if byUrl.DoesExist(key)
                        Sub_MergeInto(byUrl[key], item)
                    else
                        byUrl[key] = item
                        items.Push(item)
                    end if
                end if
            end for
        end if
    end for
    buckets = [[], [], [], [], [], [], []]
    major = { en: true, "es-419": true, "es-es": true, es: true, "pt-br": true, "pt-pt": true, pt: true, fr: true, de: true, it: true }
    passes = [0, 1, 2]
    if preferForced then passes = [2, 0, 1]
    for each pass in passes
        for each item in items
            if (pass = 0 and not item.forced and not item.sdh) or (pass = 1 and not item.forced and item.sdh) or (pass = 2 and item.forced)
                lk = item.langKey
                s1 = Lang_MatchScore(lk, pref1)
                s2 = Lang_MatchScore(lk, pref2)
                b = 5
                if s1 >= 2
                    b = 0
                else if s1 = 1 or s2 >= 2
                    b = 1
                else if s2 = 1 or (audio1 <> "" and Lang_Matches(lk, audio1)) or (origLang <> "" and Lang_Matches(lk, origLang)) or (uiLang <> "" and Lang_Matches(lk, uiLang))
                    b = 2
                else if major.DoesExist(lk)
                    b = 3
                else if lk <> "und"
                    b = 4
                else
                    b = 6
                end if
                buckets[b].Push(item)
            end if
        end for
    end for
    out = []
    langCounts = {}
    for b = 0 to 6
        for each item in buckets[b]
            if out.Count() >= 160 then exit for
            lk = item.langKey
            cur = ToInt(langCounts[lk], 0)
            cap = 15
            if (pref1 <> "" and Lang_Matches(lk, pref1)) or (pref2 <> "" and Lang_Matches(lk, pref2)) then cap = 40
            if cur < cap
                langCounts[lk] = cur + 1
                out.Push(item)
            end if
        end for
        if out.Count() >= 160 then exit for
    end for
    m.top.subs = out
end sub

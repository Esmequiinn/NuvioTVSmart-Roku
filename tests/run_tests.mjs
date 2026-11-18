import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import { createBrsSandbox } from "./brs_runtime.mjs";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");

function readBrs(rel) {
    return fs.readFileSync(path.join(ROOT, rel), "utf8");
}

function makeSandbox(opts = {}) {
    const sb = createBrsSandbox(opts);
    sb.loadBrs(readBrs("components/I18n.brs"), "I18n.brs");
    sb.loadBrs(readBrs("components/Util.brs"), "Util.brs");
    sb.loadBrs(readBrs("components/Config.brs"), "Config.brs");
    sb.loadBrs(readBrs("components/Addon.brs"), "Addon.brs");
    sb.loadBrs(readBrs("components/Http.brs"), "Http.brs");
    sb.loadBrs(readBrs("components/Store.brs"), "Store.brs");
    return sb;
}

const tests = [];
function test(name, fn) {
    tests.push({ name, fn });
}

test("Util: Img_Sized clamps TMDB original URLs to w500/w1280 without touching non-TMDB URLs", () => {
    const sb = makeSandbox();
    assert.equal(
        sb.ctx.Img_Sized("https://image.tmdb.org/t/p/original/abc123.png", "w500"),
        "https://image.tmdb.org/t/p/w500/abc123.png"
    );
    assert.equal(
        sb.ctx.Img_Sized("https://image.tmdb.org/t/p/w300/abc123.png", "w500"),
        "https://image.tmdb.org/t/p/w300/abc123.png"
    );
    assert.equal(
        sb.ctx.Img_Sized("https://images.metahub.space/logo/medium/tt1234/img", "w500"),
        "https://images.metahub.space/logo/medium/tt1234/img"
    );
});

test("Language normalization: pt-BR vs pt-PT vs es-419 vs es and ISO/name aliases", () => {
    const sb = makeSandbox();
    assert.equal(typeof sb.ctx.Lang_Variant, "function", "Lang_Variant must exist in Util.brs");
    assert.equal(sb.ctx.Lang_Variant("pob", "", ""), "pt-br");
    assert.equal(sb.ctx.Lang_Variant("pt-BR", "", ""), "pt-br");
    assert.equal(sb.ctx.Lang_Variant("pt", "Portuguese (Brazil)", ""), "pt-br");
    assert.equal(sb.ctx.Lang_Variant("por", "Português PT-PT", ""), "pt-pt");
    assert.equal(sb.ctx.Lang_Variant("lat", "", ""), "es-419");
    assert.equal(sb.ctx.Lang_Variant("es-MX", "", ""), "es-419");
    assert.equal(sb.ctx.Lang_Variant("spa", "Castellano", ""), "es-es");
    assert.equal(sb.ctx.Lang_Variant("hbs", "", ""), "hr");
    assert.equal(sb.ctx.Lang_Variant("sr-ME", "", ""), "sr-me");
    assert.equal(sb.ctx.Lang_Variant("iw", "", ""), "he");
    assert.equal(sb.ctx.Lang_Variant("ind", "", ""), "id");
    assert.equal(sb.ctx.Lang_Matches("pob", "pt-br"), true);
    assert.equal(sb.ctx.Lang_Matches("pt-br", "por"), true);
    assert.equal(sb.ctx.Lang_Matches("pt-pt", "pt-br"), false);
});

test("SubtitleTask discovery: 50+ mixed tracks keep preferred pt-BR, deduplicate URLs merging metadata, and preserve SDH/Forced", () => {
    const sb = makeSandbox({
        registry: {
            "nuviotv:prefs_p1": JSON.stringify({ subLang: "pt-br", subLang2: "en", openSubs: false })
        }
    });
    const top = sb.evalJs("({})");
    top.isSubtype = (kind) => kind === "Task";
    top.manifests = sb.evalJs(JSON.stringify([
        { name: "AddonA", base: "https://addon-a.example", manifest: { resources: ["subtitles"], types: ["movie"] } },
        { name: "AddonB", base: "https://addon-b.example", manifest: { resources: ["subtitles"], types: ["movie"] } }
    ]));
    top.kind = "movie";
    top.videoIds = sb.evalJs(JSON.stringify(["tt1234567"]));
    top.originalLang = "en";
    top.subs = sb.evalJs("[]");
    sb.ctx.m.top = top;

    sb.loadBrs(readBrs("components/tasks/SubtitleTask.brs"), "SubtitleTask.brs");

    const subsA = [];
    for (let i = 1; i <= 25; i++) {
        subsA.push({ url: `https://subs.example/es-${i}.srt`, lang: "spa", title: `Español ${i}` });
    }
    for (let i = 1; i <= 20; i++) {
        subsA.push({ url: `https://subs.example/en-${i}.vtt`, lang: "eng", title: `English ${i}` });
    }
    subsA.push({ url: "https://subs.example/shared-pt.srt", lang: "pt", title: "Portuguese" });

    const subsB = [
        { url: "https://subs.example/shared-pt.srt", lang: "pob", title: "Português BR WEB-DL SDH", hearingImpaired: true },
        { url: "https://subs.example/pt-forced.srt", lang: "pt-br", title: "PT-BR Forced", forced: true },
        { url: "https://subs.example/pt-pt.vtt", lang: "pt-pt", title: "Português Portugal" }
    ];

    sb.ctx.Http_FetchJsonAll = (urls) => sb.evalJs(JSON.stringify(
        Array.from(urls).map((u) => (u.includes("addon-a") ? { subtitles: subsA } : { subtitles: subsB }))
    ));
    sb.ctx.execute();

    const out = top.subs;
    assert.ok(out.length > 30, `Expected >30 retained tracks instead of flat 30 cap, got ${out.length}`);
    const ptBrTracks = out.filter((t) => t.langKey === "pt-br");
    assert.equal(ptBrTracks.length, 2, "Must retain both distinct pt-BR tracks after merging duplicate URL");
    const shared = ptBrTracks.find((t) => t.url === "https://subs.example/shared-pt.srt");
    const forced = ptBrTracks.find((t) => t.url === "https://subs.example/pt-forced.srt");
    assert.ok(shared, "Shared duplicate URL must exist once");
    assert.equal(shared.sdh, true, "Duplicate URL merge must preserve SDH flag");
    assert.equal(forced.forced, true, "Forced flag must be preserved");
    assert.equal(out[0].langKey, "pt-br", "Preferred pt-BR tracks must rank ahead of ES/EN");
    const ptPtTracks = out.filter((t) => t.langKey === "pt-pt");
    assert.equal(ptPtTracks.length, 1, "Distinct pt-PT track must remain grouped separately");
    assert.equal(ptPtTracks[0].format, "VTT");
});

test("Streams & Servers: Stremio stream subtitles and Jellyfin/Emby MediaStreams subtitles are preserved", () => {
    const sb = makeSandbox();
    sb.loadBrs(readBrs("components/Streams.brs"), "Streams.brs");
    sb.loadBrs(readBrs("components/Servers.brs"), "Servers.brs");

    const sv = sb.ctx.ParseJson(JSON.stringify({
        name: "MyJellyfin",
        url: "https://jf.example",
        kind: "jellyfin",
        token: "tok123",
        userId: "u1"
    }));
    const info = sb.ctx.ParseJson(JSON.stringify({
        Name: "Sample Movie",
        MediaSources: [{
            Id: "src1",
            Container: "mkv",
            Path: "/media/movie.mkv",
            MediaStreams: [
                { Type: "Video", Codec: "h264", Height: 1080 },
                { Type: "Subtitle", Index: 2, Codec: "subrip", Language: "pob", DisplayTitle: "Português BR (Forced)", IsForced: true, IsTextSubtitleStream: true },
                { Type: "Subtitle", Index: 3, Codec: "pgssub", Language: "eng", IsTextSubtitleStream: false }
            ]
        }]
    }));
    const srvStreams = sb.ctx.Srv_ItemStreams(sv, "item99", info);
    assert.equal(srvStreams.length, 2);
    assert.equal(srvStreams[0].subtitles.length, 1, "Bitmap pgssub ignored, text subrip kept");
    assert.ok(srvStreams[0].subtitles[0].url.includes("/Subtitles/2/Stream.srt?api_key=tok123"));

    const built = sb.ctx.Stream_Build(
        sb.ctx.ParseJson(JSON.stringify({ name: "MyJellyfin", title: "1080p", subtitles: srvStreams[0].subtitles, subSourceType: "server" })),
        srvStreams[0].url,
        sb.ctx.ParseJson(JSON.stringify({ name: "MyJellyfin", logo: "", order: -1 })),
        sb.evalJs("[]"),
        true
    );
    assert.equal(built.subtitles.length, 1);
    assert.equal(built.subtitles[0].langKey, "pt-br");
    assert.equal(built.subtitles[0].forced, true);
    assert.equal(built.subtitles[0].sourceType, "server");
});

test("PlayerDataTask Subs_Parse: handles UTF-8 BOM, WEBVTT/NOTE/STYLE, ASS/HTML tags, entities, simultaneous cues, and rejects HTML errors", () => {
    const sb = makeSandbox();
    sb.loadBrs(readBrs("components/tasks/PlayerDataTask.brs"), "PlayerDataTask.brs");
    assert.equal(typeof sb.ctx.Subs_Parse, "function", "Subs_Parse must exist in PlayerDataTask.brs");

    const vtt = "\uFEFFWEBVTT\n\nNOTE ignore this\nblock\n\nSTYLE\n::cue { color: white; }\n\n1\n00:01.500 --> 00:04.000 line:85%\n{\\an8}<i>Olá &amp; bem-vindo!</i>\\NLinha 2\n\n2\n00:01.500 --> 00:04.000\nSegunda fala &quot;simultânea&quot;\n\n00:08,000 --> 00:07,000\nCue inválida\n";
    const parsed = sb.ctx.Subs_Parse(vtt);
    assert.equal(parsed.error, "");
    assert.equal(parsed.cues.length, 1, "Simultaneous cues merge cleanly and inverted cue is dropped");
    assert.equal(Math.abs(parsed.cues[0].s - 1.5) < 0.001, true);
    assert.equal(Math.abs(parsed.cues[0].e - 4.0) < 0.001, true);
    assert.equal(parsed.cues[0].t, 'Olá & bem-vindo!\nLinha 2\nSegunda fala "simultânea"');

    const badHtml = sb.ctx.Subs_Parse("<!DOCTYPE html><html><body>404 Not Found</body></html>");
    assert.equal(badHtml.cues.length, 0);
    assert.equal(badHtml.error, "invalid_subtitle");

    // Out-of-order SRT cues with classic comma decimals are sorted
    const srt = "2\r\n00:00:10,000 --> 00:00:12,500\r\nSecond sorted\r\n\r\n1\r\n00:00:02,000 --> 00:00:04,500\r\nFirst sorted\r\n";
    const sorted = sb.ctx.Subs_Parse(srt);
    assert.equal(sorted.error, "");
    assert.equal(sorted.cues.length, 2);
    assert.equal(sorted.cues[0].t, "First sorted");
    assert.equal(sorted.cues[1].t, "Second sorted");
});

test("PlayerExtras timing & Sync Line math: signed delay (+ = later) + cue matching (-300ms compensation)", () => {
    const sb = makeSandbox();
    sb.ctx.m.top = sb.evalJs("({ info: { customSubs: true } })");
    sb.loadBrs(readBrs("components/views/PlayerExtras.brs"), "PlayerExtras.brs");
    assert.equal(typeof sb.ctx.Ex_CueAt, "function", "Ex_CueAt pure cue lookup helper must exist");
    assert.equal(typeof sb.ctx.Ex_CalcSyncDelay, "function", "Ex_CalcSyncDelay helper must exist");
    assert.equal(sb.ctx.Ex_UseCustom("https://subs.example/movie.srt?tok=1"), true);
    assert.equal(sb.ctx.Ex_UseCustom("https://subs.example/movie.ass?tok=1"), false, ".ass excluded from SRT/VTT custom parser");
    assert.equal(sb.ctx.Ex_UseCustom("mkv/3"), false, "Embedded track uses native video captions");

    const cues = sb.evalJs(JSON.stringify([
        { s: 10.0, e: 12.0, t: "First line" },
        { s: 15.0, e: 18.0, t: "Second line" }
    ]));
    // Zero offset
    assert.equal(sb.ctx.Ex_CueAt(cues, 0, 10.5, 0).t, "First line");
    // Positive delay (+2000ms = subtitles appear 2s later: cue 10..12 shows at playback 12..14)
    assert.equal(sb.ctx.Ex_CueAt(cues, 0, 10.5, 2000), null);
    assert.equal(sb.ctx.Ex_CueAt(cues, 0, 12.5, 2000).t, "First line");
    // Negative delay (-500ms = subtitles appear 0.5s earlier: cue 15..18 shows at playback 14.6)
    assert.equal(sb.ctx.Ex_CueAt(cues, 0, 14.6, -500).t, "Second line");

    // Sync Line calculation: user heard cue (s=10.0s -> 10000ms) at playback 11.8s (11800ms) -> 11800 - 10000 - 300 = +1500ms
    assert.equal(sb.ctx.Ex_CalcSyncDelay(11800, 10.0), 1500);
    // Clamped within [-180000, +180000]
    assert.equal(sb.ctx.Ex_CalcSyncDelay(500000, 10.0), 180000);
    assert.equal(sb.ctx.Ex_CalcSyncDelay(1000, 300.0), -180000);

    // Sync Line window & delay formatting
    const win = sb.ctx.Ex_SyncLineWindow(cues, 15200, 0);
    assert.equal(win.entries.Count(), 2);
    assert.equal(win.focus, 1, "Closest cue to 15.2s is Second line at 15.0s");
    assert.ok(sb.ctx.Ex_FormatDelay(500, false).startsWith("+0.5 s"));
    assert.ok(sb.ctx.Ex_FormatDelay(-1200, false).startsWith("-1.2 s"));
    assert.equal(sb.ctx.Ex_FormatDelay(0, true), "0.0 s");
});

test("Store bounded subdelay_<pid>: saves per videoId/profile, deletes on zero, evicts oldest past 150", () => {
    const sb = makeSandbox({
        registry: {
            "nuviotv:profiles": JSON.stringify([{ id: "p1", name: "Default" }, { id: "p2", name: "Kids" }]),
            "nuviotv:settings": JSON.stringify({ active: "p1", shared: true })
        }
    });
    assert.equal(typeof sb.ctx.St_SubDelay, "function", "St_SubDelay must exist in Store.brs");
    assert.equal(sb.ctx.St_SubDelay("tt123"), 0);

    sb.ctx.St_SaveSubDelay("tt123", 700);
    assert.equal(sb.ctx.St_SubDelay("tt123"), 700);

    // Switch profile -> isolated
    sb.ctx.St_SetActiveProfile("p2");
    assert.equal(sb.ctx.St_SubDelay("tt123"), 0);
    sb.ctx.St_SetActiveProfile("p1");
    assert.equal(sb.ctx.St_SubDelay("tt123"), 700);

    // Eviction bound at 150
    for (let i = 1; i <= 155; i++) {
        sb.setNow(1700000000 + i);
        sb.ctx.St_SaveSubDelay(`v_${i}`, i * 100);
    }
    const stored = JSON.parse(sb.files.get("cachefs:/subdelay_p1.json") || sb.files.get("tmp:/subdelay_p1.json"));
    assert.ok(Object.keys(stored).length <= 150, `Expected <=150 entries, got ${Object.keys(stored).length}`);

    // Resetting to 0 deletes entry
    sb.ctx.St_SaveSubDelay("v_155", 0);
    assert.equal(sb.ctx.St_SubDelay("v_155"), 0);
});

test("Debrid TorBox alt-hash mapping & Streams audio pref hoisting", () => {
    const sb = makeSandbox();
    sb.loadBrs(readBrs("components/Debrid.brs"), "Debrid.brs");
    sb.loadBrs(readBrs("components/Streams.brs"), "Streams.brs");
    assert.equal(typeof sb.ctx.Deb_TorBoxMapCached, "function", "Deb_TorBoxMapCached must exist in Debrid.brs");

    // Single hash returned under an alternative canonical hash
    const singleMap = sb.ctx.Deb_TorBoxMapCached(
        sb.ctx.ParseJson(JSON.stringify(["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"])),
        sb.ctx.ParseJson(JSON.stringify({ "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { name: "Movie.mkv", size: 4200000000 } }))
    );
    assert.ok(singleMap.DoesExist("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));
    assert.equal(singleMap["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"].name, "Movie.mkv");

    // Full multi-hash Deb_CheckCached with canonical alias fallback probe
    sb.setHttpMock((method, url, headers, body) => {
        if (method === "POST") {
            return sb.ctx.ParseJson(JSON.stringify({
                code: 200,
                json: { data: { "altcanonical9999999999999999999999999999": { name: "AltHash.mkv", size: 1000 } } }
            }));
        }
        if (url.includes("hash=1111111111111111111111111111111111111111")) {
            return sb.ctx.ParseJson(JSON.stringify({
                code: 200,
                json: { data: { "altcanonical9999999999999999999999999999": { name: "AltHash.mkv", size: 1000 } } }
            }));
        }
        return sb.ctx.ParseJson(JSON.stringify({ code: 200, json: { data: {} } }));
    });
    const tbFound = sb.ctx.Deb_CheckCached(
        sb.ctx.ParseJson(JSON.stringify({ id: "torbox", key: "tbk" })),
        sb.ctx.ParseJson(JSON.stringify(["1111111111111111111111111111111111111111", "2222222222222222222222222222222222222222"]))
    );
    assert.ok(tbFound.DoesExist("1111111111111111111111111111111111111111"), "Multi-hash fallback must map alternative canonical hash back to requested hash");
    assert.equal(tbFound["1111111111111111111111111111111111111111"].name, "AltHash.mkv");
    assert.equal(tbFound.DoesExist("2222222222222222222222222222222222222222"), false);
});

test("PlayerScreen grouped subtitles: groups by language with counts, preference order, and SDH/onlyPreferred guards", () => {
    const sb = makeSandbox();
    sb.loadBrs(readBrs("components/Mask.brs"), "Mask.brs");
    sb.loadBrs(readBrs("components/Ink.brs"), "Ink.brs");
    sb.loadBrs(readBrs("components/views/PlayerScreen.brs"), "PlayerScreen.brs");

    const internal = sb.ctx.ParseJson(JSON.stringify([
        { TrackName: "mkv/1", Language: "eng", Description: "English Full" },
        { TrackName: "mkv/2", Language: "und", Description: "Track 2" }
    ]));
    const extra = sb.ctx.ParseJson(JSON.stringify([
        { url: "https://s/fr1.srt", lang: "fra", title: "French SDH", sdh: true, provider: "OpenSubs" },
        { url: "https://s/ptbr1.srt", lang: "pob", title: "PT-BR Retail", provider: "SubDL" },
        { url: "https://s/ptbr2.vtt", lang: "pt-br", title: "PT-BR Forced", forced: true, provider: "SubDL" },
        { url: "https://s/es1.srt", lang: "es-419", title: "Latino", provider: "OpenSubs" }
    ]));
    const info = sb.ctx.ParseJson(JSON.stringify({
        subLang: "pt-br",
        subLang2: "es-419",
        originalLang: "en",
        stripSdh: true,
        onlyPreferred: true
    }));

    // With stripSdh=true and onlyPreferred=true, active internal English track & unknown internal track must be preserved
    const collected = sb.ctx.Player_CollectSubs(internal, extra, info, "mkv/1");
    const urls = collected.map((x) => x.url);
    assert.ok(urls.includes("mkv/1"), "Active track preserved even when outside preferred");
    assert.ok(urls.includes("mkv/2"), "Unknown internal track preserved per upstream rule");
    assert.ok(urls.includes("https://s/ptbr1.srt"), "Preferred pt-br track included");
    assert.ok(!urls.includes("https://s/fr1.srt"), "Unpreferred SDH filtered out");

    const groups = sb.ctx.Player_GroupSubs(collected, info, "mkv/1", "eng");
    assert.equal(groups[0].langKey, "pt-br", "Preferred pt-br group ranked first");
    assert.equal(groups[0].tracks.Count(), 2, "pt-br group has 2 tracks");
    assert.equal(groups[0].tracks[0].forced, false, "Normal non-forced track sorted before forced");
    assert.equal(groups[groups.length - 1].langKey, "und", "Unknown language sunk to last");
});

test("Slice 1 perf & cache: St_Prefs caches across reads and Streams_AudioOrder hoists pref lookups", () => {
    const sb = makeSandbox({
        registry: {
            "nuviotv:prefs_p1": JSON.stringify({ audioSafe: true, stereoOnly: true })
        }
    });
    sb.loadBrs(readBrs("components/Streams.brs"), "Streams.brs");
    let reads = 0;
    const origStPrefs = sb.ctx.St_Prefs;
    sb.ctx.St_Prefs = () => {
        reads++;
        return origStPrefs();
    };
    const streams = sb.evalJs(JSON.stringify([
        { name: "5.1 DTS-HD", desc: "", filename: "a.mkv" },
        { name: "2.0 AAC Stereo", desc: "", filename: "b.mkv" },
        { name: "5.1 AC3", desc: "", filename: "c.mkv" },
        { name: "Unknown track", desc: "", filename: "d.mkv" }
    ]));
    const ordered = sb.ctx.Streams_AudioOrder(streams);
    assert.equal(ordered[0].filename, "b.mkv", "Stereo track must rank first when stereoOnly=true");
    assert.ok(reads <= 3, `Expected hoisted St_Prefs reads <= 3, got ${reads}`);

    // Verify Store cache invalidation when St_SetPref bumps stVer
    sb.ctx.St_SetPref("stereoOnly", false);
    assert.equal(origStPrefs().stereoOnly, false, "St_Prefs cache must invalidate immediately on St_SetPref");
});

let passed = 0;
let failed = 0;
for (const t of tests) {
    try {
        await t.fn();
        console.log(`PASS  ${t.name}`);
        passed++;
    } catch (err) {
        console.error(`FAIL  ${t.name}\n  -> ${err.stack || err.message}`);
        failed++;
    }
}
console.log(`\nSummary: ${passed} passed, ${failed} failed.`);
if (failed > 0) process.exit(1);

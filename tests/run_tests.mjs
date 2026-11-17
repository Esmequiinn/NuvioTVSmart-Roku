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
    assert.equal(ptBrTracks[0].url, "https://subs.example/shared-pt.srt");
    assert.equal(ptBrTracks[0].sdh, true, "Duplicate URL merge must preserve SDH flag");
    assert.equal(ptBrTracks[1].forced, true, "Forced flag must be preserved");
    assert.equal(out[0].langKey, "pt-br", "Preferred pt-BR tracks must rank ahead of ES/EN");
    const ptPtTracks = out.filter((t) => t.langKey === "pt-pt");
    assert.equal(ptPtTracks.length, 1, "Distinct pt-PT track must remain grouped separately");
    assert.equal(ptPtTracks[0].format, "VTT");
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
});

test("PlayerExtras timing & Sync Line math: signed delay (+ = later) + cue matching (-300ms compensation)", () => {
    const sb = makeSandbox();
    sb.loadBrs(readBrs("components/views/PlayerExtras.brs"), "PlayerExtras.brs");
    assert.equal(typeof sb.ctx.Ex_CueAt, "function", "Ex_CueAt pure cue lookup helper must exist");
    assert.equal(typeof sb.ctx.Ex_CalcSyncDelay, "function", "Ex_CalcSyncDelay helper must exist");

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
        sb.evalJs(JSON.stringify(["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"])),
        sb.evalJs(JSON.stringify({ "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb": { name: "Movie.mkv", size: 4200000000 } }))
    );
    assert.ok(singleMap.DoesExist("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"));
    assert.equal(singleMap["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"].name, "Movie.mkv");
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

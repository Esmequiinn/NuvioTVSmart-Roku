import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const errors = [];
const warnings = [];

function walk(dir, out = []) {
    for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
        if (ent.name === ".git" || ent.name === "node_modules") continue;
        const full = path.join(dir, ent.name);
        if (ent.isDirectory()) walk(full, out);
        else out.push(full);
    }
    return out;
}

const allFiles = walk(ROOT);
const xmlFiles = allFiles.filter((f) => f.endsWith(".xml"));
const brsFiles = allFiles.filter((f) => f.endsWith(".brs"));
const localeFiles = allFiles.filter((f) => f.includes(`${path.sep}locale${path.sep}`) && f.endsWith(".json"));

// 1. Validate XML components, pkg:/ URIs, IDs, script symbols & callbacks
const fileFunctionMap = new Map();

for (const bf of brsFiles) {
    const rel = path.relative(ROOT, bf);
    const text = fs.readFileSync(bf, "utf8");
    const fnNames = [];
    const stack = [];
    const lines = text.split(/\r?\n/);

    for (let idx = 0; idx < lines.length; idx++) {
        // Strip string literals & comments for structural scanning
        let line = "";
        let inStr = false;
        const raw = lines[idx];
        for (let i = 0; i < raw.length; i++) {
            const c = raw[i];
            if (c === '"') inStr = !inStr;
            else if (!inStr) {
                if (c === "'") break;
                line += c;
            }
        }
        const trimmed = line.trim();
        if (!trimmed) continue;

        const mFn = trimmed.match(/^(sub|function)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/i);
        if (mFn) {
            if (stack.length > 0) {
                errors.push(`${rel}:${idx + 1} nested ${mFn[1]} inside ${stack[stack.length - 1]}`);
            }
            stack.push(mFn[1].toLowerCase());
            fnNames.push(mFn[2].toLowerCase());
            continue;
        }
        if (/^end\s+(sub|function)\b/i.test(trimmed)) {
            const want = /^end\s+sub\b/i.test(trimmed) ? "sub" : "function";
            const top = stack.pop();
            if (top !== want) errors.push(`${rel}:${idx + 1} mismatched "end ${want}" (top=${top || "empty"})`);
            continue;
        }
        if (/^if\b/i.test(trimmed)) {
            // Check inline single-line if: "if cond then stmt" (only multi-line if pushes)
            const thenMatch = trimmed.match(/\bthen\s+(.*)$/i);
            if (!thenMatch || !thenMatch[1].trim()) stack.push("if");
            continue;
        }
        if (/^else\s+if\b/i.test(trimmed)) {
            if (stack[stack.length - 1] !== "if") {
                errors.push(`${rel}:${idx + 1} "else if" without matching "if" block`);
            }
            continue;
        }
        if (/^end\s*if\b/i.test(trimmed)) {
            const top = stack.pop();
            if (top !== "if") errors.push(`${rel}:${idx + 1} mismatched "end if" (top=${top || "empty"})`);
            continue;
        }
        if (/^for\b/i.test(trimmed)) {
            stack.push("for");
            continue;
        }
        if (/^(end\s+for|next)\b/i.test(trimmed)) {
            const top = stack.pop();
            if (top !== "for") errors.push(`${rel}:${idx + 1} mismatched "end for" (top=${top || "empty"})`);
            continue;
        }
        if (/^while\b/i.test(trimmed)) {
            stack.push("while");
            continue;
        }
        if (/^end\s+while\b/i.test(trimmed)) {
            const top = stack.pop();
            if (top !== "while") errors.push(`${rel}:${idx + 1} mismatched "end while" (top=${top || "empty"})`);
            continue;
        }
        if (/^try$/i.test(trimmed)) {
            stack.push("try");
            continue;
        }
        if (/^end\s+try\b/i.test(trimmed)) {
            const top = stack.pop();
            if (top !== "try") errors.push(`${rel}:${idx + 1} mismatched "end try" (top=${top || "empty"})`);
            continue;
        }

        // Guardrail: subOffset must NEVER be used for subtitle delay/timing calculations
        if (/subOffset/i.test(trimmed) && /(delay|syncLine|subTime|effectiveAt|MS)/i.test(trimmed)) {
            errors.push(`${rel}:${idx + 1} suspicious timing reference using subOffset: ${trimmed}`);
        }

        // Dynamic pill template check: Ex_PillMake(parent, H) -> pkg:/images/c/hlH.png & hrH.png
        const pillMatch = trimmed.match(/Ex_PillMake\s*\([^,]+,\s*(\d+)\s*\)/i);
        if (pillMatch) {
            const h = pillMatch[1];
            for (const side of ["hl", "hr"]) {
                const pillPath = path.join(ROOT, "images", "c", `${side}${h}.png`);
                if (!fs.existsSync(pillPath)) {
                    errors.push(`${rel}:${idx + 1} Ex_PillMake(..., ${h}) missing asset images/c/${side}${h}.png`);
                }
            }
        }
    }

    // Validate complete literal pkg:/ URIs inside BrightScript files
    const codeNoComments = text.replace(/^[ \t]*'.*$/gm, "");
    const pkgLiteralRe = /"(pkg:\/[A-Za-z0-9_./-]+\.(?:png|jpg|json|xml|brs))"/g;
    let pm;
    while ((pm = pkgLiteralRe.exec(codeNoComments)) !== null) {
        const uri = pm[1];
        const diskPath = path.join(ROOT, uri.slice(5));
        if (!fs.existsSync(diskPath)) {
            errors.push(`${rel}: missing pkg asset "${uri}"`);
        }
    }

    // Validate dynamic player icon suffix replacements (e.g., _36.png / _44.png)
    const replRe = /\.Replace\(\s*"\.png"\s*,\s*"_(\d+)\.png"\s*\)/g;
    let rm;
    while ((rm = replRe.exec(codeNoComments)) !== null) {
        const sz = rm[1];
        const chevronPath = path.join(ROOT, "images", "s", `ic_subs_${sz}.png`);
        if (!fs.existsSync(chevronPath)) {
            errors.push(`${rel}: dynamic _${sz}.png sprite replacement missing ic_subs_${sz}.png`);
        }
    }

    if (stack.length > 0) {
        errors.push(`${rel}: unclosed BrightScript blocks at EOF: ${stack.join(", ")}`);
    }
    fileFunctionMap.set(rel, fnNames);
}

for (const xf of xmlFiles) {
    const rel = path.relative(ROOT, xf);
    const text = fs.readFileSync(xf, "utf8");
    const ids = new Map();
    const scripts = [];
    const callbacks = [];

    // Strip XML comments
    const stripped = text.replace(/<!--[\s\S]*?-->/g, "").replace(/<\?[\s\S]*?\?>/g, "");
    const tagRe = /<\/?([A-Za-z_][A-Za-z0-9_:-]*)([^>]*)>/g;
    const tagStack = [];
    let m;
    while ((m = tagRe.exec(stripped)) !== null) {
        const full = m[0];
        const tag = m[1];
        const attrs = m[2] || "";
        const isClose = full.startsWith("</");
        const isSelfClose = full.endsWith("/>");
        if (isClose) {
            const open = tagStack.pop();
            if (open !== tag) errors.push(`${rel}: XML closing </${tag}> mismatched with <${open || "none"}>`);
            continue;
        }
        if (!isSelfClose) tagStack.push(tag);

        const attrRe = /([A-Za-z_][A-Za-z0-9_:-]*)\s*=\s*"([^"]*)"/g;
        let a;
        while ((a = attrRe.exec(attrs)) !== null) {
            const [, k, v] = a;
            if (k === "id" && tag !== "field") {
                if (ids.has(v)) errors.push(`${rel}: duplicate XML id="${v}"`);
                ids.set(v, true);
            }
            if ((tag === "script" && k === "uri") || (k.toLowerCase().includes("uri") && v.startsWith("pkg:/"))) {
                if (v.startsWith("pkg:/")) {
                    const diskPath = path.join(ROOT, v.slice(5));
                    if (!fs.existsSync(diskPath)) errors.push(`${rel}: missing pkg asset "${v}"`);
                    if (tag === "script") scripts.push(v.slice(5));
                }
            }
            if (k === "onChange" && tag === "field") {
                callbacks.push(v);
            }
        }
    }
    if (tagStack.length > 0) errors.push(`${rel}: unclosed XML tags: ${tagStack.join(", ")}`);

    // Verify zero duplicate functions across a component's compiled script bundle & verify callbacks exist
    const seenFns = new Map();
    for (const sRel of scripts) {
        const fns = fileFunctionMap.get(sRel) || [];
        for (const fn of fns) {
            if (seenFns.has(fn)) {
                errors.push(`${rel}: duplicate BrightScript function "${fn}" in scripts (${seenFns.get(fn)} and ${sRel})`);
            }
            seenFns.set(fn, sRel);
        }
    }
    for (const cb of callbacks) {
        if (!seenFns.has(cb.toLowerCase()) && !rel.includes("MainSceneBase.xml")) {
            warnings.push(`${rel}: onChange="${cb}" not found in direct component scripts`);
        }
    }
}

// 2. Validate locale JSON files & placeholder parity
const placeholderRe = /\{[a-zA-Z0-9_]+\}/g;
for (const lf of localeFiles) {
    const rel = path.relative(ROOT, lf);
    let obj;
    try {
        obj = JSON.parse(fs.readFileSync(lf, "utf8"));
    } catch (e) {
        errors.push(`${rel}: invalid JSON (${e.message})`);
        continue;
    }
    for (const [k, v] of Object.entries(obj)) {
        if (typeof v !== "string") {
            errors.push(`${rel}: value for key "${k}" must be string`);
            continue;
        }
        const phK = (k.match(placeholderRe) || []).sort().join(",");
        const phV = (v.match(placeholderRe) || []).sort().join(",");
        if (phK !== phV) {
            errors.push(`${rel}: placeholder mismatch for "${k}" (${phK} vs ${phV})`);
        }
    }
}

console.log(`Checked ${brsFiles.length} .brs files, ${xmlFiles.length} .xml files, ${localeFiles.length} locale files.`);
if (warnings.length) {
    console.log("Warnings:");
    for (const w of warnings) console.log(`  WARN  ${w}`);
}
if (errors.length) {
    console.error("Static Verification FAILED:");
    for (const e of errors) console.error(`  ERR   ${e}`);
    process.exit(1);
}
console.log("Static Verification PASSED.");

// 3. Run unit tests against real BrightScript files
execFileSync("node", [path.join(ROOT, "tests", "run_tests.mjs")], { stdio: "inherit" });

// 4. Optional clean zip package test
if (process.argv.includes("--package")) {
    execFileSync("bash", [path.join(ROOT, "scripts", "package.sh")], { stdio: "inherit" });
}

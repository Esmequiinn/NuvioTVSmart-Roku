import vm from "node:vm";

function stripComments(line) {
    let inStr = false;
    for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (ch === '"') {
            inStr = !inStr;
        } else if (!inStr) {
            if (ch === "'") return line.slice(0, i);
            if ((ch === "r" || ch === "R") && /^rem(?:\s|$)/i.test(line.slice(i)) && (i === 0 || /\s/.test(line[i - 1]))) {
                return line.slice(0, i);
            }
        }
    }
    return line;
}

function splitTopLevelCommas(expr) {
    const parts = [];
    let cur = "";
    let depth = 0;
    let inStr = false;
    for (let i = 0; i < expr.length; i++) {
        const ch = expr[i];
        if (ch === '"') inStr = !inStr;
        if (!inStr) {
            if (ch === "(" || ch === "[" || ch === "{") depth++;
            else if (ch === ")" || ch === "]" || ch === "}") depth--;
            else if (ch === "," && depth === 0) {
                parts.push(cur.trim());
                cur = "";
                continue;
            }
        }
        cur += ch;
    }
    if (cur.trim() !== "") parts.push(cur.trim());
    return parts;
}

function mapOutsideStrings(src, fn, stringFn = (s) => s) {
    let out = "";
    let i = 0;
    while (i < src.length) {
        if (src[i] === '"') {
            let j = i + 1;
            while (j < src.length && src[j] !== '"') j++;
            if (j < src.length) j++;
            out += stringFn(src.slice(i, j));
            i = j;
        } else {
            let j = i;
            while (j < src.length && src[j] !== '"') j++;
            out += fn(src.slice(i, j));
            i = j;
        }
    }
    return out;
}

function transformExpr(expr) {
    return mapOutsideStrings(
        expr,
        (seg) => {
            let s = seg;
            s = s.replace(/\b(\d+)&/g, "$1");
            s = s.replace(/\b([A-Za-z_][A-Za-z0-9_]*)#/g, "$1_num");
            s = s.replace(/<>/g, " !== ");
            s = s.replace(/(?<![!<>=])=(?![=])/g, " === ");
            s = s.replace(/\bnot\b/gi, "!");
            s = s.replace(/\band\b/gi, "&&");
            s = s.replace(/\bor\b/gi, "||");
            s = s.replace(/\bmod\b/gi, "%");
            s = s.replace(/\binvalid\b/gi, "null");
            s = s.replace(/\btrue\b/gi, "true");
            s = s.replace(/\bfalse\b/gi, "false");
            s = s.replace(/===\s*null\b/g, "== null");
            s = s.replace(/!==\s*null\b/g, "!= null");
            s = s.replace(/\bnull\s*===/g, "null ==");
            s = s.replace(/\bnull\s*!==/g, "null !=");
            return s;
        },
        (lit) => {
            // BrightScript has no backslash escape sequences inside strings; escape backslashes for JS
            return lit.replace(/\\/g, "\\\\");
        }
    );
}

function findAssignmentIndex(stmt) {
    let inStr = false;
    let depth = 0;
    for (let i = 0; i < stmt.length; i++) {
        const ch = stmt[i];
        if (ch === '"') inStr = !inStr;
        if (!inStr) {
            if (ch === "(" || ch === "[" || ch === "{") depth++;
            else if (ch === ")" || ch === "]" || ch === "}") depth--;
            else if (ch === "=" && depth === 0) {
                const prev = i > 0 ? stmt[i - 1] : "";
                const next = i + 1 < stmt.length ? stmt[i + 1] : "";
                if (prev !== "<" && prev !== ">" && prev !== "!" && next !== "=") {
                    return i;
                }
            }
        }
    }
    return -1;
}

function transformSingleStmt(stmt) {
    const trimmed = stmt.trim();
    if (!trimmed) return "";
    if (/^return\b/i.test(trimmed)) {
        const rest = trimmed.slice(6).trim();
        return rest ? `return (${transformExpr(rest)});` : "return;";
    }
    if (/^exit\s+(for|while)\b/i.test(trimmed)) return "break;";
    if (/^print\b/i.test(trimmed)) return `/* print */ void 0;`;
    if (/^sleep\s*\(/i.test(trimmed)) return `void 0;`;

    // Assignment at top-level?
    const eqIdx = findAssignmentIndex(trimmed);
    // Ensure LHS doesn't look like "if ..." or function call unless indexed on left
    if (eqIdx > 0) {
        const lhs = trimmed.slice(0, eqIdx).trim();
        const rhs = trimmed.slice(eqIdx + 1).trim();
        if (/^[A-Za-z_][A-Za-z0-9_#\.\[\]"']*$/.test(lhs) || /\[\s*.*\s*\]$/.test(lhs)) {
            const cleanLhs = lhs.replace(/#/g, "_num");
            return `${cleanLhs} = ${transformExpr(rhs)};`;
        }
    }
    return `${transformExpr(trimmed)};`;
}

function joinMultilineLiterals(lines) {
    const out = [];
    let i = 0;
    let braceDepth = 0;
    let parenDepth = 0;
    while (i < lines.length) {
        const raw = stripComments(lines[i]).trim();
        if (!raw) {
            i++;
            continue;
        }
        // Track multi-line { ... } or [ ... ] or ( ... ) literals across lines
        let combined = raw;
        const countDelta = (str) => {
            let b = 0;
            let p = 0;
            let inStr = false;
            for (let k = 0; k < str.length; k++) {
                const ch = str[k];
                if (ch === '"') inStr = !inStr;
                if (!inStr) {
                    if (ch === "{" || ch === "[") b++;
                    else if (ch === "}" || ch === "]") b--;
                    else if (ch === "(") p++;
                    else if (ch === ")") p--;
                }
            }
            return { b, p };
        };
        let delta = countDelta(combined);
        braceDepth = delta.b;
        parenDepth = delta.p;
        while ((braceDepth > 0 || parenDepth > 0) && i + 1 < lines.length) {
            i++;
            const nextRaw = stripComments(lines[i]).trim();
            if (!nextRaw) continue;
            const prevEnd = combined.slice(-1);
            const nextStart = nextRaw[0];
            const needComma =
                prevEnd !== "{" &&
                prevEnd !== "[" &&
                prevEnd !== "(" &&
                prevEnd !== "," &&
                prevEnd !== ":" &&
                nextStart !== "}" &&
                nextStart !== "]" &&
                nextStart !== ")";
            combined += (needComma ? ", " : " ") + nextRaw;
            const nd = countDelta(nextRaw);
            braceDepth += nd.b;
            parenDepth += nd.p;
        }
        out.push(combined);
        i++;
    }
    return out;
}

function splitThenInline(line) {
    // Finds top-level "then" keyword outside strings
    let inStr = false;
    let depth = 0;
    for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (ch === '"') inStr = !inStr;
        if (!inStr) {
            if (ch === "(" || ch === "[" || ch === "{") depth++;
            else if (ch === ")" || ch === "]" || ch === "}") depth--;
            else if (depth === 0 && /^then(?=\s|$)/i.test(line.slice(i)) && (i === 0 || /\s|\)/.test(line[i - 1]))) {
                return { cond: line.slice(0, i).trim(), rest: line.slice(i + 4).trim() };
            }
        }
    }
    return { cond: line.trim(), rest: "" };
}

function splitElseInline(rest) {
    let inStr = false;
    let depth = 0;
    for (let i = 0; i < rest.length; i++) {
        const ch = rest[i];
        if (ch === '"') inStr = !inStr;
        if (!inStr) {
            if (ch === "(" || ch === "[" || ch === "{") depth++;
            else if (ch === ")" || ch === "]" || ch === "}") depth--;
            else if (depth === 0 && /^else(?=\s|$)/i.test(rest.slice(i)) && (i === 0 || /\s/.test(rest[i - 1]))) {
                return { thenStmt: rest.slice(0, i).trim(), elseStmt: rest.slice(i + 4).trim() };
            }
        }
    }
    return { thenStmt: rest.trim(), elseStmt: "" };
}

function rewriteMethods(jsCode) {
    // Wrap BrightScript AA object literals & array/string methods safely via AST-free token helpers
    // Specifically wrap `{ ... }` object literals outside keys only at runtime? Better: prototype-less helpers not needed if we run in isolated VM context!
    return jsCode;
}

export function transpileBrsToJs(sourceText) {
    const rawLines = sourceText.split(/\r?\n/);
    const lines = joinMultilineLiterals(rawLines);
    const js = [];
    const declaredVars = [new Set()];

    const trackLocals = (line) => {
        const scope = declaredVars[declaredVars.length - 1];
        const eqIdx = findAssignmentIndex(line);
        if (eqIdx > 0) {
            const lhs = line.slice(0, eqIdx).trim();
            if (/^[A-Za-z_][A-Za-z0-9_#]*$/.test(lhs)) {
                const name = lhs.replace(/#/g, "_num");
                if (name !== "m" && !scope.has(name)) {
                    scope.add(name);
                    return `var ${name}; `;
                }
            }
        }
        return "";
    };

    function transformInlineIf(stmtStr, isMultilineElseIf = false) {
        let s = stmtStr.trim();
        let prefix = "";
        if (/^if\b/i.test(s)) {
            const afterIf = s.slice(2).trim();
            const { cond, rest } = splitThenInline(afterIf);
            if (!rest) return { code: `if (__truthy(${transformExpr(cond)})) {`, closed: false };
            const { thenStmt, elseStmt } = splitElseInline(rest);
            const decl1 = trackLocals(thenStmt);
            if (!elseStmt) return { code: `if (__truthy(${transformExpr(cond)})) { ${decl1}${transformSingleStmt(thenStmt)} }`, closed: true };
            if (/^if\b/i.test(elseStmt)) {
                const sub = transformInlineIf(elseStmt, false);
                return { code: `if (__truthy(${transformExpr(cond)})) { ${decl1}${transformSingleStmt(thenStmt)} } else ${sub.code}`, closed: sub.closed };
            }
            const decl2 = trackLocals(elseStmt);
            return { code: `if (__truthy(${transformExpr(cond)})) { ${decl1}${transformSingleStmt(thenStmt)} } else { ${decl2}${transformSingleStmt(elseStmt)} }`, closed: true };
        }
        return { code: `${trackLocals(s)}${transformSingleStmt(s)}`, closed: true };
    }

    for (const line of lines) {
        let s = line.trim();
        if (!s) continue;

        const fnMatch = s.match(/^(sub|function)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)(?:\s+as\s+[A-Za-z_][A-Za-z0-9_]*)?$/i);
        if (fnMatch) {
            const fnName = fnMatch[2];
            const paramsRaw = fnMatch[3].trim();
            const paramNames = [];
            const paramDefs = [];
            if (paramsRaw) {
                for (const p of splitTopLevelCommas(paramsRaw)) {
                    const pm = p.match(/^([A-Za-z_][A-Za-z0-9_#]*)(?:\s*=\s*([^ ]+))?(?:\s+as\s+[A-Za-z_][A-Za-z0-9_]*)?$/i);
                    if (pm) {
                        const pn = pm[1].replace(/#/g, "_num");
                        paramNames.push(pn);
                        paramDefs.push(pm[2] ? `${pn} = ${transformExpr(pm[2])}` : pn);
                    }
                }
            }
            declaredVars.push(new Set(paramNames));
            js.push(`function ${fnName}(${paramDefs.join(", ")}) {`);
            continue;
        }

        if (/^end\s+(sub|function)$/i.test(s)) {
            declaredVars.pop();
            js.push("}");
            continue;
        }

        if (/^if\b/i.test(s)) {
            js.push(transformInlineIf(s).code);
            continue;
        }

        if (/^else\s+if\b/i.test(s)) {
            const afterElseIf = s.replace(/^else\s+if\b/i, "").trim();
            const { cond, rest } = splitThenInline(afterElseIf);
            if (rest) {
                const { thenStmt, elseStmt } = splitElseInline(rest);
                const decl = trackLocals(thenStmt);
                let outLine = `} else if (__truthy(${transformExpr(cond)})) { ${decl}${transformSingleStmt(thenStmt)}`;
                if (elseStmt) {
                    const decl2 = trackLocals(elseStmt);
                    outLine += ` } else { ${decl2}${transformSingleStmt(elseStmt)}`;
                }
                js.push(outLine);
            } else {
                js.push(`} else if (__truthy(${transformExpr(cond)})) {`);
            }
            continue;
        }

        if (/^else$/i.test(s)) {
            js.push("} else {");
            continue;
        }

        if (/^end\s*if$/i.test(s)) {
            js.push("}");
            continue;
        }

        if (/^for\s+each\b/i.test(s)) {
            const fem = s.match(/^for\s+each\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.+)$/i);
            if (fem) {
                const v = fem[1];
                const col = transformExpr(fem[2]);
                declaredVars[declaredVars.length - 1].add(v);
                js.push(`for (const ${v} of __iter(${col})) {`);
                continue;
            }
        }

        if (/^for\s+/i.test(s)) {
            const fm = s.match(/^for\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/i);
            if (fm) {
                const v = fm[1];
                let rest = fm[2];
                let stepExpr = "1";
                const stepMatch = rest.match(/^(.*)\s+step\s+(.+)$/i);
                if (stepMatch) {
                    rest = stepMatch[1];
                    stepExpr = transformExpr(stepMatch[2]);
                }
                const toParts = rest.split(/\s+to\s+/i);
                const startExpr = transformExpr(toParts[0]);
                const endExpr = transformExpr(toParts.slice(1).join(" to "));
                declaredVars[declaredVars.length - 1].add(v);
                js.push(`for (let ${v} = (${startExpr}), __end_${v} = (${endExpr}), __step_${v} = (${stepExpr}); __step_${v} >= 0 ? ${v} <= __end_${v} : ${v} >= __end_${v}; ${v} += __step_${v}) {`);
                continue;
            }
        }

        if (/^(end\s+for|next)$/i.test(s)) {
            js.push("}");
            continue;
        }

        if (/^while\b/i.test(s)) {
            const cond = s.slice(5).trim();
            js.push(`while (__truthy(${transformExpr(cond)})) {`);
            continue;
        }

        if (/^end\s+while$/i.test(s)) {
            js.push("}");
            continue;
        }

        if (/^try$/i.test(s)) {
            js.push("try {");
            continue;
        }

        if (/^catch\b/i.test(s)) {
            const varName = s.slice(5).trim() || "_err";
            js.push(`} catch (${varName}) {`);
            continue;
        }

        if (/^end\s+try$/i.test(s)) {
            js.push("}");
            continue;
        }

        const decl = trackLocals(s);
        js.push(decl + transformSingleStmt(s));
    }

    return rewriteMethods(js.join("\n"));
}

export function createBrsSandbox(overrides = {}) {
    const logs = [];
    const files = new Map(Object.entries(overrides.files || {}));
    const registry = new Map(Object.entries(overrides.registry || {}));
    let httpMock = overrides.httpMock || (() => ({ code: 0, body: "", json: null, headers: {} }));
    let nowSeconds = overrides.nowSeconds ?? 1700000000;
    const deviceLocale = overrides.locale || "pt_BR";
    const mGlobal = overrides.global || {
        uiLang: "pt",
        stVer: 1,
        i18n: {},
        hasField(k) { return Object.prototype.hasOwnProperty.call(this, k); }
    };

    const wrapAA = (obj) => obj; // handled via runtime helpers & prototype inside VM only

    const contextObj = {
        m: { global: mGlobal, top: overrides.top || null },
        __iter(col) {
            if (!col) return [];
            if (Array.isArray(col)) return col;
            if (typeof col === "object") return Object.keys(col);
            return [];
        },
        __truthy(v) {
            return Boolean(v);
        },
        LCase(s) { return String(s ?? "").toLowerCase(); },
        UCase(s) { return String(s ?? "").toUpperCase(); },
        Len(s) { return s == null ? 0 : String(s).length; },
        Left(s, n) { return String(s ?? "").slice(0, Math.max(0, n | 0)); },
        Right(s, n) {
            const str = String(s ?? "");
            const k = Math.max(0, n | 0);
            return k === 0 ? "" : str.slice(-k);
        },
        Mid(s, start1, length) {
            const str = String(s ?? "");
            const idx = Math.max(0, (start1 | 0) - 1);
            if (length === undefined) return str.slice(idx);
            return str.slice(idx, idx + Math.max(0, length | 0));
        },
        Instr(arg1, arg2, arg3) {
            let start1 = 1;
            let text = "";
            let sub = "";
            if (arg3 !== undefined) {
                start1 = Math.max(1, arg1 | 0);
                text = String(arg2 ?? "");
                sub = String(arg3 ?? "");
            } else {
                text = String(arg1 ?? "");
                sub = String(arg2 ?? "");
            }
            if (!sub) return 0;
            const idx = text.indexOf(sub, start1 - 1);
            return idx < 0 ? 0 : idx + 1;
        },
        Asc(s) {
            const str = String(s ?? "");
            return str.length ? str.codePointAt(0) : 0;
        },
        Chr(cp) {
            const code = cp | 0;
            try { return String.fromCodePoint(code); } catch { return ""; }
        },
        Int(v) { return Math.floor(Number(v) || 0); },
        Fix(v) { return Math.trunc(Number(v) || 0); },
        Abs(v) { return Math.abs(Number(v) || 0); },
        Val(s, radix = 10) {
            if (typeof s === "number") return s;
            const n = parseFloat(String(s ?? "").trim());
            return Number.isNaN(n) ? 0 : n;
        },
        Str(v) {
            const n = Number(v) || 0;
            return n >= 0 ? ` ${n}` : `${n}`;
        },
        Stri(v) {
            const n = Math.trunc(Number(v) || 0);
            return n >= 0 ? ` ${n}` : `${n}`;
        },
        Rnd(n) {
            return Math.floor(Math.random() * Math.max(1, n | 0)) + 1;
        },
        FormatJson(v) { return JSON.stringify(v); },
        ParseJson(s) {
            return vm.runInContext(`(() => { try { return JSON.parse(${JSON.stringify(String(s ?? ""))}); } catch { return null; } })()`, contextObj);
        },
        lcase(s) { return contextObj.LCase(s); },
        ucase(s) { return contextObj.UCase(s); },
        len(s) { return contextObj.Len(s); },
        left(s, n) { return contextObj.Left(s, n); },
        right(s, n) { return contextObj.Right(s, n); },
        mid(s, a, b) { return contextObj.Mid(s, a, b); },
        instr(a, b, c) { return contextObj.Instr(a, b, c); },
        asc(s) { return contextObj.Asc(s); },
        chr(cp) { return contextObj.Chr(cp); },
        formatjson(v) { return contextObj.FormatJson(v); },
        parsejson(s) { return contextObj.ParseJson(s); },
        ReadAsciiFile(path) {
            return files.has(path) ? files.get(path) : "";
        },
        WriteAsciiFile(path, text) {
            files.set(path, String(text));
            return true;
        },
        DeleteFile(path) {
            return files.delete(path);
        },
        type(v) {
            if (v === null || v === undefined) return "Invalid";
            if (typeof v === "string") return "roString";
            if (typeof v === "boolean") return "roBoolean";
            if (typeof v === "number") return Number.isInteger(v) ? "roInt" : "roFloat";
            if (Array.isArray(v)) return "roArray";
            if (v.__roType) return v.__roType;
            return "roAssociativeArray";
        },
        GetInterface(v, iface) {
            if (v === null || v === undefined) return null;
            if (iface === "ifString" && typeof v === "string") return true;
            if (iface === "ifBoolean" && typeof v === "boolean") return true;
            if (iface === "ifInt" && typeof v === "number" && Number.isInteger(v)) return true;
            if (iface === "ifLongInt" && typeof v === "number" && Number.isInteger(v)) return true;
            if ((iface === "ifFloat" || iface === "ifDouble") && typeof v === "number") return true;
            if (iface === "ifToStr" && (typeof v === "string" || typeof v === "number" || typeof v === "boolean")) return true;
            return null;
        },
        CreateObject(kind, ...args) {
            if (kind === "roRegex") {
                const pattern = String(args[0] || "");
                const flags = String(args[1] || "").replace(/[^im]/g, "");
                const reSingle = new RegExp(pattern, flags);
                const reGlobal = new RegExp(pattern, flags.includes("g") ? flags : `${flags}g`);
                const toVmArr = (arr) => {
                    const out = vm.runInContext("[]", contextObj);
                    for (const x of arr) out.Push(x);
                    return out;
                };
                return {
                    __roType: "roRegex",
                    IsMatch(s) { return reSingle.test(String(s ?? "")); },
                    Match(s) {
                        const m = String(s ?? "").match(reSingle);
                        return m ? toVmArr(m) : toVmArr([]);
                    },
                    MatchAll(s) {
                        const out = toVmArr([]);
                        for (const m of String(s ?? "").matchAll(reGlobal)) {
                            out.Push(toVmArr(m));
                        }
                        return out;
                    },
                    Replace(s, repl) { return String(s ?? "").replace(reSingle, repl); },
                    ReplaceAll(s, repl) { return String(s ?? "").replace(reGlobal, repl); },
                    Split(s) { return toVmArr(String(s ?? "").split(reSingle)); }
                };
            }
            if (kind === "roByteArray") {
                let bytes = Buffer.alloc(0);
                return {
                    __roType: "roByteArray",
                    FromAsciiString(s) { bytes = Buffer.from(String(s ?? ""), "utf8"); },
                    Count() { return bytes.length; }
                };
            }
            if (kind === "roDateTime") {
                return {
                    __roType: "roDateTime",
                    AsSeconds() { return nowSeconds; },
                    ToISOString() { return new Date(nowSeconds * 1000).toISOString(); }
                };
            }
            if (kind === "roTimespan") {
                const start = Date.now();
                return {
                    __roType: "roTimespan",
                    Mark() {},
                    TotalMilliseconds() { return Date.now() - start; },
                    TotalSeconds() { return Math.floor((Date.now() - start) / 1000); }
                };
            }
            if (kind === "roDeviceInfo") {
                return {
                    __roType: "roDeviceInfo",
                    GetCurrentLocale() { return deviceLocale; },
                    CanDecodeAudio() { return { result: false }; },
                    CanDecodeVideo() { return { result: true }; },
                    GetModel() { return "3941X"; },
                    GetModelDisplayName() { return "Roku Express 4K"; },
                    GetVideoMode() { return "1080p"; },
                    GetUIResolution() { return { name: "FHD" }; },
                    GetChannelClientId() { return "roku-test-device-id"; },
                    GetRandomUUID() { return "00000000-0000-4000-8000-000000000001"; },
                    GetIPAddrs() { return {}; }
                };
            }
            if (kind === "roFileSystem") {
                return {
                    __roType: "roFileSystem",
                    Exists(path) { return files.has(path); },
                    Delete(path) { return files.delete(path); }
                };
            }
            if (kind === "roRegistrySection") {
                const sec = args[0] || "nuviotv";
                return {
                    __roType: "roRegistrySection",
                    Exists(k) { return registry.has(`${sec}:${k}`); },
                    Read(k) { return registry.get(`${sec}:${k}`) || ""; },
                    Write(k, v) { registry.set(`${sec}:${k}`, String(v)); return true; },
                    Delete(k) { return registry.delete(`${sec}:${k}`); },
                    Flush() { return true; },
                    GetKeyList() {
                        const prefix = `${sec}:`;
                        return Array.from(registry.keys()).filter((k) => k.startsWith(prefix)).map((k) => k.slice(prefix.length));
                    }
                };
            }
            if (kind === "roAssociativeArray") return {};
            if (kind === "roArray") return [];
            return {};
        },
        Http_Request(method, url, headers, body, timeout) {
            return httpMock(method, url, headers, body, timeout);
        }
    };

    const ctx = vm.createContext(contextObj);

    // Install isolated prototype helpers ONLY inside this VM realm!
    vm.runInContext(`
        String.prototype.Trim = function() { return this.trim(); };
        String.prototype.Split = function(sep) {
            if (!sep) return Array.from(this);
            return this.split(sep);
        };
        String.prototype.Replace = function(a, b) { return this.split(a).join(b); };
        String.prototype.ToInt = function() {
            const n = parseInt(this, 10);
            return Number.isNaN(n) ? 0 : n;
        };
        String.prototype.ToFloat = function() {
            const n = parseFloat(this);
            return Number.isNaN(n) ? 0 : n;
        };
        String.prototype.ToStr = function() { return String(this); };
        String.prototype.EncodeUriComponent = function() { return encodeURIComponent(String(this)); };
        Number.prototype.ToStr = function() { return String(this); };
        Boolean.prototype.ToStr = function() { return String(this); };

        Array.prototype.Push = function(x) { return this.push(x); };
        Array.prototype.Pop = function() { return this.pop(); };
        Array.prototype.Shift = function() { return this.shift(); };
        Array.prototype.Unshift = function(x) { return this.unshift(x); };
        Array.prototype.Count = function() { return this.length; };
        Array.prototype.Delete = function(idx) { this.splice(idx, 1); };
        Array.prototype.Append = function(other) {
            if (Array.isArray(other)) this.push(...other);
        };
        Array.prototype.Join = function(sep) { return this.join(sep); };
        Array.prototype.SortBy = function(field, flags) {
            const desc = String(flags || "").toLowerCase().includes("r");
            this.sort((a, b) => {
                const va = a && a[field] !== undefined ? a[field] : "";
                const vb = b && b[field] !== undefined ? b[field] : "";
                if (va < vb) return desc ? 1 : -1;
                if (va > vb) return desc ? -1 : 1;
                return 0;
            });
        };

        // Case-insensitive AA helper methods (defined non-enumerable)
        function __aaFindKey(obj, k) {
            const low = String(k).toLowerCase();
            if (Object.prototype.hasOwnProperty.call(obj, k)) return k;
            for (const key of Object.keys(obj)) {
                if (key.toLowerCase() === low) return key;
            }
            return null;
        }
        Object.defineProperty(Object.prototype, "DoesExist", {
            value: function(k) { return __aaFindKey(this, k) !== null; },
            enumerable: false, configurable: true
        });
        Object.defineProperty(Object.prototype, "Delete", {
            value: function(k) {
                if (Array.isArray(this)) { this.splice(k, 1); return true; }
                const found = __aaFindKey(this, k);
                if (found !== null) { delete this[found]; return true; }
                return false;
            },
            enumerable: false, configurable: true
        });
        Object.defineProperty(Object.prototype, "Count", {
            value: function() { return Array.isArray(this) ? this.length : Object.keys(this).length; },
            enumerable: false, configurable: true
        });
        Object.defineProperty(Object.prototype, "Keys", {
            value: function() { return Object.keys(this); },
            enumerable: false, configurable: true
        });
        Object.defineProperty(Object.prototype, "Append", {
            value: function(other) {
                if (Array.isArray(this) && Array.isArray(other)) { this.push(...other); return; }
                if (other && typeof other === "object") Object.assign(this, other);
            },
            enumerable: false, configurable: true
        });
    `, ctx);

    return {
        ctx,
        files,
        registry,
        setHttpMock(fn) {
            httpMock = fn;
            contextObj.Http_Request = (method, url, headers, body, timeout) => fn(method, url, headers, body, timeout);
        },
        setNow(sec) { nowSeconds = sec; },
        loadBrs(code, label = "brs") {
            const js = transpileBrsToJs(code);
            vm.runInContext(js, ctx, { filename: label });
        },
        evalJs(code) {
            return vm.runInContext(code, ctx);
        }
    };
}

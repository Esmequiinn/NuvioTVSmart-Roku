import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

const proxySource = await readFile("docs/youtube-proxy.html", "utf8");
const captionFunction = proxySource.slice(
  proxySource.indexOf("function setCaptionsEnabled("),
  proxySource.indexOf("function handleCommand(")
);
const calls = [];
const player = {
  getOptions: () => [],
  loadModule: (name) => calls.push("load:" + name),
  unloadModule: (name) => calls.push("unload:" + name)
};
const captionContext = vm.createContext({
  player,
  captionsEnabled: false,
  safeCall: (fn, fallback) => {
    try {
      return fn();
    } catch {
      return fallback;
    }
  }
});
vm.runInContext(captionFunction, captionContext);
captionContext.setCaptionsEnabled(false);
assert.equal(calls.length, 0, "do not unload modules already absent on API-change callbacks");
player.getOptions = () => ["captions"];
captionContext.setCaptionsEnabled(false);
assert.deepEqual(calls.splice(0), ["unload:captions"]);
player.getOptions = () => {
  throw new Error("unsupported");
};
captionContext.setCaptionsEnabled(false);
assert.deepEqual(
  calls.splice(0),
  ["unload:captions", "unload:cc"],
  "retain the legacy fallback if module discovery fails"
);
captionContext.setCaptionsEnabled(true);
assert.deepEqual(calls, ["load:captions", "load:cc"], "enabling captions must remain unchanged");
console.log("YouTube caption module fixtures passed.");

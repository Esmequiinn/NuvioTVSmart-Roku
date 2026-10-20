import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { build } from "esbuild";

// Execute production functions with platform/network dependencies replaced by fixtures.
const entry = `
export { AmbientMode } from './js/ui/ambient/ambientMode.js';
export { isAmbientTrailerPlaying } from './js/ui/ambient/ambientPlaybackPolicy.js';
export { syncHtmlSubtitleClearance } from './js/ui/screens/player/subtitleOverlayClearance.js';
export { createStreamScreenMethods09 } from './js/ui/screens/stream/streamScreenMethods-09-render.js';
export { ratingToneClass } from './js/ui/screens/detail/metaDetailsScreenHelpers-04-detect-quality.js';
export { createHomeScreenMethods13 } from './js/ui/screens/home/homeScreenMethods-13-mount-trailer-layer.js';
export { createHomeScreenMethods12 } from './js/ui/screens/home/homeScreenMethods-12-sync-collection-hero-media.js';
`;
const bundle = await build({
  stdin: { contents: entry, resolveDir: process.cwd() },
  bundle: true,
  write: false,
  format: "iife",
  globalName: "subject",
  plugins: [
    {
      name: "fixture-dependencies",
      setup(b) {
        b.onLoad(
          {
            filter:
              /(?:ambientMode|metaDetailsScreenHelpers-04-detect-quality|streamScreenMethods-09-render|homeScreenMethods-1[23]-[^/]+)\.js$/
          },
          async ({ path }) => {
            let contents = await readFile(path, "utf8");
            contents = contents.replace(
              /^import \* as internals from [^;]+;/gm,
              "const internals = globalThis.fixtures;"
            );
            contents = contents.replace(
              /^import \{([\s\S]*?)\} from "([^"]+)";/gm,
              (all, names, target) =>
                target.endsWith("ambientPlaybackPolicy.js")
                  ? all
                  : `const {${names.replace(/\bas\b/g, ":")}} = globalThis.fixtures;`
            );
            return { contents, loader: "js" };
          }
        );
      }
    }
  ]
});
let clock = 0,
  route = "home",
  screen = {},
  started = 0;
const classes = () => ({ contains: () => false, add() {}, remove() {} });
const fixtures = {
  Router: { getCurrent: () => route, getCurrentScreen: () => screen },
  ProfileManager: { getActiveProfileId: () => "1" },
  AmbientModeStore: { get: () => ({ enabled: true, timeoutMinutes: 1 }) },
  ScreenUtils: { indexFocusables() {} },
  DebridSettingsStore: { get: () => ({}) },
  StreamBadgeSettingsStore: { snapshot: () => ({}) },
  isPerformanceConstrainedRuntime: () => false,
  escapeHtml: String,
  contentTextDirection: () => "ltr",
  findStreamVirtualIndex: () => 0
};
const context = vm.createContext({
  fixtures,
  console,
  performance: { now: () => clock },
  setTimeout,
  clearTimeout,
  WeakMap,
  document: { hidden: false },
  getComputedStyle: () => ({ display: "block", visibility: "visible" })
});
vm.runInContext(bundle.outputFiles[0].text, context);
const api = context.subject;
const ambient = api.AmbientMode;
ambient.show = () => {
  started++;
};
ambient.signature = JSON.stringify(["1", fixtures.AmbientModeStore.get()]);
ambient.tick();
clock = 61000;
screen = {
  isTrailerPlaying: true,
  getTrailerPlaybackSnapshot: () => ({ paused: false, loading: false })
};
ambient.tick();
assert.equal(started, 0);
clock = 120000;
ambient.tick();
assert.equal(started, 0);
screen = {};
clock = 121000;
ambient.tick();
assert.equal(started, 0);
clock = 180999;
ambient.tick();
assert.equal(started, 0);
clock = 181001;
ambient.tick();
assert.equal(started, 1);
route = "detail";
ambient.tick();
assert.equal(started, 1, "route changes reset idle");
assert.equal(
  api.isAmbientTrailerPlaying({
    isTrailerPlaying: true,
    getTrailerPlaybackSnapshot: () => ({ paused: true })
  }),
  false
);
const video = { isConnected: true, tagName: "VIDEO", paused: false, ended: false, readyState: 2 };
const home = { container: { querySelectorAll: () => [video] } };
assert.equal(api.isAmbientTrailerPlaying(home), true);
video.ended = true;
assert.equal(api.isAmbientTrailerPlaying(home), false);
let listener, frame;
context.window = {
  addEventListener: (_, fn) => {
    listener = fn;
  },
  removeEventListener() {}
};
context.document.createElement = () =>
  (frame = { dataset: {}, contentWindow: {}, addEventListener() {}, isConnected: true });
const layer = {
  classList: classes(),
  appendChild: (node) => {
    node.parentElement = layer;
  }
};
api.createHomeScreenMethods13().mountTrailerLayer.call({ clearTrailerLayer() {} }, layer, {
  kind: "youtube",
  embedUrl: "http://localhost/fixture"
});
const message = (data, source = frame.contentWindow) =>
  listener({ source, data: { source: "nuvio-youtube-proxy", ...data } });
message({ type: "state", state: { paused: false, loading: false } }, {});
assert.equal(frame.dataset.ambientTrailerPlaying, undefined, "ignore another frame");
message({ type: "state", state: { paused: false, loading: false } });
assert.equal(frame.dataset.ambientTrailerPlaying, "true");
frame.tagName = "IFRAME";
assert.equal(api.isAmbientTrailerPlaying({ container: { querySelectorAll: () => [frame] } }), true);
message({ type: "state", state: { paused: true, loading: false } });
assert.equal(frame.dataset.ambientTrailerPlaying, "false");
frame.dataset.ambientTrailerPlaying = "true";
api
  .createHomeScreenMethods12()
  .pauseTrailerLayer.call(
    {},
    { querySelector: (selector) => (selector === "iframe" ? frame : null) }
  );
assert.equal(frame.dataset.ambientTrailerPlaying, "false");
const properties = new Map();
let placement;
const node = (top) => ({
  classList: classes(),
  getClientRects: () => [1],
  getBoundingClientRect: () => ({ top, height: 40 })
});
const player = {
  controlsVisible: true,
  seekOverlayVisible: true,
  subtitleStyleSettings: { verticalOffset: 15 },
  assSubtitleRenderer: {
    setPlacement: (p) => {
      placement = p;
    }
  },
  uiRefs: {
    root: {
      style: {
        getPropertyValue: (k) => properties.get(k),
        setProperty: (k, v) => properties.set(k, v)
      },
      getBoundingClientRect: () => ({ bottom: 540, height: 540 })
    },
    controlsBottom: node(350),
    controlsOverlay: { classList: classes() },
    skipIntro: node(290),
    nextEpisodeCard: node(250),
    seekOverlay: node(280)
  }
};
api.syncHtmlSubtitleClearance(player);
const lift = properties.get("--player-subtitle-clearance");
const offset = placement.userOffsetPx;
assert.notEqual(lift, "0px");
player.subtitleDialogVisible = true;
api.syncHtmlSubtitleClearance(player);
assert.equal(properties.get("--player-subtitle-clearance"), "0px");
assert.equal(placement.overlayTop, null);
assert.equal(placement.userOffsetPx, offset);
player.subtitleDialogVisible = false;
api.syncHtmlSubtitleClearance(player);
assert.equal(properties.get("--player-subtitle-clearance"), lift);
const render = api.createStreamScreenMethods09().render;
function renderCase(index, moved, virtualized = true) {
  const old = ["old-first", "selected"];
  const current = ["new-first", ...old];
  const state = {
    focusState: { zone: "card", row: index },
    streamUserMovedFocus: moved,
    streamVirtualized: true,
    streamVirtualModel: { keys: old, offsets: [0, 100] },
    listScrollTop: 25,
    params: {},
    streams: current,
    sourceChips: [],
    container: { querySelector: () => null },
    getFilteredStreams: () => current,
    getHeaderMeta: () => ({}),
    getBackdropUrl: () => "",
    buildSourceChipMarkup: () => "",
    hasPendingSourceLoads: () => false,
    shouldUseStreamVirtualization: () => virtualized,
    getStreamVirtualKeys: () => current,
    renderStreamVirtualMarkup: () => "",
    renderStreamCard: () => "",
    renderStableStreamEmptyState: () => "",
    renderStableStreamLoadingRow: () => "",
    renderContinueWatchingResumeOverlay: () => "",
    renderAutoPlayOverlay: () => "",
    stopStreamVirtualization() {
      this.streamVirtualized = false;
    }
  };
  for (const name of [
    "cancelScheduledRender",
    "applyAddonFilterDomState",
    "restoreScrollPosition",
    "hydrateVisibleStreamBadges",
    "bindAddonLogoFallbacks",
    "applyFocus",
    "bindListScrollState",
    "requestStreamVirtualMeasure",
    "requestStreamVirtualSync"
  ])
    state[name] = () => {};
  render.call(state);
  return state;
}
assert.equal(renderCase(0, false).focusState.row, 0);
assert.equal(renderCase(0, false).listScrollTop, 0);
assert.equal(renderCase(1, true).focusState.row, 2);
assert.equal(
  renderCase(0, true).focusState.row,
  1,
  "preserve explicit selection/return from playback"
);
assert.equal(renderCase(0, false, false).focusState.row, 0);
assert.equal(api.ratingToneClass(9.7), "exceptional");
assert.equal(api.ratingToneClass(10), "exceptional");
assert.equal(api.ratingToneClass(9.69), "excellent");
assert.equal(api.ratingToneClass(9), "excellent");
assert.equal(api.ratingToneClass(8), "great");
console.log(
  "October 16 UI parity fixtures passed (ambient, subtitle preview, stream focus, ratings)"
);

const ratingCss = await readFile("css/components-40.css", "utf8");
assert.match(
  ratingCss,
  /\.series-episode-rating-chip\.exceptional\s*\{[^}]*background:\s*#1da1f3/i
);

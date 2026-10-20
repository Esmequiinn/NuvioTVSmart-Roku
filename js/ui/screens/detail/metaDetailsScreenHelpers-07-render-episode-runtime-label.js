import { Router } from "../../navigation/routerState.js";

import { ScreenUtils } from "../../navigation/screen.js";

import { metaRepository } from "../../../data/repository/metaRepository.js";

import { watchProgressRepository } from "../../../data/repository/watchProgressRepository.js";

import { savedLibraryRepository } from "../../../data/repository/savedLibraryRepository.js";

import { watchedItemsRepository } from "../../../data/repository/watchedItemsRepository.js";

import { watchedItemsShareIdentity } from "../../../data/repository/watchedIdentity.js";

import { watchedTitleStateRepository } from "../../../data/repository/watchedTitleStateRepository.js";

import { libraryRepository, LibrarySourceMode } from "../../../data/repository/libraryRepository.js";

import { detailWatchedEnrichmentService } from "../../../data/repository/detailWatchedEnrichmentService.js";

import { watchedSeriesReconciliationService } from "../../../data/repository/watchedSeriesReconciliationService.js";

import { TmdbService } from "../../../core/tmdb/tmdbService.js";

import { TmdbMetadataService } from "../../../core/tmdb/tmdbMetadataService.js";

import { normalizeTmdbBackdropUrl } from "../../../core/tmdb/tmdbImageUrl.js";

import { LayoutPreferences } from "../../../data/local/layoutPreferences.js";

import { showHomeRatings, showStandardDetailRatings } from "../../../core/util/imdbRatingVisibility.js";

import { imdbEpisodeRatingsRepository } from "../../../data/repository/imdbEpisodeRatingsRepository.js";

import { formatHeroRuntime, normalizeEpisodeImdbRating, parseEpisodeRuntimeMinutes } from "./episodeCardMetadata.js";

import { mdbListRepository } from "../../../data/repository/mdbListRepository.js";

import { TmdbSettingsStore } from "../../../data/local/tmdbSettingsStore.js";

import { PlayerSettingsStore } from "../../../data/local/playerSettingsStore.js";

import { MoreLikeThisSourcePreference, TraktSettingsStore, WatchProgressSource } from "../../../data/local/traktSettingsStore.js";

import { requestJson as traktRequestJson, TraktAuthService } from "../../../data/repository/traktAuthService.js";

import { toTraktImageUrl } from "../../../core/trakt/traktImageUrl.js";

import { supportsMembershipFor } from "../../../core/tracking/trackingLibraryMembership.js";

import { Environment } from "../../../platform/environment.js";

import { Platform } from "../../../platform/index.js";

import { getTvRuntimePerformanceProfile } from "../../../platform/tvRuntimePerformance.js";

import { TMDB_API_KEY, TRAKT_API_URL, TRAKT_CLIENT_ID, YOUTUBE_PROXY_URL } from "../../../config.js";

import { I18n } from "../../../i18n/index.js";

import { localizedGenreLabel } from "../../../i18n/genreLabels.js";

import { contentTextDirection } from "../../../core/util/contentTextDirection.js";

import { mdbListRatingIcon } from "../../../core/util/mdbListRatingStatus.js";

import { NuvioDialog } from "../../components/nuvioDialog.js";

import { renderLoadingIndicator } from "../../components/loadingIndicator.js";

import { resolveMovieStreamIdentity } from "./movieStreamIdentity.js";

import { posterItemFromNode, PosterOptionsDialogController } from "../../components/posterOptionsMenu.js";

import { StreamPreferencesStore } from "../../../data/local/streamPreferencesStore.js";

import { buildWatchedTitleIdSet, isTitleItemWatched } from "../../components/watchedTitleBadge.js";

import {
  getWatchProgressFraction,
  isWatchProgressCompleted,
  isWatchProgressInProgress,
  watchProgressCompletedThreshold,
  resolveWatchProgressResumePositionMs
} from "../../../domain/model/watchProgress.js";

import { formatRuntimeMinutes } from "./metaDetailsScreenHelpers-04-detect-quality.js";
import { escapeHtml } from "./metaDetailsScreenHelpers-05-get-addon-badge-label.js";

export function renderEpisodeRuntimeLabel(runtimeMinutes = 0) {
  const runtime = formatRuntimeMinutes(runtimeMinutes);
  if (!runtime) {
    return "";
  }
  return `
    <span class="series-episode-runtime">
      <svg class="series-episode-runtime-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
        <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 10.1 3.3 3.3-1.4 1.4L11 12.9V6h2v6.1Z"></path>
      </svg>
      <span>${escapeHtml(runtime)}</span>
    </span>
  `;
}

export { formatPlaybackTime } from "./episodeCardMetadata.js";

export function normalizeTrailerProxyStatePayload(payload, fallbackMuted = false, fallbackCaptionsEnabled = false) {
  const source = payload && typeof payload === "object" ? payload : {};
  const nestedState = source.state && typeof source.state === "object" ? source.state : null;
  const candidate = nestedState || source;
  return {
    currentTime: Number(candidate.currentTime || 0),
    duration: Number(candidate.duration || 0),
    playerState: Number(candidate.playerState ?? -1),
    ended: Boolean(candidate.ended),
    paused: Boolean(candidate.paused),
    muted: candidate.muted == null ? Boolean(fallbackMuted) : Boolean(candidate.muted),
    captionsEnabled: candidate.captionsEnabled == null ? Boolean(fallbackCaptionsEnabled) : Boolean(candidate.captionsEnabled),
    loading: Boolean(candidate.loading),
    controllable: candidate.controllable !== false
  };
}

export function captureHorizontalScrollMap(container) {
  const state = {};
  Array.from(container?.querySelectorAll("[data-scroll-key]") || []).forEach((node) => {
    const key = String(node.dataset.scrollKey || "").trim();
    if (!key) {
      return;
    }
    state[key] = Number(node.scrollLeft || 0);
  });
  return state;
}

import { normalizeTmdbLanguageCode, TmdbSettingsStore } from "../../data/local/tmdbSettingsStore.js";

import { TMDB_API_KEY } from "../../config.js";

import { tmdbShowReleaseInfo, tmdbYearPart } from "../util/tmdbReleaseRange.js";

import { sortCollectionPartsByReleaseDate } from "./tmdbCollectionOrdering.js";
import { fetchTmdbJson } from "./tmdbService.js";

import {
  resolvePersonName,
  TMDB_IMAGE_SIZES,
  TMDB_LANGUAGE_DEFAULT_REGIONS,
  TMDB_TRAILER_FALLBACK_LANGUAGE,
  TMDB_BASE_URL
} from "./tmdbMetadataServiceHelpers-01-tmdb-base-url.js";

export function resolveCreditEntries(items, englishNames, language) {
  if (!Array.isArray(items)) {
    return items;
  }
  return items.map((item) => {
    const name = resolvePersonName({
      localizedName: item?.name,
      originalName: item?.original_name,
      fallbackEnglishName: englishNames.get(String(item?.id || "")),
      preferredLanguage: language
    });
    return name && name !== item?.name ? { ...item, name } : item;
  });
}

export function resolveCredits(credits, englishNames, language) {
  if (!credits || typeof credits !== "object") {
    return credits || null;
  }
  return {
    ...credits,
    ...(Array.isArray(credits.cast) ? { cast: resolveCreditEntries(credits.cast, englishNames, language) } : {}),
    ...(Array.isArray(credits.crew) ? { crew: resolveCreditEntries(credits.crew, englishNames, language) } : {})
  };
}

export function toImageUrl(path, kind = "backdrop") {
  if (!path) {
    return null;
  }
  const normalizedPath = String(path);
  if (/^https?:\/\//i.test(normalizedPath)) {
    return normalizedPath;
  }
  const size = TMDB_IMAGE_SIZES[kind] || kind;
  return `https://image.tmdb.org/t/p/${size}${normalizedPath}`;
}

export function normalizeTmdbArtworkLanguage(language = "") {
  const normalized = normalizeTmdbLanguageCode(language);
  const [rawLanguage = "en", rawRegion = ""] = normalized.split("-", 2);
  const languageCode = rawLanguage.toLowerCase() || "en";
  const regionCode = rawRegion.length === 2 ? rawRegion.toUpperCase() : languageCode === "pt" ? "PT" : languageCode === "es" ? "ES" : "";
  return {
    locale: regionCode ? `${languageCode}-${regionCode}` : languageCode,
    languageCode,
    regionCode
  };
}

export function buildTmdbImageLanguageFilter(language = "") {
  const { locale, languageCode } = normalizeTmdbArtworkLanguage(language);
  return [...new Set([languageCode, locale, "en", "null"])].join(",");
}

export function selectBestLocalizedImagePath(images = [], normalizedLanguage = "en") {
  const entries = Array.isArray(images) ? images : [];
  if (!entries.length) {
    return null;
  }

  const languageCode = String(normalizedLanguage || "en")
    .split("-", 1)[0]
    .toLowerCase();
  const explicitRegion = String(normalizedLanguage || "")
    .split("-", 2)[1]
    ?.toUpperCase();
  const regionCode =
    explicitRegion?.length === 2
      ? explicitRegion
      : TMDB_LANGUAGE_DEFAULT_REGIONS[languageCode] || (languageCode === "pt" ? "PT" : languageCode === "es" ? "ES" : "");

  return (
    entries
      .map((image, index) => {
        const imageLanguage = String(image?.iso_639_1 || "").toLowerCase();
        const imageRegion = String(image?.iso_3166_1 || "").toUpperCase();
        const priority =
          imageLanguage === languageCode && imageRegion === regionCode
            ? 5
            : imageLanguage === languageCode && !imageRegion
              ? 4
              : imageLanguage === languageCode
                ? 3
                : imageLanguage === "en"
                  ? 2
                  : !imageLanguage
                    ? 1
                    : 0;
        return { image, index, priority };
      })
      .sort((left, right) => right.priority - left.priority || left.index - right.index)[0]?.image?.file_path || null
  );
}

export function selectBestLocalizedLogoPath(logos = [], language = "") {
  const { languageCode, regionCode } = normalizeTmdbArtworkLanguage(language);
  const ranked = (Array.isArray(logos) ? logos : [])
    .map((logo, index) => {
      const logoLanguage = String(logo?.iso_639_1 || "").toLowerCase();
      const logoRegion = String(logo?.iso_3166_1 || "").toUpperCase();
      let priority = -1;
      if (logoLanguage === languageCode && regionCode && logoRegion === regionCode) {
        priority = 5;
      } else if (logoLanguage === languageCode && !logoRegion) {
        priority = 4;
      } else if (logoLanguage === languageCode) {
        priority = 3;
      } else if (logoLanguage === "en") {
        priority = 2;
      } else if (!logoLanguage) {
        priority = 1;
      }
      return {
        logo,
        index,
        priority,
        voteAverage: Number(logo?.vote_average || 0)
      };
    })
    // Never select artwork explicitly tagged with an unrelated language.
    .filter((entry) => entry.priority >= 0 && entry.logo?.file_path)
    .sort((left, right) => right.priority - left.priority || right.voteAverage - left.voteAverage || left.index - right.index);
  return ranked[0]?.logo?.file_path || null;
}

export function normalizeTmdbTrailerLanguage(language = "") {
  const normalized = String(language || "")
    .trim()
    .replace(/_/g, "-");
  if (!normalized) {
    return TMDB_TRAILER_FALLBACK_LANGUAGE;
  }
  if (normalized.includes("-")) {
    const [locale, region] = normalized.split("-", 2);
    return region ? `${locale.toLowerCase()}-${region.toUpperCase()}` : locale.toLowerCase();
  }
  if (normalized.toLowerCase() === "en") {
    return TMDB_TRAILER_FALLBACK_LANGUAGE;
  }
  return normalized.toLowerCase();
}

export function videoTypePriority(type = "") {
  const normalized = String(type || "")
    .trim()
    .toLowerCase();
  if (normalized === "trailer") return 0;
  if (normalized === "teaser") return 1;
  return 2;
}

export function parsePublishedAtEpoch(value = "") {
  const parsed = Date.parse(String(value || ""));
  return Number.isFinite(parsed) ? parsed : Number.MIN_SAFE_INTEGER;
}

export function rankTmdbVideoCandidates(results = [], preferredLanguageCode = TMDB_TRAILER_FALLBACK_LANGUAGE) {
  const preferredLanguage = String(preferredLanguageCode || TMDB_TRAILER_FALLBACK_LANGUAGE)
    .split("-")[0]
    .trim()
    .toLowerCase();
  const seenKeys = new Set();
  const candidates = (Array.isArray(results) ? results : [])
    .filter((entry) => String(entry?.site || "").toLowerCase() === "youtube")
    .filter((entry) => Boolean(String(entry?.key || "").trim()))
    .filter((entry) => {
      const normalizedType = String(entry?.type || "")
        .trim()
        .toLowerCase();
      return normalizedType === "trailer" || normalizedType === "teaser";
    })
    .filter((entry) => {
      const key = String(entry?.key || "").trim();
      if (seenKeys.has(key)) {
        return false;
      }
      seenKeys.add(key);
      return true;
    });

  const languageRank = (entry) => {
    const language = String(entry?.iso_639_1 || "")
      .trim()
      .toLowerCase();
    if (language === preferredLanguage) {
      return 0;
    }
    if (language === "en") {
      return 1;
    }
    return 2;
  };

  return candidates.sort((left, right) => {
    const typeDiff = videoTypePriority(left?.type) - videoTypePriority(right?.type);
    if (typeDiff !== 0) return typeDiff;
    const languageDiff = languageRank(left) - languageRank(right);
    if (languageDiff !== 0) return languageDiff;
    const officialDiff = Number(Boolean(right?.official)) - Number(Boolean(left?.official));
    if (officialDiff !== 0) return officialDiff;
    const sizeDiff = Number(right?.size || 0) - Number(left?.size || 0);
    if (sizeDiff !== 0) return sizeDiff;
    return parsePublishedAtEpoch(right?.published_at) - parsePublishedAtEpoch(left?.published_at);
  });
}

export async function fetchTmdbVideos({ type, tmdbId, apiKey, language }) {
  const url = `${TMDB_BASE_URL}/${type}/${encodeURIComponent(String(tmdbId))}/videos?api_key=${encodeURIComponent(apiKey)}&language=${encodeURIComponent(language)}`;
  const data = await fetchTmdbJson(url);
  if (!data) {
    return [];
  }
  return Array.isArray(data?.results) ? data.results : [];
}

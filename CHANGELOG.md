# Changelog

All notable changes to Nuvio TV for Roku are listed here. This changelog only covers the Roku channel.

## [2.2.1] - 2026-10-21

### Added
- Two-way Nuvio sync. The channel syncs with your Nuvio account every time it opens, and changes made on the Roku are sent back a few seconds later: addons, My List, Continue Watching progress, settings and home catalog order. Only the settings you change on the Roku are updated in your account.
- Addons are read from your account's addon list for each profile, like Nuvio TV for Smart TVs.
- Home catalog order, hidden catalogs and custom catalog names from your Nuvio account.
- Nuvio collections on the home screen, in the same place as in Nuvio. Opening a folder shows its catalogs.
- Profile pictures from your Nuvio account, on the profile screen and the side menu.
- Your Nuvio theme color is used as the channel accent color.
- Trailer for the focused poster, played in the home hero or in the expanded card, like Nuvio.
- Trakt, Simkl and TMDB work without creating your own apps or keys. You only need to link your Trakt or Simkl account.
- Continue Watching cards like Nuvio: time left badge, episode number, title, episode name and a thin progress bar. Focusing one shows the episode, genre, year and time left at the top.
- Landscape and square catalogs keep their shape instead of being shown as posters.
- Flag emojis in source descriptions are shown as the language name (for example Latino, Castellano or English).
- Skipping in the player speeds up the longer you hold or keep pressing left and right: 10 seconds, then 30 seconds, 1 minute and 2 minutes.

### Changed
- The expanded poster now looks like Nuvio (backdrop with only the logo or title), and the posters after it move to the right instead of being covered.
- Rows keep the focused title on the left edge, like Nuvio.
- The focus border uses your accent color and hugs posters and cards.
- The details page hides while its trailer plays. Any button brings it back.
- Trakt and Simkl no longer ask for a Client ID or Client Secret on the phone page.
- Clearer name and description for the profile color setting.
- The Settings side menu now fits every section.

### Fixed
- Settings did not open.
- Audio and subtitle tracks could not be changed in the player.
- The expanded poster appeared in the top left corner of the screen.
- Dark pixels around the expanded poster and behind poster corners.
- The progress bar stayed at the start on videos where the Roku doesn't report a length.
- The phone setup page could stop responding ("Could not reach the Roku"). It now shows the real error and restarts by itself.
- Emojis that Roku can't show appeared as empty boxes in source descriptions.
- The focus border was cut off on the left side of rows.
- Some checks with missing values could stop the channel on real Roku devices.

## [2.2.0] - 2026-10-21

First public release.

### Added
- English interface, alongside Spanish. Choose it in **Settings → Appearance → Interface language** (Automatic follows your Roku's language). The phone setup page follows the same language.
- Nuvio-style source list: addon filter chips, full addon formatter text, addon logo and resume or start-over chip.
- Built-in source badges for quality, HDR / Dolby Vision, codec, audio and file size.
- Fusion badges, imported from your Nuvio account or from a badge JSON URL on the phone page, shown at the top or bottom of each source.
- Auto-play modes: Manual, First source and Regex match. They use the same regex rules as Nuvio TV, including presets, allowed addons and selection timeout.
- Reuse last link, same source for the next episode and remember each show's source.
- Preferred and secondary audio languages (System, Original or a specific language).
- Preferred and secondary subtitle languages, plus forced subtitles.
- Custom poster URL patterns with Nuvio placeholders (`{id}`, `{imdb_id}`, `{tmdb_id}`, `{type}` and more). The channel falls back to the original poster if the custom one fails to load.
- Focused poster that expands into a landscape card after a delay, with an optional muted trailer.
- Trailers: a trailer button on the details page and optional auto-play. Sources are IMDb first, then the title's own trailers, then YouTube.
- Nuvio account sync for player, auto-play, layout, trailer, TMDB, MDBList and badge settings, plus your MDBList API key.
- **Fuentes** and **Tráilers** sections in Settings.
- Phone page options for the auto-play regex, custom poster pattern, Fusion badges and switching back to the official server.

### Changed
- The Nuvio server address lives in `components/Config.brs`. It is empty in the source code, like the official Nuvio repositories, and filled in the release builds.

### Fixed
- Synced settings with mixed-case names that were sometimes not applied.

## [2.1.0] - 2026-10-20

### Added
- Nuvio account sign-in with QR or email, which pulls profiles, addons, library, Continue Watching and settings.
- TMDB metadata in your language and MDBList ratings.
- Trakt and Simkl scrobbling.
- Preferred audio and subtitle languages.
- Continue Watching in landscape with episode images, configurable to poster.
- Profile picker with a black background tinted by the profile color.
- Nuvio-style Settings screen.

### Changed
- The pause screen now waits longer before it appears.

### Fixed
- Subtitle and audio track detection in the player.
- Switching sources while something was already playing.
- The last home row being cut off.

## [2.0.0] - 2026-10

### Added
- Rebuilt channel with a Nuvio-style interface: side navigation rail, home hero, details page, episodes view, custom player and pause screen.
- Stremio-style addons for catalogs, metadata, streams and subtitles.
- Search across all addons.
- Profiles, My List and Continue Watching.
- Phone setup page to add addons, import collections and manage catalogs and profiles.
- Real Nuvio logos and branding (unofficial fork, used with permission).

### Fixed
- Remote controls and settings that didn't respond.
- The phone page doing nothing when sending addons.
- Empty catalogs.
- Missing sources for titles from TMDB-based catalogs.

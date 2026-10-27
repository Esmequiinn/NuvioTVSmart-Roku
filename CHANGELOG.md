# Changelog

All notable changes to Nuvio TV for Roku are listed here. This changelog only covers the Roku channel.

**English** · [Español](CHANGELOG.es.md)

## [0.0.7] - 2026-10-27

### Added
- New auto-play preset **HDR without Dolby Vision**, for TVs with HDR but no Dolby Vision.
- If your TV doesn't support Dolby Vision, auto-play skips sources that are only Dolby Vision (they show a green or purple picture). Sources marked DV + HDR10 still play. **Settings → About** shows whether your TV supports Dolby Vision.
- **Settings → About** shows your Roku model and video mode, and which formats it supports (HEVC, HDR10, Dolby Vision and 4K).

### Fixed
- Addons whose link has something after `manifest.json` (like `manifest.json?token=...`) showed their catalogs but never returned sources. The channel now keeps that part at the end of every request, like Nuvio on Android and phones. These links can also be added from the phone page now.
- With a light theme color (like Nuvio's White theme), the selected player buttons, source filters and switches turned completely white and their icons disappeared. Icons and text on the highlight now turn dark when the color is light.
- Shows with many seasons couldn't scroll past the seasons that fit on screen. The season tabs now scroll with the focus.
- Single `.ts` video files stayed frozen at 0:00 with a huge length (around 10 hours). The channel now checks what the link really is before playing it, and plays these files through a small playlist made on the Roku, so they can play and seek.
- If a source never starts playing, the channel now tries the next way to open it after 20 seconds, and shows an error at the end instead of staying frozen.

## [0.0.6] - 2026-10-26

### Added
- **Discover**, like Nuvio TV: browse any catalog from your addons by type, catalog and genre, and more titles load as you scroll down. By default it's a button under the keyboard in Search. In **Settings → Layout → Discover location** you can move it to its own spot in the side menu or turn it off. This setting syncs with your Nuvio account.
- **Recent searches** in Search, like Nuvio TV. Your last 8 searches show up when the search box is empty. Select one to search again, use the X next to it to remove it, or use **Clear history**. Each profile has its own history.
- **MDBList account**, like Nuvio: in **Settings → Integrations → MDBList account**, scan the QR code with your phone and approve. Ratings and MDBList lists then work with your account, without typing a key.

### Changed
- The trailer that plays on the home screen after a few seconds on a title now fills the whole screen, like Nuvio TV on Android. The rows, the side menu and the description fade out and only the title logo stays. Press any button to stop it and go back to the rows.

### Fixed
- MDBList ratings were downloaded but never shown. They now appear on the details page under the title info, with each site's icon, like Nuvio.
- The MDBList key from your Nuvio account (and the MDBList account) was saved but read back as empty, so the channel always said it was missing. This could also affect other settings synced from your account.

## [0.0.5] - 2026-10-25

### Added
- Interface in French, German, Italian, Dutch, Polish, Turkish, Romanian, Czech and Hungarian. Choose it in **Settings → Appearance → Interface language**, or leave it on Automatic to use your Roku's language. The texts reuse the Nuvio TV translations wherever the wording is the same.
- New version notice, like Nuvio on Smart TVs. When a new release is out on GitHub, the channel shows what's new once, with a small QR code to download it. The notes appear in Spanish or English depending on your Roku, and other languages get an automatic translation.

### Changed
- The home screen shows up sooner, especially the first time or after reinstalling the channel. If one catalog is slow, the rest appear after a few seconds instead of waiting for it, and the slow one is added when it arrives.
- Titles in other alphabets (like Japanese or Chinese) are translated after the rows appear, so they no longer hold up the whole home screen.
- With a language other than Spanish or Portuguese, the phone setup page opens in English.

### Fixed
- Catalogs that answered while the channel was busy could be marked as "took too long" and stay empty.
- The movie length on the details page said "min left" in English.

## [0.0.4] - 2026-10-25

### Added
- Skip intro, recap and credits. A **Skip** button appears during those parts, and each one can also be skipped automatically (**Settings → Playback → Skip segments**). Uses introdb.app, and AniSkip for anime.
- Next episode card near the end of an episode, with a countdown when auto-play is on. It appears when the credits start if they are known, or at the percentage or minutes before the end that you choose.
- Preload the next episode's sources before the card appears.
- Option to use the first available source when the next episode doesn't have the same source group, or to show the list instead.
- **Are you still watching?** on the full screen after several episodes in a row, with Yes and No.
- Recommendations near the end of a movie or the last episode (needs TMDB). Select one to open its details.
- Content warnings (nudity, violence, profanity, drugs and frightening scenes) for a few seconds when a title starts.
- Hide SDH subtitles and show only your preferred subtitle languages.
- Subtitle style for addon subtitles: size, color, background, edge, bold and height. Subtitles inside the video keep the Roku style from **Settings → Accessibility → Captions style**.
- Playback stats overlay with resolution, codec, audio and bitrate (**Settings → Advanced**).
- All these settings sync with your Nuvio account.
- **Next up** in Continue Watching: when you finish an episode, the next one appears in the row so you can keep going.

### Fixed
- Settings from your Nuvio TV account now really come to the Roku (trailer on idle, custom poster, regex, secondary audio language, reuse last link and the rest). Nuvio stores each value with its type, and the Roku was ignoring them. Changes made on the Roku are also sent back in the format Nuvio TV reads. Subtitle style, addon name and type suffix on catalogs are also synced now.
- Posters, episodes, cast photos and profile pictures rounded on one side only on HD Rokus. If it still happens, **Settings → Advanced → Rounded corners** has other options.
- The channel no longer freezes when you switch to another profile.
- Search no longer turns the focused poster into a wide card after a few seconds.
- If something fails inside the player, the channel shows the error instead of closing.
- You can type your TMDB and MDBList keys on the TV in **Settings → Integrations**, and saving keys from the phone page no longer fails with "Couldn't connect to the Roku".
- One more way to open .ts links on Rokus that couldn't play them.
- Posters and the wide focused card no longer show square corners outside the focus frame on HD Rokus.
- The title logo at the top of the home screen loads faster and only once, in your language. The channel asks TMDB only for the logo first, without waiting for the rest of the details, and remembers logos it already found.
- The MDBList key comes from the Nuvio profile you're using. Before, the sync went through all your profiles and the last one, without a key, erased it. The channel also syncs again when you switch profiles. A key you typed on the TV or the phone page stays.
- Your TMDB key also comes from the Nuvio profile you're using, like the MDBList key. **Settings → Integrations** shows what the channel found in your account the last time it checked.
- Keys typed on the TV keyboard are read correctly on newer Roku OS versions, and every setting is also saved in the channel's files in case the Roku storage is full.
- Trailers prefer your TMDB region and try a second way to open YouTube trailers before falling back to English.
- The Roku keeps only small settings in its own storage, which has a 16 KB limit. Your library and Continue Watching filled it up, so new changes (like an MDBList key typed on the TV) weren't being saved. They now live in the channel's files.
- Home rows update in place when catalogs finish loading, instead of disappearing and loading again.
- The channel icon and splash screen have the right size on HD Rokus.
- A key you type on the TV is no longer replaced by your Nuvio account sync.
- Auto-play checks what your Roku can play and never picks sources it can't (HEVC / x265 on models without HEVC, 4K when the Roku or TV isn't in 4K), even when they match your regex. If none of the sources can play, it shows the list. When one of those fails, the error says why. You can turn this off in **Settings → Playback → Prefer Roku-compatible sources**.
- **Settings → About** shows the Roku model, video mode, whether it plays HEVC and the free storage space.
- Trakt lists in collections failed with "Trakt (403)" because the list number wasn't sent. TMDB collections, companies, networks and people saved with a numeric ID also loaded the wrong titles. Both now work, and Trakt lists in a folder load at the same time instead of one by one.
- The channel saved home posters in the background while you browsed, which slowed down everything else (collections, cast photos) and sometimes made posters stop loading. It now waits until the home screen is ready, downloads less at once and stops as soon as you open something.
- Playing a source again after leaving it no longer fails with "the connection dropped". If the link can't resume where you left off, the channel tries again with another method, and if that fails too it starts from the beginning instead of showing an error.

- The channel no longer freezes when you go back to the home screen after opening Settings.
- IPTV and other links without a file extension play again. Since 0.0.3 the channel gave the Roku a list of formats to try, and the Roku rejected it, so the screen stayed black until "the connection dropped". The Roku now detects the format by itself first, like in 0.0.2.

### Changed
- The README explains which codecs some Roku models can't play.
- The README explains how to keep the Roku in 4K with **Settings → Display type → Auto detect**.
- The README and this changelog are also available in Spanish.

### Known issues
- The MDBList key from your Nuvio account still doesn't reach the Roku for some accounts. **Settings → Integrations** shows what the channel found in your account, to help find the cause.

## [0.0.3] - 2026-10-24

### Added
- Nuvio sign-in screen the first time you open the channel, with a QR code like the other Nuvio apps. You can also continue without an account and add addons from your phone or from Settings on the TV.
- Portuguese interface and phone setup page. Choose it in **Settings → Appearance → Interface language**.
- Press `*` on Continue Watching for the Nuvio TV options: go to details, play manually, start from the beginning or remove it. Removed items are also removed from your Nuvio account.
- Press `*` on any poster to go to details, add it to or remove it from your library, or mark it as watched or unwatched. Watched titles show a check mark, synced with Nuvio.
- Details page like Nuvio: season tabs, episode cards with description, date, length and preview image in your metadata language, cast with photos and the director or creators.
- Nuvio-style Settings, account QR, Trakt and Simkl codes, Watch Party panel and join screen.
- Your active Nuvio collections are listed in **Settings → Content and discovery**, where you can turn each one on or off.
- Collection folders with TMDB (lists, collections, people, companies, networks and discover) and Trakt list sources, not only addon catalogs.
- All TMDB languages from Nuvio TV, and full language lists for audio and subtitles.
- **Prefer Roku-compatible sources** in Settings → Playback: auto-play leaves REMUX files with TrueHD or DTS-HD audio, and 4K when your TV is not in 4K mode, for last.
- The player lists every audio track the Roku reports, even repeated languages, with the track name and format.
- Addon subtitles that arrive after playback starts can be picked from the subtitles menu.
- Version shown on the Roku as 0.0.3 beta.
- Select an actor on the details page to see their movies and series (needs TMDB).
- Press `*` on the Play button of the details page to choose the source manually.
- Loading screen like Nuvio while a source opens: the title's backdrop with its logo in the middle.
- Source list like Nuvio: a refresh button and one filter per addon that you can select, scrolling sideways when there are many.
- Collection folders show their GIF while focused, like Nuvio (needs a Roku that supports animated images; GIFs are converted to animated WebP), and their title logo and hero video in the home banner.
- When a collection folder can't load a source, the channel says which one and why (for example a Trakt error code or an addon that isn't installed).
- Titles in Chinese, Japanese, Korean and other scripts the Roku can't draw are shown with their TMDB name in your metadata language, or in English.
- On Xtream live channels that play through HLS with a single audio track, the audio menu offers to load all audio tracks from the original `.ts` link. If the Roku can't open it, it goes back to the version that works.
- The interface language is chosen from a list, and the notice to reopen the channel is shown in the language you picked.

### Changed
- Home opens right away with the last loaded rows and refreshes them in the background, and catalogs are loaded in parallel. The "addons loaded" messages are gone.
- Continue Watching plays directly with the last source you used instead of opening the details page. If that link expired, it looks for sources again.
- Option menus, audio, subtitle and source menus use the Nuvio TV dialog style.
- Posters and cards have rounder corners, matching Nuvio, and the focus border follows them.
- Trailers look for a trailer in your metadata language first.
- Only the settings you change on the Roku, and that already exist in your Nuvio account, are sent to your account. Home catalogs that only exist on the Roku are no longer added to your account.
- Continue Watching from your account shows one entry per show (the latest episode) and keeps local progress that hasn't been sent yet.
- Collection tiles only show the folder name when the collection says so.
- The library no longer shows Continue Watching, and its posters don't expand or play trailers.
- The focused source is only highlighted, without the outer border, and the highlight moves with the list instead of appearing late.
- Emojis are removed from every title, name and description, not only in sources.
- Round images, icons, switches and player buttons are drawn at their exact size, so they look sharper.
- Home posters are saved on the Roku after they load, so they don't load again when you scroll back.

### Fixed
- Watch Party ended when you paused, and other devices didn't follow the Roku. The Roku now sends its state to the room right away and only leaves when the room really ends.
- Resuming from Continue Watching started from the beginning on some sources.
- Seeking far ahead jumped back to the old position.
- Some sources closed the player without an error, and Continue Watching progress could disappear because of it. The channel now retries the link in other formats before showing an error.
- Changing the audio track sometimes reverted to the original track.
- Switching sources from the player sometimes did nothing or closed the player.
- Subtitles from addons only loaded sometimes.
- Xtream IPTV live channels (`.ts`) didn't play. The channel now tries the HLS version of the link.
- Movie logos didn't show on the player and pause screen when a title was played again.
- Adding a title to My List from a landscape row saved the landscape image instead of the poster.
- Collections showed the folder name over the cover even when it was hidden in the collection.
- The MDBList key was not brought from your Nuvio account on some profiles.
- The Trakt and MDBList cards on the phone setup page were broken.
- Only the first source in the list could be selected with OK.
- `*` on Continue Watching opened Settings.
- After opening the audio, subtitles or sources menu in the player, the remote stopped responding until the channel was closed.
- Home catalogs that took too long disappeared a few seconds after loading. They now keep their last loaded titles.
- The focus border on posters, cards and episodes was cut at the top and its corners didn't match. It now sits inside the card.
- Trailers and backdrops in the expanded card had square corners.
- The focus border in the source list appeared late and could stay on several sources at once. The last source was cut off.
- On/off switches and buttons looked cut at the edges.
- Emojis in collection and catalog names showed as empty boxes.
- My List saved the landscape image for a moment before switching to the poster.
- Live channels appeared in Continue Watching.
- Back on the profile screen opened from the app returns to your profile instead of closing the channel.
- The channel froze after removing the last title from My List.
- Saving the TMDB or MDBList key from the phone page sometimes said it couldn't connect to the Roku.
- Collection folders with list ids stored as decimal numbers didn't load.
- Collection logos and images linked from GitHub pages (`github.com/.../blob/...?raw=true`) didn't show.
- TMDB collection sources with a maximum rating of 0 returned no titles.
- The About section still said version 2.2.0.
- Trakt lists in collections now retry with your Trakt account and with both movies and shows when the first request comes back empty.


## [0.0.2] - 2026-10-21

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

## [0.0.1] - 2026-10-21

First public release (first beta).

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

## Internal builds before 0.0.1

### 2026-10-20

#### Added
- Nuvio account sign-in with QR or email, which pulls profiles, addons, library, Continue Watching and settings.
- TMDB metadata in your language and MDBList ratings.
- Trakt and Simkl scrobbling.
- Preferred audio and subtitle languages.
- Continue Watching in landscape with episode images, configurable to poster.
- Profile picker with a black background tinted by the profile color.
- Nuvio-style Settings screen.

#### Changed
- The pause screen now waits longer before it appears.

#### Fixed
- Subtitle and audio track detection in the player.
- Switching sources while something was already playing.
- The last home row being cut off.

### 2026-10

#### Added
- Rebuilt channel with a Nuvio-style interface: side navigation rail, home hero, details page, episodes view, custom player and pause screen.
- Stremio-style addons for catalogs, metadata, streams and subtitles.
- Search across all addons.
- Profiles, My List and Continue Watching.
- Phone setup page to add addons, import collections and manage catalogs and profiles.
- Real Nuvio logos and branding (unofficial fork, used with permission).

#### Fixed
- Remote controls and settings that didn't respond.
- The phone page doing nothing when sending addons.
- Empty catalogs.
- Missing sources for titles from TMDB-based catalogs.

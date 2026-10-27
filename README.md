# Nuvio TV for Roku

**English** · [Español](README.es.md)

<div align="center">

  <img src="assets/brand/app_logo_wordmark.png" alt="Nuvio" width="300" />

  <p>
    A free, open-source media app for your phone, your desktop, and the TV you already own.
    <br />
    Bring your own sources. Nuvio turns them into a library with artwork, ratings, subtitles, and your place saved on every screen.
  </p>

  [Website](https://nuvio.tv) · [GitHub releases](https://github.com/NuvioMedia/NuvioTVSmart/releases/latest) · [Support Nuvio](https://nuvio.tv/support)

</div>

This is an unofficial Roku channel based on [Nuvio](https://github.com/NuvioMedia). It is in **beta**: the current version is **0.0.6**. It lets you browse and play content from Stremio-style addons on any Roku TV or streaming stick.

> **This is not an official Nuvio app** and it is not affiliated with or endorsed by the Nuvio team. It does not host, store or distribute any content. Everything you see comes from the addons you install.

> **AI was madly used on this, so any thoughts you have about that, keep them to yourself I just wanted to have nuvio on my sh!ty Roku.**

---

## Features

- Stremio-style addons: catalogs, metadata, streams and subtitles
- Nuvio-style interface: side navigation rail, home hero, profile picker, details page, episodes view and pause screen
- Custom player with source switching, audio tracks and subtitles
- Skip intro, recap and credits (introdb.app, and AniSkip for anime), with optional auto-skip
- Next episode card with countdown, next episode preloading and **Are you still watching?** on the full screen
- Recommendations at the end of a movie and content warnings when a title starts
- Subtitle style for addon subtitles, SDH filtering and preferred-languages-only subtitles
- Playback stats overlay
- **Next up** in Continue Watching after you finish an episode
- Search across all your addons, with recent searches
- Discover: browse any addon catalog by type, catalog and genre, from Search or its own spot in the side menu
- Profiles, with shared or per-profile addons
- My List and Continue Watching
- Phone setup page: add addons, import collections, manage catalogs and settings from your phone's browser
- Nuvio-style sign-in screen the first time you open the channel, or continue without an account and add addons from your phone or the TV
- Nuvio account sign-in (QR or email) with two-way sync of profiles, addons, library, progress, settings and home catalogs
- Nuvio collections (addon, TMDB and Trakt sources), profile pictures and theme color from your account
- Watch Party with your Nuvio account
- Nuvio TV options with the `*` button: go to details, play manually, start from the beginning or remove from Continue Watching, and add to library or mark as watched on any poster
- Details page like Nuvio: episodes with descriptions and preview images in your metadata language, ratings, cast and crew
- TMDB metadata in your language and MDBList ratings
- Trakt and Simkl scrobbling, just link your account
- Works with debrid services through your addons (for example AIOStreams)
- Auto-play: first source, manual or regex match, compatible with your Nuvio TV regex patterns
- Nuvio-style source list with full formatter text, quality badges and Fusion badges
- Custom poster URL patterns (RPDB-style placeholders)
- Trailers from IMDb and YouTube, on the details page, the home hero or the expanded card
- Focused poster that expands into a landscape card
- Landscape and square catalogs
- Interface in Spanish, English, Portuguese, French, German, Italian, Dutch, Polish, Turkish, Romanian, Czech and Hungarian
- Fast home: the last home screen opens right away while catalogs refresh in the background
- New version notice with what's new and a QR code to download it
- Full-screen trailer on the home screen after a few seconds on a title, like Nuvio TV on Android

## Status

Some features haven't been tried yet. If you test any of the **Not tested yet** items, please open an issue and tell us how it went.

| Feature | Status |
| --- | --- |
| HTTP stream addons (direct `http`/`https` links) | ✅ Working |
| Catalog addons | ✅ Working |
| Metadata addons | ✅ Working |
| Metadata language | ✅ Working |
| Source player (playback and switching sources) | ✅ Working |
| Search | ✅ Working |
| My List | ✅ Working |
| Home hero | ✅ Working |
| Side navigation rail | ✅ Working |
| Episodes view | ✅ Working |
| Phone setup page (add addons from your phone) | ✅ Working |
| Settings screen | ✅ Working |
| Debrid services (through addons like AIOStreams) | ✅ Working |
| Switching audio and subtitle tracks | ✅ Working |
| Trailers | ✅ Working |
| Expanding focused poster | ✅ Working |
| TMDB integration | ✅ Working |
| MDBList integration | ✅ Working |
| Trakt | ⚠️ Not tested yet |
| Simkl | ⚠️ Not tested yet |
| Nuvio account sign-in and sync | ✅ Working |
| Sources with addon formatter text | ✅ Working but with no emojis |
| Badges (quality, HDR, codec, audio, size and Fusion) | ✅ Working |
| Continue Watching in landscape | ✅ Working |
| Collections import | ✅ Working |
| Nuvio collections | ✅ Working |
| Sync from the Roku to your Nuvio account | ✅ Working  |
| Profile pictures and theme color from Nuvio | ✅ Working |
| Landscape and square catalogs | ✅ Working |
| Auto-play (first source and regex pattern) | ✅ Working |
| Reuse last link and same source for next episode | ✅ Working |
| Preferred and secondary audio and subtitle languages | ✅ Working |
| Custom poster URL patterns | ⚠️ Not tested yet |
| English interface | ✅ Working |
| Portuguese interface | ✅ Working |
| French, German, Italian, Dutch, Polish, Turkish, Romanian, Czech and Hungarian interface | ⚠️ Not tested yet |
| New version notice | ⚠️ Not tested yet |
| Discover | ✅ Working |
| Recent searches | ⚠️ Not tested yet |
| Full-screen home trailer | ✅ Working |
| MDBList account (QR) | ⚠️ Not tested yet |
| Watch Party | ✅ Working |
| `*` options menu and removing Continue Watching items | ✅ Working |
| Collections with TMDB and Trakt sources | ⚠️ Not tested yet |
| Next episode card | ✅ Working |
| Are you still watching? | ✅ Working |
| Recommendations at the end of a movie | ✅ Working |
| Content warnings | ✅ Working |
| Skip intro, recap and credits | ✅ Working |
| Subtitle style and SDH filtering | ⚠️ Not tested yet |
| Playback stats | ⚠️ Not tested yet |
| Next up in Continue Watching | ⚠️ Not tested yet |
| MDBList key from your Nuvio account | ✅ Working |

### Known limitations

- Roku can only play direct links. Torrent, magnet and external links are skipped.
- Playable formats depend on your Roku model (MP4, MKV, HLS and DASH are the usual ones).
- Some Roku models, like the Roku Express, can't decode some video codecs, such as HEVC (x265), 10-bit or HDR. The channel checks what your Roku can play, and auto-play never picks those sources, even if they match your regex. If you pick one yourself it may fail with "the connection dropped" or a codec error. **Settings → About** in the channel shows your Roku model and whether it can play HEVC.
- On 720p TVs the Roku scales the interface down, so focus frames and buttons look less sharp than on 1080p or 4K TVs.
- Roku can't decode TrueHD or DTS-HD audio, which most REMUX files use. Those audio tracks don't show up in the player. The channel prefers other sources for auto-play.
- 4K (HEVC above 1080p) only plays when your Roku and your TV are in 4K mode. Channels can't change the display mode, so set it on your Roku in **Settings → Display type → Auto detect** (in Spanish: **Ajustes → Tipo de pantalla → Detectar automáticamente**). If your TV supports 4K, the Roku will stay in 4K.
- Animated GIFs in collections only move on Roku models that support animated images. Older models show the cover image.
- Profiles created on the Roku and collection edits are not sent to your Nuvio account. Collections can only be viewed.
- Roku can't show emojis. Flag emojis in source descriptions are shown as the language name and other emojis are removed.
- Watch Party checks the room every 2.5 seconds and sends play, pause and seek changes right away, so playback can be 1 or 2 seconds apart from other people.
- Nuvio plugins are not available, because they need JavaScript and Roku can't run it.

## Install

The channel is installed with Roku's Developer Mode (sideloading). You only need to enable it once.

1. **Download the channel.** Get the latest `.zip` from the [Releases](../../releases) page. Don't unzip it.
2. **Enable Developer Mode.** With your Roku remote, press: `Home` ×3, `Up` ×2, `Right`, `Left`, `Right`, `Left`, `Right`. Accept the agreement, choose a password and let the Roku restart. Write down the IP address it shows (for example `192.168.1.50`).
3. **Open the installer.** On a computer or phone on the same Wi-Fi, open `http://YOUR_ROKU_IP` in a browser. Sign in with the user `rokudev` and the password you chose.
4. **Upload the zip.** Click **Upload**, pick the `.zip` you downloaded and click **Install with zip**. The channel opens by itself when it's done.
5. **Updating.** Repeat steps 3 and 4 with the new `.zip`. Your profiles and addons are kept.

Only one sideloaded channel can be installed at a time. It shows up on your Roku home screen as **Nuvio TV**.

## Setup

When the channel is open, go to `http://YOUR_ROKU_IP:8888` on a phone or computer on the same Wi-Fi. From there you can:

- Add addons (paste the `manifest.json` address) or import a collection
- Show, hide and reorder home rows
- Create profiles
- Sign in to your Nuvio account
- Paste your own TMDB or MDBList key (optional)
- Set the auto-play regex, custom poster pattern and Fusion badges

You can also add an addon from your computer with Roku's External Control: `curl -d "" "http://YOUR_ROKU_IP:8060/launch/dev?addon_url=ADDON_MANIFEST_URL"`

### API keys and accounts

The release `.zip` already includes the TMDB, Trakt and Simkl keys, so you don't need to create anything:

| Service | What you need to do |
| --- | --- |
| TMDB | Nothing. You can still paste your own key on the phone page (Account) if you want. |
| MDBList | Connect your account with the QR code in **Settings → Integrations → MDBList account**, or use your free key from [mdblist.com](https://mdblist.com): paste it on the phone page (Account), type it on the Roku in **Settings → Integrations**, or it comes in automatically if it's saved in your Nuvio account. |
| Trakt | Link your account on the Roku in **Settings → Tracking** and enter the code. |
| Simkl | Link your account on the Roku in **Settings → Tracking** and enter the code. |

### Nuvio account

Sign in from **Settings → Account** on the Roku (QR code) or from the phone page (email and password). The Roku brings your profiles, profile pictures, addons, library, Continue Watching, collections, home catalogs and your Nuvio TV settings (audio and subtitle languages, auto-play rules, badges, custom posters, trailers, theme color and more). It syncs every time the channel opens, and changes you make on the Roku are sent back to your account a few seconds later.

You can also connect to a [self-hosted Nuvio server](https://github.com/NuvioMedia/self-host) from the phone page (**Account → Your own server**).

## Building from source

The channel is plain BrightScript and SceneGraph, so there is nothing to compile. Zip these files and folders from the repository root and sideload the result:

```
zip -r NuvioTV-Roku.zip manifest source components images web locale LICENSE
```

### Translations

Interface text is written in Spanish in the code and translated through the files in `locale/` (`en.json`, `pt.json`, `fr.json`, `de.json`, `it.json`, `nl.json`, `pl.json`, `tr.json`, `ro.json`, `cs.json` and `hu.json`). The new languages reuse the Nuvio TV translations where the text is the same, and the rest was translated for this channel, so some phrases may sound off. Languages with other alphabets (like Russian, Greek, Arabic, Chinese or Japanese) aren't included because the Roku system font may not show them. Pull requests that add or improve translations are welcome.

## Contributing

Bug reports, problems, ideas and feature requests are all very welcome. Open an issue and include your Roku model and OS version (**Settings → System → About**).

**New testers are very welcome too!** If you have a Roku and some time, try the features marked **Not tested yet** and tell me what works and what doesn't.

## Credits and license

- Based on [Nuvio](https://github.com/NuvioMedia) by the Nuvio team. Nuvio name and logos belong to their owners.
- Licensed under the [GNU General Public License v3.0](LICENSE).

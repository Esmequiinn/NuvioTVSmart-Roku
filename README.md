# Nuvio TV for Roku

<div align="center">

  <img src="assets/brand/app_logo_wordmark.png" alt="Nuvio" width="300" />

  <p>
    A free, open-source media app for your phone, your desktop, and the TV you already own.
    <br />
    Bring your own sources. Nuvio turns them into a library with artwork, ratings, subtitles, and your place saved on every screen.
  </p>

  [Website](https://nuvio.tv) · [GitHub releases](https://github.com/NuvioMedia/NuvioTVSmart/releases/latest) · [Support Nuvio](https://nuvio.tv/support)

</div>

This is an unofficial Roku channel based on [Nuvio](https://github.com/NuvioMedia). It lets you browse and play content from Stremio-style addons on any Roku TV or streaming stick.

> **This is not an official Nuvio app** and it is not affiliated with or endorsed by the Nuvio team. It does not host, store or distribute any content. Everything you see comes from the addons you install.

> **AI was madly used on this, so any thoughts you have about that, keep them to yourself I just wanted to have nuvio on my sh@ty Roku.**

---

## Features

- Stremio-style addons: catalogs, metadata, streams and subtitles
- Nuvio-style interface: side navigation rail, home hero, profile picker, details page, episodes view and pause screen
- Custom player with source switching, audio tracks and subtitles
- Search across all your addons
- Profiles, with shared or per-profile addons
- My List and Continue Watching
- Phone setup page: add addons, import collections, manage catalogs and settings from your phone's browser
- Nuvio account sign-in (QR or email) to bring your profiles, addons, library, progress and settings
- TMDB metadata in your language and MDBList ratings
- Trakt and Simkl scrobbling
- Auto-play: first source, manual or regex match, compatible with your Nuvio TV regex patterns
- Nuvio-style source list with full formatter text, quality badges and Fusion badges
- Custom poster URL patterns (RPDB-style placeholders)
- Trailers from IMDb and YouTube
- Focused poster that expands into a landscape card
- English and Spanish interface

## Status

So far the channel has only been tested on a real Roku by me, so some features haven't been tried yet. If you test any of the **Not tested yet** items, please open an issue and tell us how it went.

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
| TMDB integration | ⚠️ Not tested yet |
| MDBList integration | ⚠️ Not tested yet |
| Trakt | ⚠️ Not tested yet |
| Simkl | ⚠️ Not tested yet |
| Nuvio account sign-in and sync | ⚠️ Not tested yet |
| Sources with addon formatter text | ⚠️ Not tested yet |
| Badges (quality, HDR, codec, audio, size and Fusion) | ⚠️ Not tested yet |
| Continue Watching in landscape | ⚠️ Not tested yet |
| Collections import | ⚠️ Not tested yet |
| Auto-play (first source and regex pattern) | ⚠️ Not tested yet |
| Reuse last link and same source for next episode | ⚠️ Not tested yet |
| Preferred and secondary audio and subtitle languages | ⚠️ Not tested yet |
| Custom poster URL patterns | ⚠️ Not tested yet |
| Expanding focused poster | ⚠️ Not tested yet |
| Trailers | ⚠️ Not tested yet |
| English interface | ⚠️ Not tested yet |

### Known limitations

- Roku can only play direct links. Torrent, magnet and external links are skipped.
- Playable formats depend on your Roku model (MP4, MKV, HLS and DASH are the usual ones).
- Account sync only pulls from your Nuvio account. Changes made on the Roku are not sent back.
- Watch Party is not available.

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
- Paste your own API keys
- Set the auto-play regex, custom poster pattern and Fusion badges

You can also add an addon from your computer with Roku's External Control: `curl -d "" "http://YOUR_ROKU_IP:8060/launch/dev?addon_url=ADDON_MANIFEST_URL"`

### Your own API keys

The channel doesn't ship with any API keys. Each person uses their own:

| Service | What you need | Where |
| --- | --- | --- |
| TMDB | Free API key (v3) from [themoviedb.org](https://www.themoviedb.org/settings/api) | Phone page → Account |
| MDBList | Free API key from [mdblist.com](https://mdblist.com) | Phone page → Account, or it comes in automatically if it's saved in your Nuvio account |
| Trakt | Create an app at [trakt.tv/oauth/applications](https://trakt.tv/oauth/applications) with the redirect URI `urn:ietf:wg:oauth:2.0:oob`, then paste its Client ID and Client Secret | Phone page → Account, then connect on the Roku in Settings → Tracking |
| Simkl | Create an app at [simkl.com/settings/developer](https://simkl.com/settings/developer) and paste its Client ID | Phone page → Account, then connect on the Roku in Settings → Tracking |

### Nuvio account

Sign in from **Settings → Account** on the Roku (QR code) or from the phone page (email and password). The Roku pulls your profiles, addons, library, Continue Watching and your Nuvio TV settings (audio and subtitle languages, auto-play rules, badges, custom posters, trailers and more).

You can also connect to a [self-hosted Nuvio server](https://github.com/NuvioMedia/self-host) from the phone page (**Account → Your own server**).

## Building from source

The channel is plain BrightScript and SceneGraph, so there is nothing to compile. Zip these files and folders from the repository root and sideload the result:

```
zip -r NuvioTV-Roku.zip manifest source components images web locale LICENSE
```

### Translations

Interface text is written in Spanish in the code and translated through `locale/en.json`. Pull requests that add or improve translations are welcome.

## Contributing

Bug reports, problems, ideas and feature requests are all very welcome. Open an issue and include your Roku model and OS version (**Settings → System → About**).

**New testers are very welcome too!** If you have a Roku and some time, try the features marked **Not tested yet** and tell us what works and what doesn't.

## Credits and license

- Based on [Nuvio](https://github.com/NuvioMedia) by the Nuvio team. Nuvio name and logos belong to their owners.
- Licensed under the [GNU General Public License v3.0](LICENSE).

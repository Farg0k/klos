# Changelog

Notable changes in each klos release. The newest version is on top.

The app shows the section of the release it downloads, so the entries here are
what the user reads under **What's new** in «About the app».

## 1.0.3

- Release notes in «About the app» are shown as a readable list instead of raw
  Markdown, and no longer include GitHub's bare compare link.
- Every release now carries a real changelog, taken from `CHANGELOG.md`.

## 1.0.2

- klos checks GitHub Releases by itself when it starts, without waiting for the
  user to open «About the app».
- A newer release is announced on the home screen; tapping the card opens the
  release notes and the install button.
- The card can be closed and stays hidden until the next launch.
- A failed check never blocks the app and keeps the home screen clean, so the
  local server keeps working without the network.

## 1.0.1

- Update check in **Settings → About the app**: it compares the installed
  version with the newest GitHub release and offers to download it.
- The APK is chosen for the phone's ABI — `arm64-v8a`, `armeabi-v7a`,
  `x86_64` or the universal build — so the download is as small as possible.
- The downloaded APK installs over the current version and keeps the settings,
  the favorites and the chosen folder.

## 1.0.0

- First release: a local OPDS server that lets a Kindle download books from the
  phone over Wi-Fi.
- Two independent book sources: an OPDS catalog and a folder on the phone.
- EPUB and FB2 are converted to MOBI on the phone, ZIP archives are unpacked
  automatically.
- Books can be sent to the Kindle by email, through SMTP or the phone's mail
  app.
- English and Ukrainian interface, light and dark theme, PIN protection.
- Release builds are signed with a permanent key, so later versions install
  over the current one.

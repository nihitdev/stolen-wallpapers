# Kairo Wallpapers

A large curated wallpaper collection for **Kairo**, **Hyprland**, and Linux desktops.

This repository provides the wallpaper library used by Kairo Shell and the wider Kairo desktop environment.

## About

Kairo Wallpapers is a curated collection of wallpapers collected from various sources across the internet and organized for use with Kairo.

The repository is designed to work directly with the Kairo Shell installer while remaining completely usable on its own.

The collection includes wallpapers suitable for:

- Minimal desktops
- Dark themes
- AMOLED setups
- Nature
- Landscapes
- Anime
- Abstract art
- Architecture
- Space
- Cars
- Cyberpunk
- Retro themes
- Monochrome desktops
- Colorful setups
- Hyprland rice setups

The collection may grow and change over time as wallpapers are added, reorganized, or removed.

---

## Kairo Integration

Kairo Shell can automatically download wallpapers from this repository during installation.

The wallpaper repository used by Kairo is:

```text
https://github.com/nihitdev/kairo-wallpapers
```

Kairo Shell installs wallpapers into the user's configured Pictures directory.

Typically:

```text
~/Pictures/Wallpapers
```

If the user's XDG Pictures directory is configured elsewhere, Kairo uses that location instead.

---

## Installation

### Clone the complete collection

```bash
git clone --depth 1 https://github.com/nihitdev/kairo-wallpapers.git
```

Then copy whichever wallpapers you want into:

```text
~/Pictures/Wallpapers
```

### Clone directly into your wallpaper directory

```bash
git clone --depth 1 \
  https://github.com/nihitdev/kairo-wallpapers.git \
  ~/Pictures/Wallpapers
```

Because the repository is large, downloading it may take some time depending on your connection.

---

## Using with Kairo Shell

You normally do not need to clone this repository manually when using Kairo Shell.

The Kairo installer can download wallpapers automatically.

Kairo Shell:

```text
https://github.com/nihitdev/kairo-shell
```

The installer maintains its own cached clone at approximately:

```text
~/.cache/kairo-wallpapers
```

and copies selected wallpapers into the user's wallpaper directory.

---

## Using with Hyprland

These wallpapers can be used with any wallpaper daemon or tool.

Examples include:

```text
hyprpaper
swww
mpvpaper
waypaper
```

Kairo itself handles wallpaper selection through the Kairo Shell wallpaper interface.

---

## Repository Size

This is intentionally a large wallpaper collection.

The repository may exceed **1 GB** as the collection grows.

If you only want a few wallpapers, using Kairo Shell's wallpaper installer or downloading individual files from GitHub may be preferable to cloning the entire repository.

---

## Structure

The repository may contain wallpapers directly or inside an `images/` directory.

Kairo Shell supports both layouts.

A typical structure is:

```text
kairo-wallpapers/
├── images/
│   ├── wallpaper-01.jpg
│   ├── wallpaper-02.png
│   ├── wallpaper-03.webp
│   └── ...
├── README.md
└── LICENSE
```

Supported image formats include:

```text
.jpg
.jpeg
.png
.webp
.gif
```

---

## Contributions

Wallpaper contributions are welcome.

When contributing a wallpaper:

- Prefer high-resolution images
- Avoid unnecessary duplicates
- Avoid heavily compressed images
- Keep filenames reasonably descriptive
- Include attribution when the original creator is known
- Do not intentionally submit copyrighted commercial artwork when redistribution is prohibited

Pull requests that improve organization or attribution are also welcome.

---

## Attribution

This repository is a **curated collection**.

Unless explicitly stated otherwise, the wallpapers in this repository were not created by the Kairo project or by @nihitdev.

Copyright remains with the respective artists, photographers, designers, and original rights holders.

Where reliable attribution information is known, it should be preserved or added.

If you are the creator or copyright holder of an image included here and want:

- attribution added,
- attribution corrected,
- or your work removed,

please open an issue on this repository.

Removal requests from verified creators or rights holders will be respected.

---

## License

The Kairo project branding, documentation, scripts, and repository-specific material may be licensed separately from the individual wallpapers.

Individual wallpapers remain subject to the rights and licenses of their respective creators.

Do not assume that every wallpaper in this repository is freely licensed for redistribution, modification, or commercial use.

---

<p align="center">
  <strong>Kairo Wallpapers</strong>
  <br>
  A curated wallpaper library for Kairo and Hyprland.
  <br><br>
  Maintained by <strong>@nihitdev</strong>
</p>

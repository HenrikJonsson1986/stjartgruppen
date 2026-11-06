# Stjärtgruppen art bible

Everything the addon shows (logo, windows, the marker wheel, future art) should look like it
came from the same place as the logo (`logo-v2.png`, in the project folder, not in git).
Read this before making or generating new art.

## The look in one sentence
A warm, painterly fantasy treasure: embossed **gold** on dark, weathered **iron and stone** with
spiky, battle-worn edges, wrapped in a bit of **ivy**, with **teal** banners and a glowing
four-pointed **gold star**, lit like a summer evening at golden hour.

It's affectionate and a little silly (the logo is a lazy hero in socks), never grim.

## Palette
Measured from the logo.

| Role | Hex | Use |
|---|---|---|
| Gold highlight | `#FDE864` | top edges of metal, glints, the star's core, hover glow |
| Gold | `#DB9521` | main metal colour, titles, rims |
| Gold shadow | `#AB680C` | lower edges, engraved lines |
| Iron / stone dark | `#120D07` | backplates, deep shadow, behind icons |
| Iron / stone mid | `#322415` | worn stone surface, panel fill |
| Banner teal | `#225A50` | accent cloth, selected state, small banners |
| Ivy green | `#3F5D26` | vines and leaves (sparingly, at edges) |
| Evening sky | `#59789F` | background only, never on UI chrome |
| Sunset cream | `#E9C088` | soft light, body text on dark |

Rules:
- Dark iron/stone is the base, and gold sits on top of it. Never gold on gold, never a bright background behind UI.
- Teal is the only cool accent on chrome. Use it for "selected" or "active", not for decoration everywhere.
- Ivy is a garnish: a few leaves at the edges or corners, never covering text or icons.

## Shapes and motifs
- **Plaque edges:** the logo's frame has spiky, notched, slightly broken edges (like old iron or carved stone). Use that silhouette for frames and rims, not smooth rounded rectangles.
- **Four-pointed star:** the group's symbol (stjärna and stjärt, it's a pun). Gold, glowing, with long thin points. Put it in the middle of round things and at the top of frames.
- **Fleur-de-lis on teal banners:** small hanging pennants for headers.
- **Rivets and engraved lines:** small gold rivets on iron, thin engraved grooves along rims.
- **Ivy:** curling vines with a few heart-shaped leaves.

## Rendering style
- Painted, not flat: visible brush texture, soft rim light, warm highlights from the upper left, cool shadows.
- Metal reads as **embossed and polished** where it catches light, worn and dark in the recesses.
- No outlines in black; edges are made by light and shadow.
- Original art only. Don't copy Blizzard's logos, fonts or branded frames, but it should feel at home next to the WoW UI.

## Prompt prefix (for generated art)
Put this at the start of every image prompt (Codex CLI, see the user's instructions):

> Painterly high-fantasy game UI art in the style of a warm golden-hour oil painting. Embossed polished gold (#DB9521 with #FDE864 highlights and #AB680C shadows) on dark weathered iron and stone (#120D07 to #322415) with spiky notched battle-worn edges, small gold rivets and engraved grooves, a few curling ivy leaves (#3F5D26), accents of deep teal cloth (#225A50). Soft warm rim light from the upper left. Original design, no text, no logos.

Then describe the single object. Add: "Centered, on a fully transparent background, nothing else in the image."

## In-game textures (technical)
- Folder: `Stjartgruppen/Media/`. Name files in lowercase with dashes (`wheel-ring.tga`).
- Format: 32-bit uncompressed TGA with alpha (WoW addons can't load PNG). Sizes must be powers of two: 64, 128, 256, 512.
- Convert with ffmpeg: `ffmpeg -i in.png -vf scale=512:512,format=bgra -rle 0 out.tga`
- **A new texture file needs a full game restart**, not just `/reload`. Changing an existing file only needs `/reload`.
- Keep the source PNGs out of the addon folder. They go in `art-bible/source/` (gitignored if they're large).
- Prefer Blizzard art (by file ID or atlas) for small things like the raid marker icons. Use our own textures only where the group's look matters.

## UI text
- Titles: Blizzard's gold fonts (`GameFontNormalLarge`, `GameFontNormalHuge`). They already match our gold.
- Body: `GameFontHighlight` (white) or sunset cream `#E9C088` on dark.
- Short and friendly. Swedish in-jokes are welcome in quips; UI labels stay plain English.

## Where it's used
- `Media/logo.tga`: MOTD window (from `logo-v2.png`).
- `Media/wheel-ring.tga`: the marker wheel's ring (`Marker.lua`).
- `Media/wheel-face.tga`: the hero's face in the middle of the wheel, a round portrait from the logo with a soft feathered edge (source: `art-bible/source/face-round.png`).
- `art-bible/source/face-cutout.png`, `wheel-face.png`: the face with the background removed (rembg/u2net), kept for later.
- `art-bible/source/wheel-star.png`: the gold star, made for the wheel, not used in game right now.

"""Build the Stjartgruppen release zip (and optionally bump the version / install for testing).

Usage:
    python -I build.py                                   # zip the current version
    python -I build.py --install                         # also copy into the Forever AddOns folder
    python -I build.py --bump patch --notes "Fixed X"    # new version + changelog entry + zip

--bump takes major, minor or patch. --notes can be given several times (one bullet each).
Output goes in dist/:
  Stjartgruppen-<version>.zip   upload this to CurseForge
  Stjartgruppen-Installer.zip   for friends: addon + double-click Windows installer
  release-notes.md              the text to paste into the upload form for this version

The zip has one top-level folder, Stjartgruppen/, which is what CurseForge and addon
managers expect. The version lives in the ## Version line of the .toc.
"""
import argparse
import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NAME = "Stjartgruppen"
ADDON = ROOT / NAME
TOC = ADDON / f"{NAME}.toc"
CHANGELOG = ROOT / "CHANGELOG.md"
DIST = ROOT / "dist"
INSTALLER = ROOT / "installer"
# Fixed name on purpose: the GitHub "latest release" link to this file never changes.
INSTALLER_ZIP = f"{NAME}-Installer.zip"
CRLF_SUFFIXES = {".bat", ".cmd", ".ps1", ".txt"}  # Windows files get Windows line endings
# <WoW root>/_dev/projects/Stjartgruppen -> <WoW root>
ADDONS_DIR = ROOT.parents[1].parent / "_forever_" / "Interface" / "AddOns"
VERSION_RE = re.compile(r"^(## Version:\s*)(.+)$", re.M)


def read_version() -> str:
    match = VERSION_RE.search(TOC.read_text(encoding="utf-8"))
    if not match:
        raise SystemExit(f"No '## Version:' line found in {TOC}")
    return match.group(2).strip()


def bump_version(version: str, part: str) -> str:
    nums = version.split(".")
    if len(nums) != 3 or not all(n.isdigit() for n in nums):
        raise SystemExit(f"Version '{version}' is not major.minor.patch, cannot bump")
    major, minor, patch = (int(n) for n in nums)
    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    else:
        patch += 1
    return f"{major}.{minor}.{patch}"


def write_version(new_version: str) -> None:
    text = TOC.read_text(encoding="utf-8")
    TOC.write_text(VERSION_RE.sub(lambda m: m.group(1) + new_version, text, count=1), encoding="utf-8")


def add_changelog(version: str, notes: list) -> None:
    bullets = "\n".join(f"- {n}" for n in notes) if notes else "- Updates and fixes."
    text = CHANGELOG.read_text(encoding="utf-8")
    entry = f"## {version}\n{bullets}\n\n"
    if text.startswith("# Changelog"):
        head, _, rest = text.partition("\n")
        text = head + "\n\n" + entry + rest.lstrip("\n")
    else:
        text = "# Changelog\n\n" + entry + text
    CHANGELOG.write_text(text, encoding="utf-8")


def release_notes(version: str) -> str:
    """The changelog section for `version`, or a generic line if it is missing."""
    text = CHANGELOG.read_text(encoding="utf-8")
    match = re.search(rf"^## {re.escape(version)}\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return match.group(1).strip() if match else "Updates and fixes."


def build_zip(version: str) -> Path:
    DIST.mkdir(exist_ok=True)
    out = DIST / f"{NAME}-{version}.zip"
    for old in DIST.glob(f"{NAME}-*.zip"):
        old.unlink()  # keep only the current version so the wrong zip is never uploaded
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for path in sorted(ADDON.rglob("*")):
            if path.is_file():
                z.write(path, f"{NAME}/{path.relative_to(ADDON).as_posix()}")
    (DIST / "release-notes.md").write_text(release_notes(version) + "\n", encoding="utf-8")
    return out


def build_installer_zip() -> Path:
    """Zip for friends: the addon folder plus the double-click installer at the top level."""
    out = DIST / INSTALLER_ZIP
    if out.exists():
        out.unlink()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for path in sorted(INSTALLER.iterdir()):
            if path.is_file():
                data = path.read_bytes()
                if path.suffix.lower() in CRLF_SUFFIXES:
                    data = data.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n")
                z.writestr(path.name, data)
        for path in sorted(ADDON.rglob("*")):
            if path.is_file():
                z.write(path, f"{NAME}/{path.relative_to(ADDON).as_posix()}")
    return out


def install() -> Path:
    dest = ADDONS_DIR / NAME
    if not ADDONS_DIR.is_dir():
        raise SystemExit(f"AddOns folder not found: {ADDONS_DIR}")
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(ADDON, dest)
    return dest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", action="store_true", help="copy the addon into the Forever AddOns folder")
    parser.add_argument("--bump", choices=["major", "minor", "patch"], help="raise the version before building")
    parser.add_argument("--notes", action="append", default=[], help="changelog bullet (repeatable); used with --bump")
    args = parser.parse_args()

    version = read_version()
    if args.bump:
        version = bump_version(version, args.bump)
        write_version(version)
        add_changelog(version, args.notes)
        print(f"Version bumped to {version}")
    elif args.notes:
        raise SystemExit("--notes only makes sense together with --bump")

    out = build_zip(version)
    print(f"Built {out} (version {version})")
    print(f"Built {build_installer_zip()} (friends installer)")
    print(f"Release notes for the upload form: {DIST / 'release-notes.md'}")
    if args.install:
        print(f"Installed to {install()}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Clone upstream repos, build xcframeworks with `make package`, upload them to the `storage` release."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = REPO_ROOT / "Config" / "upstream-sources.json"
RENDER_SCRIPT = REPO_ROOT / "Scripts" / "render_package_manifest.py"
STORAGE_TAG = "storage"
CLEAR_CACHE_SCRIPT = REPO_ROOT / "Scripts" / "clear_spm_artifact_cache.sh"


def run(cmd, *, cwd=None, env=None, shell=False, capture=False):
    printable = cmd if shell else " ".join(shlex.quote(p) for p in cmd)
    print(f"$ {printable}", flush=True)
    result = subprocess.run(
        cmd, cwd=cwd, env=env, check=True, text=True,
        capture_output=capture, shell=shell,
    )
    return result.stdout.strip() if capture else ""


def authed_clone_url(repo, token):
    if token and repo.startswith("https://github.com/"):
        return repo.replace("https://", f"https://x-access-token:{token}@")
    return repo


def repo_name():
    return run(
        ["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"],
        cwd=REPO_ROOT, capture=True,
    )


def build_archive(source, *, token, workdir):
    src_dir = workdir / source["id"]
    run(["git", "clone", "--quiet", authed_clone_url(source["repository"], token), str(src_dir)])
    build_cmd = f'set -o pipefail; {source["buildCommand"]} | xcbeautify'
    run(build_cmd, cwd=src_dir, env=os.environ.copy(), shell=True)

    artifact = src_dir / source["artifactPath"]
    if artifact.is_file():
        return artifact
    if artifact.is_dir() and artifact.name.endswith(".xcframework"):
        zip_name = source.get("assetName", f"{artifact.name}.zip")
        zip_path = workdir / zip_name
        run(["ditto", "-c", "-k", "--keepParent", str(artifact), str(zip_path)])
        return zip_path
    raise SystemExit(f"Artifact missing for {source['id']}: {artifact}")


def checksum(path):
    out = run(["shasum", "-a", "256", str(path)], capture=True)
    return out.split()[0]


def ensure_storage_release():
    probe = subprocess.run(
        ["gh", "release", "view", STORAGE_TAG],
        cwd=REPO_ROOT, text=True, capture_output=True,
    )
    if probe.returncode != 0:
        run(
            ["gh", "release", "create", STORAGE_TAG,
             "--title", "Binary Storage",
             "--notes", "Rebuilt xcframework archives. Always the latest build."],
            cwd=REPO_ROOT,
        )


def render_package(state):
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
        json.dump(state, fh)
        state_path = fh.name
    try:
        run([sys.executable, str(RENDER_SCRIPT), "--state-path", state_path], cwd=REPO_ROOT)
    finally:
        os.unlink(state_path)


def load_existing_mirrors(sources):
    package_text = (REPO_ROOT / "Package.swift").read_text()
    mirrors = {}
    for source in sources:
        module_name = re.escape(source["moduleName"])
        match = re.search(
            rf'\.binaryTarget\(\s*name:\s*"{module_name}",\s*url:\s*"([^"]+)",\s*checksum:\s*"([^"]+)"',
            package_text,
            re.MULTILINE | re.DOTALL,
        )
        if not match:
            continue

        download_url, sha = match.groups()
        asset_name = Path(download_url.split("?", 1)[0]).name
        mirrors[source["id"]] = {
            "assetName": asset_name,
            "checksum": sha,
            "downloadURL": download_url,
        }
    return mirrors


def validate_rendered_package():
    run(["zsh", str(CLEAR_CACHE_SCRIPT)], cwd=REPO_ROOT)
    run(["swift", "test"], cwd=REPO_ROOT)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", action="append", dest="source_ids",
                        help="Only build the given source id. Repeatable.")
    args = parser.parse_args()

    sources = json.loads(SOURCES_PATH.read_text())
    if args.source_ids:
        wanted = set(args.source_ids)
        sources = [s for s in sources if s["id"] in wanted]
        if not sources:
            raise SystemExit(f"No matching sources for {sorted(wanted)}")

    mirror_repo = repo_name()
    token = os.environ.get("UPSTREAM_MIRROR_TOKEN") or os.environ.get("GH_TOKEN")

    with tempfile.TemporaryDirectory(prefix="lookinside-build-") as work:
        workdir = Path(work)
        archives = []
        mirrors = load_existing_mirrors(json.loads(SOURCES_PATH.read_text()))

        for source in sources:
            print(f"==> {source['id']}", flush=True)
            archive = build_archive(source, token=token, workdir=workdir)
            sha = checksum(archive)
            name = archive.name
            url = (
                f"https://github.com/{mirror_repo}/releases/download/{STORAGE_TAG}/{name}"
                f"?sha256={sha}"
            )
            mirrors[source["id"]] = {"assetName": name, "checksum": sha, "downloadURL": url}
            archives.append(archive)

        ensure_storage_release()
        for archive in archives:
            run(["gh", "release", "upload", STORAGE_TAG, str(archive), "--clobber"],
                cwd=REPO_ROOT)

        render_package({"mirrors": mirrors})
        validate_rendered_package()


if __name__ == "__main__":
    main()

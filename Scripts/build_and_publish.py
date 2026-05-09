#!/usr/bin/env python3
"""Clone upstream repos, build xcframeworks, and render the release manifest."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = REPO_ROOT / "Config" / "upstream-sources.json"
RENDER_SCRIPT = REPO_ROOT / "Scripts" / "render_package_manifest.py"


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


def resolve_source_repo(source):
    if "repository" in source and source["repository"]:
        return source["repository"]
    env_key = source.get("repositoryEnv")
    if env_key:
        url = os.environ.get(env_key)
        if not url:
            raise SystemExit(
                f"Source {source['id']!r} expects repository URL in env var {env_key!r}, "
                "but it is not set."
            )
        return url
    raise SystemExit(f"Source {source['id']!r} has no repository or repositoryEnv field.")


def build_archive(source, *, token, workdir):
    src_dir = workdir / source["id"]
    repo_url = resolve_source_repo(source)
    run(["git", "clone", "--quiet", authed_clone_url(repo_url, token), str(src_dir)])
    raw_log = workdir / f"{source['id']}-build.log"
    build_cmd = (
        f'set -o pipefail; '
        f'{source["buildCommand"]} 2>&1 | tee {shlex.quote(str(raw_log))} | xcbeautify'
    )
    try:
        run(build_cmd, cwd=src_dir, env=os.environ.copy(), shell=True)
    except subprocess.CalledProcessError:
        if raw_log.exists():
            print("----- raw xcodebuild log (tail) -----", flush=True)
            tail = raw_log.read_text(errors="replace").splitlines()[-400:]
            print("\n".join(tail), flush=True)
        raise

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


def release_download_url(mirror_repo, release_tag, asset_name):
    return f"https://github.com/{mirror_repo}/releases/download/{release_tag}/{asset_name}"


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--release-tag",
        required=True,
        help="Version tag whose GitHub Release will host the built artifacts.",
    )
    parser.add_argument(
        "--asset-output-dir",
        default="build/release-assets",
        help="Directory to copy release assets into before the GitHub Release upload step.",
    )
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
    asset_output_dir = Path(args.asset_output_dir)
    if not asset_output_dir.is_absolute():
        asset_output_dir = REPO_ROOT / asset_output_dir
    if asset_output_dir.exists():
        shutil.rmtree(asset_output_dir)
    asset_output_dir.mkdir(parents=True)

    with tempfile.TemporaryDirectory(prefix="lookinside-build-") as work:
        workdir = Path(work)
        mirrors = load_existing_mirrors(json.loads(SOURCES_PATH.read_text()))

        for source in sources:
            print(f"==> {source['id']}", flush=True)
            archive = build_archive(source, token=token, workdir=workdir)
            sha = checksum(archive)
            name = source.get("assetName", archive.name)
            asset_path = asset_output_dir / name
            shutil.copy2(archive, asset_path)
            url = release_download_url(mirror_repo, args.release_tag, name)
            mirrors[source["id"]] = {"assetName": name, "checksum": sha, "downloadURL": url}

        render_package({"releaseTag": args.release_tag, "mirrors": mirrors})


if __name__ == "__main__":
    main()

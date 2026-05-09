#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = REPO_ROOT / "Config" / "upstream-sources.json"
PACKAGE_PATH = REPO_ROOT / "Package.swift"
PODSPEC_PATH = REPO_ROOT / "LookInsideServer.podspec"
LEGACY_SHIMS_ROOT = REPO_ROOT / "Sources"
TESTS_ROOT = REPO_ROOT / "Tests"
RELEASE_REPO_URL = "https://github.com/LookInsideApp/LookInside-Release.git"


def load_json(path: Path) -> object:
    return json.loads(path.read_text())


def quoted(value: str) -> str:
    return json.dumps(value)


def test_target_name(module_name: str) -> str:
    prefix = "LookInsideServer"
    suffix = module_name.removeprefix(prefix)
    return f"LookInsideRelease{suffix or module_name}Tests"


def render_package_dependency(spec: dict) -> str:
    url = quoted(spec["url"])
    if "branch" in spec:
        return f"        .package(url: {url}, branch: {quoted(spec['branch'])})"
    if "version" in spec:
        return f'        .package(url: {url}, from: {quoted(spec["version"])})'
    raise SystemExit(f"swiftPackageDependency missing branch/version: {spec}")


def infer_release_tag(download_url: str | None) -> str | None:
    if not download_url:
        return None
    marker = "/releases/download/"
    if marker not in download_url:
        return None
    tail = download_url.split(marker, 1)[1]
    return tail.split("/", 1)[0]


def ruby_string(value: str) -> str:
    return json.dumps(value)


def render_lookinside_server_podspec(
    *,
    version: str,
    download_url: str,
    checksum: str,
) -> str:
    return f"""Pod::Spec.new do |s|
  s.name = "LookInsideServer"
  s.version = {ruby_string(version)}
  s.summary = "LookInside runtime server for debuggable iOS and macOS apps."
  s.homepage = "https://github.com/LookInsideApp/LookInside-Release"
  s.license = {{ :type => "MIT" }}
  s.authors = {{ "LookInside" => "support@lookinside-app.com" }}
  s.source = {{ :git => {ruby_string(RELEASE_REPO_URL)}, :tag => s.version.to_s }}
  s.ios.deployment_target = "13.0"
  s.osx.deployment_target = "14.0"
  s.swift_versions = ["5.9"]
  s.vendored_frameworks = "LookInsideServer.xcframework"
  s.prepare_command = <<-CMD
set -eu
curl -L -o LookInsideServer.xcframework.zip {ruby_string(download_url)}
echo "{checksum}  LookInsideServer.xcframework.zip" | shasum -a 256 -c -
rm -rf LookInsideServer.xcframework
ditto -x -k LookInsideServer.xcframework.zip .
rm LookInsideServer.xcframework.zip
  CMD
end
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--state-path",
        required=True,
        help="Path to the mirror state JSON to render from.",
    )
    parser.add_argument(
        "--local-binary-override",
        action="append",
        default=[],
        help="Source override in the form source-id=relative/path/to/Artifact.xcframework",
    )
    return parser.parse_args()


def parse_local_overrides(raw_overrides: list[str]) -> dict[str, str]:
    overrides: dict[str, str] = {}
    for raw in raw_overrides:
        source_id, separator, path = raw.partition("=")
        if not separator or not source_id or not path:
            raise SystemExit(f"Invalid local override: {raw}")
        override_path = Path(path)
        if override_path.is_absolute():
            try:
                override_path = override_path.relative_to(REPO_ROOT)
            except ValueError as error:
                raise SystemExit(
                    f"Local override path must live inside the package root: {path}"
                ) from error
        overrides[source_id] = override_path.as_posix()
    return overrides


def remove_legacy_shims() -> None:
    if not LEGACY_SHIMS_ROOT.exists():
        return

    for child in LEGACY_SHIMS_ROOT.iterdir():
        if child.is_dir() and child.name.endswith("PackageShim"):
            shutil.rmtree(child)


def write_test_sources(module_names: list[str]) -> None:
    active_tests = {test_target_name(module): module for module in module_names}
    TESTS_ROOT.mkdir(exist_ok=True)

    for child in TESTS_ROOT.iterdir():
        if (
            child.is_dir()
            and child.name.startswith("LookInsideRelease")
            and child.name.endswith("Tests")
            and child.name not in active_tests
        ):
            shutil.rmtree(child)

    for test_name, module_name in active_tests.items():
        test_dir = TESTS_ROOT / test_name
        test_dir.mkdir(parents=True, exist_ok=True)
        body = f"""import XCTest
import {module_name}

final class ImportSmokeTests: XCTestCase {{
    func testModulesLink() {{
        // Successful compilation + link of the imports above is the assertion.
    }}
}}
"""
        (test_dir / "ImportSmokeTests.swift").write_text(body)


def main() -> None:
    args = parse_args()
    sources = load_json(SOURCES_PATH)
    state = load_json(Path(args.state_path))
    mirrors = state.get("mirrors", {})
    release_tag = state.get("releaseTag")
    local_overrides = parse_local_overrides(args.local_binary_override)

    products: list[str] = []
    targets: list[str] = []
    active_modules: list[str] = []
    podspec_text: str | None = None
    package_dependencies: list[str] = []
    seen_package_urls: set[str] = set()
    for source in sources:
        mirror = mirrors.get(source["id"], {})
        checksum = mirror.get("checksum")
        download_url = mirror.get("downloadURL")
        local_binary_path = local_overrides.get(source["id"])

        if not checksum or (not download_url and not local_binary_path):
            continue

        library_name = source["libraryName"]
        module_name = source["moduleName"]
        active_modules.append(module_name)

        if module_name == "LookInsideServer" and download_url:
            podspec_version = release_tag or infer_release_tag(download_url)
            if not podspec_version:
                raise SystemExit(
                    "LookInsideServer podspec rendering needs a release tag."
                )
            podspec_text = render_lookinside_server_podspec(
                version=podspec_version,
                download_url=download_url,
                checksum=checksum,
            )

        spm_deps = source.get("swiftPackageDependencies", [])
        if spm_deps:
            raise SystemExit(
                f"{source['id']} declares swiftPackageDependencies, but direct "
                "binary products do not support extra target dependencies"
            )
        for spec in spm_deps:
            if spec["url"] not in seen_package_urls:
                package_dependencies.append(render_package_dependency(spec))
                seen_package_urls.add(spec["url"])

        products.append(
            f"""        .library(
            name: {quoted(library_name)},
            targets: [{quoted(module_name)}]
        )"""
        )
        if local_binary_path:
            targets.append(
                f"""        .binaryTarget(
            name: {quoted(module_name)},
            path: {quoted(local_binary_path)}
        )"""
            )
        else:
            targets.append(
                f"""        .binaryTarget(
            name: {quoted(module_name)},
            url: {quoted(download_url)},
            checksum: {quoted(checksum)}
        )"""
            )

    if active_modules:
        for module_name in active_modules:
            test_name = test_target_name(module_name)
            targets.append(
                f"""        .testTarget(
            name: {quoted(test_name)},
            dependencies: [{quoted(module_name)}],
            path: {quoted(f"Tests/{test_name}")}
        )"""
            )

    products_body = ",\n".join(products)
    targets_body = ",\n".join(targets)
    dependencies_section = ""
    if package_dependencies:
        deps_body = ",\n".join(package_dependencies)
        dependencies_section = f"""    dependencies: [
{deps_body},
    ],
"""

    package_text = f"""// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInside-Release",
    platforms: [
        .iOS("13.0"),
        .macOS("14.0"),
    ],
    products: [
{products_body}
    ],
{dependencies_section}    targets: [
{targets_body}
    ]
)
"""

    PACKAGE_PATH.write_text(package_text)
    if podspec_text:
        PODSPEC_PATH.write_text(podspec_text)
    remove_legacy_shims()
    if active_modules:
        write_test_sources(active_modules)


if __name__ == "__main__":
    main()

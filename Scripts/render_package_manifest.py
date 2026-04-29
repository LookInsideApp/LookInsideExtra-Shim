#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = REPO_ROOT / "Config" / "upstream-sources.json"
PACKAGE_PATH = REPO_ROOT / "Package.swift"
LEGACY_SHIMS_ROOT = REPO_ROOT / "Sources"
TESTS_ROOT = REPO_ROOT / "Tests"


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
    local_overrides = parse_local_overrides(args.local_binary_override)

    products: list[str] = []
    targets: list[str] = []
    active_modules: list[str] = []
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
        .iOS("15.0"),
        .macOS("15.0"),
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
    remove_legacy_shims()
    if active_modules:
        write_test_sources(active_modules)


if __name__ == "__main__":
    main()

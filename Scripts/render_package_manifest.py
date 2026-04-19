#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = REPO_ROOT / "Config" / "upstream-sources.json"
PACKAGE_PATH = REPO_ROOT / "Package.swift"
SHIMS_ROOT = REPO_ROOT / "Sources"
TESTS_ROOT = REPO_ROOT / "Tests"
TEST_TARGET_NAME = "LookInsideExtraShimTests"


def load_json(path: Path) -> object:
    return json.loads(path.read_text())


def quoted(value: str) -> str:
    return json.dumps(value)


def shim_target_name(module_name: str) -> str:
    return f"{module_name}PackageShim"


def render_shim_target(module_name: str, shim_name: str) -> str:
    return f"""        .target(
            name: {quoted(shim_name)},
            dependencies: [{quoted(module_name)}],
            path: {quoted(f"Sources/{shim_name}")}
        )"""


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


def write_shim_sources(active_shims: dict[str, str]) -> None:
    SHIMS_ROOT.mkdir(exist_ok=True)

    for child in SHIMS_ROOT.iterdir():
        if child.is_dir() and child.name.endswith("PackageShim") and child.name not in active_shims:
            for nested in child.iterdir():
                if nested.is_file():
                    nested.unlink()
            child.rmdir()

    for shim_name, module_name in active_shims.items():
        shim_dir = SHIMS_ROOT / shim_name
        shim_dir.mkdir(parents=True, exist_ok=True)
        (shim_dir / "Exports.swift").write_text(f"@_exported import {module_name}\n")


def write_test_sources(module_names: list[str]) -> None:
    test_dir = TESTS_ROOT / TEST_TARGET_NAME
    test_dir.mkdir(parents=True, exist_ok=True)
    imports = "\n".join(f"import {module}" for module in module_names)
    body = f"""import XCTest
{imports}

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
    active_shims: dict[str, str] = {}
    active_modules: list[str] = []
    for source in sources:
        mirror = mirrors.get(source["id"], {})
        checksum = mirror.get("checksum")
        download_url = mirror.get("downloadURL")
        local_binary_path = local_overrides.get(source["id"])

        if not checksum or (not download_url and not local_binary_path):
            continue

        library_name = source["libraryName"]
        module_name = source["moduleName"]
        shim_name = shim_target_name(module_name)
        active_shims[shim_name] = module_name
        active_modules.append(module_name)

        products.append(
            f"""        .library(
            name: {quoted(library_name)},
            targets: [{quoted(module_name)}, {quoted(shim_name)}]
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
        targets.append(render_shim_target(module_name, shim_name))

    if active_modules:
        test_deps = ", ".join(quoted(shim_target_name(m)) for m in active_modules)
        targets.append(
            f"""        .testTarget(
            name: {quoted(TEST_TARGET_NAME)},
            dependencies: [{test_deps}],
            path: {quoted(f"Tests/{TEST_TARGET_NAME}")}
        )"""
        )

    products_body = ",\n".join(products)
    targets_body = ",\n".join(targets)

    package_text = f"""// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInsideExtra-Shim",
    platforms: [
        .iOS(.v15),
        .macOS(.v15),
    ],
    products: [
{products_body}
    ],
    targets: [
{targets_body}
    ]
)
"""

    PACKAGE_PATH.write_text(package_text)
    write_shim_sources(active_shims)
    if active_modules:
        write_test_sources(active_modules)


if __name__ == "__main__":
    main()

"""Sinh SBOM CycloneDX 1.5 cho các gói Dart đi vào bản build (COMPLIANCE S-04).

Chạy tại thư mục app (Flutter phải có trong PATH):
    python tool/make_sbom.py
Ghi ra docs/sbom/vigon.cdx.json và in bảng giấy phép để rà.
Chỉ tính gói "main" và phụ thuộc của chúng; gói chỉ dùng để test/sinh mã bị loại.
"""

import json
import os
import re
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

APP = Path(__file__).resolve().parent.parent
CACHE = Path(os.environ.get("PUB_CACHE") or Path(os.environ["LOCALAPPDATA"]) / "Pub" / "Cache")

# Nhận dạng giấy phép theo câu đặc trưng trong file LICENSE (mã SPDX).
SIGNATURES = [
    ("Apache-2.0", r"Apache License,?\s+Version 2\.0"),
    ("MPL-2.0", r"Mozilla Public License,? v(ersion)?\.? ?2\.0"),
    ("BSD-3-Clause", r"Neither the name of .+? nor the names of its\s+contributors"),
    ("BSD-2-Clause", r"Redistributions in binary form must reproduce"),
    ("MIT", r"Permission is hereby granted, free of charge"),
    ("Unlicense", r"This is free and unencumbered software"),
    ("Zlib", r"This software is provided 'as-is'"),
]


def detect_license(text: str) -> str:
    for spdx, pattern in SIGNATURES:
        if re.search(pattern, text, re.S | re.I):
            return spdx
    return "NOASSERTION"


def license_of(name: str, version: str, source: str) -> str:
    if source == "sdk":
        return "BSD-3-Clause"  # gói đi kèm Flutter SDK
    folder = CACHE / "hosted" / "pub.dev" / f"{name}-{version}"
    for f in ("LICENSE", "LICENSE.md", "LICENSE.txt", "COPYING"):
        p = folder / f
        if p.exists():
            return detect_license(p.read_text(encoding="utf-8", errors="ignore"))
    return "NOASSERTION"


def main() -> None:
    deps = json.loads(
        subprocess.run(
            "flutter pub deps --json", cwd=APP, shell=True, check=True,
            capture_output=True, text=True, encoding="utf-8",
        ).stdout
    )
    packages = {p["name"]: p for p in deps["packages"]}
    root = deps["root"]
    # Gói đi vào bản build: phụ thuộc "main" của gốc và mọi phụ thuộc của chúng.
    todo = [n for n in packages[root]["directDependencies"] if packages[n]["kind"] == "direct"]
    runtime: set[str] = set()
    while todo:
        n = todo.pop()
        if n in runtime:
            continue
        runtime.add(n)
        todo.extend(packages[n].get("dependencies", []))

    components = []
    for n in sorted(runtime):
        p = packages[n]
        lic = license_of(n, p["version"], p["source"])
        comp = {
            "type": "library",
            "bom-ref": f"pkg:pub/{n}@{p['version']}",
            "name": n,
            "version": p["version"],
            "purl": f"pkg:pub/{n}@{p['version']}",
            "licenses": [{"license": {"id": lic}}] if lic != "NOASSERTION" else [],
        }
        components.append(comp)

    app = packages[root]
    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tools": [{"name": "tool/make_sbom.py"}],
            "component": {
                "type": "application",
                "bom-ref": f"pkg:pub/{root}@{app['version']}",
                "name": "Ví Gọn",
                "version": app["version"],
            },
        },
        "components": components,
        "dependencies": [
            {"ref": f"pkg:pub/{n}@{packages[n]['version']}",
             "dependsOn": [f"pkg:pub/{d}@{packages[d]['version']}"
                           for d in packages[n].get("dependencies", []) if d in runtime]}
            for n in sorted(runtime)
        ],
    }
    out = APP / "docs" / "sbom" / "vigon.cdx.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(bom, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    counts: dict[str, int] = {}
    for c in components:
        lic = c["licenses"][0]["license"]["id"] if c["licenses"] else "NOASSERTION"
        counts[lic] = counts.get(lic, 0) + 1
    print(f"{len(components)} gói đi vào bản build -> {out.relative_to(APP)}")
    for lic, n in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {lic}: {n}")
    for c in components:
        if not c["licenses"]:
            print(f"  CHƯA NHẬN DẠNG: {c['name']} {c['version']}")


if __name__ == "__main__":
    main()

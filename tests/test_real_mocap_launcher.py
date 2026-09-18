from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def test_interactive_launcher_imports_its_own_checkout(tmp_path: Path) -> None:
    repo_root = Path(__file__).resolve().parents[1]
    old_checkout = tmp_path / "old_checkout"
    old_package = old_checkout / "teleopit"
    old_package.mkdir(parents=True)
    (old_package / "__init__.py").write_text("")

    fake_home = tmp_path / "home"
    fake_home.mkdir()
    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    commands = {
        "python3": (
            "#!/bin/sh\n"
            "exec \"$REAL_PYTHON\" -c 'import sys; "
            "sys.path[0] = \"scripts/run\"; "
            "import teleopit; print(teleopit.__file__)'\n"
        ),
        "ssh": "#!/bin/sh\nexit 1\n",
        "pgrep": "#!/bin/sh\nexit 1\n",
        "systemctl": "#!/bin/sh\nexit 0\n",
        "sleep": "#!/bin/sh\nexit 0\n",
    }
    for name, contents in commands.items():
        path = fake_bin / name
        path.write_text(contents)
        path.chmod(0o755)

    env = os.environ.copy()
    env.update(
        HOME=str(fake_home),
        PATH=f"{fake_bin}{os.pathsep}{env['PATH']}",
        PYTHONPATH=str(old_checkout),
        REAL_PYTHON=sys.executable,
        TELEOPIT_IFACE="test0",
    )
    master, slave = os.openpty()
    try:
        result = subprocess.run(
            ["bash", str(repo_root / "run/real_mocap.sh"), "--interactive"],
            cwd=repo_root,
            env=env,
            stdin=slave,
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    finally:
        os.close(master)
        os.close(slave)

    assert result.returncode == 0, result.stderr
    assert str(repo_root / "teleopit/__init__.py") in result.stdout

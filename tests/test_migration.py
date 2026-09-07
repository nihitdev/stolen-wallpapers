"""Offline regression checks for Kairo's public entrypoints and checkout lifecycle."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="kairo-test-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.env = dict(os.environ)
        for name, directory in [("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_DATA_HOME", "data"),
                                ("XDG_RUNTIME_DIR", "runtime"), ("KAIRO_BIN_DIR", "bin")]:
            path = self.base / directory
            path.mkdir()
            self.env[name] = str(path)
        for name in ["KAIRO_DIR", "KAIRO_VERSION", "HYPRLAND_INSTANCE_SIGNATURE", "I18N_DIR"]:
            self.env.pop(name, None)

    def run_cmd(self, *args, code=0):
        result = subprocess.run(args, cwd=ROOT, env=self.env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, code, result.stdout + result.stderr)
        return result

    def test_help_and_rejected_commands(self):
        for binary, args in [("kairo", ["--help"]), ("kairo", ["launch", "--help"]),
                             ("kairo", ["msg", "--help"]), ("kairo", ["ipc", "--help"]),
                             ("kairod", ["--help"]), ("kairo", ["--version"]), ("kairod", ["--version"])]:
            result = self.run_cmd(str(ROOT / "bin" / binary), *args)
            self.assertIn("kairo", result.stdout.lower())
            self.assertFalse(result.stderr)
        self.run_cmd(str(ROOT / "bin/kairo"), "nonexistent", code=1)
        self.run_cmd(str(ROOT / "bin/kairod"), "start", "stop", code=1)
        self.run_cmd(str(ROOT / "bin/kairod"), "start", code=1)
        self.run_cmd(str(ROOT / "bin/kairo"), "msg", "toggle", "launcher", code=1)
        self.assertFalse((self.base / "config/kairo/settings.json").exists(), "help must not create settings")

    def test_checkout_install_update_remove(self):
        dry = self.run_cmd("bash", "install/install.sh", "--local", "--dry-run")
        self.assertIn(str(self.base / "data/kairo"), dry.stdout)
        self.assertFalse(list((self.base / "data").iterdir()))
        self.run_cmd("bash", "install/install.sh", "--local")
        installed = self.base / "data/kairo"
        for name in ["kairo", "kairod"]:
            self.assertTrue((self.base / "bin" / name).is_symlink())
            self.run_cmd(str(self.base / "bin" / name), "--help")
        for name in ["LICENSE.md", "UPSTREAM.md", "README.md", "version.txt"]:
            self.assertTrue((installed / "src" / name).is_file())
        self.assertTrue((installed / "config/kairo/settings.json").is_file())
        settings = self.base / "config/kairo/settings.json"
        data = json.loads(settings.read_text())
        data["test_preserved"] = True
        settings.write_text(json.dumps(data))
        self.run_cmd("bash", "install/install.sh", "--local")
        self.assertTrue(json.loads(settings.read_text())["test_preserved"])
        self.run_cmd("bash", "install/uninstall.sh", "--dry-run")
        self.assertTrue(installed.exists())
        self.run_cmd("bash", "install/uninstall.sh")
        self.assertFalse(installed.exists())
        self.assertTrue(settings.exists())
        self.assertFalse((self.base / "bin/kairo").is_symlink())
        self.assertFalse((self.base / "data/applications/kairo.desktop").is_symlink())

    def test_scoped_daemon_lifecycle(self):
        # Keep the real launchers and lifecycle code; replace desktop children only.
        fixture = self.base / "fixture"
        fixture.mkdir()
        (fixture / "scripts").symlink_to(ROOT / "src/scripts", target_is_directory=True)
        tracker = fixture / "quickshell/guide/wellbeing/launch_daemon.sh"
        tracker.parent.mkdir(parents=True)
        tracker.write_text("#!/bin/bash\nexec sleep 60\n")
        (fixture / "quickshell/Shell.qml").write_text("// test entrypoint\n")
        qs = self.base / "bin/quickshell"
        qs.write_text("#!/bin/bash\nexec sleep 60\n")
        qs.chmod(0o755)
        self.env.update(KAIRO_DIR=str(fixture), HYPRLAND_INSTANCE_SIGNATURE="test",
                        PATH=str(self.base / "bin") + ":" + self.env["PATH"])
        unrelated = subprocess.Popen(["sleep", "60"])
        self.addCleanup(lambda: unrelated.poll() is None and unrelated.terminate())
        daemon = subprocess.Popen([str(ROOT / "bin/kairod"), "start"], env=self.env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.addCleanup(lambda: daemon.poll() is None and daemon.terminate())
        pid_file = self.base / "runtime/kairo/kairod.pid"
        for _ in range(50):
            if pid_file.exists():
                break
            time.sleep(.05)
        self.assertTrue(pid_file.exists())
        self.run_cmd(str(ROOT / "bin/kairod"), "status")
        self.run_cmd(str(ROOT / "bin/kairod"), "start", code=1)
        self.run_cmd(str(ROOT / "bin/kairo"), "kill")
        out, err = daemon.communicate(timeout=10)
        self.assertEqual(daemon.returncode, 0, out + err)
        self.assertFalse(pid_file.exists())
        self.assertTrue((pid_file.parent / "kairod.lock").exists())
        self.assertIsNone(unrelated.poll())
        unrelated.terminate()
        unrelated.wait()
        self.run_cmd(str(ROOT / "bin/kairod"), "status", code=1)
        # A stale or unrelated PID must not be killed.
        pid_file.write_text(str(os.getpid()))
        self.run_cmd(str(ROOT / "bin/kairod"), "stop")

    def test_workspace_and_ipc(self):
        log = self.base / "calls"
        self.env["KAIRO_TEST_LOG"] = str(log)
        self.env["PATH"] = str(self.base / "bin") + ":" + self.env["PATH"]
        for name in ["hyprctl", "quickshell"]:
            command = self.base / "bin" / name
            command.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$KAIRO_TEST_LOG"\n')
            command.chmod(0o755)
        for args in [["1"], ["2", "move"], ["toggle", "launcher"], ["open", "network", "wifi"], ["close"]]:
            self.run_cmd("bash", "src/scripts/qs_manager.sh", *args)
        time.sleep(.1)
        calls = log.read_text()
        self.assertIn('hl.dsp.focus({ workspace = "1" })', calls)
        self.assertIn('hl.dsp.window.move({ workspace = "2" })', calls)
        self.assertIn("ipc call main handleCommand toggle launcher", calls)
        self.run_cmd("bash", "src/scripts/qs_manager.sh", "not-an-action", code=1)


if __name__ == "__main__":
    unittest.main()

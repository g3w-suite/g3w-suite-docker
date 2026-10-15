import os
from pathlib import Path
import unittest
from unittest.mock import patch


class GunicornWorkersTest(unittest.TestCase):
    def test_generated_config(self):
        entrypoint = Path(__file__).resolve().parents[1] / "scripts/docker-entrypoint.sh"
        config = entrypoint.read_text().split("<< EOF\n", 1)[1].split("\nEOF", 1)[0]
        for value, cpus, expected in [
            (None, 4, 4),
            ("", 4, 4),
            ("3", 4, 3),
            (None, None, 1),
            ("", None, 1),
        ]:
            with self.subTest(value=value, cpus=cpus):
                env = {} if value is None else {"G3WSUITE_GUNICORN_NUM_WORKERS": value}
                with patch.dict(os.environ, env, clear=True), patch("os.cpu_count", return_value=cpus):
                    namespace = {}
                    exec(config, namespace)
                self.assertEqual(namespace["workers"], expected)
                self.assertIsInstance(namespace["workers"], int)


if __name__ == "__main__":
    unittest.main()

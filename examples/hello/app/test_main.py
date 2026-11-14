import unittest

from main import response_for


class ResponseTest(unittest.TestCase):
    def test_health(self):
        self.assertEqual(response_for("/health", {}), (200, {"status": "ok"}))

    def test_greeting_and_revision(self):
        status, body = response_for("/", {"GREETING": "Olá", "K_REVISION": "hello-00002"})
        self.assertEqual(status, 200)
        self.assertEqual(body["message"], "Olá from Cloud Run")
        self.assertEqual(body["revision"], "hello-00002")

    def test_secret_is_reported_but_never_returned(self):
        status, body = response_for("/", {"API_TOKEN": "s3cr3t-value"})
        self.assertEqual(status, 200)
        self.assertTrue(body["secret_loaded"])
        self.assertNotIn("s3cr3t-value", str(body))

    def test_unknown_path(self):
        self.assertEqual(response_for("/admin", {})[0], 404)


if __name__ == "__main__":
    unittest.main()

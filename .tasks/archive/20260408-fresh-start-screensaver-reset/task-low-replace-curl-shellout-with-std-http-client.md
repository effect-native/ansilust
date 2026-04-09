---
id: task-low-replace-curl-shellout-with-std-http-client
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Replace Curl Shellout With Std Http Client

Move `src/download/protocols/http.zig` off `sh -c curl` and onto a tested native HTTP client implementation.

## Red Phase Update

- Red phase complete.
- Added executable failing tests in `src/download/protocols/http_test.zig` that pin the minimum native-client contract for the HTTP downloader.
- The new coverage explicitly rejects `std.process.Child.run`, `sh -c`, inline `curl -s -f -o`, and the remaining curl-replacement TODO in the production source.
- Production transport implementation intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `zig test src/download/protocols/http_test.zig`
- Observed failure: `HttpClient.download does not shell out through curl or sh` fails at `src/download/protocols/http_test.zig:41` because `src/download/protocols/http.zig` still contains `std.process.Child.run` and shells out through `sh -c`.
- Observed failure: `HttpClient.download no longer carries curl replacement TODO` fails at `src/download/protocols/http_test.zig:50` because the production source still contains `TODO: Replace with proper std.http.Client implementation`.

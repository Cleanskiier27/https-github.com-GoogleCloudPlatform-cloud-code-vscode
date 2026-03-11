# Server Scrambler

This service rotates a local secret periodically and can start an "avatar world" process when a boot-flag file is present (default `./tmp/os_flash_done.flag`).

Quickstart:

1. Install deps: `npm ci`
2. Start scrambler: `npm run start:scrambler`
3. Control API:
   - GET /scrambler/status
   - POST /scrambler/rotate
   - POST /scrambler/start-avatar
   - POST /scrambler/stop-avatar
   - GET /metrics

Configuration: `config/scrambler.json`.

Notes:
- Default secret rotates on start and every hour.
- Default boot flag path is local `./tmp/os_flash_done.flag` for testing. Set to `C:\\boot_signals\\os_flash_done` for real devices.

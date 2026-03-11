const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const pino = require('pino');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const ROOT = path.resolve(__dirname, '..');
const STATIC_DIR = path.join(__dirname, '..', 'cuda-binaries', 'web-app');
const PUBLIC = path.join(__dirname, 'public');

// Serve server UI
app.use(express.static(PUBLIC));

// If the repo contains a web-app build, serve it under /app
if (fs.existsSync(STATIC_DIR)) {
    app.use('/app', express.static(STATIC_DIR));
}

app.get('/api/status', (req, res) => {
    res.json({ status: 'ok', uptime: process.uptime(), app: fs.existsSync(STATIC_DIR) });
});

function spawnBackground(cmd, args, logPrefix) {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], shell: true });
    p.stdout.on('data', d => logger.info(`${logPrefix}: ${d.toString()}`));
    p.stderr.on('data', d => logger.error(`${logPrefix}-err: ${d.toString()}`));
    p.on('close', code => logger.info(`${logPrefix} exited ${code}`));
    return p.pid;
}

app.post('/api/prep-sample', (req, res) => {
    // run Python data_prep on a small sample
    const pid = spawnBackground('python', ['ml/data_prep.py', '--src', 'cuda-binaries', '--out', 'ml/data/processed', '--limit', '32'], 'prep');
    res.json({ started: true, pid });
});

app.post('/api/train', (req, res) => {
    // start lightweight training for validation
    const pid = spawnBackground('python', ['ml/train.py', '--data', 'ml/data/processed', '--epochs', '1', '--max-samples', '32'], 'train');
    res.json({ started: true, pid });
});

app.get('/api/list-files', (req, res) => {
    const dir = path.join(__dirname, '..', 'cuda-binaries');
    if (!fs.existsSync(dir)) return res.json({ files: [] });
    const items = fs.readdirSync(dir).slice(0, 200);
    res.json({ files: items });
});

app.listen(PORT, () => {
    logger.info(`Server started on ${PORT}`);
});

module.exports = app;

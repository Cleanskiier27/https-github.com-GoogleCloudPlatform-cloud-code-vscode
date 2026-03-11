#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawn } = require('child_process');
const express = require('express');
const { inferenceCounter, inferenceLatency } = require('./metrics');

const ROOT = path.resolve(__dirname);
const CONFIG_PATH = path.join(ROOT, 'config', 'scrambler.json');
const SECRETS_DIR = path.join(ROOT, 'secrets');
const DEFAULT_CONFIG = {
  rotateIntervalSeconds: 3600,
  secretFile: path.join(SECRETS_DIR, 'secret.txt'),
  bootFlag: 'C:\\boot_signals\\os_flash_done',
  avatarCommand: 'node avatar/run-avatar.js',
  avatarCwd: ROOT,
  httpPort: 3010
};

function loadConfig(){
  try{
    const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
    return Object.assign({}, DEFAULT_CONFIG, JSON.parse(raw));
  }catch(e){
    return DEFAULT_CONFIG;
  }
}

function ensureSecretsDir(){
  if(!fs.existsSync(SECRETS_DIR)) fs.mkdirSync(SECRETS_DIR, { recursive: true });
}

function rotateSecret(secretFile){
  ensureSecretsDir();
  const secret = crypto.randomBytes(32).toString('hex');
  const payload = { secret, ts: new Date().toISOString() };
  fs.writeFileSync(secretFile, JSON.stringify(payload, null, 2), { mode: 0o600 });
  console.log('[scrambler] rotated secret ->', secretFile);
}

let avatarProc = null;
function startAvatar(cmd, cwd){
  if(avatarProc){
    console.log('[scrambler] avatar already running');
    return;
  }
  const parts = cmd.split(' ');
  const proc = spawn(parts[0], parts.slice(1), { cwd, stdio: ['ignore', 'pipe', 'pipe'], shell: true });
  avatarProc = proc;
  proc.stdout.on('data', d => console.log('[avatar]', d.toString().trim()));
  proc.stderr.on('data', d => console.error('[avatar-err]', d.toString().trim()));
  proc.on('exit', (code) => { console.log('[scrambler] avatar exited', code); avatarProc = null; });
  console.log('[scrambler] avatar started with pid', proc.pid);
}

function stopAvatar(){
  if(!avatarProc) return;
  try{ avatarProc.kill(); }catch(e){}
  avatarProc = null;
}

async function monitorBootFlag(cfg){
  const flag = cfg.bootFlag;
  console.log('[scrambler] monitoring boot flag:', flag);
  const check = () => {
    if(fs.existsSync(flag)){
      console.log('[scrambler] boot flag detected, starting avatar world');
      startAvatar(cfg.avatarCommand, cfg.avatarCwd);
      // stop monitoring after start
    } else {
      setTimeout(check, 3000);
    }
  };
  check();
}

function startHttpServer(cfg){
  const app = express();
  app.use(express.json());

  app.get('/scrambler/status', (req, res) => {
    const secret = fs.existsSync(cfg.secretFile) ? JSON.parse(fs.readFileSync(cfg.secretFile,'utf8')) : null;
    res.json({ secret: !!secret, avatarRunning: !!avatarProc, config: cfg });
  });

  app.post('/scrambler/rotate', (req, res) => {
    rotateSecret(cfg.secretFile);
    res.json({ ok: true });
  });

  app.post('/scrambler/start-avatar', (req, res) => { startAvatar(cfg.avatarCommand, cfg.avatarCwd); res.json({ started: !!avatarProc }); });
  app.post('/scrambler/stop-avatar', (req, res) => { stopAvatar(); res.json({ stopped: true }); });

  app.get('/metrics', async (req, res) => {
    const client = require('prom-client');
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  });

  app.listen(cfg.httpPort, () => console.log('[scrambler] http control listening on', cfg.httpPort));
}

async function main(){
  const cfg = loadConfig();
  ensureSecretsDir();
  rotateSecret(cfg.secretFile);
  // periodic rotate
  setInterval(()=> rotateSecret(cfg.secretFile), Math.max(1000, cfg.rotateIntervalSeconds*1000));
  // monitor boot flag
  monitorBootFlag(cfg);
  // http server
  startHttpServer(cfg);
}

if(require.main === module) main();

module.exports = { rotateSecret, startAvatar, stopAvatar };

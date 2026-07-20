// JS helper that loads the native addon, with CPU fallback if loading fails
const path = require('path');
let addon = null;
try {
  addon = require('node-gyp-build')(path.resolve(__dirname));
} catch (e) {
  console.warn('Native addon not built or failed to load, using CPU fallback', e.message);
}

function addVectors(a, b) {
  if (addon && addon.addVectors) {
    return addon.addVectors(a, b);
  }
  // fallback CPU implementation
  const n = Math.min(a.length, b.length);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) out[i] = a[i] + b[i];
  return out;
}

module.exports = { addVectors };

// Menulis public/config.js dari environment variable (Vercel) atau file .env (lokal).
// Hanya URL dan anon/publishable key yang boleh masuk ke frontend. service_role key ditolak.
const fs = require('fs');
const env = { ...process.env };
if (fs.existsSync('.env')) for (const l of fs.readFileSync('.env', 'utf8').split(/\r?\n/)) {
  const m = l.match(/^\s*([A-Z_]+)\s*=\s*(.*?)\s*$/);
  if (m && !(m[1] in process.env)) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
}
const u = env.SUPABASE_URL || '', k = env.SUPABASE_ANON_KEY || '';
let role = '';
try { role = JSON.parse(Buffer.from(k.split('.')[1], 'base64url').toString()).role; } catch {}
if (role === 'service_role' || k.startsWith('sb_secret_')) {
  console.error('DITOLAK: SUPABASE_ANON_KEY berisi secret/service_role key. Gunakan anon/publishable key.');
  process.exit(1);
}
if (!u || !k) console.warn('Peringatan: SUPABASE_URL / SUPABASE_ANON_KEY belum diisi.');
fs.mkdirSync('public', { recursive: true });
fs.writeFileSync('public/config.js', 'window.APP_CONFIG=' + JSON.stringify({ SUPABASE_URL: u, SUPABASE_ANON_KEY: k }) + ';');
console.log('public/config.js dibuat');

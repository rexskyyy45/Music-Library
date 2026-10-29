# Personal Music Library (Supabase + Vercel)

Koleksi lagu pribadi yang tersinkron antarperangkat. Login email/password, data di Postgres (RLS), file audio dan cover di Supabase Storage (bucket privat). Frontend statis (React via CDN), tanpa `npm install`.

```
public/index.html      aplikasi (React + Tailwind + Lucide + supabase-js)
build.js               membuat public/config.js dari environment variable
supabase/schema.sql    tabel, RLS, bucket Storage + policies, Realtime
vercel.json            konfigurasi build dan header keamanan
.env.example           contoh environment
```

## 1. Setup Supabase
1. Buat project baru di https://supabase.com.
2. **SQL Editor** > New query > tempel seluruh isi `supabase/schema.sql` > **Run**. Ini membuat tabel, RLS, bucket privat `music`, Storage Policies, dan Realtime.
3. **Authentication > Providers**: pastikan Email aktif. Untuk percobaan cepat, matikan *Confirm email*; untuk produksi biarkan aktif.
4. **Project Settings > API**: salin **Project URL** dan **anon / publishable key**. Jangan gunakan `service_role` / secret key. `build.js` akan menolaknya.
5. Batas upload plan gratis Supabase adalah 50 MB per file (sesuai batas di aplikasi).

## 2. Jalankan lokal
```bash
cp .env.example .env      # isi SUPABASE_URL dan SUPABASE_ANON_KEY
npm run dev               # buka http://localhost:5500
```
Daftar akun, upload lagu, lalu buka dari browser/perangkat lain dengan akun yang sama untuk memeriksa sinkronisasi.

## 3. Deploy ke Vercel
1. Push folder ini ke repository GitHub (`.env` dan `config.js` sudah di `.gitignore`).
2. Vercel > **Add New > Project** > import repository. Framework Preset: **Other** (build command dan output directory dibaca dari `vercel.json`).
3. **Environment Variables**: tambahkan `SUPABASE_URL` dan `SUPABASE_ANON_KEY` (hanya dua ini). Klik **Deploy**.
4. Setelah mendapat URL (mis. `https://music-library.vercel.app`), buka Supabase > **Authentication > URL Configuration**: isi **Site URL** dan tambahkan URL itu ke **Redirect URLs** (dipakai untuk link konfirmasi email).
5. Mengubah environment variable? Lakukan **Redeploy** agar `config.js` dibuat ulang.

Alternatif CLI: `npm i -g vercel && vercel` lalu `vercel env add SUPABASE_URL`, `vercel env add SUPABASE_ANON_KEY`, dan `vercel --prod`.

## Keamanan
- Anon key memang publik; yang melindungi data adalah **RLS** (`user_id = auth.uid()`) di semua tabel dan policy di `storage.objects` (folder pertama path harus `auth.uid()`).
- Bucket privat: audio dan cover dibuka lewat *signed URL* berumur 7 hari yang dibuat setelah login.
- Uji isolasi: daftar dua akun; akun B tidak akan melihat lagu/playlist akun A.

## Pemecahan masalah
- Layar "Konfigurasi Supabase belum diisi": env belum diisi atau `config.js` belum dibuat. Jalankan ulang `node build.js` / redeploy.
- `new row violates row-level security policy`: `schema.sql` belum dijalankan penuh atau Anda belum login.
- Upload gagal "exceeded the maximum allowed size": file di atas 50 MB.
- Perubahan tidak muncul di perangkat lain: pastikan baris `alter publication supabase_realtime ...` berhasil; data juga disegarkan otomatis saat tab kembali aktif.

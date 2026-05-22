# 🔧 Troubleshooting: Supabase DNS/Network Error

## ⚠️ Masalah

```
Failed host lookup
No address associated with hostname
```

## ✅ Penyebab Utama

- **Internet emulator bermasalah**
- **DNS emulator/laptop rusak**
- **Network diblokir** (VPN, AdBlock, Antivirus)
- **INTERNET permission belum ditambahkan** ← SUDAH DIPERBAIKI ✅

## 🎯 URL yang Benar

```
https://lfxwvrlvefrjhmqaerbz.supabase.co
```

---

## 📋 FIX yang Sudah Diimplementasikan

### ✅ 1. INTERNET Permission Ditambahkan

📁 File: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Permission lainnya -->
    <application>
        <!-- ... -->
    </application>
</manifest>
```

### ✅ 2. Network Diagnostic Test Ditambahkan

📁 File: `lib/main.dart`

```dart
Future<void> _testNetworkConnectivity() async {
  // Test 1: Google DNS
  // Test 2: Supabase DNS
  // Menampilkan ✅ atau ❌ di debug console
}
```

**Cara membaca hasil:**

1. Jalankan: `flutter run`
2. Lihat di **Debug Console** output dari network test
3. Jika Google ✅ tapi Supabase ❌ → network issue
4. Jika Google ❌ → emulator/device tidak ada internet

---

## 🚀 Fix yang Harus Dilakukan SECARA MANUAL

### **FIX #1: Test Internet Emulator** 🌐

```
Android Studio → Device Manager → dropdown emulator → buka
Chrome di emulator → akses Google

✅ Berhasil: Lanjut ke FIX #2
❌ Gagal: Internet emulator rusak
```

### **FIX #2: Cold Boot Emulator** ❄️

```
Android Studio → Device Manager
Dropdown emulator → Cold Boot Now

Tunggu 2 menit emulator reboot
flutter run
```

### **FIX #3: Wipe Data Emulator** (Jika masih error)

```
Android Studio → Device Manager
Dropdown emulator → Wipe Data
Cold Boot Now
flutter run
```

### **FIX #4: Coba Physical Phone** 📱

```
adb devices (pastikan phone terhubung)
flutter run

Kalau di phone NORMAL → emulator problem
Kalau di phone juga ERROR → fokus ke FIX #5-#7
```

### **FIX #5: Flush DNS Windows** 🖥️

```
Buka CMD sebagai Administrator:

ipconfig /flushdns

netsh winsock reset

Restart laptop

flutter run
```

### **FIX #6: Ganti DNS** (Windows Settings)

```
Settings → Network & Internet → Wi-Fi → Advanced → DNS server settings

Pilih: Manual
Primary DNS: 8.8.8.8 (Google)
Secondary DNS: 1.1.1.1 (Cloudflare)

Simpan → Restart laptop
flutter run
```

### **FIX #7: Disable VPN/AdBlock/Antivirus** 🛡️

```
❌ Disable sementara:
- VPN (Windscribe, ExpressVPN, dll)
- AdBlock DNS (AdGuard, NextDNS)
- Antivirus Firewall

flutter run

✅ Jika bekerja: Tambahkan exception di VPN/Antivirus untuk emulator
```

### **FIX #8: Buka URL Supabase di Emulator Chrome** 🔗

```
Emulator: Chrome
Ketik: https://lfxwvrlvefrjhmqaerbz.supabase.co

✅ Page load: DNS working
❌ Error: DNS/Network problem
```

---

## 🔍 Cara Debugging (Via Debug Console)

Setelah `flutter run`, lihat Debug Console VS Code/Android Studio:

```
🔍 [NETWORK TEST] Testing DNS resolution...
✅ [NETWORK] Google DNS: SUCCESS - 142.250.185.46
✅ [NETWORK] Supabase DNS: SUCCESS - 34.90.108.226
```

### ✅ Jika KEDUA ✅

```
Network OK ✅
Lanjut cek Supabase credentials (key, URL)
```

### ❌ Jika SALAH SATU atau KEDUA ❌

```
❌ [NETWORK] Supabase DNS: FAILED
   → Network problem
   → Jalankan FIX #1 - #7 di atas
```

---

## 📝 Checklist Troubleshooting

- [ ] **INTERNET permission di AndroidManifest.xml** ✅ Sudah ditambahkan
- [ ] **Network diagnostic test di main.dart** ✅ Sudah ditambahkan
- [ ] Lanjutkan dengan FIX manual:
  - [ ] FIX #1: Test Chrome di emulator → akses Google
  - [ ] FIX #2: Cold Boot emulator
  - [ ] FIX #3: Wipe Data emulator (jika masih error)
  - [ ] FIX #4: Coba physical phone
  - [ ] FIX #5: Flush DNS Windows (CMD Administrator)
  - [ ] FIX #6: Ganti DNS ke 8.8.8.8
  - [ ] FIX #7: Disable VPN/AdBlock
  - [ ] FIX #8: Test buka Supabase URL di Chrome emulator

---

## 🎯 Step-by-Step Debugging

### Step 1: Cek Network Diagnostic

```bash
flutter run
# Lihat Debug Console
# Cari: [NETWORK TEST]
```

### Step 2: Jika Ada ❌

```bash
# FIX #1: Test Google Chrome di emulator
# Emulator → Chrome → google.com
# Jika tidak bisa → emulator internet rusak
```

### Step 3: Cold Boot

```bash
# Android Studio → Device Manager
# Dropdown emulator → Cold Boot Now
# Tunggu 2 menit
flutter run
```

### Step 4: Windows DNS Flush

```bash
# CMD Administrator:
ipconfig /flushdns
netsh winsock reset
# Restart laptop
flutter run
```

---

## 💡 Tips Cepat

| Gejala                                 | Fix                                        |
| -------------------------------------- | ------------------------------------------ |
| **Google ❌ Supabase ❌**              | Emulator/Device internet rusak → FIX #1-#3 |
| **Google ✅ Supabase ❌**              | Supabase domain blocked → FIX #5-#7        |
| **Error di emulator, normal di phone** | Emulator problem → FIX #2-#3               |
| **Error di phone juga**                | Network/DNS Windows → FIX #5-#6            |

---

## 📌 Kesimpulan

✅ **SUDAH DIPERBAIKI:**

- INTERNET permission di AndroidManifest.xml
- Network diagnostic test di main.dart

❌ **MASIH PERLU DILAKUKAN MANUAL:**

- Test internet emulator (Chrome → Google)
- Cold Boot emulator
- Flush DNS Windows
- Disable VPN/AdBlock

**Urutan FIX yang paling sering berhasil:**

1. Test Chrome emulator → Google ✅
2. Cold Boot emulator ✅
3. Flush DNS Windows ✅
4. Ganti DNS 8.8.8.8 ✅
5. Coba physical phone ✅

---

**Status:** 🟢 Setup Configuration Done  
**Next:** 🔵 Manual Troubleshooting Needed  
**Target:** 🎯 Supabase Connection Success ✅

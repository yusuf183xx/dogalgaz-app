# Release Setup

Bu projede Android release imzalama altyapisi hazirlandi.

## Android keystore

1. Bir upload keystore olustur.
2. `android/key.properties.example` dosyasini `android/key.properties` olarak kopyala.
3. Icini kendi keystore bilgilerinle doldur.

Ornek:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\path\\to\\upload-keystore.jks
```

## Build alma

APK:

```powershell
flutter build apk --release
```

AAB:

```powershell
flutter build appbundle --release
```

## Notlar

- `android/key.properties` git'e eklenmez.
- `android/app/build.gradle.kts` su an `key.properties` varsa release signing kullanir.
- Dosya yoksa debug signing ile devam eder; bu gelistirme icin kolayliktir, yayin icin yeterli degildir.
- Paket adi halen `com.example.dogalgazz`. Magazaya cikmadan once kalici bir paket adina gecmek gerekir.

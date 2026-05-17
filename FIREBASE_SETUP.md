# Firebase Setup

Bu proje artik repo icindeki FlutterFire dosyalariyla calisiyor.

## Mevcut durum

- `lib/firebase_options.dart` mevcut
- `android/app/google-services.json` mevcut
- Android gradle tarafinda `com.google.gms.google-services` aktif
- Teklifler `quote_requests` koleksiyonuna yazilacak sekilde hazir

Yani Firebase baglantisi icin artik `--dart-define` vermek gerekmiyor.

## Hala dikkat edilmesi gereken tek sey

Uygulamanin paket adi halen placeholder:

- `com.example.dogalgazz`

Bu teknik olarak calismaya engel degil, ama Play Store veya kalici yayin icin bunu kendi paket adinla degistirmen gerekir.

## Firestore koleksiyonu

Uygulama su koleksiyona yazar:

- `quote_requests`

Kaydedilen temel alanlar:

- `leadId`
- `fullName`
- `phone`
- `location`
- `service`
- `propertyType`
- `urgency`
- `contactPreference`
- `note`
- `submittedAtIso`
- `createdAt`
- `status`
- `source`
- `searchKeywords`

## Onerilen Firestore rule

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /quote_requests/{document} {
      allow create: if true;
      allow read, update, delete: if false;
    }
  }
}
```

Not:
Bu minimum kurulumdur. Uretimde spam korumasi icin App Check, Cloud Functions veya kendi backend katmani daha saglam olur.

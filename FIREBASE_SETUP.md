# Firebase Setup

Bu proje Firebase Auth, Firestore ve Storage ile calisir.

## Mevcut durum

- `lib/firebase_options.dart` mevcut
- `android/app/google-services.json` mevcut
- Android gradle tarafinda `com.google.gms.google-services` aktif

## Firestore koleksiyonlari

| Koleksiyon | Aciklama |
|---|---|
| `quote_requests` | Teklif formlari |
| `complaints` | Arıza / sikayet kayitlari |
| `sales` | Admin satis kayitlari |
| `users` | Musteri profilleri |
| `admins` | Admin yetkili kullanici UID listesi |

## Admin hesabi

Uygulama ilk acilista admin hesabini otomatik hazirlar:

- Kullanici adi: `admin`
- E-posta: `admin@camli.com`
- Sifre: `464512Y.`

Firebase Console > Authentication > Email/Password acik olmalidir.

## Onerilen Firestore rules

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn() &&
        (exists(/databases/$(database)/documents/admins/$(request.auth.uid)) ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }

    match /quote_requests/{document} {
      allow create: if true;
      allow read, update, delete: if isAdmin();
    }

    match /complaints/{document} {
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow read: if isSignedIn() &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow update, delete: if isAdmin();
    }

    match /sales/{document} {
      allow read, write: if isAdmin();
    }

    match /users/{userId} {
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow read: if isSignedIn() && (request.auth.uid == userId || isAdmin());
      allow update, delete: if isAdmin();
    }

    match /admins/{adminId} {
      allow read: if isSignedIn() && request.auth.uid == adminId;
      allow write: if false;
    }
  }
}
```

## Storage rules (PDF yukleme)

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /complaint_reports/{complaintId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

Not: Uretimde App Check ve daha siki kurallar onerilir.

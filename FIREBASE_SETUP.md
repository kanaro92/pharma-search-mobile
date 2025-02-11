# Configuration Firebase pour PharmaSearch

Suivez ces étapes pour configurer Firebase dans votre application :

1. **Créer un projet Firebase**
   - Allez sur [Firebase Console](https://console.firebase.google.com/)
   - Créez un nouveau projet ou sélectionnez un projet existant
   - Donnez-lui un nom (ex: "pharma-search")

2. **Configuration Android**
   - Dans Firebase Console, cliquez sur "Android" pour ajouter une app Android
   - Package name: Utilisez l'ID de votre application (trouvez-le dans `android/app/build.gradle`)
   - Téléchargez le fichier `google-services.json`
   - Placez-le dans `android/app/`
   - Modifiez `android/build.gradle` :
     ```gradle
     buildscript {
         dependencies {
             classpath 'com.google.gms:google-services:4.4.0'
         }
     }
     ```
   - Modifiez `android/app/build.gradle` :
     ```gradle
     apply plugin: 'com.google.gms.google-services'
     ```

3. **Configuration iOS**
   - Dans Firebase Console, cliquez sur "iOS" pour ajouter une app iOS
   - Bundle ID: Utilisez l'ID de votre application (trouvez-le dans Xcode)
   - Téléchargez `GoogleService-Info.plist`
   - Placez-le dans `ios/Runner/` via Xcode
   - Dans Xcode, activez les capacités Push Notifications et Background Modes

4. **Configuration Web**
   - Dans Firebase Console, cliquez sur "Web" pour ajouter une app web
   - Enregistrez la configuration Firebase
   - Créez un fichier `web/firebase-messaging-sw.js` avec le contenu suivant :
     ```javascript
     importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js');
     importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-messaging-compat.js');

     firebase.initializeApp({
       // Copiez votre configuration Firebase ici
       // apiKey, authDomain, etc.
     });

     const messaging = firebase.messaging();

     messaging.onBackgroundMessage((payload) => {
       console.log('Received background message:', payload);
       
       const notificationTitle = payload.notification.title;
       const notificationOptions = {
         body: payload.notification.body,
         icon: '/icons/icon-192x192.png'
       };

       return self.registration.showNotification(notificationTitle, notificationOptions);
     });
     ```

5. **Mise à jour du token FCM**
   - Implémentez la méthode `_updateTokenOnServer` dans `notification_service.dart`
   - Cette méthode doit envoyer le token FCM à votre backend Spring Boot

6. **Test des notifications**
   - Utilisez l'interface Firebase Console pour envoyer une notification test
   - Vérifiez que les notifications fonctionnent en premier plan et en arrière-plan

## Notes importantes

- Assurez-vous que les versions des dépendances Firebase correspondent dans tous vos fichiers
- N'oubliez pas d'ajouter les fichiers de configuration Firebase dans .gitignore
- Pour le développement local, vous pouvez utiliser l'émulateur Firebase

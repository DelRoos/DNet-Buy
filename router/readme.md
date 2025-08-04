### ✅ Option 2 : Export de la configuration (.rsc)

Cette méthode exporte la configuration en **fichier texte** lisible et modifiable.

### 📌 Étapes via Winbox / Terminal :

1. Ouvrez le **Terminal** MikroTik.
2. Tapez la commande suivante :

```bash
/export file=avant_test
```

3. Cela génère un fichier `avant_test.rsc` dans le menu **Files**.
4. Téléchargez ce fichier comme précédemment (clic droit > **Download**).

---

## 🧪 2. Faire vos tests ou réinitialiser le routeur

### 🔁 Réinitialisation du routeur (optionnel)

Si vous voulez partir d’un routeur « vierge » :

### Via Winbox / WebFig :

1. Allez dans **System > Reset Configuration**
2. Cochez si nécessaire :

   * **No Default Configuration** : pour un routeur complètement vide
   * **Keep Users** : pour garder les utilisateurs existants
3. Cliquez sur **Reset Configuration** puis redémarrez.

🛑 **Attention** : vous perdrez l’accès si vous n’avez pas de configuration IP par défaut après le reset. Ayez un accès via port Ethernet direct si nécessaire.

---

## ♻️ 3. Restaurer la configuration sauvegardée

### 🔄 Option 1 : Restaurer à partir du fichier `.backup`

1. Allez dans **Files**
2. Glissez/déposez ou téléversez le fichier `avant_test.backup`
3. Sélectionnez-le > clic droit > **Restore**
4. Le routeur redémarre avec la configuration restaurée.

### 🔄 Option 2 : Restaurer à partir du fichier `.rsc`

1. Téléversez le fichier `avant_test.rsc` dans **Files**
2. Ouvrez un terminal et tapez :

```bash
/import file-name=avant_test.rsc
```

✅ La configuration sera **rejouée** ligne par ligne (vous pouvez même éditer ce fichier au préalable pour n’importer qu’une partie).

---

## 🔧 Conseils supplémentaires

* 📁 Sauvegardez régulièrement votre configuration, surtout avant des mises à jour.
* 💾 Gardez les `.backup` et `.rsc` sur un cloud ou un disque externe.
* ⚠️ Un fichier `.backup` est propre à un **modèle spécifique** de routeur — évitez de le restaurer sur un autre modèle.
* 🧼 Le fichier `.rsc` peut être adapté d’un routeur à un autre si besoin.

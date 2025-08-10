Pour configurer l'expiration d'un utilisateur après un certain temps dès sa première connexion dans MIKHMON, qu'il utilise ou non la connexion, vous devez utiliser le champ **Validity** lors de la création d'un profil utilisateur.

MIKHMON est une interface qui simplifie la gestion des utilisateurs Hotspot sur votre MikroTik. La configuration de l'expiration se fait donc en créant un profil avec une durée de validité. Le décompte de cette validité commence automatiquement dès la toute première connexion de l'utilisateur.

Voici comment procéder étape par étape :

### Étape 1 : Accéder à la gestion des profils dans MIKHMON

1.  Connectez-vous à votre interface MIKHMON.
2.  Dans le menu de gauche, allez dans **Hotspot**.
3.  Cliquez sur **User Profile**.

### Étape 2 : Créer un nouveau profil utilisateur

1.  Cliquez sur le bouton **Add Profile**.
2.  Vous verrez un formulaire pour définir les caractéristiques du profil.

### Étape 3 : Configurer la validité du profil

C'est l'étape la plus importante pour répondre à votre besoin.

1.  **Name** : Donnez un nom explicite à votre profil (par exemple, `7_Jours_Validite`).
2.  **Shared Users** : Définissez combien d'appareils peuvent utiliser un même compte simultanément.
3.  **Rate Limit [up/down]** : Définissez la limite de vitesse pour les utilisateurs de ce profil (par exemple, `1M/5M` pour 1 Mbps en upload et 5 Mbps en download).
4.  **Expired Mode** : Vous pouvez laisser sur "Remove" pour que l'utilisateur soit supprimé après expiration, ou "Remove & Record" pour garder une trace de la vente.
5.  **Validity** : C'est ici que vous définissez la durée de vie du compte à partir de la première connexion. Le format est simple :
    *   `30d` pour 30 jours
    *   `7d` pour 7 jours
    *   `24h` pour 24 heures
    *   `12h` pour 12 heures
    *   `30m` pour 30 minutes
6.  **Price & Selling Price** : Vous pouvez définir un prix si vous vendez ces accès.
7.  **Lock User** : Laissez sur `Disabled`.

**Exemple de configuration pour un profil valide 7 jours :**

*   **Name** : `Forfait_7_Jours`
*   **Shared Users** : `1`
*   **Rate Limit** : `2M/10M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `7d`
*   **Price** : `5.00`

Cliquez sur **Save** pour enregistrer le profil.

### Étape 4 : Créer un utilisateur avec ce profil

1.  Dans le menu de gauche, allez dans **Hotspot** > **Users**.
2.  Cliquez sur **Add User** ou **Generate** pour créer des utilisateurs en masse.
3.  Lors de la création de l'utilisateur, dans le champ **Profile**, sélectionnez le profil que vous venez de créer (par exemple, `Forfait_7_Jours`).

Dès que l'utilisateur se connectera pour la toute première fois avec son identifiant et son mot de passe, le routeur MikroTik enregistrera l'heure de début, et le compte expirera automatiquement une fois la durée de validité (dans notre exemple, 7 jours) écoulée, qu'il se soit connecté 5 minutes ou qu'il ait utilisé la connexion en continu.





Absolument ! C'est un cas d'usage parfait pour MIKHMON. Nous allons procéder en deux grandes étapes :

1.  **Création des Profils Utilisateurs** : Chaque type de forfait correspondra à un "User Profile" dans MIKHMON. C'est le modèle pour vos tickets.
2.  **Génération des Tickets** : Une fois les profils créés, vous pourrez générer autant de tickets (utilisateurs) que vous le souhaitez pour chaque forfait.

Voici le guide complet et détaillé.

---

### Étape 1 : Création des Profils pour chaque Forfait

Connectez-vous à votre interface MIKHMON, allez dans le menu **Hotspot > User Profile** et cliquez sur **Add Profile**. Vous allez répéter cette opération pour chaque forfait de votre liste.

#### Profil 1 : Forfait 1 Heure
*   **Name** : `Forfait_1_Heure` (ou un nom que vous reconnaîtrez facilement)
*   **Shared Users** : `1` (car c'est pour 1 appareil)
*   **Rate Limit [up/down]** : `2M/2M`
*   **Expired Mode** : `Remove & Record` (Supprime l'utilisateur après expiration mais garde une trace dans les rapports de vente)
*   **Validity** : `1h` (h pour heure)
*   **Price** : `100` (MIKHMON ne gère pas la devise, n'écrivez que le nombre)
*   **Selling Price** : `100`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

#### Profil 2 : Forfait 1 Jour
*   **Name** : `Forfait_1_Jour`
*   **Shared Users** : `1`
*   **Rate Limit [up/down]** : `2M/2M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `1d` (d pour jour)
*   **Price** : `500`
*   **Selling Price** : `500`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

#### Profil 3 : Forfait 3 Jours
*   **Name** : `Forfait_3_Jours`
*   **Shared Users** : `1`
*   **Rate Limit [up/down]** : `2M/2M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `3d`
*   **Price** : `1000`
*   **Selling Price** : `1000`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

#### Profil 4 : Forfait 1 Semaine
*   **Name** : `Forfait_1_Semaine`
*   **Shared Users** : `1`
*   **Rate Limit [up/down]** : `5M/5M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `7d` (Il est souvent plus sûr d'utiliser `7d` que `1w`)
*   **Price** : `2000`
*   **Selling Price** : `2000`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

#### Profil 5 : Forfait 1 Mois (1 Appareil)
*   **Name** : `Forfait_1_Mois`
*   **Shared Users** : `1`
*   **Rate Limit [up/down]** : `5M/5M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `30d`
*   **Price** : `5000`
*   **Selling Price** : `5000`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

#### Profil 6 : Forfait 1 Mois (3 Appareils)
*Pour cette ligne "1 Mois Illimite 3", je suppose que le "3" signifie "3 Appareils".*
*   **Name** : `Forfait_1_Mois_VIP`
*   **Shared Users** : `3` (C'est ici que vous définissez le nombre d'appareils)
*   **Rate Limit [up/down]** : `10M/10M`
*   **Expired Mode** : `Remove & Record`
*   **Validity** : `30d`
*   **Price** : `10000`
*   **Selling Price** : `10000`
*   **Lock User** : `Disabled`
*   Cliquez sur **Save**.

Une fois terminé, votre liste de profils dans MIKHMON devrait ressembler à ceci :



---

### Étape 2 : Générer les Tickets (Utilisateurs)

Maintenant que vos modèles (profils) sont prêts, vous pouvez créer les tickets à vendre.

1.  Dans le menu de gauche, allez dans **Hotspot > Users**.
2.  Cliquez sur le bouton **Generate**. C'est beaucoup plus pratique que "Add User" pour créer plusieurs tickets.

Un formulaire de génération va s'ouvrir. Voici comment le remplir :

*   **Qty (Quantity)** : Le nombre de tickets que vous voulez créer. Par exemple, `50`.
*   **User Mode** : Sélectionnez `Username = Password`. C'est le plus simple pour les tickets.
*   **Name Length** : La longueur du nom d'utilisateur. `4` ou `5` est une bonne valeur.
*   **Password Length** : La longueur du mot de passe. `4` ou `5` est également suffisant.
*   **Prefix** : (Optionnel) Un préfixe pour le nom d'utilisateur. Par exemple `sm-` pour les tickets d'une semaine.
*   **Character** : Le type de caractères à utiliser pour l'identifiant et le mot de passe.
*   **Profile** : **Ceci est le champ le plus important.** C'est ici que vous choisissez le forfait pour les tickets que vous générez. Sélectionnez l'un des profils que vous avez créés à l'étape 1 (par exemple, `Forfait_1_Semaine`).
*   **Time Limit** : Laissez vide, car la durée est déjà définie dans le profil avec **Validity**.
*   **Data Limit** : Laissez vide, car vos forfaits sont illimités en données.
*   **Comment** : (Optionnel) Vous pouvez ajouter un commentaire pour retrouver facilement ce lot de tickets plus tard. Par exemple, "Vente du 15 Aout".

#### Exemple Concret : Générer 20 tickets pour le forfait "3 Jours"

*   **Qty** : `20`
*   **User Mode** : `Username = Password`
*   **Name Length** : `5`
*   **Password Length** : `5`
*   **Profile** : `Forfait_3_Jours`
*   Cliquez sur le bouton **Generate**.

MIKHMON va instantanément créer 20 utilisateurs uniques, chacun avec une validité de 3 jours qui commencera à sa première connexion, et une vitesse de 2M/2M.

---

### Étape 3 : Imprimer et Gérer les Tickets

1.  Après la génération, vous serez redirigé vers la liste des utilisateurs. Les tickets que vous venez de créer seront affichés.
2.  Pour les imprimer, vous pouvez :
    *   Cliquer sur **Print** pour avoir une liste simple.
    *   Cliquer sur **QR Code** pour générer des tickets avec un QR code que les utilisateurs peuvent scanner pour se connecter plus facilement.
3.  Sélectionnez un modèle qui vous plaît, et vous êtes prêt à imprimer et à vendre vos tickets 
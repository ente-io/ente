import { Box, Typography } from '@mui/material';
import Link from '@mui/material/Link';
import LinkButton from 'components/pages/gallery/LinkButton';
import React from 'react';
import { SuggestionType } from 'types/search';
import { formatNumberWithCommas } from '.';

/**
 * Global French constants.
 */

const dateString = function (date) {
    return new Date(date / 1000).toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
};

const frenchConstants = {
    HERO_SLIDE_1_TITLE: () => (
        <>
            <div>Private backups</div>
            <div> for your memories</div>
        </>
    ),
    HERO_SLIDE_1: 'Chiffrement de bout en bout par défaut',
    HERO_SLIDE_2_TITLE: () => (
        <>
            <div>Safely stored </div>
            <div>at a fallout shelter</div>
        </>
    ),
    HERO_SLIDE_2: 'Conçu pour survivre',
    HERO_SLIDE_3_TITLE: () => (
        <>
            <div>Available</div>
            <div> everywhere</div>
        </>
    ),
    HERO_SLIDE_3: 'Android, iOS, Web, Ordinateur',
    COMPANY_NAME: 'ente',
    LOGIN: 'Connexion',
    SIGN_UP: 'Inscription',
    NEW_USER: 'Nouveau sur ente',
    EXISTING_USER: 'Utilisateur existant',
    NAME: 'Nom',
    ENTER_NAME: 'Saisir un nom',
    PUBLIC_UPLOADER_NAME_MESSAGE:
        'Ajouter un nom afin que vos amis sachent qui remercier pour ces magnifiques photos!',
    EMAIL: 'E-mail',
    ENTER_EMAIL: 'Saisir l''adresse e-mail',
    DATA_DISCLAIMER: "Nous ne partagerons jamais vos données avec qui que ce soit.",
    SUBMIT: 'Soumettre',
    EMAIL_ERROR: 'Saisir un e-mail valide',
    REQUIRED: 'Nécessaire',
    VERIFY_EMAIL: 'Vérifier l''e-mail',
    EMAIL_SENT: ({ email }) => (
        <span>
            Verification code sent to{' '}
            <Typography
                component={'span'}
                fontSize="inherit"
                color="text.secondary">
                {email}
            </Typography>
        </span>
    ),
    CHECK_INBOX: 'Veuillez consulter votre boite de réception (et indésirables) pour poursuivre la vérification',
    ENTER_OTT: 'Code de vérification',
    RESEND_MAIL: 'envoyer le code',
    VERIFY: 'Vérifier',
    UNKNOWN_ERROR: 'Quelque chose s''est mal passé, veuillez recommencer',
    INVALID_CODE: 'Code de vérification non valide',
    EXPIRED_CODE: 'Votre code de vérification a expiré',
    SENDING: 'Envoi...',
    SENT: 'Envoyé!',
    PASSWORD: 'Mot de passe',
    LINK_PASSWORD: 'Saisir le mot de passe pour déverrouiller l''album',
    ENTER_PASSPHRASE: 'Saisir votre mot de passe',
    RETURN_PASSPHRASE_HINT: 'Mot de passe',
    SET_PASSPHRASE: 'Définir le mot de passe',
    VERIFY_PASSPHRASE: 'Connexion',
    INCORRECT_PASSPHRASE: 'Mot de passe non valide',
    ENTER_ENC_PASSPHRASE:
        'Veuillez saisir un mot de passe que nous pourrons utiliser pour chiffrer vos données',
    PASSPHRASE_DISCLAIMER: () => (
        <>
            Nous ne stockons pas votre mot de passe, donc si vous le perdez,{' '}
            <strong>nous ne pourrons pas vous aider</strong>
            à récupérer vos données sans une clé de récupération.
        </>
    ),
    KEY_GENERATION_IN_PROGRESS_MESSAGE: 'Génération des clés de chiffrage...',
    PASSPHRASE_HINT: 'Mot de passe',
    CONFIRM_PASSPHRASE: 'Confirmer le mot de passe',
    PASSPHRASE_MATCH_ERROR: "Les mots de passe ne correspondent pas",
    CONSOLE_WARNING_STOP: 'STOP!',
    CONSOLE_WARNING_DESC:
        "Ceci est une fonction de navigateur dédiée aux développeurs. Veuillez ne pas copier-coller un code non vérifié à cet endroit.",
    SELECT_COLLECTION: 'Choisir un album à charge vers',
    CREATE_COLLECTION: 'Nouvel album',
    ENTER_ALBUM_NAME: 'Nom de l''album',
    CLOSE_OPTION: 'Fermer (Échap)',
    ENTER_FILE_NAME: 'Nom du fichier',
    CLOSE: 'Fermer',
    NO: 'Non',
    NOTHING_HERE: 'Il n''y a encore rien à voir ici 👀',
    UPLOAD: 'Charger',
    ADD_MORE_PHOTOS: 'Ajouter plus de photos',
    ADD_PHOTOS: 'Ajouter des photos',
    SELECT_PHOTOS: 'Sélectionner des photos',
    FILE_UPLOAD: 'Fichier chargé',
    UPLOAD_STAGE_MESSAGE: {
        0: 'Préparation du chargement',
        1: 'Lire les fichiers métadonnées de Google',
        2: (fileCounter) =>
            `${fileCounter.finished} / ${fileCounter.total} files metadata extracted`,
        3: (fileCounter) =>
            `${fileCounter.finished} / ${fileCounter.total} files backed up`,
        4: 'Annulation des chargements restants',
        5: 'Sauvegarde terminée',
    },
    UPLOADING_FILES: 'Chargement de fichiers',
    FILE_NOT_UPLOADED_LIST: 'Les fichiers suivants n''ont pas été chargés',
    SUBSCRIPTION_EXPIRED: 'Abonnement expiré',
    SUBSCRIPTION_EXPIRED_MESSAGE: (onClick) => (
        <>
            Votre abonnement a expiré, veuillez{' '}
            <LinkButton onClick={onClick}> le renouvelleer </LinkButton>
        </>
    ),
    STORAGE_QUOTA_EXCEEDED: 'Limite de stockage atteinte',
    INITIAL_LOAD_DELAY_WARNING: 'La première consultation peut prendre du temps',
    USER_DOES_NOT_EXIST: 'Désolé, impossible de trouver un utilisateur avec cet e-mail',
    UPLOAD_BUTTON_TEXT: 'Charger',
    NO_ACCOUNT: "Je n''ai pas de compte",
    ACCOUNT_EXISTS: 'J''ai déjà un compte',
    ALBUM_NAME: 'Nom de l''album',
    CREATE: 'Créer',
    DOWNLOAD: 'Télécharger',
    DOWNLOAD_OPTION: 'Télécharger (D)',
    DOWNLOAD_FAVORITES: 'Télécharger les favoris',
    DOWNLOAD_UNCATEGORIZED: 'Télécharger les hors catégories',
    COPY_OPTION: 'Copier en PNG (Ctrl/Cmd - C)',
    TOGGLE_FULLSCREEN: 'Plein écran (F)',
    ZOOM_IN_OUT: 'Zoom in/out',
    PREVIOUS: 'Précédent (←)',
    NEXT: 'Suivant (→)',
    NO_INTERNET_CONNECTION:
        'Veuillez vérifier votre connexion internet puis réessayer',
    TITLE: 'ente Photos',
    UPLOAD_FIRST_PHOTO_DESCRIPTION: () => (
        <>
            Protégez votre premier souvenir avec<strong> ente </strong>
        </>
    ),
    UPLOAD_FIRST_PHOTO: 'Protéger',
    UPLOAD_DROPZONE_MESSAGE: 'Drop to backup your files',
    WATCH_FOLDER_DROPZONE_MESSAGE: 'Drop to add watched folder',
    TRASH_FILES_TITLE: 'Supprimer les fichiers?',
    TRASH_FILE_TITLE: 'Supprimer le fichier?',
    DELETE_FILES_TITLE: 'Supprimer immédiatement?',
    DELETE_FILES_MESSAGE:
        'Les fichiers sélectionnés seront définitivement supprimés de votre compte ente.',
    DELETE_FILE: 'Supprimer les fichiers',
    DELETE: 'Supprimer',
    DELETE_OPTION: 'Supprimer (DEL)',
    FAVORITE: 'Favori',
    FAVORITE_OPTION: 'Favori (L)',
    UNFAVORITE_OPTION: 'Non favori (L)',
    UNFAVORITE: 'Non favori',
    MULTI_FOLDER_UPLOAD: 'Plusieurs dossiers détectés',
    UPLOAD_STRATEGY_CHOICE: 'Voulez-vous les charger dans',
    UPLOAD_STRATEGY_SINGLE_COLLECTION: 'Un seul album',
    OR: 'ou',
    UPLOAD_STRATEGY_COLLECTION_PER_FOLDER: 'Albums séparés',
    SESSION_EXPIRED_MESSAGE:
        'Votre session a expiré, veuillez vous reconnecter pour poursuivre',
    SESSION_EXPIRED: 'Session expiré',
    SYNC_FAILED: 'Échec de synchronisation avec le serveur, veuillez rafraîchir la page',
    PASSWORD_GENERATION_FAILED:
        "Votre navigateur ne permet pas de générer une clé forte correspondant aux standards de chiffrement de ente, veuillez réessayer en utilisant l'appli mobile ou un autre navigateur",
    CHANGE_PASSWORD: 'Modifier le mot de passe',
    GO_BACK: 'Retour',
    RECOVERY_KEY: 'Clé de récupération',
    SAVE_LATER: 'Plus tard',
    SAVE: 'Sauvegarder la clé',
    RECOVERY_KEY_DESCRIPTION:
        'Si vous oubliez votre mot de passe, la seule façon de récupérer vos données est grâce à cette clé.',
    RECOVER_KEY_GENERATION_FAILED:
        'Le code de récupération ne peut être généré, veuillez réessayer',
    KEY_NOT_STORED_DISCLAIMER:
        "Nous ne stockons pas cette clé, veuillez donc la sauvegarder dans un endroit sûr",
    FORGOT_PASSWORD: 'Mot de passe oublié',
    RECOVER_ACCOUNT: 'Récupérer le compte',
    RECOVERY_KEY_HINT: 'Clé de récupération',
    RECOVER: 'Récupérer',
    NO_RECOVERY_KEY: 'Pas de clé de récuparation?',
    INCORRECT_RECOVERY_KEY: 'Clé de récupération non valide',
    SORRY: 'Désolé',
    NO_RECOVERY_KEY_MESSAGE:
        'En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent être décryptées sans votre mot de passe ou clé de récupération',
    NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE: () => (
        <>
            Veuillez envoyer un e-mail à{' '}
            <a href="mailto:support@ente.io">support@ente.io</a> depuis votre
            adresse enregistrée
        </>
    ),
    CONTACT_SUPPORT: 'Contacter le support',
    REQUEST_FEATURE: 'Soumettre une idée',
    SUPPORT: 'Support',
    CONFIRM: 'Confirmer',
    SKIP_SUBSCRIPTION_PURCHASE: 'Poursuivre avec l''option gratuite',
    CANCEL: 'Annuler',
    LOGOUT: 'Déconnexion',
    DELETE_ACCOUNT: 'Supprimer le compte',
    DELETE_ACCOUNT_MESSAGE: () => (
        <>
            <p>
                Veuillez envoyer un e-mail à{' '}
                <Link href="mailto:account-deletion@ente.io">
                    account-deletion@ente.io
                </Link>{' '}
                depuis votre
            adresse enregistrée.{' '}
            </p>
            <p>Votre demande sera traitée dans les 72 heures.</p>
        </>
    ),
    LOGOUT_MESSAGE: 'Voulez-vous vraiment vous déconnecter?',
    CHANGE: 'Modifier',
    CHANGE_EMAIL: 'Modifier l''e-mail',
    OK: 'OK',
    SUCCESS: 'Parfait',
    ERROR: 'Erreur',
    MESSAGE: 'Message',
    INSTALL_MOBILE_APP: () => (
        <>
            Installez notre application{' '}
            <a
                href="https://play.google.com/store/apps/details?id=io.ente.photos"
                target="_blank"
                style={{ color: '#51cd7c' }}
                rel="noreferrer">
                Android
            </a>{' '}
            ou{' '}
            <a
                href="https://apps.apple.com/in/app/ente-photos/id1542026904"
                style={{ color: '#51cd7c' }}
                target="_blank"
                rel="noreferrer">
                iOS {' '}
            </a>
            pour sauvegarder automatiquement toutes vos photos
        </>
    ),
    DOWNLOAD_APP_MESSAGE:
        'Désolé, cette opération est actuellement supportée uniquement sur notre appli pour ordinateur',
    DOWNLOAD_APP: 'Télécharger l''appli pour ordinateur',
    EXPORT: 'Exporter des données',

    // ========================
    // Subscription
    // ========================
    SUBSCRIPTION: 'Abonnement',
    SUBSCRIBE: 'S''abonner',
    SUBSCRIPTION_PLAN: 'Plan d''abonnement',
    USAGE_DETAILS: 'Utilisation',
    MANAGE: 'Gérer',
    MANAGEMENT_PORTAL: 'Gérer le mode de paiement',
    MANAGE_FAMILY_PORTAL: 'Gérer la famille',
    LEAVE_FAMILY_PLAN: 'Quitter le plan famille',
    LEAVE: 'Quitter',
    LEAVE_FAMILY_CONFIRM: 'Êtes-vous certains de vouloir quitter le plan famille?',
    CHOOSE_PLAN: 'Choisir votre plan',
    MANAGE_PLAN: 'Gérer votre abonnement',
    ACTIVE: 'Actif',

    OFFLINE_MSG: 'Vous êtes hors-ligne, les mémoires cache sont affichées',

    FREE_SUBSCRIPTION_INFO: (expiryTime) => (
        <>
            Vous êtes sur le plan <strong>gratuit</strong> qui expire le{' '}
            {dateString(expiryTime)}
        </>
    ),

    FAMILY_SUBSCRIPTION_INFO: 'Vous êtes sur le plan famille géré par',

    RENEWAL_ACTIVE_SUBSCRIPTION_STATUS: (expiryTime) => (
        <>Renouveller le {dateString(expiryTime)}</>
    ),
    RENEWAL_CANCELLED_SUBSCRIPTION_STATUS: (expiryTime) => (
        <>Pris fin le {dateString(expiryTime)}</>
    ),

    RENEWAL_CANCELLED_SUBSCRIPTION_INFO: (expiryTime) => (
        <>Votre abonnement sera annulé le {dateString(expiryTime)}</>
    ),

    STORAGE_QUOTA_EXCEEDED_SUBSCRIPTION_INFO: (onClick) => (
        <>
            Vous avez dépassé votre quota de stockage,, veuillez{' '}
            <LinkButton onClick={onClick}>mettre à  niveau</LinkButton>
        </>
    ),
    SUBSCRIPTION_PURCHASE_SUCCESS: (expiryTime) => (
        <>
            <p>Nous avons reçu votre paiement</p>
            <p>
                Votre abonnement est valide jusqu''au{' '}
                <strong>{dateString(expiryTime)}</strong>
            </p>
        </>
    ),
    SUBSCRIPTION_PURCHASE_CANCELLED:
        'Votre achat est annulé, veuillez réessayer si vous souhaitez vous abonner',
    SUBSCRIPTION_VERIFICATION_FAILED:
        'Nous ne sommes pas encore en mesure de vérifier votre achat, cela peut prendre quelques heures',
    SUBSCRIPTION_PURCHASE_FAILED:
        'Échec lors de l''achat de l''abonnement, veuillez réessayer',
    SUBSCRIPTION_UPDATE_FAILED:
        'Échec lors de la mise à niveau de l''abonnement, veuillez réessayer',
    UPDATE_PAYMENT_METHOD_MESSAGE:
        'Désolé, échec de paiement lors de la saisie de votre carte, veuillez mettr eà jour votre moyen de paiement et réessayer',
    STRIPE_AUTHENTICATION_FAILED:
        'Nous n''avons pas pu authentifier votre moyen de paiement. Veuillez choisir un moyen différent et réessayer',
    UPDATE_PAYMENT_METHOD: 'Mise à jour du moyen de paiement',
    MONTHLY: 'Mensuel',
    YEARLY: 'Annuel',
    UPDATE_SUBSCRIPTION_MESSAGE: 'Êtes-vous certains de vouloir changer de plan?',
    UPDATE_SUBSCRIPTION: 'Changer de plan',

    CANCEL_SUBSCRIPTION: 'Annuler l''abonnement',
    CANCEL_SUBSCRIPTION_MESSAGE: () => (
        <>
            <p>
                Toutes vos données seront supprimées de nos serveurs à la fin de cette période d'abonnement.
            </p>
            <p>Voulez-vous vraiment annuler votre abonnement?</p>
        </>
    ),
    SUBSCRIPTION_CANCEL_FAILED: 'Échec lors de l''annulation de l''abonnement',
    SUBSCRIPTION_CANCEL_SUCCESS: 'Votre abonnement a bien été annulé',

    REACTIVATE_SUBSCRIPTION: 'Réactiver l''abonnement',
    REACTIVATE_SUBSCRIPTION_MESSAGE: (expiryTime) =>
        `Une fois réactivée, vous serrez facturé de ${dateString(expiryTime)}`,
    SUBSCRIPTION_ACTIVATE_SUCCESS: 'Votre abonnement est bien activé',
    SUBSCRIPTION_ACTIVATE_FAILED: 'Échec lors de la réactivation de l''abonnement',

    SUBSCRIPTION_PURCHASE_SUCCESS_TITLE: 'Merci',
    CANCEL_SUBSCRIPTION_ON_MOBILE: 'Annuler l''abonnement mobile',
    CANCEL_SUBSCRIPTION_ON_MOBILE_MESSAGE:
        'Veuillez annuler votre abonnement depuis l''appli mobile pour activer un abonnement ici',
    MAIL_TO_MANAGE_SUBSCRIPTION: (
        <>
            Veuillez nous contacter à{' '}
            <Link href={`mailto:support@ente.io`}>support@ente.io</Link> pour
            gérer votre abonnement
        </>
    ),
    RENAME: 'Renommer',
    RENAME_FILE: 'Renommer le fichier',
    RENAME_COLLECTION: 'Renommer l''album',
    DELETE_COLLECTION_TITLE: 'Supprimer l''album?',
    DELETE_COLLECTION: 'Supprimer l''album',
    DELETE_COLLECTION_FAILED: 'L''album n''a pas pu être supprimé, veuillez réessayer',
    DELETE_COLLECTION_MESSAGE: () => (
        <p>
            Supprimer aussi les photos (et vidéos) présentes dans cet album depuis
            <span style={{ color: '#fff' }}> tous </span> les autres albums dont ils font partie?
        </p>
    ),
    DELETE_PHOTOS: 'Supprimer des photos',
    KEEP_PHOTOS: 'Conserver des photos',
    SHARE: 'Partager',
    SHARE_COLLECTION: 'Partager l''album',
    SHARE_WITH_PEOPLE: 'Partager avec vos proches',
    SHAREES: 'Partager avec',
    PUBLIC_URL: 'Lien public',
    SHARE_WITH_SELF: 'Oups, vous ne pouvez pas partager avec  vous même',
    ALREADY_SHARED: (email) =>
        `Oups, vous partager déjà cela avec ${email}`,
    SHARING_BAD_REQUEST_ERROR: 'Partage d''album non autorisé',
    SHARING_DISABLED_FOR_FREE_ACCOUNTS: 'Le partage est désactivé pour les comptes gratuits',
    DOWNLOAD_COLLECTION: 'Télécharger l''album',
    DOWNLOAD_COLLECTION_MESSAGE: () => (
        <>
            <p>Êtes-vous certains de vouloir télécharger l''album complet?</p>
            <p>Tous les fichiers seront mis en file d''attente pour un téléchargement fractionné</p>
        </>
    ),
    DOWNLOAD_COLLECTION_FAILED: 'Échec de téléchargement de l''album, veuillez réessayer',
    CREATE_ALBUM_FAILED: 'Échec de création de l''album , veuillez réessayer',

    SEARCH_RESULTS: 'Résultats de la recherche',
    SEARCH_HINT: () => <span>Recherche d''albums, dates ...</span>,
    SEARCH_TYPE: (type: SuggestionType) => {
        switch (type) {
            case SuggestionType.COLLECTION:
                return 'Album';
            case SuggestionType.LOCATION:
                return 'Location';
            case SuggestionType.DATE:
                return 'Date';
            case SuggestionType.IMAGE:
            case SuggestionType.VIDEO:
                return 'File';
        }
    },
    PHOTO_COUNT: (count: number) =>
        `${
            count === 1
                ? `1 memory`
                : `${formatNumberWithCommas(count)} memories`
        }`,
    TERMS_AND_CONDITIONS: () => (
        <Typography variant="body2">
            I agree to the{' '}
            <Link href="https://ente.io/terms" target="_blank" rel="noreferrer">
                terms
            </Link>{' '}
            and{' '}
            <Link
                href="https://ente.io/privacy"
                target="_blank"
                rel="noreferrer">
                privacy policy
            </Link>{' '}
        </Typography>
    ),
    CONFIRM_PASSWORD_NOT_SAVED: () => (
        <p>
            Je comprend que si je perd le mot de passe,je peux perdre mes données puisque mes données sont
            {' '}
            <a
                href="https://ente.io/architecture"
                target="_blank"
                rel="noreferrer">
                chiffrées de bout en bout
            </a>{' '}
            avec ente
        </p>
    ),
    NOT_FILE_OWNER: 'Vous ne pouvez pas supprimer les fichiers d''un album partagé',
    ADD_TO_COLLECTION: 'Ajouter à l''album',
    SELECTED: 'sélectionné',
    VIDEO_PLAYBACK_FAILED: 'Le format vidéo n''est pas supporté',
    VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD:
        'Cette vidéo ne peut pas être lue sur votre navigateur',
    METADATA: 'Metadonnées',
    INFO: 'Info ',
    INFO_OPTION: 'Info (I)',
    FILE_ID: 'ID fichier',
    FILE_NAME: 'Nom de fichier',
    CAPTION: 'Description',
    CAPTION_PLACEHOLDER: 'Ajouter une description',
    CREATION_TIME: 'Heure de création',
    UPDATED_ON: 'Mis à jour le',
    LOCATION: 'Emplacement',
    SHOW_ON_MAP: 'Visualiser sur OpenStreetMap',
    DETAILS: 'Détails',
    VIEW_EXIF: 'Visualiser toutes les données EXIF',
    NO_EXIF: 'Aucune donnée EXIF',
    EXIF: 'EXIF',
    DEVICE: 'Appareil',
    IMAGE_SIZE: 'Taille de l''image',
    FLASH: 'Flash',
    FOCAL_LENGTH: 'Distance focale',
    APERTURE: 'Ouverture',
    ISO: 'ISO',
    SHOW_ALL: 'Afficher tout',
    LOGIN_TO_UPLOAD_FILES: (count: number) =>
        count === 1
            ? `1 fichier reçu. Connectez-vous pour le charger`
            : `${count} fichiers reçus. Connectez-vous pour les charger`,
    FILES_TO_BE_UPLOADED: (count: number) =>
        count === 1
            ? `1 fichier reçu. Chargement en tant que jiffy`
            : `${count} fichiers reçus. Chargement en tant que jiffy`,
    TWO_FACTOR: 'Double authentification',
    TWO_FACTOR_AUTHENTICATION: 'Authentification double-facteur',
    TWO_FACTOR_QR_INSTRUCTION:
        'Scannez le QRCode ci-dessous avec une appli d''authentification (ex: FreeOTP) ',
    ENTER_CODE_MANUALLY: 'Saisir le code manuellement',
    TWO_FACTOR_MANUAL_CODE_INSTRUCTION:
        'Veuillez saisir ce code dans votre appli d''authentification',
    SCAN_QR_CODE: 'Scannez le QRCode de préférence',
    CONTINUE: 'Continuer',
    BACK: 'Retour',
    ENABLE_TWO_FACTOR: 'Activer la double-authentification',
    ENABLE: 'Activer',
    LOST_DEVICE: 'Perte de l''appareil identificateur',
    INCORRECT_CODE: 'Code non valide',
    RECOVER_TWO_FACTOR: 'Récupérer la double-authentification',
    TWO_FACTOR_INFO:
        'Ajouter une couche de sécurité supplémentaire afin de nécessiter plus que simplement votre e-mail et mot de passe pour vous connecter à votre compte',
    DISABLE_TWO_FACTOR_LABEL: 'Désactiver la double-authentification',
    UPDATE_TWO_FACTOR_LABEL: 'Mise à jour de votre appareil identificateur',
    DISABLE: 'Désactiver',
    RECONFIGURE: 'Reconfigurer',
    UPDATE_TWO_FACTOR: 'Mise à jour de la double-authentification',
    UPDATE_TWO_FACTOR_MESSAGE:
        'Continuer annulera tous les identificateurs précédemment configurés',
    UPDATE: 'Mise à jour',
    DISABLE_TWO_FACTOR: 'Désactiver la double-authentification',
    DISABLE_TWO_FACTOR_MESSAGE:
        'Êtes-vous certains de vouloir désactiver la double-authentification',
    TWO_FACTOR_SETUP_FAILED: 'Échec de configuration de la double-authentification, veuillez réessayer',
    TWO_FACTOR_SETUP_SUCCESS:
        'La double-authentification est configurée',
    TWO_FACTOR_DISABLE_SUCCESS: 'La double-authentification est désactivée',
    TWO_FACTOR_DISABLE_FAILED: 'Échec de désactivation de la double-authentification, veuillez réessayer',
    EXPORT_DATA: 'Exporter les données',
    SELECT_FOLDER: 'Sélectionner un dossier',
    DESTINATION: 'Destination',
    EXPORT_SIZE: 'Taille d''export',
    START: 'Démarrer',
    EXPORT_IN_PROGRESS: 'Export en cours...',
    PAUSE: 'Pause',
    RESUME: 'Reprendre',
    MINIMIZE: 'Réduire',
    LAST_EXPORT_TIME: 'Horaire du dernier export',
    SUCCESSFULLY_EXPORTED_FILES: 'Exports effectués',
    FAILED_EXPORTED_FILES: 'Échec des exports',
    EXPORT_AGAIN: 'Resynchro',
    RETRY_EXPORT_: 'Réessayer les exports ayant échoués',
    LOCAL_STORAGE_NOT_ACCESSIBLE: 'Stockage local non accessible',
    LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE:
        'Votre navigateur ou un complément bloque ente qui ne peut sauvegarder les données sur votre stockage local. Veuillez relancer cette page après avoir changé de mode de navigation.',
    RETRY: 'Réessayer',
    SEND_OTT: 'Envoyer OTP',
    EMAIl_ALREADY_OWNED: 'Cet e-mail est déjà pris',
    EMAIL_UDPATE_SUCCESSFUL: 'Votre e-mail a été mis à jour',
    UPLOAD_FAILED: 'Échec du chargement',
    ETAGS_BLOCKED: (link: string) => (
        <>
            <Box mb={1}>
                Nosu n''avons pas pu charger les fichiers suivants à cause de la configuration de votre navigateur
               .
            </Box>
            <Box>
                Veuillez désactiver tous les compléments qui pourraient empêcher ente d''utiliser
                 les<code>eTags</code> pour charger de larges fichiers, ou bien utilisez notre{' '}
                <Link href={link} target="_blank">
                    appli pour ordinateur
                </Link>{' '}
                pour une meilleure expérience lors des chargements.
            </Box>
        </>
    ),
    SKIPPED_VIDEOS_INFO: (link: string) => (
        <>
            <Box mb={1}>
                Actuellement, nous ne supportons pas l''ajout de videos via des liens publics.{' '}
            </Box>
            <Box>
                Pour partager des vidéos, veuillez{' '}
                <Link href={link} target="_blank">
                    vous connecter à
                </Link>{' '}
                 ente et partager en utilisant l''e-mail concerné
                .
            </Box>
        </>
    ),

    LIVE_PHOTOS_DETECTED:
        'Les fichiers photos et vidéos depuis votre espace Live Photos ont été fusionnés en un seul fichier',

    RETRY_FAILED: 'Réessayer les chargements ayant échoués',
    FAILED_UPLOADS: 'Chargements échoués ',
    SKIPPED_FILES: 'Chargements ignorés',
    THUMBNAIL_GENERATION_FAILED_UPLOADS: 'Échec de création d''une miniature',
    UNSUPPORTED_FILES: 'Fichiers non supportés',
    SUCCESSFUL_UPLOADS: 'Chargements réussis',
    SKIPPED_INFO:
        'Ignorer ceux-ci car il y a des fichiers avec des noms identiques dans le même album',
    UNSUPPORTED_INFO: 'ente ne supporte pas encore ces formats de fichiers',
    BLOCKED_UPLOADS: 'Chargements bloqués',
    SKIPPED_VIDEOS: 'Vidéos ignorées',
    INPROGRESS_METADATA_EXTRACTION: 'En cours',
    INPROGRESS_UPLOADS: 'Chargements en cours',
    TOO_LARGE_UPLOADS: 'Gros fichiers',
    LARGER_THAN_AVAILABLE_STORAGE_UPLOADS: 'Stockage insuffisant',
    LARGER_THAN_AVAILABLE_STORAGE_INFO:
        'Ces fichiers n''ont pas été chargés car ils dépassent la taille maximale pour votre plan de stockage',
    TOO_LARGE_INFO:
        'Ces fichiers n''ont pas été chargés car ils dépassent notre taille limite par fichier',
    THUMBNAIL_GENERATION_FAILED_INFO:
        'Ces fichiers sont bien chargés, mais nous ne pouvons pas créer de miniatures pour eux.',
    UPLOAD_TO_COLLECTION: 'Charger dans l''album',
    UNCATEGORIZED: 'Aucune catégorie',
    MOVE_TO_UNCATEGORIZED: 'Déplacer vers aucune catégorie',
    ARCHIVE: 'Archiver',
    ARCHIVE_COLLECTION: 'Archiver l''album',
    ARCHIVE_SECTION_NAME: 'Archiver',
    ALL_SECTION_NAME: 'Tous',
    MOVE_TO_COLLECTION: 'Déplacer vers l''album',
    UNARCHIVE: 'Désarchiver',
    UNARCHIVE_COLLECTION: 'Désarchiver l''album',
    MOVE: 'Déplacer',
    ADD: 'Ajouter',
    SORT: 'Trier',
    REMOVE: 'Retirer',
    YES_REMOVE: 'Oui, retirer',
    CONFIRM_REMOVE: 'Confirmer le retrait',
    REMOVE_FROM_COLLECTION: 'Retirer de l''album',
    TRASH: 'Corbeille',
    MOVE_TO_TRASH: 'Déplacer vers la corbeille',
    TRASH_FILES_MESSAGE:
        'Les fichiers sélectionnés seront retirés de tous les albums puis déplacés dans la corbeille.',
    TRASH_FILE_MESSAGE:
        'Le fichier sera retiré de tous les albums puis déplacé dans la corbeille.',
    DELETE_PERMANENTLY: 'Supprimer définitivement',
    RESTORE: 'Restaurer',
    CONFIRM_RESTORE: 'Confirmer la restauration',
    RESTORE_MESSAGE: 'Restaurer les fichiers sélectionnés ?',
    RESTORE_TO_COLLECTION: 'Restaurer vers l''album',
    EMPTY_TRASH: 'Corbeille vide',
    EMPTY_TRASH_TITLE: 'Corbeille vide?',
    EMPTY_TRASH_MESSAGE:
        'Ces fichiers seront définitivement supprimés de votre compte ente.',
    LEAVE_SHARED_ALBUM: 'Oui, quitter',
    LEAVE_ALBUM: 'Quitter l''album',
    LEAVE_SHARED_ALBUM_TITLE: 'Quitter l''album partagé?',
    LEAVE_SHARED_ALBUM_FAILED: 'Échec pour quitter l''album, veuillez réessayer',
    LEAVE_SHARED_ALBUM_MESSAGE:
        'Vous allez quitter cet album, il ne sera plus visible pour vous.',
    CONFIRM_SELF_REMOVE_MESSAGE: () => (
        <>
            <p>
                Choisir les objets qui seront retirés de cet album. Ceux qui sont présents uniquement dans cet album seront déplacés comme hors catégorie.
            </p>
        </>
    ),
    CONFIRM_SELF_AND_OTHER_REMOVE_MESSAGE: () => (
        <>
            <p>
                Certains des objets que vous êtes en train de retirer ont été ajoutés par d''autres personnes,
                vous perdrez l''accès vers ces objets.
            </p>
        </>
    ),

    SORT_BY_CREATION_TIME_ASCENDING: 'Plus anciens',
    SORT_BY_CREATION_TIME_DESCENDING: 'Plus récents',
    SORT_BY_UPDATION_TIME_DESCENDING: 'Dernière mise à jour',
    SORT_BY_NAME: 'Nom',
    COMPRESS_THUMBNAILS: 'Compresser les miniatures',
    THUMBNAIL_REPLACED: 'Les miniatures sont compressées',
    FIX_THUMBNAIL: 'Compresser',
    FIX_THUMBNAIL_LATER: 'Compresser plus tard',
    REPLACE_THUMBNAIL_NOT_STARTED: () => (
        <>
            Certaines miniatures de vidéos peuvent être compressées pour gagner de la place.
            Voulez-vous que ente les compresse?
        </>
    ),
    REPLACE_THUMBNAIL_COMPLETED: () => (
        <>Toutes les miniatures ont été compressées</>
    ),
    REPLACE_THUMBNAIL_NOOP: () => (
        <>Vous n''avez aucune miniature qui peut être encore plus compressée</>
    ),
    REPLACE_THUMBNAIL_COMPLETED_WITH_ERROR: () => (
        <>Impossible de compresser certaines miniatures, veuillez réessayer</>
    ),
    FIX_CREATION_TIME: 'Réajuster l''heure',
    FIX_CREATION_TIME_IN_PROGRESS: 'Réajustement de l''heure',
    CREATION_TIME_UPDATED: `L''heure du fichier a été réajustée`,

    UPDATE_CREATION_TIME_NOT_STARTED: () => (
        <>Sélectionnez l''option que vous souhaitez utiliser</>
    ),
    UPDATE_CREATION_TIME_COMPLETED: () => <>Mise à jour effectuée pour tous les fichiers</>,

    UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR: () => (
        <>L''heure du fichier n''a pas été mise à jour pour certains fichiers, veuillez réessayer</>
    ),
    FILE_NAME_CHARACTER_LIMIT: '100 caractères max',
    CAPTION_CHARACTER_LIMIT: '5000 caractères max',

    DATE_TIME_ORIGINAL: 'EXIF:DateTimeOriginal',
    DATE_TIME_DIGITIZED: 'EXIF:DateTimeDigitized',
    CUSTOM_TIME: 'Heure personnalisée',
    REOPEN_PLAN_SELECTOR_MODAL: 'Rouvrir les plans',
    OPEN_PLAN_SELECTOR_MODAL_FAILED: 'Échec pour rouvrir les plans',
    COMMENT: 'Commentaire',
    ABUSE_REPORT_DESCRIPTION:
        'Soumettre ce rapport notifiera le propriétaire de l''album.',
    OTHER_REASON_REQUIRES_COMMENTS:
        'Raison = autre, nécessite un commentaire obligatoire ',
    REPORT_SUBMIT_SUCCESS_CONTENT: 'Votre commentaire a été soumis',
    REPORT_SUBMIT_SUCCESS_TITLE: 'Commentaire envoyé',
    REPORT_SUBMIT_FAILED: 'Échec lors de l''envoi du commentaire, veuillez réessayer',
    INSTALL: 'Installer',
    ALBUM_URL: 'Lien de l''album',
    PUBLIC_SHARING: 'Lien public',
    SHARING_DETAILS: 'Détails du partage',
    MODIFY_SHARING: 'Modifier le partage',
    NOT_FOUND: '404 - non trouvé',
    LINK_EXPIRED: 'Lien expiré',
    LINK_EXPIRED_MESSAGE: 'Ce lien à soit expiré soit est supprimé!',
    MANAGE_LINK: 'Gérer le lien',
    LINK_TOO_MANY_REQUESTS: 'Cet album est trop populaire pour que nous puissions le gérer!',
    DISABLE_PUBLIC_SHARING: 'Désactiver le partage public',
    DISABLE_PUBLIC_SHARING_MESSAGE:
        'Êtes-vous certains de vouloir désactiver le lien public?',
    FILE_DOWNLOAD: 'Autoriser les téléchargements',
    LINK_PASSWORD_LOCK: 'Verrou par mot de passe',
    PUBLIC_COLLECT: 'Autoriser l''ajout de photos',
    LINK_DEVICE_LIMIT: 'Limite d''appareil',
    LINK_EXPIRY: 'Expiration du lien',
    LINK_EXPIRY_NEVER: 'Jamais',
    DISABLE_FILE_DOWNLOAD: 'Désactiver le téléchargement',
    DISABLE_FILE_DOWNLOAD_MESSAGE: () => (
        <>
            <p>
                Êtes-vous certains de vouloir désactiver le bouton de téléchargement pour les fichiers
                ?{' '}
            </p>{' '}
            <p>
                Ceux qui les visualisent pourront tout de même prendre des imprim-écrans ou sauvegarder une copie de vos photos en utilisant des outils externes
                {' '}
            </p>
        </>
    ),
    ABUSE_REPORT: 'Signaler un abus',
    ABUSE_REPORT_BUTTON_TEXT: 'Signaler un abus?',
    MALICIOUS_CONTENT: 'Contient du contenu malveillant',
    COPYRIGHT:
        'Enfreint les droits d''une personne que je réprésente',
    ENTER_EMAIL_ADDRESS: 'E-mail*',
    SELECT_REASON: 'Choisir une raison*',
    ENTER_FULL_NAME: 'Nom*',
    ENTER_DIGITAL_SIGNATURE:
        'Saisir votre nom complet dans la case vaudra pour signature numérique*',
    ENTER_ON_BEHALF_OF: 'Je rends compte au nom de*',
    ENTER_ADDRESS: 'Adresse*',
    ENTER_JOB_TITLE: 'Type d''emploi*',
    ENTER_CITY: 'Ville*',
    ENTER_PHONE: 'Num de téléphone*',

    ENTER_STATE: 'État*',
    ENTER_POSTAL_CODE: 'Zip/Code postal*',
    ENTER_COUNTRY: 'Pays*',
    JUDICIAL_DESCRIPTION: () => (
        <>
            En cliquant dans les cases suivantes, je déclare{' '}
            <strong>SOUS PEINE DE FAUX TEMOIGNAGE </strong>aux yeux de la loi que:
        </>
    ),
    TERM_1: 'Je déclare par la présente être de bonne foi quant au partage de ressources protégés par des droits d''auteur n''est pas autorisé à l''emplacement ci-dessus par le titulaire du droit d''auteur, son agent ou la loi (par exemple, en tant qu''utilisation équitable). ',
    TERM_2: 'Je déclare par la présente que les informations contenues dans cet avis sont exactes et, sous peine de faux témoignage, que j''en suis le propriétaire, ou autorisé à agir au nom du propriétaire, du droit d''auteur ou d''un droit exclusif au titre du droit d''auteur qui est prétendument violé. ',
    TERM_3: 'Je reconnais que toute personne qui, sciemment, déforme matériellement que les ressources ou l''activité enfreinte peut être tenue responsable des dommages. ',
    SHARED_USING: 'Partager en utilisant ',
    ENTE_IO: 'ente.io',
    LIVE: 'LIVE',
    DISABLE_PASSWORD: 'Désactiver le verrou par mot de passe',
    DISABLE_PASSWORD_MESSAGE:
        'Êtes-vous certains de vouloir désactiver le verrou par mot de passe?',
    PASSWORD_LOCK: 'Mot de passe verrou',
    LOCK: 'Verrouiller',
    DOWNLOAD_UPLOAD_LOGS: 'Journaux de débugs',
    CHOOSE_UPLOAD_TYPE: 'Charger',
    UPLOAD_FILES: 'Fichier',
    UPLOAD_DIRS: 'Dossier',
    UPLOAD_GOOGLE_TAKEOUT: 'Google takeout',
    CANCEL_UPLOADS: 'Annuler les chargements',
    DEDUPLICATE_FILES: 'Déduplication de fichiers',
    NO_DUPLICATES_FOUND: "Vous n''avez aucun fichier dédupliqué pouvant être nettoyé",
    CLUB_BY_CAPTURE_TIME: 'Club by capture time',
    FILES: 'Fichiers',
    EACH: 'Chacun',
    DEDUPLICATION_LOGIC_MESSAGE: (captureTime: boolean) => (
        <>
            Les fichiers suivants ont été clubbed, basé sur leurs tailles
            {captureTime && ' and capture time'}, veuillez corriger et supprimer les objets
            que vous pensez être dupliqués{' '}
        </>
    ),
    STOP_ALL_UPLOADS_MESSAGE:
        'Êtes-vous certains de vouloir arrêter tous les chargements en cours?',
    STOP_UPLOADS_HEADER: 'Arrêter les chargements?',
    YES_STOP_UPLOADS: 'Oui, arrêter tout',
    ALBUMS: 'Albums',
    NEW: 'Nouveau',
    VIEW_ALL_ALBUMS: 'Voir tous les albums',
    ALL_ALBUMS: 'Tous les albums',
    ENDS: 'Ends',
    ENTER_TWO_FACTOR_OTP: 'Saisir le code à 6 caractères de votre appli d''authentification.',
    CREATE_ACCOUNT: 'Créer un compte',
    COPIED: 'Copieé',
    CANVAS_BLOCKED_TITLE: 'Impossible de créer une miniature',
    CANVAS_BLOCKED_MESSAGE: () => (
        <>
            <p>
                Il semblerait que votre navigateur ait désactivé l''accès au canevas, qui est nécessaire
                pour créer les miniatures de vos photos
            </p>
            <p>
                Veuillez activer l''accès au canevas du navigateur, ou consulter notre appli pour ordinateur
                
            </p>
        </>
    ),
    WATCH_FOLDERS: 'Voir les dossiers',
    UPGRADE_NOW: 'Mettre à niveau maintenant',
    RENEW_NOW: 'Renouveler maintenant',
    STORAGE: 'Stockage',
    USED: 'utilisé',
    YOU: 'Vous',
    FAMILY: 'Famille',
    FREE: 'gratuit',
    OF: 'de',
    WATCHED_FOLDERS: 'Voir les dossiers',
    NO_FOLDERS_ADDED: 'Aucun dossiers d''ajouté!',
    FOLDERS_AUTOMATICALLY_MONITORED:
        'Les dossiers que vous ajoutez ici seront supervisés automatiquement',
    UPLOAD_NEW_FILES_TO_ENTE: 'Charger de nouveaux fichiers sur ente',
    REMOVE_DELETED_FILES_FROM_ENTE: 'Retirer de ente les fichiers supprimés',
    ADD_FOLDER: 'Ajouter un dossier',
    STOP_WATCHING: 'Arrêter de voir',
    STOP_WATCHING_FOLDER: 'Arrêter de voir le dossier?',
    STOP_WATCHING_DIALOG_MESSAGE:
        'Vos fichiers existants ne seront pas supprimés, mais ente arrêtera automatiquement de mettre à jour le lien de l''album à chaque changements sur ce dossier.',
    YES_STOP: 'Oui, arrêter',
    MONTH_SHORT: 'mo',
    YEAR: 'année',
    FAMILY_PLAN: 'Plan famille',
    DOWNLOAD_LOGS: 'Journaux de téléchargements',
    DOWNLOAD_LOGS_MESSAGE: () => (
        <>
            <p>
                Cela va télécharger les journaux de débug, que vous pourrez nosu envoyer par e-mail pour nous aider à résoudre votre problàme
                .
            </p>
            <p>
                Veuillez noter que les noms de fichiers seront inclus
                .
            </p>
        </>
    ),
    CHANGE_FOLDER: 'Modifier le dossier',
    TWO_MONTHS_FREE: 'Obtenir 2 mois gratuits sur les plans annuels',
    GB: 'Go',
    POPULAR: 'Populaire',
    FREE_PLAN_OPTION_LABEL: 'Poursuivre avec la version d''essai gratuite',
    FREE_PLAN_DESCRIPTION: '1 Go pour 1 an',
    CURRENT_USAGE: (usage) => (
        <>
            L''utilisation actuelle est de <strong>{usage}</strong>
        </>
    ),
    WEAK_DEVICE:
        "Le navigateur que vous utilisez n''est pas assez puissant pour chiffrer vos photos. Veuillez essayer de vous connecter à ente sur votre ordinateur, ou télécharger l'appli ente mobile/ordinateur.",
    DRAG_AND_DROP_HINT: 'Sinon glissez déposez dans la fenêtre ente',
    ASK_FOR_FEEDBACK: (
        <>
            <p>Nous serrions navré de vous voir partir. Avez-vous rencontré des problèmes?</p>
            <p>
                Veuillez nous écrire à{' '}
                <Link href="mailto:feedback@ente.io">feedback@ente.io</Link>,
                nous pouvons peut-être vous aider.
            </p>
        </>
    ),
    SEND_FEEDBACK: 'Oui, envoyer un commentaire',
    CONFIRM_ACCOUNT_DELETION_TITLE:
        'Êtes-vous certains de vouloir supprimer votre compte?',
    CONFIRM_ACCOUNT_DELETION_MESSAGE: (
        <>
            <p>
                Vos données chargées seront programmées pour suppression, et votre comptre sera supprimé définitivement
                .
            </p>
            <p>Cette action n''est pas reversible.</p>
        </>
    ),
    AUTHENTICATE: 'Authentification',
    UPLOADED_TO_SINGLE_COLLECTION: 'Chargé dans une seule collection',
    UPLOADED_TO_SEPARATE_COLLECTIONS: 'Chargé dans des collections séparées',
    NEVERMIND: 'Peu-importe',
    UPDATE_AVAILABLE: 'Une mise à jour est disponible',
    UPDATE_INSTALLABLE_MESSAGE:
        'Une nouvelle version de ente est prête à être installée.',
    INSTALL_NOW: `Installer maintenant`,
    INSTALL_ON_NEXT_LAUNCH: 'Installer au prochain démarrage',
    UPDATE_AVAILABLE_MESSAGE:
        'Une nouvelle version de ente est sortie, mais elle ne peut pas être automatiquement téléchargée puis installée.',
    DOWNLOAD_AND_INSTALL: 'Télécharger et installer',
    IGNORE_THIS_VERSION: 'Ignorer cette version',
    TODAY: 'Aujourd''ui',
    YESTERDAY: 'Hier',
    AT: 'à',
    NAME_PLACEHOLDER: 'Nom...',
    ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED:
        'Impossible de créer des albums depuis un mix fichier/dossier',
    ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED_MESSAGE: () => (
        <>
            <p>Vous avez glissé déposé un mélange de fichiers et dossiers.</p>
            <p>
                Veuillez sélectionner soit uniquement des fichiers, ou des dossiers lors du choix d''options pour créer des albums séparés
                
            </p>
        </>
    ),
    ADD_X_PHOTOS: (x: number) => `Add ${x} ${x > 1 ? 'photos' : 'photo'}`,
    CHOSE_THEME: 'Choisir un thème',
    YOURS: 'Le vôtre',
};

export default frenchConstants;

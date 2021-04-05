import { template } from './vernacularStrings';

/**
 * Global English constants.
 */
const englishConstants = {
    COMPANY_NAME: 'ente',
    LOGIN: 'login',
    SIGN_UP: 'sign up',
    NAME: 'name',
    ENTER_NAME: 'your name',
    EMAIL: 'email',
    ENTER_EMAIL: 'email',
    DATA_DISCLAIMER: `we'll never share your data with anyone else.`,
    SUBMIT: 'submit',
    EMAIL_ERROR: 'enter a valid email',
    REQUIRED: 'required',
    VERIFY_EMAIL: 'verify email',
    EMAIL_SENT: ({ email }) => (
        <p>
            we have sent a mail to <b>{email}</b>
        </p>
    ),
    CHECK_INBOX: 'please check your inbox (and spam) to complete verification',
    ENTER_OTT: 'verification code',
    RESEND_MAIL: 'resend?',
    VERIFY: 'verify',
    UNKNOWN_ERROR: 'something went wrong, please try again',
    INVALID_CODE: 'invalid verification code',
    SENDING: 'sending...',
    SENT: 'sent!',
    ENTER_PASSPHRASE: 'enter your password',
    RETURN_PASSPHRASE_HINT: 'password',
    SET_PASSPHRASE: 'set password',
    VERIFY_PASSPHRASE: 'sign in',
    INCORRECT_PASSPHRASE: 'incorrect password',
    ENTER_ENC_PASSPHRASE:
        'please enter a password that we can use to encrypt your data',
    PASSPHRASE_DISCLAIMER: () => (
        <p>
            we don't store your password, so if you forget,
            <strong> we will not be able to help you</strong> recover your data.
        </p>
    ),
    PASSPHRASE_HINT: 'password',
    PASSPHRASE_CONFIRM: 'password again',
    PASSPHRASE_MATCH_ERROR: `passwords don't match`,
    CONSOLE_WARNING_STOP: 'STOP!',
    CONSOLE_WARNING_DESC: `This is a browser feature intended for developers. Please don't copy-paste unverified code here.`,
    SELECT_COLLECTION: `select an album to upload to`,
    CREATE_COLLECTION: `create album`,
    CLOSE: 'close',
    NOTHING_HERE: `nothing to see here, yet 👀`,
    UPLOAD: {
        0: 'preparing to upload',
        1: 'reading google metadata files',
        2: (fileCounter) =>
            `${fileCounter.finished} / ${fileCounter.total} files backed up`,
        3: 'backup complete!',
    },
    UPLOADING_FILES: `file upload`,
    FAILED_UPLOAD_FILE_LIST: 'upload failed for following files',
    FILE_UPLOAD_PROGRESS: (name, progress) => (
        <div id={name}>
            <strong>{name}</strong>
            {` - `}
            {progress !== -1 ? progress + '%' : 'failed'}
        </div>
    ),
    SUBSCRIPTION_EXPIRED:
        'your subscription has expired, please renew it form the mobile app',
    STORAGE_QUOTA_EXCEEDED:
        'you have exceeded your storage quota, please upgrade your plan from the mobile app',
    INITIAL_LOAD_DELAY_WARNING: 'the first load may take some time',
    USER_DOES_NOT_EXIST: 'sorry, could not find a user with that email',
    UPLOAD_BUTTON_TEXT: 'upload',
    NO_ACCOUNT: "don't have an account?",
    ALBUM_NAME: 'album name',
    CREATE: 'create',
    DOWNLOAD: 'download',
    TOGGLE_FULLSCREEN: 'toggle fullscreen',
    ZOOM_IN_OUT: 'zoom in/out',
    PREVIOUS: 'previous (arrow left)',
    NEXT: 'next (arrow right)',
    NO_INTERNET_CONNECTION:
        'please check your internet connection and try again',
    TITLE: 'ente.io | encrypted photo storage',
    UPLOAD_FIRST_PHOTO: 'backup your first photo',
    INSTALL_MOBILE_APP: () => (
        <div>
            install our{' '}
            <a
                href="https://play.google.com/store/apps/details?id=io.ente.photos"
                target="_blank"
            >
                android
            </a>{' '}
            or{' '}
            <a
                href="https://apps.apple.com/in/app/ente-photos/id1542026904"
                target="_blank"
            >
                ios app{' '}
            </a>
            to automatically backup all your photos
        </div>
    ),
    LOGOUT: 'logout',
    LOGOUT_MESSAGE: 'sure you want to logout?',
    CANCEL: 'cancel',
    DOWNLOAD_APP_MESSAGE:
        'sorry, this operation is currently not supported on the web, please install the desktop app',
    DOWNLOAD_APP: 'download',
    APP_DOWNLOAD_URL: 'https://github.com/ente-io/bhari-frame/releases/',
    EXPORT: 'export ',
    SUBSCRIPTION_PLAN: 'subscription plan',
    USAGE_DETAILS: 'usage',
    FREE_SUBSCRIPTION_INFO: (expiryTime) => (
        <>
            <p>
                you are on the <strong>free</strong> plan that expires on{' '}
                {new Date(expiryTime / 1000).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                })}
            </p>
        </>
    ),
    PAID_SUBSCRIPTION_INFO: (expiryTime) => (
        <>
            <p>
                your subscription will renew on{' '}
                {new Date(expiryTime / 1000).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                })}
            </p>
        </>
    ),
    USAGE_INFO: (usage, quota) => (
        <p>
            you have used {usage} GB out of your {quota} GB quota
        </p>
    ),
    UPLOAD_DROPZONE_MESSAGE: 'drop to backup your files',
    CHANGE: 'change',
    CHANGE_EMAIL: 'change email?',
    DELETE_MESSAGE: 'sure you want to delete selected files?',
    DELETE: 'delete',
    UPLOAD_STRATEGY_CHOICE:
        'you are uploading multiple folders, would you like us to create',
    UPLOAD_STRATEGY_SINGLE_COLLECTION: 'a single album for everything',
    OR: 'or',
    UPLOAD_STRATEGY_COLLECTION_PER_FOLDER: 'separate albums for every folder',
    SESSION_EXPIRED_MESSAGE:
        'your session has expired, please login again to continue',
    SESSION_EXPIRED: 'login',
    SYNC_FAILED:
        'failed to sync with remote server, please refresh page to try again',
    PASSWORD_GENERATION_FAILED: `your browser was unable to generate a strong enough password  that meets ente's encryption standards, please try using the mobile app or another browser`,
    CHANGE_PASSWORD: 'change password',
    GO_BACK: 'go back',
    DOWNLOAD_RECOVERY_KEY: 'recovery key',
    SAVE_LATER: 'save later',
    SAVE: 'save',
    KEY_NOT_STORED_DISCLAIMER: () => (
        <>
            <p>we don't store this key</p>
            <p>so please save this key in a safe place</p>
        </>
    ),
};

export default englishConstants;

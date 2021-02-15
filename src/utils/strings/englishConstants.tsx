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
    RESEND_MAIL: 'did not get email?',
    VERIFY: 'verify',
    UNKNOWN_ERROR: 'something went wrong, please try again',
    INVALID_CODE: 'invalid verification code',
    SENDING: 'sending...',
    SENT: 'sent!',
    ENTER_PASSPHRASE: 'Please enter your passphrase.',
    RETURN_PASSPHRASE_HINT: 'That thing you promised to never forget.',
    SET_PASSPHRASE: 'Set Passphrase',
    VERIFY_PASSPHRASE: 'Verify Passphrase',
    INCORRECT_PASSPHRASE: 'Incorrect Passphrase',
    ENTER_ENC_PASSPHRASE:
        'Please enter a passphrase that we can use to encrypt your data.',
    PASSPHRASE_DISCLAIMER: () => (
        <p>
            We don't store your passphrase, so if you forget,
            <strong> we will not be able to help you</strong> recover your data.
        </p>
    ),
    PASSPHRASE_HINT: 'Something you will never forget',
    PASSPHRASE_CONFIRM: 'Please repeat it once more',
    PASSPHRASE_MATCH_ERROR: `Passphrase didn't match`,
    CONSOLE_WARNING_STOP: 'STOP!',
    CONSOLE_WARNING_DESC: `This is a browser feature intended for developers. If someone told you to copy-paste something here to enable a feature or "hack" someone's account, it is a scam and will give them access to your account.`,
    SELECT_COLLECTION: `Select/Click on Collection to upload`,
    CLOSE: 'Close',
    NOTHING_HERE: `nothing to see here! 👀`,
    UPLOAD: {
        0: 'Preparing to upload',
        1: 'Encryting your files',
        2: 'Uploading your Files',
        3: 'Files Uploaded Successfully !!!',
    },
    OF: 'of',
    SUBSCRIPTION_EXPIRED:
        "You don't have a active subscription plan!! Please get one in the mobile app",
    STORAGE_QUOTA_EXCEEDED:
        'You have exceeded your designated storage Quota, please upgrade your plan to add more files',
    WEB_SIGNUPS_DISABLED:
        'Web signups are disabled for now, please install the mobile app and signup there',
    USER_DOES_NOT_EXIST: 'sorry, could not find an ente user',
    UPLOAD_BUTTON_TEXT: 'Upload',
    NO_ACCOUNT: 'don\'t have an account?',
};

export default englishConstants;

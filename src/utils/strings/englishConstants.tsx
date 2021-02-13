import { template } from './vernacularStrings';

/**
 * Global English constants.
 */
const englishConstants = {
    COMPANY_NAME: 'ente',
    LOGIN: 'Login',
    SIGN_UP: 'Sign Up',
    NAME: 'Name',
    ENTER_NAME: 'your name',
    EMAIL: 'Email Address',
    ENTER_EMAIL: 'email address',
    DATA_DISCLAIMER: `We'll never share your data with anyone else.`,
    SUBMIT: 'Submit',
    EMAIL_ERROR: 'Enter a valid email address',
    REQUIRED: 'Required',
    VERIFY_EMAIL: 'Verify Email',
    EMAIL_SENT: ({ email }) => (
        <p>
            We have sent a mail to <b>{email}</b>.
        </p>
    ),
    CHECK_INBOX: 'Please check your inbox (and spam) to complete verification.',
    ENTER_OTT: 'Enter verification code here',
    RESEND_MAIL: 'Did not get email?',
    VERIFY: 'Verify',
    UNKNOWN_ERROR: 'Oops! Something went wrong. Please try again.',
    INVALID_CODE: 'Invalid verification code',
    SENDING: 'Sending...',
    SENT: 'Sent! Check again.',
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
    WEB_SIGNUPS_DISABLED:'Web signups are disabled for now, please install the mobile app and signup there'
};

export default englishConstants;

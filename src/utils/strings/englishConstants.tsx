import { Box, Typography } from '@mui/material';
import Link from '@mui/material/Link';
import LinkButton from 'components/pages/gallery/LinkButton';
import React from 'react';
import { SuggestionType } from 'types/search';
import { formatNumberWithCommas } from '.';

/**
 * Global English constants.
 */

const dateString = function (date) {
    return new Date(date / 1000).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
    });
};

const englishConstants = {
    HERO_SLIDE_1_TITLE: () => (
        <>
            <div>Private backups</div>
            <div> for your memories</div>
        </>
    ),
    HERO_SLIDE_1: 'End-to-end encrypted by default',
    HERO_SLIDE_2_TITLE: () => (
        <>
            <div>Safely stored </div>
            <div>at a fallout shelter</div>
        </>
    ),
    HERO_SLIDE_2: 'Designed to outlive',
    HERO_SLIDE_3_TITLE: () => (
        <>
            <div>Available</div>
            <div> everywhere</div>
        </>
    ),
    HERO_SLIDE_3: 'Android, iOS, Web, Desktop',
    COMPANY_NAME: 'ente',
    LOGIN: 'Login',
    SIGN_UP: 'Signup',
    NEW_USER: 'New to ente',
    EXISTING_USER: 'Existing user',
    NAME: 'Name',
    ENTER_NAME: 'Enter name',
    PUBLIC_UPLOADER_NAME_MESSAGE:
        'Add a name so that your friends know who to thank for these great photos!',
    EMAIL: 'Email',
    ENTER_EMAIL: 'Enter email address',
    DATA_DISCLAIMER: "We'll never share your data with anyone else.",
    SUBMIT: 'Submit',
    EMAIL_ERROR: 'Enter a valid email',
    REQUIRED: 'Required',
    VERIFY_EMAIL: 'Verify email',
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
    CHECK_INBOX: 'Please check your inbox (and spam) to complete verification',
    ENTER_OTT: 'Verification code',
    RESEND_MAIL: 'Resend code',
    VERIFY: 'Verify',
    UNKNOWN_ERROR: 'Something went wrong, please try again',
    INVALID_CODE: 'Invalid verification code',
    EXPIRED_CODE: 'Your verification code has expired',
    SENDING: 'Sending...',
    SENT: 'Sent!',
    PASSWORD: 'Password',
    LINK_PASSWORD: 'Enter password to unlock the album',
    ENTER_PASSPHRASE: 'Enter your password',
    RETURN_PASSPHRASE_HINT: 'Password',
    SET_PASSPHRASE: 'Set password',
    VERIFY_PASSPHRASE: 'Sign in',
    INCORRECT_PASSPHRASE: 'Incorrect password',
    ENTER_ENC_PASSPHRASE:
        'Please enter a password that we can use to encrypt your data',
    PASSPHRASE_DISCLAIMER: () => (
        <>
            We don't store your password, so if you forget it,{' '}
            <strong>we will not be able to help you </strong>
            recover your data without a recovery key.
        </>
    ),
    KEY_GENERATION_IN_PROGRESS_MESSAGE: 'Generating encryption keys...',
    PASSPHRASE_HINT: 'Password',
    CONFIRM_PASSPHRASE: 'Confirm password',
    PASSPHRASE_MATCH_ERROR: "Passwords don't match",
    CONSOLE_WARNING_STOP: 'STOP!',
    CONSOLE_WARNING_DESC:
        "This is a browser feature intended for developers. Please don't copy-paste unverified code here.",
    SELECT_COLLECTION: 'Select an album to upload to',
    CREATE_COLLECTION: 'New album',
    ENTER_ALBUM_NAME: 'Album name',
    CLOSE_OPTION: 'Close (Esc)',
    ENTER_FILE_NAME: 'File name',
    CLOSE: 'Close',
    NO: 'No',
    NOTHING_HERE: 'Nothing to see here yet 👀',
    UPLOAD: 'Upload',
    ADD_MORE_PHOTOS: 'Add more photos',
    ADD_PHOTOS: 'Add photos',
    SELECT_PHOTOS: 'Select photos',
    FILE_UPLOAD: 'File Upload',
    UPLOAD_STAGE_MESSAGE: {
        0: 'Preparing to upload',
        1: 'Reading google metadata files',
        2: (fileCounter) =>
            `${fileCounter.finished} / ${fileCounter.total} files metadata extracted`,
        3: (fileCounter) =>
            `${fileCounter.finished} / ${fileCounter.total} files backed up`,
        4: 'Cancelling remaining uploads',
        5: 'Backup complete',
    },
    UPLOADING_FILES: 'File upload',
    FILE_NOT_UPLOADED_LIST: 'The following files were not uploaded',
    SUBSCRIPTION_EXPIRED: 'Subscription expired',
    SUBSCRIPTION_EXPIRED_MESSAGE: (onClick) => (
        <>
            Your subscription has expired, please{' '}
            <LinkButton onClick={onClick}> renew </LinkButton>
        </>
    ),
    STORAGE_QUOTA_EXCEEDED: 'Storage limit exceeded',
    INITIAL_LOAD_DELAY_WARNING: 'First load may take some time',
    USER_DOES_NOT_EXIST: 'Sorry, could not find a user with that email',
    UPLOAD_BUTTON_TEXT: 'Upload',
    NO_ACCOUNT: "Don't have an account",
    ACCOUNT_EXISTS: 'Already have an account',
    ALBUM_NAME: 'Album name',
    CREATE: 'Create',
    DOWNLOAD: 'Download',
    DOWNLOAD_OPTION: 'Download (D)',
    DOWNLOAD_FAVORITES: 'Download favorites',
    DOWNLOAD_UNCATEGORIZED: 'Download uncategorized',
    COPY_OPTION: 'Copy as PNG (Ctrl/Cmd - C)',
    TOGGLE_FULLSCREEN: 'Toggle fullscreen (F)',
    ZOOM_IN_OUT: 'Zoom in/out',
    PREVIOUS: 'Previous (←)',
    NEXT: 'Next (→)',
    NO_INTERNET_CONNECTION:
        'Please check your internet connection and try again',
    TITLE: 'ente Photos',
    UPLOAD_FIRST_PHOTO_DESCRIPTION: () => (
        <>
            Preserve your first memory with <strong> ente </strong>
        </>
    ),
    UPLOAD_FIRST_PHOTO: 'Preserve',
    UPLOAD_DROPZONE_MESSAGE: 'Drop to backup your files',
    WATCH_FOLDER_DROPZONE_MESSAGE: 'Drop to add watched folder',
    TRASH_FILES_TITLE: 'Delete files?',
    TRASH_FILE_TITLE: 'Delete file?',
    DELETE_FILES_TITLE: 'Delete immediately?',
    DELETE_FILES_MESSAGE:
        'Selected files will be permanently deleted from your ente account.',
    DELETE_FILE: 'Delete files',
    DELETE: 'Delete',
    DELETE_OPTION: 'Delete (DEL)',
    FAVORITE: 'Favorite',
    FAVORITE_OPTION: 'Favorite (L)',
    UNFAVORITE_OPTION: 'Unfavorite (L)',
    UNFAVORITE: 'Unfavorite',
    MULTI_FOLDER_UPLOAD: 'Multiple folders detected',
    UPLOAD_STRATEGY_CHOICE: 'Would you like to upload them into',
    UPLOAD_STRATEGY_SINGLE_COLLECTION: 'A single album',
    OR: 'or',
    UPLOAD_STRATEGY_COLLECTION_PER_FOLDER: 'Separate albums',
    SESSION_EXPIRED_MESSAGE:
        'Your session has expired, please login again to continue',
    SESSION_EXPIRED: 'Session expired',
    SYNC_FAILED: 'Failed to sync with server, please refresh this page',
    PASSWORD_GENERATION_FAILED:
        "Your browser was unable to generate a strong key that meets ente's encryption standards, please try using the mobile app or another browser",
    CHANGE_PASSWORD: 'Change password',
    GO_BACK: 'Go back',
    RECOVERY_KEY: 'Recovery key',
    SAVE_LATER: 'Do this later',
    SAVE: 'Save Key',
    RECOVERY_KEY_DESCRIPTION:
        'If you forget your password, the only way you can recover your data is with this key.',
    RECOVER_KEY_GENERATION_FAILED:
        'Recovery code could not be generated, please try again',
    KEY_NOT_STORED_DISCLAIMER:
        "We don't store this key, so please save this in a safe place",
    FORGOT_PASSWORD: 'Forgot password',
    RECOVER_ACCOUNT: 'Recover account',
    RECOVERY_KEY_HINT: 'Recovery key',
    RECOVER: 'Recover',
    NO_RECOVERY_KEY: 'No recovery key?',
    INCORRECT_RECOVERY_KEY: 'Incorrect recovery key',
    SORRY: 'Sorry',
    NO_RECOVERY_KEY_MESSAGE:
        'Due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key',
    NO_TWO_FACTOR_RECOVERY_KEY_MESSAGE: () => (
        <>
            Please drop an email to{' '}
            <a href="mailto:support@ente.io">support@ente.io</a> from your
            registered email address
        </>
    ),
    CONTACT_SUPPORT: 'Contact support',
    REQUEST_FEATURE: 'Request Feature',
    SUPPORT: 'Support',
    CONFIRM: 'Confirm',
    SKIP_SUBSCRIPTION_PURCHASE: 'Continue with free plan',
    CANCEL: 'Cancel',
    LOGOUT: 'Logout',
    DELETE_ACCOUNT: 'Delete account',
    DELETE_ACCOUNT_MESSAGE: () => (
        <>
            <p>
                Please send an email to{' '}
                <Link href="mailto:account-deletion@ente.io">
                    account-deletion@ente.io
                </Link>{' '}
                from your registered email address.{' '}
            </p>
            <p>Your request will be processed within 72 hours.</p>
        </>
    ),
    LOGOUT_MESSAGE: 'Are you sure you want to logout?',
    CHANGE: 'Change',
    CHANGE_EMAIL: 'Change email',
    OK: 'OK',
    SUCCESS: 'Success',
    ERROR: 'Error',
    MESSAGE: 'Message',
    INSTALL_MOBILE_APP: () => (
        <>
            Install our{' '}
            <a
                href="https://play.google.com/store/apps/details?id=io.ente.photos"
                target="_blank"
                style={{ color: '#51cd7c' }}
                rel="noreferrer">
                Android
            </a>{' '}
            or{' '}
            <a
                href="https://apps.apple.com/in/app/ente-photos/id1542026904"
                style={{ color: '#51cd7c' }}
                target="_blank"
                rel="noreferrer">
                iOS app{' '}
            </a>
            to automatically backup all your photos
        </>
    ),
    DOWNLOAD_APP_MESSAGE:
        'Sorry, this operation is currently only supported on our desktop app',
    DOWNLOAD_APP: 'Download desktop app',
    EXPORT: 'Export Data',

    // ========================
    // Subscription
    // ========================
    SUBSCRIPTION: 'Subscription',
    SUBSCRIBE: 'Subscribe',
    SUBSCRIPTION_PLAN: 'Subscription plan',
    USAGE_DETAILS: 'Usage',
    MANAGE: 'Manage',
    MANAGEMENT_PORTAL: 'Manage payment method',
    MANAGE_FAMILY_PORTAL: 'Manage family',
    LEAVE_FAMILY_PLAN: 'Leave family plan',
    LEAVE: 'Leave',
    LEAVE_FAMILY_CONFIRM: 'Are you sure that you want to leave family plan?',
    CHOOSE_PLAN: 'Choose your plan',
    MANAGE_PLAN: 'Manage your subscription',
    ACTIVE: 'Active',

    OFFLINE_MSG: 'You are offline, cached memories are being shown',

    FREE_SUBSCRIPTION_INFO: (expiryTime) => (
        <>
            You are on the <strong>free</strong> plan that expires on{' '}
            {dateString(expiryTime)}
        </>
    ),

    FAMILY_SUBSCRIPTION_INFO: 'You are on a family plan managed by',

    RENEWAL_ACTIVE_SUBSCRIPTION_STATUS: (expiryTime) => (
        <>Renews on {dateString(expiryTime)}</>
    ),
    RENEWAL_CANCELLED_SUBSCRIPTION_STATUS: (expiryTime) => (
        <>Ends on {dateString(expiryTime)}</>
    ),

    RENEWAL_CANCELLED_SUBSCRIPTION_INFO: (expiryTime) => (
        <>Your subscription will be cancelled on {dateString(expiryTime)}</>
    ),

    STORAGE_QUOTA_EXCEEDED_SUBSCRIPTION_INFO: (onClick) => (
        <>
            You have exceeded your storage quota,, please{' '}
            <LinkButton onClick={onClick}> upgrade </LinkButton>
        </>
    ),
    SUBSCRIPTION_PURCHASE_SUCCESS: (expiryTime) => (
        <>
            <p>We've received your payment</p>
            <p>
                Your subscription is valid till{' '}
                <strong>{dateString(expiryTime)}</strong>
            </p>
        </>
    ),
    SUBSCRIPTION_PURCHASE_CANCELLED:
        'Your purchase was canceled, please try again if you want to subscribe',
    SUBSCRIPTION_VERIFICATION_FAILED:
        'We were not able to verify your purchase, verification can take few hours',
    SUBSCRIPTION_PURCHASE_FAILED:
        'Subscription purchase failed , please try again',
    SUBSCRIPTION_UPDATE_FAILED:
        'Subscription updated failed , please try again',
    UPDATE_PAYMENT_METHOD_MESSAGE:
        'We are sorry, payment failed when we tried to charge your card, please update your payment method and try again',
    STRIPE_AUTHENTICATION_FAILED:
        'We are unable to authenticate your payment method. please choose a different payment method and try again',
    UPDATE_PAYMENT_METHOD: 'Update payment method',
    MONTHLY: 'Monthly',
    YEARLY: 'Yearly',
    UPDATE_SUBSCRIPTION_MESSAGE: 'Are you sure you want to change your plan?',
    UPDATE_SUBSCRIPTION: 'Change plan',

    CANCEL_SUBSCRIPTION: 'Cancel subscription',
    CANCEL_SUBSCRIPTION_MESSAGE: () => (
        <>
            <p>
                All of your data will be deleted from our servers at the end of
                this billing period.
            </p>
            <p>Are you sure that you want to cancel your subscription?</p>
        </>
    ),
    SUBSCRIPTION_CANCEL_FAILED: 'Failed to cancel subscription',
    SUBSCRIPTION_CANCEL_SUCCESS: 'Subscription canceled successfully',

    REACTIVATE_SUBSCRIPTION: 'Reactivate subscription',
    REACTIVATE_SUBSCRIPTION_MESSAGE: (expiryTime) =>
        `Once reactivated, you will be billed on ${dateString(expiryTime)}`,
    SUBSCRIPTION_ACTIVATE_SUCCESS: 'Subscription activated successfully ',
    SUBSCRIPTION_ACTIVATE_FAILED: 'Failed to reactivate subscription renewals',

    SUBSCRIPTION_PURCHASE_SUCCESS_TITLE: 'Thank you',
    CANCEL_SUBSCRIPTION_ON_MOBILE: 'Cancel mobile subscription',
    CANCEL_SUBSCRIPTION_ON_MOBILE_MESSAGE:
        'Please cancel your subscription from the mobile app to activate a subscription here',
    MAIL_TO_MANAGE_SUBSCRIPTION: (
        <>
            Please contact us at{' '}
            <Link href={`mailto:support@ente.io`}>support@ente.io</Link> to
            manage your subscription
        </>
    ),
    RENAME: 'Rename',
    RENAME_FILE: 'Rename file',
    RENAME_COLLECTION: 'Rename album',
    DELETE_COLLECTION_TITLE: 'Delete album?',
    DELETE_COLLECTION: 'Delete album',
    DELETE_COLLECTION_FAILED: 'Album deletion failed, please try again',
    DELETE_COLLECTION_MESSAGE: () => (
        <p>
            Also delete the photos (and videos) present in this album from
            <span style={{ color: '#fff' }}> all </span> other albums they are
            part of?
        </p>
    ),
    DELETE_PHOTOS: 'Delete photos',
    KEEP_PHOTOS: 'Keep photos',
    SHARE: 'Share',
    SHARE_COLLECTION: 'Share album',
    SHARE_WITH_PEOPLE: 'Share with your loved ones',
    SHAREES: 'Shared with',
    PUBLIC_URL: 'Public link',
    SHARE_WITH_SELF: 'Oops, you cannot share with yourself',
    ALREADY_SHARED: (email) =>
        `Oops, you're already sharing this with ${email}`,
    SHARING_BAD_REQUEST_ERROR: 'Sharing album not allowed',
    SHARING_DISABLED_FOR_FREE_ACCOUNTS: 'Sharing is disabled for free accounts',
    DOWNLOAD_COLLECTION: 'Download album',
    DOWNLOAD_COLLECTION_MESSAGE: () => (
        <>
            <p>Are you sure you want to download the complete album?</p>
            <p>All files will be queued for download sequentially</p>
        </>
    ),
    DOWNLOAD_COLLECTION_FAILED: 'Album downloading failed, please try again',
    CREATE_ALBUM_FAILED: 'Failed to create album , please try again',

    SEARCH_RESULTS: 'Search results',
    SEARCH_HINT: () => <span>Search for albums, dates ...</span>,
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
            I understand that if I lose my password , I may lose my data since
            my data is{' '}
            <a
                href="https://ente.io/architecture"
                target="_blank"
                rel="noreferrer">
                end-to-end encrypted
            </a>{' '}
            with ente
        </p>
    ),
    NOT_FILE_OWNER: 'You cannot delete files in a shared album',
    ADD_TO_COLLECTION: 'Add to album',
    SELECTED: 'selected',
    VIDEO_PLAYBACK_FAILED: 'Video format not supported',
    VIDEO_PLAYBACK_FAILED_DOWNLOAD_INSTEAD:
        'This video cannot be played on your browser',
    METADATA: 'Metadata',
    INFO: 'Info ',
    INFO_OPTION: 'Info (I)',
    FILE_ID: 'File ID',
    FILE_NAME: 'File name',
    CAPTION: 'Description',
    CAPTION_PLACEHOLDER: 'Add a description',
    CREATION_TIME: 'Creation time',
    UPDATED_ON: 'Updated on',
    LOCATION: 'Location',
    SHOW_ON_MAP: 'View on OpenStreetMap',
    DETAILS: 'Details',
    VIEW_EXIF: 'View all EXIF data',
    NO_EXIF: 'No EXIF data',
    EXIF: 'EXIF',
    DEVICE: 'Device',
    IMAGE_SIZE: 'Image size',
    FLASH: 'Flash',
    FOCAL_LENGTH: 'Focal length',
    APERTURE: 'Aperture',
    ISO: 'ISO',
    SHOW_ALL: 'show all',
    LOGIN_TO_UPLOAD_FILES: (count: number) =>
        count === 1
            ? `1 file received. login to upload`
            : `${count} files received. login to upload`,
    FILES_TO_BE_UPLOADED: (count: number) =>
        count === 1
            ? `1 file received. uploading in a jiffy`
            : `${count} files received. uploading in a jiffy`,
    TWO_FACTOR: 'Two-factor',
    TWO_FACTOR_AUTHENTICATION: 'Two-factor authentication',
    TWO_FACTOR_QR_INSTRUCTION:
        'Scan the QR code below with your favorite authenticator app',
    ENTER_CODE_MANUALLY: 'Enter the code manually',
    TWO_FACTOR_MANUAL_CODE_INSTRUCTION:
        'Please enter this code in your favorite authenticator app',
    SCAN_QR_CODE: 'Scan QR code instead',
    CONTINUE: 'Continue',
    BACK: 'Back',
    ENABLE_TWO_FACTOR: 'Enable two-factor',
    ENABLE: 'Enable',
    LOST_DEVICE: 'Lost two-factor device',
    INCORRECT_CODE: 'Incorrect code',
    RECOVER_TWO_FACTOR: 'Recover two-factor',
    TWO_FACTOR_INFO:
        'Add an additional layer of security by requiring more than your email and password to log in to your account',
    DISABLE_TWO_FACTOR_LABEL: 'Disable two-factor authentication',
    UPDATE_TWO_FACTOR_LABEL: 'Update your authenticator device',
    DISABLE: 'Disable',
    RECONFIGURE: 'Reconfigure',
    UPDATE_TWO_FACTOR: 'Update two-factor',
    UPDATE_TWO_FACTOR_MESSAGE:
        'Continuing forward will void any previously configured authenticators',
    UPDATE: 'Update',
    DISABLE_TWO_FACTOR: 'Disable two-factor',
    DISABLE_TWO_FACTOR_MESSAGE:
        'Are you sure you want to disable your two-factor authentication',
    TWO_FACTOR_SETUP_FAILED: 'Failed to setup two factor, please try again',
    TWO_FACTOR_SETUP_SUCCESS:
        'Two factor authentication successfully configured',
    TWO_FACTOR_DISABLE_SUCCESS: 'Two factor authentication disabled',
    TWO_FACTOR_DISABLE_FAILED: 'Failed to disable two factor, please try again',
    EXPORT_DATA: 'Export data',
    SELECT_FOLDER: 'Select folder',
    DESTINATION: 'Destination',
    EXPORT_SIZE: 'Export size',
    START: 'Start',
    EXPORT_IN_PROGRESS: 'Export in progress...',
    PAUSE: 'Pause',
    RESUME: 'Resume',
    MINIMIZE: 'Minimize',
    LAST_EXPORT_TIME: 'Last export time',
    SUCCESSFULLY_EXPORTED_FILES: 'Successful exports',
    FAILED_EXPORTED_FILES: 'Failed exports',
    EXPORT_AGAIN: 'Resync',
    RETRY_EXPORT_: 'Retry failed exports',
    LOCAL_STORAGE_NOT_ACCESSIBLE: 'Local storage not accessible',
    LOCAL_STORAGE_NOT_ACCESSIBLE_MESSAGE:
        'Your browser or an addon is blocking ente from saving data into local storage. please try loading this page after switching your browsing mode.',
    RETRY: 'Retry',
    SEND_OTT: 'Send OTP',
    EMAIl_ALREADY_OWNED: 'Email already taken',
    EMAIL_UDPATE_SUCCESSFUL: 'Your email has been updated successfully',
    UPLOAD_FAILED: 'Upload failed',
    ETAGS_BLOCKED: (link: string) => (
        <>
            <Box mb={1}>
                We were unable to upload the following files because of your
                browser configuration.
            </Box>
            <Box>
                Please disable any addons that might be preventing ente from
                using <code>eTags</code> to upload large files, or use our{' '}
                <Link href={link} target="_blank">
                    desktop app
                </Link>{' '}
                for a more reliable import experience.
            </Box>
        </>
    ),
    SKIPPED_VIDEOS_INFO: (link: string) => (
        <>
            <Box mb={1}>
                Presently we do not support adding videos via public links.{' '}
            </Box>
            <Box>
                To share videos, please{' '}
                <Link href={link} target="_blank">
                    signup
                </Link>{' '}
                for ente and share with the intended recipients using their
                email.
            </Box>
        </>
    ),

    LIVE_PHOTOS_DETECTED:
        'The photo and video files from your Live Photos have been merged into a single file',

    RETRY_FAILED: 'Retry failed uploads',
    FAILED_UPLOADS: 'Failed uploads ',
    SKIPPED_FILES: 'Ignored uploads',
    THUMBNAIL_GENERATION_FAILED_UPLOADS: 'Thumbnail generation failed',
    UNSUPPORTED_FILES: 'Unsupported files',
    SUCCESSFUL_UPLOADS: 'Successful uploads',
    SKIPPED_INFO:
        'Skipped these as there are files with matching names in the same album',
    UNSUPPORTED_INFO: 'ente does not support these file formats yet',
    BLOCKED_UPLOADS: 'Blocked uploads',
    SKIPPED_VIDEOS: 'Skipped videos',
    INPROGRESS_METADATA_EXTRACTION: 'In progress',
    INPROGRESS_UPLOADS: 'Uploads in progress',
    TOO_LARGE_UPLOADS: 'Large files',
    LARGER_THAN_AVAILABLE_STORAGE_UPLOADS: 'Insufficient storage',
    LARGER_THAN_AVAILABLE_STORAGE_INFO:
        'These files were not uploaded as they exceed the maximum size limit for your storage plan',
    TOO_LARGE_INFO:
        'These files were not uploaded as they exceed our maximum file size limit',
    THUMBNAIL_GENERATION_FAILED_INFO:
        'These files were uploaded, but unfortunately we could not generate the thumbnails for them.',
    UPLOAD_TO_COLLECTION: 'Upload to album',
    UNCATEGORIZED: 'Uncategorized',
    MOVE_TO_UNCATEGORIZED: 'Move to uncategorized',
    ARCHIVE: 'Archive',
    ARCHIVE_COLLECTION: 'Archive album',
    ARCHIVE_SECTION_NAME: 'Archive',
    ALL_SECTION_NAME: 'All',
    MOVE_TO_COLLECTION: 'Move to album',
    UNARCHIVE: 'Unarchive',
    UNARCHIVE_COLLECTION: 'Unarchive album',
    MOVE: 'Move',
    ADD: 'Add',
    SORT: 'Sort',
    REMOVE: 'Remove',
    YES_REMOVE: 'Yes, remove',
    CONFIRM_REMOVE: 'Confirm removal',
    REMOVE_FROM_COLLECTION: 'Remove from album',
    TRASH: 'Trash',
    MOVE_TO_TRASH: 'Move to trash',
    TRASH_FILES_MESSAGE:
        'Selected files will be removed from all albums and moved to trash.',
    TRASH_FILE_MESSAGE:
        'The file will be removed from all albums and moved to trash.',
    DELETE_PERMANENTLY: 'Delete permanently',
    RESTORE: 'Restore',
    CONFIRM_RESTORE: 'Confirm restoration',
    RESTORE_MESSAGE: 'Restore selected files ?',
    RESTORE_TO_COLLECTION: 'Restore to album',
    EMPTY_TRASH: 'Empty trash',
    EMPTY_TRASH_TITLE: 'Empty trash?',
    EMPTY_TRASH_MESSAGE:
        'These files will be permanently deleted from your ente account.',
    LEAVE_SHARED_ALBUM: 'Yes, leave',
    LEAVE_ALBUM: 'Leave album',
    LEAVE_SHARED_ALBUM_TITLE: 'Leave shared album?',
    LEAVE_SHARED_ALBUM_FAILED: 'failed to leave the album, please try again',
    LEAVE_SHARED_ALBUM_MESSAGE:
        'You will leave the album, and it will stop being visible to you.',
    CONFIRM_SELF_REMOVE_MESSAGE: () => (
        <>
            <p>
                Selected items will be removed from this album. Items which are
                only in this album will be moved to Uncategorized.
            </p>
        </>
    ),
    CONFIRM_SELF_AND_OTHER_REMOVE_MESSAGE: () => (
        <>
            <p>
                Some of the items you are removing were added by other people,
                and you will lose access to them.
            </p>
        </>
    ),

    SORT_BY_CREATION_TIME_ASCENDING: 'Oldest',
    SORT_BY_CREATION_TIME_DESCENDING: 'Newest',
    SORT_BY_UPDATION_TIME_DESCENDING: 'Last updated',
    SORT_BY_NAME: 'Name',
    COMPRESS_THUMBNAILS: 'Compress thumbnails',
    THUMBNAIL_REPLACED: 'Thumbnails compressed',
    FIX_THUMBNAIL: 'Compress',
    FIX_THUMBNAIL_LATER: 'Compress later',
    REPLACE_THUMBNAIL_NOT_STARTED: () => (
        <>
            Some of your videos thumbnails can be compressed to save space.
            would you like ente to compress them?
        </>
    ),
    REPLACE_THUMBNAIL_COMPLETED: () => (
        <>Successfully compressed all thumbnails</>
    ),
    REPLACE_THUMBNAIL_NOOP: () => (
        <>You have no thumbnails that can be compressed further</>
    ),
    REPLACE_THUMBNAIL_COMPLETED_WITH_ERROR: () => (
        <>Could not compress some of your thumbnails, please retry</>
    ),
    FIX_CREATION_TIME: 'Fix time',
    FIX_CREATION_TIME_IN_PROGRESS: 'Fixing time',
    CREATION_TIME_UPDATED: `File time updated`,

    UPDATE_CREATION_TIME_NOT_STARTED: () => (
        <>Select the option you want to use</>
    ),
    UPDATE_CREATION_TIME_COMPLETED: () => <>Successfully updated all files</>,

    UPDATE_CREATION_TIME_COMPLETED_WITH_ERROR: () => (
        <>File time updation failed for some files, please retry</>
    ),
    FILE_NAME_CHARACTER_LIMIT: '100 characters max',
    CAPTION_CHARACTER_LIMIT: '5000 characters max',

    DATE_TIME_ORIGINAL: 'EXIF:DateTimeOriginal',
    DATE_TIME_DIGITIZED: 'EXIF:DateTimeDigitized',
    CUSTOM_TIME: 'Custom time',
    REOPEN_PLAN_SELECTOR_MODAL: 'Re-open plans',
    OPEN_PLAN_SELECTOR_MODAL_FAILED: 'Failed to open plans',
    COMMENT: 'Comment',
    ABUSE_REPORT_DESCRIPTION:
        'Submitting this report will notify the album owner.',
    OTHER_REASON_REQUIRES_COMMENTS:
        'Reason = other, require  a mandatory comment ',
    REPORT_SUBMIT_SUCCESS_CONTENT: 'Your report has been submitted',
    REPORT_SUBMIT_SUCCESS_TITLE: 'Report sent',
    REPORT_SUBMIT_FAILED: 'Failed to sent report, try again',
    INSTALL: 'Install',
    ALBUM_URL: 'Album url',
    PUBLIC_SHARING: 'Public link',
    SHARING_DETAILS: 'Sharing details',
    MODIFY_SHARING: 'Modify sharing',
    NOT_FOUND: '404 - not found',
    LINK_EXPIRED: 'Link expired',
    LINK_EXPIRED_MESSAGE: 'This link has either expired or been disabled!',
    MANAGE_LINK: 'Manage link',
    LINK_TOO_MANY_REQUESTS: 'This album is too popular for us to handle!',
    DISABLE_PUBLIC_SHARING: 'Disable public sharing',
    DISABLE_PUBLIC_SHARING_MESSAGE:
        'Are you sure you want to disable public sharing?',
    FILE_DOWNLOAD: 'Allow downloads',
    LINK_PASSWORD_LOCK: 'Password lock',
    PUBLIC_COLLECT: 'Allow adding photos',
    LINK_DEVICE_LIMIT: 'Device limit',
    LINK_EXPIRY: 'Link expiry',
    LINK_EXPIRY_NEVER: 'Never',
    DISABLE_FILE_DOWNLOAD: 'Disable download',
    DISABLE_FILE_DOWNLOAD_MESSAGE: () => (
        <>
            <p>
                Are you sure that you want to disable the download button for
                files?{' '}
            </p>{' '}
            <p>
                Viewers can still take screenshots or save a copy of your photos
                using external tools{' '}
            </p>
        </>
    ),
    ABUSE_REPORT: 'Abuse report',
    ABUSE_REPORT_BUTTON_TEXT: 'Report abuse?',
    MALICIOUS_CONTENT: 'Contains malicious content',
    COPYRIGHT:
        'Infringes on the copyright of someone I am authorized to represent',
    ENTER_EMAIL_ADDRESS: 'Email*',
    SELECT_REASON: 'Select a reason*',
    ENTER_FULL_NAME: 'Full name*',
    ENTER_DIGITAL_SIGNATURE:
        'Typing your full name in this box will act as your digital signature*',
    ENTER_ON_BEHALF_OF: 'I am reporting on behalf of*',
    ENTER_ADDRESS: 'Address*',
    ENTER_JOB_TITLE: 'Job title*',
    ENTER_CITY: 'City*',
    ENTER_PHONE: 'Phone number*',

    ENTER_STATE: 'State*',
    ENTER_POSTAL_CODE: 'Zip/postal code*',
    ENTER_COUNTRY: 'Country*',
    JUDICIAL_DESCRIPTION: () => (
        <>
            By checking the following boxes, I state{' '}
            <strong>UNDER PENALTY OF PERJURY </strong>of law that:
        </>
    ),
    TERM_1: 'I hereby state that I have a good faith belief that the sharing of copyrighted material at the location above is not authorized by the copyright owner, its agent, or the law (e.g., as a fair use). ',
    TERM_2: 'I hereby state that the information in this Notice is accurate and, under penalty of perjury, that I am the owner, or authorized to act on behalf of, the owner, of the copyright or of an exclusive right under the copyright that is allegedly infringed. ',
    TERM_3: 'I acknowledge that any person who knowingly materially misrepresents that material or activity is infringing may be subject to liability for damages. ',
    SHARED_USING: 'Shared using ',
    ENTE_IO: 'ente.io',
    LIVE: 'LIVE',
    DISABLE_PASSWORD: 'Disable password lock',
    DISABLE_PASSWORD_MESSAGE:
        'Are you sure that you want to disable the password lock?',
    PASSWORD_LOCK: 'Password lock',
    LOCK: 'Lock',
    DOWNLOAD_UPLOAD_LOGS: 'Debug logs',
    CHOOSE_UPLOAD_TYPE: 'Upload',
    UPLOAD_FILES: 'File',
    UPLOAD_DIRS: 'Folder',
    UPLOAD_GOOGLE_TAKEOUT: 'Google takeout',
    CANCEL_UPLOADS: 'Cancel uploads',
    DEDUPLICATE_FILES: 'Deduplicate files',
    NO_DUPLICATES_FOUND: "You've no duplicate files that can be cleared",
    CLUB_BY_CAPTURE_TIME: 'Club by capture time',
    FILES: 'Files',
    EACH: 'Each',
    DEDUPLICATION_LOGIC_MESSAGE: (captureTime: boolean) => (
        <>
            The following files were clubbed based on their sizes
            {captureTime && ' and capture time'}, please review and delete items
            you believe are duplicates{' '}
        </>
    ),
    STOP_ALL_UPLOADS_MESSAGE:
        'Are you sure that you want to stop all the uploads in progress?',
    STOP_UPLOADS_HEADER: 'Stop uploads?',
    YES_STOP_UPLOADS: 'Yes, stop uploads',
    ALBUMS: 'Albums',
    NEW: 'New',
    VIEW_ALL_ALBUMS: 'View all Albums',
    ALL_ALBUMS: 'All Albums',
    ENDS: 'Ends',
    ENTER_TWO_FACTOR_OTP: 'Enter the 6-digit code from your authenticator app.',
    CREATE_ACCOUNT: 'Create account',
    COPIED: 'Copied',
    CANVAS_BLOCKED_TITLE: 'Unable to generate thumbnail',
    CANVAS_BLOCKED_MESSAGE: () => (
        <>
            <p>
                It looks like your browser has disabled access to canvas, which
                is necessary to generate thumbnails for your photos
            </p>
            <p>
                Please enable access to your browser's canvas, or check out our
                desktop app
            </p>
        </>
    ),
    WATCH_FOLDERS: 'Watch folders',
    UPGRADE_NOW: 'Upgrade now',
    RENEW_NOW: 'Renew now',
    STORAGE: 'Storage',
    USED: 'used',
    YOU: 'You',
    FAMILY: 'Family',
    FREE: 'free',
    OF: 'of',
    WATCHED_FOLDERS: 'Watched folders',
    NO_FOLDERS_ADDED: 'No folders added yet!',
    FOLDERS_AUTOMATICALLY_MONITORED:
        'The folders you add here will monitored to automatically',
    UPLOAD_NEW_FILES_TO_ENTE: 'Upload new files to ente',
    REMOVE_DELETED_FILES_FROM_ENTE: 'Remove deleted files from ente',
    ADD_FOLDER: 'Add folder',
    STOP_WATCHING: 'Stop watching',
    STOP_WATCHING_FOLDER: 'Stop watching folder?',
    STOP_WATCHING_DIALOG_MESSAGE:
        'Your existing files will not be deleted, but ente will stop automatically updating the linked ente album on changes in this folder.',
    YES_STOP: 'Yes, stop',
    MONTH_SHORT: 'mo',
    YEAR: 'year',
    FAMILY_PLAN: 'Family plan',
    DOWNLOAD_LOGS: 'Download logs',
    DOWNLOAD_LOGS_MESSAGE: () => (
        <>
            <p>
                This will download debug logs, which you can email to us to help
                debug your issue.
            </p>
            <p>
                Please note that file names will be included to help track
                issues with specific files.
            </p>
        </>
    ),
    CHANGE_FOLDER: 'Change Folder',
    TWO_MONTHS_FREE: 'Get 2 months free on yearly plans',
    GB: 'GB',
    POPULAR: 'Popular',
    FREE_PLAN_OPTION_LABEL: 'Continue with free trial',
    FREE_PLAN_DESCRIPTION: '1 GB for 1 year',
    CURRENT_USAGE: (usage) => (
        <>
            Current usage is <strong>{usage}</strong>
        </>
    ),
    WEAK_DEVICE:
        "The web browser you're using is not powerful enough to encrypt your photos. Please try to log in to ente on your computer, or download the ente mobile/desktop app.",
    DRAG_AND_DROP_HINT: 'Or drag and drop into the ente window',
    ASK_FOR_FEEDBACK: (
        <>
            <p>We'll be sorry to see you go. Are you facing some issue?</p>
            <p>
                Please write to us at{' '}
                <Link href="mailto:feedback@ente.io">feedback@ente.io</Link>,
                maybe there is a way we can help.
            </p>
        </>
    ),
    SEND_FEEDBACK: 'Yes, send feedback',
    CONFIRM_ACCOUNT_DELETION_TITLE:
        'Are you sure you want to delete your account?',
    CONFIRM_ACCOUNT_DELETION_MESSAGE: (
        <>
            <p>
                Your uploaded data will be scheduled for deletion, and your
                account will be permanently deleted.
            </p>
            <p>This action is not reversible.</p>
        </>
    ),
    AUTHENTICATE: 'Authenticate',
    UPLOADED_TO_SINGLE_COLLECTION: 'Uploaded to single collection',
    UPLOADED_TO_SEPARATE_COLLECTIONS: 'Uploaded to separate collections',
    NEVERMIND: 'Nevermind',
    UPDATE_AVAILABLE: 'Update available',
    UPDATE_INSTALLABLE_MESSAGE:
        'A new version of ente is ready to be installed.',
    INSTALL_NOW: `Install now`,
    INSTALL_ON_NEXT_LAUNCH: 'Install on next launch',
    UPDATE_AVAILABLE_MESSAGE:
        'A new version of ente has been released, but it cannot be automatically downloaded and installed.',
    DOWNLOAD_AND_INSTALL: 'Download and install',
    IGNORE_THIS_VERSION: 'Ignore this version',
    TODAY: 'Today',
    YESTERDAY: 'Yesterday',
    AT: 'at',
    NAME_PLACEHOLDER: 'Name...',
    ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED:
        'Cannot create albums from file/folder mix',
    ROOT_LEVEL_FILE_WITH_FOLDER_NOT_ALLOWED_MESSAGE: () => (
        <>
            <p>You have dragged and dropped a mixture of files and folders.</p>
            <p>
                Please provide either only files, or only folders when selecting
                option to create separate albums
            </p>
        </>
    ),
    ADD_X_PHOTOS: (x: number) => `Add ${x} ${x > 1 ? 'photos' : 'photo'}`,
    CHOSE_THEME: 'Choose theme',
    YOURS: 'yours',
};

export default englishConstants;

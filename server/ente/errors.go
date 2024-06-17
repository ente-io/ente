package ente

import (
	"errors"
	"fmt"
	"net/http"
)

// ErrPermissionDenied is returned when a user has insufficient permissions to
// perform an action
var ErrPermissionDenied = errors.New("insufficient permissions to perform this action")

// ErrIncorrectOTT is returned when a user tries to validate an email with an
// incorrect OTT
var ErrIncorrectOTT = errors.New("incorrect OTT")

// ErrExpiredOTT is returned when a user tries to validate an email but there's no active ott
var ErrExpiredOTT = errors.New("no active OTT")

// ErrIncorrectTOTP is returned when a user tries to validate an two factor with an
// incorrect TOTP
var ErrIncorrectTOTP = errors.New("incorrect TOTP")

// ErrNotFound is returned when the requested resource was not found
var ErrNotFound = errors.New("not found")

var ErrFileLimitReached = errors.New("file limit reached")

// ErrBadRequest is returned when a bad request is encountered
var ErrBadRequest = errors.New("bad request")

// ErrTooManyBadRequest is returned when user send many bad requests, especailly for authentication
var ErrTooManyBadRequest = errors.New("too many bad request")

// ErrUnexpectedState is returned when certain assumption/assets fails
var ErrUnexpectedState = errors.New("unexpected state")

// ErrCannotDowngrade is thrown when a user tries to downgrade to a plan whose
// limits are lower than current consumption
var ErrCannotDowngrade = errors.New("usage is greater than selected plan, cannot downgrade")

// ErrCannotSwitchPaymentProvider is thrown when a user attempts to renew a subscription from a different payment provider
var ErrCannotSwitchPaymentProvider = errors.New("cannot switch payment provider")

// ErrNoActiveSubscription is returned when user's doesn't has any active plans
var ErrNoActiveSubscription = errors.New("no Active Subscription")

// ErrStorageLimitExceeded is thrown when user exceed the plan's data Storage limit
var ErrStorageLimitExceeded = errors.New("storage Limit exceeded")

// ErrFileTooLarge thrown when an uploaded file is too large for the storage plan
var ErrFileTooLarge = errors.New("file too large")

// ErrSharingDisabledForFreeAccounts is thrown when free subscription user tries to share files
var ErrSharingDisabledForFreeAccounts = errors.New("sharing Feature is disabled for free accounts")

// ErrDuplicateFileObjectFound is thrown when another file with the same objectKey is detected
var ErrDuplicateFileObjectFound = errors.New("file object already exists")

var ErrFavoriteCollectionAlreadyExist = errors.New("favorites collection already exists")

var ErrUncategorizeCollectionAlreadyExists = errors.New("uncategorized collection already exists")

// ErrDuplicateThumbnailObjectFound is thrown when another thumbnail with the same objectKey is detected
var ErrDuplicateThumbnailObjectFound = errors.New("thumbnail object already exists")

// ErrVersionMismatch is thrown when for versioned updates, client is sending incorrect version to server
var ErrVersionMismatch = errors.New("client version is out of sync")

// ErrCanNotInviteUserWithPaidPlan is thrown when a family admin tries to invite another user with active paid plan
var ErrCanNotInviteUserWithPaidPlan = errors.New("can not invite user with active paid plan")

// ErrBatchSizeTooLarge is thrown when api request batch size is greater than API limit
var ErrBatchSizeTooLarge = errors.New("batch size greater than API limit")

// ErrAuthenticationRequired is thrown when authentication vector is missing
var ErrAuthenticationRequired = errors.New("authentication required")

// ErrInvalidPassword is thrown when incorrect password is provided by user
var ErrInvalidPassword = errors.New("invalid password")

// ErrCanNotInviteUserAlreadyInFamily is thrown when a family admin tries to invite another user with active paid plan
var ErrCanNotInviteUserAlreadyInFamily = errors.New("can not invite user who is already part of a family")

// ErrFamilySizeLimitReached is thrown when a family admin tries to invite more than max allowed members for family plan
var ErrFamilySizeLimitReached = errors.New("can't invite new member, family already at max allowed size")

// ErrUserDeleted is thrown when Get user is called for a deleted account
var ErrUserDeleted = errors.New("user account has been deleted")

// ErrLockUnavailable is thrown when a lock could not be acquired
var ErrLockUnavailable = errors.New("could not acquire lock")

// ErrActiveLinkAlreadyExists is thrown when the collection already has active public link
var ErrActiveLinkAlreadyExists = errors.New("Collection already has active public link")

// ErrNotImplemented indicates that the action that we tried to perform is not
// available at this museum instance. e.g. this could be something that is not
// enabled on this particular instance of museum.
//
// Semantically, it could've been better called as NotAvailable, but
// NotAvailable is meant to be used for temporary errors, whilst we wish to
// indicate that this instance will not serve this request at all.
var ErrNotImplemented = errors.New("not implemented")

var ErrInvalidApp = errors.New("invalid app")

var ErrInvalidName = errors.New("invalid name")

var ErrSubscriptionAlreadyClaimed = ApiError{
	Code:           SubscriptionAlreadyClaimed,
	HttpStatusCode: http.StatusConflict,
	Message:        "Subscription is already associted with different account",
}

var ErrCollectionNotEmpty = ApiError{
	Code:           CollectionNotEmpty,
	HttpStatusCode: http.StatusConflict,
	Message:        "The collection is not empty",
}

var ErrFileNotFoundInAlbum = ApiError{
	Code:           FileNotFoundInAlbum,
	HttpStatusCode: http.StatusNotFound,
	Message:        "File is either deleted or moved to different collection",
}

var ErrSessionAlreadyClaimed = ApiError{
	Code:           "SESSION_ALREADY_CLAIMED",
	Message:        "Session is already claimed",
	HttpStatusCode: http.StatusConflict,
}

var ErrPublicCollectDisabled = ApiError{
	Code:           PublicCollectDisabled,
	Message:        "User has not enabled public collect for this url",
	HttpStatusCode: http.StatusMethodNotAllowed,
}

var ErrNotFoundError = ApiError{
	Code:           NotFoundError,
	Message:        "",
	HttpStatusCode: http.StatusNotFound,
}

var ErrMaxPasskeysReached = ApiError{
	Code:           MaxPasskeysReached,
	Message:        "Max passkeys limit reached",
	HttpStatusCode: http.StatusConflict,
}

var ErrCastPermissionDenied = ApiError{
	Code:           "CAST_PERMISSION_DENIED",
	Message:        "Permission denied",
	HttpStatusCode: http.StatusForbidden,
}

var ErrCastIPMismatch = ApiError{
	Code:           "CAST_IP_MISMATCH",
	Message:        "IP mismatch",
	HttpStatusCode: http.StatusForbidden,
}

type ErrorCode string

const (
	// Standard, generic error codes
	BadRequest ErrorCode = "BAD_REQUEST"
	CONFLICT   ErrorCode = "CONFLICT"

	InternalError ErrorCode = "INTERNAL_ERROR"

	NotFoundError ErrorCode = "NOT_FOUND"

	// Business specific error codes
	FamiliySizeLimitExceeded ErrorCode = "FAMILY_SIZE_LIMIT_EXCEEDED"

	// Subscription Already Associted with different account
	SubscriptionAlreadyClaimed ErrorCode = "SUBSCRIPTION_ALREADY_CLAIMED"

	FileNotFoundInAlbum ErrorCode = "FILE_NOT_FOUND_IN_ALBUM"

	// PublicCollectDisabled error code indicates that the user has not enabled public collect
	PublicCollectDisabled ErrorCode = "PUBLIC_COLLECT_DISABLED"

	// CollectionNotEmpty is thrown when user attempts to delete a collection but keep files but all files from that
	// collections have been moved yet.
	CollectionNotEmpty ErrorCode = "COLLECTION_NOT_EMPTY"

	// MaxPasskeysReached is thrown when user attempts to create more than max allowed passkeys
	MaxPasskeysReached ErrorCode = "MAX_PASSKEYS_REACHED"
)

type ApiError struct {
	// Code will be returned as part of the response body. Clients are expected to rely on this code while handling any error
	Code ErrorCode `json:"code"`
	// Optional message, which can give additional details about this error. Say for generic 404 error, it can return what entity is not found
	// like file/album/user. Client should never consume this message for showing err on screen or any special handling.
	Message        string `json:"message"`
	HttpStatusCode int    `json:"-"`
}

func (e *ApiError) NewErr(message string) *ApiError {
	return &ApiError{
		Code:           e.Code,
		Message:        message,
		HttpStatusCode: e.HttpStatusCode,
	}
}
func (e *ApiError) Error() string {
	return fmt.Sprintf("%s : %s", string(e.Code), e.Message)
}

type ApiErrorParams struct {
	HttpStatusCode *int
	Code           ErrorCode
	Message        string
}

var badRequestApiError = ApiError{
	Code:           BadRequest,
	HttpStatusCode: http.StatusBadRequest,
	Message:        "BAD_REQUEST",
}

func NewBadRequestError(params *ApiErrorParams) *ApiError {
	if params == nil {
		return &badRequestApiError
	}
	apiError := badRequestApiError
	if params.HttpStatusCode != nil {
		apiError.HttpStatusCode = *params.HttpStatusCode
	}
	if params.Message != "" {
		apiError.Message = params.Message
	}
	if params.Code != "" {
		apiError.Code = params.Code
	}
	return &apiError
}
func NewBadRequestWithMessage(message string) *ApiError {
	return &ApiError{
		Code:           BadRequest,
		HttpStatusCode: http.StatusBadRequest,
		Message:        message,
	}
}

func NewConflictError(message string) *ApiError {
	return &ApiError{
		Code:           CONFLICT,
		HttpStatusCode: http.StatusConflict,
		Message:        message,
	}
}

func NewInternalError(message string) *ApiError {
	apiError := ApiError{
		Code:           InternalError,
		HttpStatusCode: http.StatusInternalServerError,
		Message:        message,
	}
	return &apiError
}

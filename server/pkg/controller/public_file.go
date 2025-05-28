package controller

import (
	"context"
	"errors"
	"fmt"
	"github.com/ente-io/museum/ente"
	enteJWT "github.com/ente-io/museum/ente/jwt"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
	"github.com/lithammer/shortuuid/v3"
	"github.com/sirupsen/logrus"
)

func (c *PublicCollectionController) CreateAccessToken(ctx context.Context, req ente.CreatePublicAccessTokenRequest) (ente.PublicURL, error) {
	accessToken := shortuuid.New()[0:AccessTokenLength]
	err := c.PublicCollectionRepo.
		Insert(ctx, req.CollectionID, accessToken, req.ValidTill, req.DeviceLimit, req.EnableCollect, req.EnableJoin)
	if err != nil {
		if errors.Is(err, ente.ErrActiveLinkAlreadyExists) {
			collectionToPubUrlMap, err2 := c.PublicCollectionRepo.GetCollectionToActivePublicURLMap(ctx, []int64{req.CollectionID})
			if err2 != nil {
				return ente.PublicURL{}, stacktrace.Propagate(err2, "")
			}
			if publicUrls, ok := collectionToPubUrlMap[req.CollectionID]; ok {
				if len(publicUrls) > 0 {
					return publicUrls[0], nil
				}
			}
			// ideally we should never reach here
			return ente.PublicURL{}, stacktrace.NewError("Unexpected state")
		} else {
			return ente.PublicURL{}, stacktrace.Propagate(err, "")
		}
	}
	response := ente.PublicURL{
		URL:             c.PublicCollectionRepo.GetAlbumUrl(accessToken),
		ValidTill:       req.ValidTill,
		DeviceLimit:     req.DeviceLimit,
		EnableDownload:  true,
		EnableCollect:   req.EnableCollect,
		PasswordEnabled: false,
	}
	return response, nil
}

func (c *PublicCollectionController) GetActivePublicCollectionToken(ctx context.Context, collectionID int64) (ente.PublicCollectionToken, error) {
	return c.PublicCollectionRepo.GetActivePublicCollectionToken(ctx, collectionID)
}

func (c *PublicCollectionController) CreateFile(ctx *gin.Context, file ente.File, app ente.App) (ente.File, error) {
	collection, err := c.GetPublicCollection(ctx, true)
	if err != nil {
		return ente.File{}, stacktrace.Propagate(err, "")
	}
	collectionOwnerID := collection.Owner.ID
	// Do not let any update happen via public Url
	file.ID = 0
	file.OwnerID = collectionOwnerID
	file.UpdationTime = time.Microseconds()
	file.IsDeleted = false
	createdFile, err := c.FileController.Create(ctx, collectionOwnerID, file, ctx.Request.UserAgent(), app)
	if err != nil {
		return ente.File{}, stacktrace.Propagate(err, "")
	}

	// Note: Stop sending email notification for public collection till
	// we add in-app setting to enable/disable email notifications
	//go c.EmailNotificationCtrl.OnFilesCollected(file.OwnerID)
	return createdFile, nil
}

// Disable all public accessTokens generated for the given cID till date.
func (c *PublicCollectionController) Disable(ctx context.Context, cID int64) error {
	err := c.PublicCollectionRepo.DisableSharing(ctx, cID)
	return stacktrace.Propagate(err, "")
}

func (c *PublicCollectionController) UpdateSharedUrl(ctx context.Context, req ente.UpdatePublicAccessTokenRequest) (ente.PublicURL, error) {
	publicCollectionToken, err := c.PublicCollectionRepo.GetActivePublicCollectionToken(ctx, req.CollectionID)
	if err != nil {
		return ente.PublicURL{}, err
	}
	if req.ValidTill != nil {
		publicCollectionToken.ValidTill = *req.ValidTill
	}
	if req.DeviceLimit != nil {
		publicCollectionToken.DeviceLimit = *req.DeviceLimit
	}
	if req.PassHash != nil && req.Nonce != nil && req.OpsLimit != nil && req.MemLimit != nil {
		publicCollectionToken.PassHash = req.PassHash
		publicCollectionToken.Nonce = req.Nonce
		publicCollectionToken.OpsLimit = req.OpsLimit
		publicCollectionToken.MemLimit = req.MemLimit
	} else if req.DisablePassword != nil && *req.DisablePassword {
		publicCollectionToken.PassHash = nil
		publicCollectionToken.Nonce = nil
		publicCollectionToken.OpsLimit = nil
		publicCollectionToken.MemLimit = nil
	}
	if req.EnableDownload != nil {
		publicCollectionToken.EnableDownload = *req.EnableDownload
	}
	if req.EnableCollect != nil {
		publicCollectionToken.EnableCollect = *req.EnableCollect
	}
	if req.EnableJoin != nil {
		publicCollectionToken.EnableJoin = *req.EnableJoin
	}
	err = c.PublicCollectionRepo.UpdatePublicCollectionToken(ctx, publicCollectionToken)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	return ente.PublicURL{
		URL:             c.PublicCollectionRepo.GetAlbumUrl(publicCollectionToken.Token),
		DeviceLimit:     publicCollectionToken.DeviceLimit,
		ValidTill:       publicCollectionToken.ValidTill,
		EnableDownload:  publicCollectionToken.EnableDownload,
		EnableCollect:   publicCollectionToken.EnableCollect,
		EnableJoin:      publicCollectionToken.EnableJoin,
		PasswordEnabled: publicCollectionToken.PassHash != nil && *publicCollectionToken.PassHash != "",
		Nonce:           publicCollectionToken.Nonce,
		MemLimit:        publicCollectionToken.MemLimit,
		OpsLimit:        publicCollectionToken.OpsLimit,
	}, nil
}

// VerifyPassword verifies if the user has provided correct pw hash. If yes, it returns a signed jwt token which can be
// used by the client to pass in other requests for public collection.
// Having a separate endpoint for password validation allows us to easily rate-limit the attempts for brute-force
// attack for guessing password.
func (c *PublicCollectionController) VerifyPassword(ctx *gin.Context, req ente.VerifyPasswordRequest) (*ente.VerifyPasswordResponse, error) {
	accessContext := auth.MustGetPublicAccessContext(ctx)
	publicCollectionToken, err := c.PublicCollectionRepo.GetActivePublicCollectionToken(ctx, accessContext.CollectionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get public collection info")
	}
	if publicCollectionToken.PassHash == nil || *publicCollectionToken.PassHash == "" {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "password is not configured for the link")
	}
	if req.PassHash != *publicCollectionToken.PassHash {
		return nil, stacktrace.Propagate(ente.ErrInvalidPassword, "incorrect password for link")
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, &enteJWT.PublicAlbumPasswordClaim{
		PassHash:   req.PassHash,
		ExpiryTime: time.NDaysFromNow(365),
	})
	// Sign and get the complete encoded token as a string using the secret
	tokenString, err := token.SignedString(c.JwtSecret)

	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ente.VerifyPasswordResponse{
		JWTToken: tokenString,
	}, nil
}

func (c *PublicCollectionController) ValidateJWTToken(ctx *gin.Context, jwtToken string, passwordHash string) error {
	token, err := jwt.ParseWithClaims(jwtToken, &enteJWT.PublicAlbumPasswordClaim{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return stacktrace.Propagate(fmt.Errorf("unexpected signing method: %v", token.Header["alg"]), ""), nil
		}
		return c.JwtSecret, nil
	})
	if err != nil {
		return stacktrace.Propagate(err, "JWT parsed failed")
	}
	claims, ok := token.Claims.(*enteJWT.PublicAlbumPasswordClaim)

	if !ok {
		return stacktrace.Propagate(errors.New("no claim in jwt token"), "")
	}
	if token.Valid && claims.PassHash == passwordHash {
		return nil
	}
	return ente.ErrInvalidPassword
}

func (c *PublicCollectionController) HandleAccountDeletion(ctx context.Context, userID int64, logger *logrus.Entry) error {
	logger.Info("updating public collection on account deletion")
	collectionIDs, err := c.PublicCollectionRepo.GetActivePublicTokenForUser(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	logger.WithField("cIDs", collectionIDs).Info("disable public tokens due to account deletion")
	for _, collectionID := range collectionIDs {
		err = c.Disable(ctx, collectionID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	return nil
}

// GetPublicCollection will return collection info for a public url.
// is mustAllowCollect is set to true but the underlying collection doesn't allow uploading
func (c *PublicCollectionController) GetPublicCollection(ctx *gin.Context, mustAllowCollect bool) (ente.Collection, error) {
	accessContext := auth.MustGetPublicAccessContext(ctx)
	collection, err := c.CollectionRepo.Get(accessContext.CollectionID)
	if err != nil {
		return ente.Collection{}, stacktrace.Propagate(err, "")
	}
	if collection.IsDeleted {
		return ente.Collection{}, stacktrace.Propagate(ente.ErrNotFound, "collection is deleted")
	}
	// hide redundant/private information
	collection.Sharees = nil
	collection.MagicMetadata = nil
	publicURLsWithLimitedInfo := make([]ente.PublicURL, 0)
	for _, publicUrl := range collection.PublicURLs {
		publicURLsWithLimitedInfo = append(publicURLsWithLimitedInfo, ente.PublicURL{
			EnableDownload:  publicUrl.EnableDownload,
			EnableCollect:   publicUrl.EnableCollect,
			PasswordEnabled: publicUrl.PasswordEnabled,
			Nonce:           publicUrl.Nonce,
			MemLimit:        publicUrl.MemLimit,
			OpsLimit:        publicUrl.OpsLimit,
			EnableJoin:      publicUrl.EnableJoin,
		})
	}
	collection.PublicURLs = publicURLsWithLimitedInfo
	if mustAllowCollect {
		if len(publicURLsWithLimitedInfo) != 1 {
			errorMsg := fmt.Sprintf("Unexpected number of public urls: %d", len(publicURLsWithLimitedInfo))
			return ente.Collection{}, stacktrace.Propagate(ente.NewInternalError(errorMsg), "")
		}
		if !publicURLsWithLimitedInfo[0].EnableCollect {
			return ente.Collection{}, stacktrace.Propagate(&ente.ErrPublicCollectDisabled, "")
		}
	}
	return collection, nil
}

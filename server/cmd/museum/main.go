package main

import (
	"context"
	"database/sql"
	b64 "encoding/base64"
	"fmt"
	"github.com/ente-io/museum/pkg/controller/file_copy"
	"net/http"
	"os"
	"os/signal"
	"path"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/ente-io/museum/pkg/repo/two_factor_recovery"

	"github.com/ente-io/museum/pkg/controller/cast"

	"github.com/ente-io/museum/pkg/controller/commonbilling"

	cache2 "github.com/ente-io/museum/ente/cache"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/controller/offer"
	"github.com/ente-io/museum/pkg/controller/usercache"

	"github.com/GoKillers/libsodium-go/sodium"
	"github.com/dlmiddlecote/sqlstats"
	"github.com/ente-io/museum/ente/jwt"
	"github.com/ente-io/museum/pkg/api"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/access"
	authenticatorCtrl "github.com/ente-io/museum/pkg/controller/authenticator"
	dataCleanupCtrl "github.com/ente-io/museum/pkg/controller/data_cleanup"
	"github.com/ente-io/museum/pkg/controller/email"
	embeddingCtrl "github.com/ente-io/museum/pkg/controller/embedding"
	"github.com/ente-io/museum/pkg/controller/family"
	kexCtrl "github.com/ente-io/museum/pkg/controller/kex"
	"github.com/ente-io/museum/pkg/controller/lock"
	remoteStoreCtrl "github.com/ente-io/museum/pkg/controller/remotestore"
	"github.com/ente-io/museum/pkg/controller/storagebonus"
	"github.com/ente-io/museum/pkg/controller/user"
	userEntityCtrl "github.com/ente-io/museum/pkg/controller/userentity"
	"github.com/ente-io/museum/pkg/middleware"
	"github.com/ente-io/museum/pkg/repo"
	authenticatorRepo "github.com/ente-io/museum/pkg/repo/authenticator"
	castRepo "github.com/ente-io/museum/pkg/repo/cast"
	"github.com/ente-io/museum/pkg/repo/datacleanup"
	"github.com/ente-io/museum/pkg/repo/embedding"
	"github.com/ente-io/museum/pkg/repo/kex"
	"github.com/ente-io/museum/pkg/repo/passkey"
	"github.com/ente-io/museum/pkg/repo/remotestore"
	storageBonusRepo "github.com/ente-io/museum/pkg/repo/storagebonus"
	userEntityRepo "github.com/ente-io/museum/pkg/repo/userentity"
	"github.com/ente-io/museum/pkg/utils/billing"
	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/s3config"
	timeUtil "github.com/ente-io/museum/pkg/utils/time"
	"github.com/gin-contrib/gzip"
	"github.com/gin-contrib/requestid"
	"github.com/gin-contrib/timeout"
	"github.com/gin-gonic/gin"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"github.com/patrickmn/go-cache"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/robfig/cron/v3"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	ginprometheus "github.com/zsais/go-gin-prometheus"
	"gopkg.in/natefinch/lumberjack.v2"
)

func main() {
	environment := os.Getenv("ENVIRONMENT")
	if environment == "" {
		environment = "local"
	}

	err := config.ConfigureViper(environment)
	if err != nil {
		panic(err)
	}

	setupLogger(environment)
	log.Infof("Booting up %s server with commit #%s", environment, os.Getenv("GIT_COMMIT"))

	secretEncryptionKey := viper.GetString("key.encryption")
	hashingKey := viper.GetString("key.hash")
	jwtSecret := viper.GetString("jwt.secret")

	secretEncryptionKeyBytes, err := b64.StdEncoding.DecodeString(secretEncryptionKey)
	if err != nil {
		log.Fatal("Could not decode email-encryption-key", err)
	}
	hashingKeyBytes, err := b64.StdEncoding.DecodeString(hashingKey)
	if err != nil {
		log.Fatal("Could not decode email-hash-key", err)
	}

	jwtSecretBytes, err := b64.URLEncoding.DecodeString(jwtSecret)
	if err != nil {
		log.Fatal("Could not decode jwt-secret ", err)
	}

	db := setupDatabase()
	defer db.Close()

	sodium.Init()

	hostName, err := os.Hostname()
	if err != nil {
		log.Fatal("Could not get host name", err)
	}
	taskLockingRepo := &repo.TaskLockRepository{DB: db}
	lockController := &lock.LockController{
		TaskLockingRepo: taskLockingRepo,
		HostName:        hostName,
	}
	// Note: during boot-up, release any locks that might have been left behind.
	// This is a safety measure to ensure that no locks are left behind in case of a crash or restart.
	lockController.ReleaseHostLock()

	var latencyLogger = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "museum_method_latency",
		Help:    "The amount of time each method is taking to respond",
		Buckets: []float64{10, 50, 100, 200, 500, 1000, 10000, 30000, 60000, 120000, 600000},
	}, []string{"method"})

	s3Config := s3config.NewS3Config()

	passkeysRepo, err := passkey.NewRepository(db)
	if err != nil {
		panic(err)
	}

	storagBonusRepo := &storageBonusRepo.Repository{DB: db}
	castDb := castRepo.Repository{DB: db}
	userRepo := &repo.UserRepository{DB: db, SecretEncryptionKey: secretEncryptionKeyBytes, HashingKey: hashingKeyBytes, StorageBonusRepo: storagBonusRepo, PasskeysRepository: passkeysRepo}

	twoFactorRepo := &repo.TwoFactorRepository{DB: db, SecretEncryptionKey: secretEncryptionKeyBytes}
	userAuthRepo := &repo.UserAuthRepository{DB: db}
	twoFactorRecoveryRepo := &two_factor_recovery.Repository{Db: db, SecretEncryptionKey: secretEncryptionKeyBytes}
	billingRepo := &repo.BillingRepository{DB: db}
	userEntityRepo := &userEntityRepo.Repository{DB: db}
	authRepo := &authenticatorRepo.Repository{DB: db}
	remoteStoreRepository := &remotestore.Repository{DB: db}
	dataCleanupRepository := &datacleanup.Repository{DB: db}

	notificationHistoryRepo := &repo.NotificationHistoryRepository{DB: db}
	queueRepo := &repo.QueueRepository{DB: db}
	objectRepo := &repo.ObjectRepository{DB: db, QueueRepo: queueRepo}
	objectCleanupRepo := &repo.ObjectCleanupRepository{DB: db}
	objectCopiesRepo := &repo.ObjectCopiesRepository{DB: db}
	usageRepo := &repo.UsageRepository{DB: db, UserRepo: userRepo}
	fileRepo := &repo.FileRepository{DB: db, S3Config: s3Config, QueueRepo: queueRepo,
		ObjectRepo: objectRepo, ObjectCleanupRepo: objectCleanupRepo,
		ObjectCopiesRepo: objectCopiesRepo, UsageRepo: usageRepo}
	familyRepo := &repo.FamilyRepository{DB: db}
	trashRepo := &repo.TrashRepository{DB: db, ObjectRepo: objectRepo, FileRepo: fileRepo, QueueRepo: queueRepo}
	publicCollectionRepo := repo.NewPublicCollectionRepository(db, viper.GetString("apps.public-albums"))
	collectionRepo := &repo.CollectionRepository{DB: db, FileRepo: fileRepo, PublicCollectionRepo: publicCollectionRepo,
		TrashRepo: trashRepo, SecretEncryptionKey: secretEncryptionKeyBytes, QueueRepo: queueRepo, LatencyLogger: latencyLogger}
	pushRepo := &repo.PushTokenRepository{DB: db}
	kexRepo := &kex.Repository{
		DB: db,
	}
	embeddingRepo := &embedding.Repository{DB: db}

	authCache := cache.New(1*time.Minute, 15*time.Minute)
	accessTokenCache := cache.New(1*time.Minute, 15*time.Minute)
	discordController := discord.NewDiscordController(userRepo, hostName, environment)
	rateLimiter := middleware.NewRateLimitMiddleware(discordController, 1000, 1*time.Second)
	defer rateLimiter.Stop()

	emailNotificationCtrl := &email.EmailNotificationController{
		UserRepo:                userRepo,
		LockController:          lockController,
		NotificationHistoryRepo: notificationHistoryRepo,
	}

	userCache := cache2.NewUserCache()
	userCacheCtrl := &usercache.Controller{UserCache: userCache, FileRepo: fileRepo, StoreBonusRepo: storagBonusRepo}
	offerController := offer.NewOfferController(*userRepo, discordController, storagBonusRepo, userCacheCtrl)
	plans := billing.GetPlans()
	defaultPlan := billing.GetDefaultPlans(plans)
	stripeClients := billing.GetStripeClients()
	commonBillController := commonbilling.NewController(storagBonusRepo, userRepo, usageRepo)
	appStoreController := controller.NewAppStoreController(defaultPlan,
		billingRepo, fileRepo, userRepo, commonBillController)
	remoteStoreController := &remoteStoreCtrl.Controller{Repo: remoteStoreRepository}
	playStoreController := controller.NewPlayStoreController(defaultPlan,
		billingRepo, fileRepo, userRepo, storagBonusRepo, commonBillController)
	stripeController := controller.NewStripeController(plans, stripeClients,
		billingRepo, fileRepo, userRepo, storagBonusRepo, discordController, emailNotificationCtrl, offerController, commonBillController)
	billingController := controller.NewBillingController(plans,
		appStoreController, playStoreController, stripeController,
		discordController, emailNotificationCtrl,
		billingRepo, userRepo, usageRepo, storagBonusRepo, commonBillController)
	pushController := controller.NewPushController(pushRepo, taskLockingRepo, hostName)
	mailingListsController := controller.NewMailingListsController()

	storageBonusCtrl := &storagebonus.Controller{
		UserRepo:                    userRepo,
		StorageBonus:                storagBonusRepo,
		LockController:              lockController,
		CronRunning:                 false,
		EmailNotificationController: emailNotificationCtrl,
	}

	objectController := &controller.ObjectController{
		S3Config:       s3Config,
		ObjectRepo:     objectRepo,
		QueueRepo:      queueRepo,
		LockController: lockController,
	}
	objectCleanupController := controller.NewObjectCleanupController(
		objectCleanupRepo,
		objectRepo,
		lockController,
		objectController,
		s3Config,
	)

	usageController := &controller.UsageController{
		BillingCtrl:      billingController,
		StorageBonusCtrl: storageBonusCtrl,
		UserCacheCtrl:    userCacheCtrl,
		UsageRepo:        usageRepo,
		UserRepo:         userRepo,
		FamilyRepo:       familyRepo,
		FileRepo:         fileRepo,
	}

	fileController := &controller.FileController{
		FileRepo:              fileRepo,
		ObjectRepo:            objectRepo,
		ObjectCleanupRepo:     objectCleanupRepo,
		TrashRepository:       trashRepo,
		UserRepo:              userRepo,
		UsageCtrl:             usageController,
		CollectionRepo:        collectionRepo,
		TaskLockingRepo:       taskLockingRepo,
		QueueRepo:             queueRepo,
		ObjectCleanupCtrl:     objectCleanupController,
		LockController:        lockController,
		EmailNotificationCtrl: emailNotificationCtrl,
		S3Config:              s3Config,
		HostName:              hostName,
	}

	replicationController3 := &controller.ReplicationController3{
		S3Config:          s3Config,
		ObjectRepo:        objectRepo,
		ObjectCopiesRepo:  objectCopiesRepo,
		DiscordController: discordController,
	}

	trashController := &controller.TrashController{
		TrashRepo:      trashRepo,
		FileRepo:       fileRepo,
		CollectionRepo: collectionRepo,
		QueueRepo:      queueRepo,
		TaskLockRepo:   taskLockingRepo,
		HostName:       hostName,
	}

	familyController := &family.Controller{
		FamilyRepo:    familyRepo,
		BillingCtrl:   billingController,
		UserRepo:      userRepo,
		UserCacheCtrl: userCacheCtrl,
	}

	publicCollectionCtrl := &controller.PublicCollectionController{
		FileController:        fileController,
		EmailNotificationCtrl: emailNotificationCtrl,
		PublicCollectionRepo:  publicCollectionRepo,
		CollectionRepo:        collectionRepo,
		UserRepo:              userRepo,
		JwtSecret:             jwtSecretBytes,
	}

	accessCtrl := access.NewAccessController(collectionRepo, fileRepo)

	collectionController := &controller.CollectionController{
		CollectionRepo:       collectionRepo,
		AccessCtrl:           accessCtrl,
		PublicCollectionCtrl: publicCollectionCtrl,
		UserRepo:             userRepo,
		FileRepo:             fileRepo,
		CastRepo:             &castDb,
		BillingCtrl:          billingController,
		QueueRepo:            queueRepo,
		TaskRepo:             taskLockingRepo,
	}

	kexCtrl := &kexCtrl.Controller{
		Repo: kexRepo,
	}

	userController := user.NewUserController(
		userRepo,
		usageRepo,
		userAuthRepo,
		twoFactorRepo,
		twoFactorRecoveryRepo,
		passkeysRepo,
		storagBonusRepo,
		fileRepo,
		collectionController,
		collectionRepo,
		dataCleanupRepository,
		billingRepo,
		secretEncryptionKeyBytes,
		hashingKeyBytes,
		authCache,
		jwtSecretBytes,
		billingController,
		familyController,
		discordController,
		mailingListsController,
		pushController,
		userCache,
		userCacheCtrl,
	)

	passkeyCtrl := &controller.PasskeyController{
		Repo:     passkeysRepo,
		UserRepo: userRepo,
	}

	authMiddleware := middleware.AuthMiddleware{UserAuthRepo: userAuthRepo, Cache: authCache, UserController: userController}
	accessTokenMiddleware := middleware.AccessTokenMiddleware{
		PublicCollectionRepo: publicCollectionRepo,
		PublicCollectionCtrl: publicCollectionCtrl,
		CollectionRepo:       collectionRepo,
		Cache:                accessTokenCache,
		BillingCtrl:          billingController,
		DiscordController:    discordController,
	}

	if environment != "local" {
		gin.SetMode(gin.ReleaseMode)
	}
	server := gin.New()

	p := ginprometheus.NewPrometheus("museum")
	p.ReqCntURLLabelMappingFn = urlSanitizer
	p.Use(server)

	// note: the recover middleware must be in the last
	server.Use(requestid.New(), middleware.Logger(urlSanitizer), cors(), gzip.Gzip(gzip.DefaultCompression), middleware.PanicRecover())

	publicAPI := server.Group("/")
	publicAPI.Use(rateLimiter.GlobalRateLimiter(), rateLimiter.APIRateLimitMiddleware(urlSanitizer))

	privateAPI := server.Group("/")
	privateAPI.Use(rateLimiter.GlobalRateLimiter(), authMiddleware.TokenAuthMiddleware(nil), rateLimiter.APIRateLimitForUserMiddleware(urlSanitizer))

	adminAPI := server.Group("/admin")
	adminAPI.Use(rateLimiter.GlobalRateLimiter(), authMiddleware.TokenAuthMiddleware(nil), authMiddleware.AdminAuthMiddleware())
	paymentJwtAuthAPI := server.Group("/")
	paymentJwtAuthAPI.Use(rateLimiter.GlobalRateLimiter(), authMiddleware.TokenAuthMiddleware(jwt.PAYMENT.Ptr()))

	familiesJwtAuthAPI := server.Group("/")
	//The middleware order matters. First, the userID must be set in the context, so that we can apply limit for user.
	familiesJwtAuthAPI.Use(rateLimiter.GlobalRateLimiter(), authMiddleware.TokenAuthMiddleware(jwt.FAMILIES.Ptr()), rateLimiter.APIRateLimitForUserMiddleware(urlSanitizer))

	publicCollectionAPI := server.Group("/public-collection")
	publicCollectionAPI.Use(rateLimiter.GlobalRateLimiter(), accessTokenMiddleware.AccessTokenAuthMiddleware(urlSanitizer))

	healthCheckHandler := &api.HealthCheckHandler{
		DB: db,
	}
	publicAPI.GET("/ping", timeout.New(
		timeout.WithTimeout(5*time.Second),
		timeout.WithHandler(healthCheckHandler.Ping),
		timeout.WithResponse(timeOutResponse),
	))

	publicAPI.GET("/fire/db-m-ping", timeout.New(
		timeout.WithTimeout(5*time.Second),
		timeout.WithHandler(healthCheckHandler.PingDBStats),
		timeout.WithResponse(timeOutResponse),
	))
	fileCopyCtrl := &file_copy.FileCopyController{
		FileController: fileController,
		CollectionCtrl: collectionController,
		S3Config:       s3Config,
		ObjectRepo:     objectRepo,
		FileRepo:       fileRepo,
	}

	fileHandler := &api.FileHandler{
		Controller:   fileController,
		FileCopyCtrl: fileCopyCtrl,
	}
	privateAPI.GET("/files/upload-urls", fileHandler.GetUploadURLs)
	privateAPI.GET("/files/multipart-upload-urls", fileHandler.GetMultipartUploadURLs)
	privateAPI.GET("/files/download/:fileID", fileHandler.Get)
	privateAPI.GET("/files/download/v2/:fileID", fileHandler.Get)
	privateAPI.GET("/files/preview/:fileID", fileHandler.GetThumbnail)
	privateAPI.GET("/files/preview/v2/:fileID", fileHandler.GetThumbnail)
	privateAPI.POST("/files", fileHandler.CreateOrUpdate)
	privateAPI.POST("/files/copy", fileHandler.CopyFiles)
	privateAPI.PUT("/files/update", fileHandler.Update)
	privateAPI.POST("/files/trash", fileHandler.Trash)
	privateAPI.POST("/files/size", fileHandler.GetSize)
	privateAPI.POST("/files/info", fileHandler.GetInfo)
	privateAPI.GET("/files/duplicates", fileHandler.GetDuplicates)
	privateAPI.GET("/files/large-thumbnails", fileHandler.GetLargeThumbnailFiles)
	privateAPI.PUT("/files/thumbnail", fileHandler.UpdateThumbnail)
	privateAPI.PUT("/files/magic-metadata", fileHandler.UpdateMagicMetadata)
	privateAPI.PUT("/files/public-magic-metadata", fileHandler.UpdatePublicMagicMetadata)
	publicAPI.GET("/files/count", fileHandler.GetTotalFileCount)

	kexHandler := &api.KexHandler{
		Controller: kexCtrl,
	}
	publicAPI.GET("/kex/get", kexHandler.GetKey)
	publicAPI.PUT("/kex/add", kexHandler.AddKey)

	trashHandler := &api.TrashHandler{
		Controller: trashController,
	}
	privateAPI.GET("/trash/diff", trashHandler.GetDiff)
	privateAPI.GET("/trash/v2/diff", trashHandler.GetDiffV2)
	privateAPI.POST("/trash/delete", trashHandler.Delete)
	privateAPI.POST("/trash/empty", trashHandler.Empty)

	userHandler := &api.UserHandler{
		UserController: userController,
	}
	publicAPI.POST("/users/ott", userHandler.SendOTT)
	publicAPI.POST("/users/verify-email", userHandler.VerifyEmail)
	publicAPI.POST("/users/two-factor/verify", userHandler.VerifyTwoFactor)
	publicAPI.GET("/users/two-factor/recover", userHandler.RecoverTwoFactor)
	publicAPI.POST("/users/two-factor/remove", userHandler.RemoveTwoFactor)
	publicAPI.POST("/users/two-factor/passkeys/begin", userHandler.BeginPasskeyAuthenticationCeremony)
	publicAPI.POST("/users/two-factor/passkeys/finish", userHandler.FinishPasskeyAuthenticationCeremony)
	privateAPI.GET("/users/two-factor/recovery-status", userHandler.GetTwoFactorRecoveryStatus)
	privateAPI.POST("/users/two-factor/passkeys/configure-recovery", userHandler.ConfigurePasskeyRecovery)
	privateAPI.GET("/users/two-factor/status", userHandler.GetTwoFactorStatus)
	privateAPI.POST("/users/two-factor/setup", userHandler.SetupTwoFactor)
	privateAPI.POST("/users/two-factor/enable", userHandler.EnableTwoFactor)
	privateAPI.POST("/users/two-factor/disable", userHandler.DisableTwoFactor)
	privateAPI.PUT("/users/attributes", userHandler.SetAttributes)
	privateAPI.PUT("/users/email-mfa", userHandler.UpdateEmailMFA)
	privateAPI.PUT("/users/keys", userHandler.UpdateKeys)
	privateAPI.POST("/users/srp/setup", userHandler.SetupSRP)
	privateAPI.POST("/users/srp/complete", userHandler.CompleteSRPSetup)
	privateAPI.POST("/users/srp/update", userHandler.UpdateSrpAndKeyAttributes)
	publicAPI.GET("/users/srp/attributes", userHandler.GetSRPAttributes)
	publicAPI.POST("/users/srp/verify-session", userHandler.VerifySRPSession)
	publicAPI.POST("/users/srp/create-session", userHandler.CreateSRPSession)
	privateAPI.PUT("/users/recovery-key", userHandler.SetRecoveryKey)
	privateAPI.GET("/users/public-key", userHandler.GetPublicKey)
	privateAPI.GET("/users/feedback", userHandler.GetRoadmapURL)
	privateAPI.GET("/users/roadmap", userHandler.GetRoadmapURL)
	privateAPI.GET("/users/roadmap/v2", userHandler.GetRoadmapURLV2)
	privateAPI.GET("/users/session-validity/v2", userHandler.GetSessionValidityV2)
	privateAPI.POST("/users/event", userHandler.ReportEvent)
	privateAPI.POST("/users/logout", userHandler.Logout)
	privateAPI.GET("/users/payment-token", userHandler.GetPaymentToken)
	privateAPI.GET("/users/families-token", userHandler.GetFamiliesToken)
	privateAPI.GET("/users/accounts-token", userHandler.GetAccountsToken)
	privateAPI.GET("/users/details", userHandler.GetDetails)
	privateAPI.GET("/users/details/v2", userHandler.GetDetailsV2)
	privateAPI.POST("/users/change-email", userHandler.ChangeEmail)
	privateAPI.GET("/users/sessions", userHandler.GetActiveSessions)
	privateAPI.DELETE("/users/session", userHandler.TerminateSession)
	privateAPI.GET("/users/delete-challenge", userHandler.GetDeleteChallenge)
	privateAPI.DELETE("/users/delete", userHandler.DeleteUser)

	accountsJwtAuthAPI := server.Group("/")
	accountsJwtAuthAPI.Use(rateLimiter.GlobalRateLimiter(), authMiddleware.TokenAuthMiddleware(jwt.ACCOUNTS.Ptr()), rateLimiter.APIRateLimitForUserMiddleware(urlSanitizer))
	passkeysHandler := &api.PasskeyHandler{
		Controller: passkeyCtrl,
	}
	accountsJwtAuthAPI.GET("/passkeys", passkeysHandler.GetPasskeys)
	accountsJwtAuthAPI.PATCH("/passkeys/:passkeyID", passkeysHandler.RenamePasskey)
	accountsJwtAuthAPI.DELETE("/passkeys/:passkeyID", passkeysHandler.DeletePasskey)
	accountsJwtAuthAPI.POST("/passkeys/registration/begin", passkeysHandler.BeginRegistration)
	accountsJwtAuthAPI.POST("/passkeys/registration/finish", passkeysHandler.FinishRegistration)

	collectionHandler := &api.CollectionHandler{
		Controller: collectionController,
	}
	privateAPI.POST("/collections", collectionHandler.Create)
	privateAPI.GET("/collections/:collectionID", collectionHandler.GetCollectionByID)
	//lint:ignore SA1019 Deprecated API will be removed in the future
	privateAPI.GET("/collections", collectionHandler.Get)
	privateAPI.GET("/collections/v2", collectionHandler.GetV2)
	privateAPI.POST("/collections/share", collectionHandler.Share)
	privateAPI.POST("/collections/share-url", collectionHandler.ShareURL)
	privateAPI.PUT("/collections/share-url", collectionHandler.UpdateShareURL)
	privateAPI.DELETE("/collections/share-url/:collectionID", collectionHandler.UnShareURL)
	privateAPI.POST("/collections/unshare", collectionHandler.UnShare)
	privateAPI.POST("/collections/leave/:collectionID", collectionHandler.Leave)
	privateAPI.POST("/collections/add-files", collectionHandler.AddFiles)
	privateAPI.POST("/collections/move-files", collectionHandler.MoveFiles)
	privateAPI.POST("/collections/restore-files", collectionHandler.RestoreFiles)

	privateAPI.POST("/collections/v3/remove-files", collectionHandler.RemoveFilesV3)
	privateAPI.GET("/collections/v2/diff", collectionHandler.GetDiffV2)
	privateAPI.GET("/collections/file", collectionHandler.GetFile)
	privateAPI.GET("/collections/sharees", collectionHandler.GetSharees)
	privateAPI.DELETE("/collections/v3/:collectionID", collectionHandler.TrashV3)
	privateAPI.POST("/collections/rename", collectionHandler.Rename)
	privateAPI.PUT("/collections/magic-metadata", collectionHandler.PrivateMagicMetadataUpdate)
	privateAPI.PUT("/collections/public-magic-metadata", collectionHandler.PublicMagicMetadataUpdate)
	privateAPI.PUT("/collections/sharee-magic-metadata", collectionHandler.ShareeMagicMetadataUpdate)

	publicCollectionHandler := &api.PublicCollectionHandler{
		Controller:             publicCollectionCtrl,
		FileCtrl:               fileController,
		CollectionCtrl:         collectionController,
		StorageBonusController: storageBonusCtrl,
	}

	publicCollectionAPI.GET("/files/preview/:fileID", publicCollectionHandler.GetThumbnail)
	publicCollectionAPI.GET("/files/download/:fileID", publicCollectionHandler.GetFile)
	publicCollectionAPI.GET("/diff", publicCollectionHandler.GetDiff)
	publicCollectionAPI.GET("/info", publicCollectionHandler.GetCollection)
	publicCollectionAPI.GET("/upload-urls", publicCollectionHandler.GetUploadUrls)
	publicCollectionAPI.GET("/multipart-upload-urls", publicCollectionHandler.GetMultipartUploadURLs)
	publicCollectionAPI.POST("/file", publicCollectionHandler.CreateFile)
	publicCollectionAPI.POST("/verify-password", publicCollectionHandler.VerifyPassword)
	publicCollectionAPI.POST("/report-abuse", publicCollectionHandler.ReportAbuse)

	castAPI := server.Group("/cast")

	castCtrl := cast.NewController(&castDb, accessCtrl)
	castMiddleware := middleware.CastMiddleware{CastCtrl: castCtrl, Cache: authCache}
	castAPI.Use(rateLimiter.GlobalRateLimiter(), castMiddleware.CastAuthMiddleware())

	castHandler := &api.CastHandler{
		CollectionCtrl: collectionController,
		FileCtrl:       fileController,
		Ctrl:           castCtrl,
	}

	publicAPI.POST("/cast/device-info/", castHandler.RegisterDevice)
	privateAPI.GET("/cast/device-info/:deviceCode", castHandler.GetDeviceInfo)
	publicAPI.GET("/cast/cast-data/:deviceCode", castHandler.GetCastData)
	privateAPI.POST("/cast/cast-data/", castHandler.InsertCastData)
	privateAPI.DELETE("/cast/revoke-all-tokens/", castHandler.RevokeAllToken)

	castAPI.GET("/files/preview/:fileID", castHandler.GetThumbnail)
	castAPI.GET("/files/download/:fileID", castHandler.GetFile)
	castAPI.GET("/diff", castHandler.GetDiff)
	castAPI.GET("/info", castHandler.GetCollection)
	familyHandler := &api.FamilyHandler{
		Controller: familyController,
	}

	publicAPI.GET("/family/invite-info/:token", familyHandler.GetInviteInfo)
	publicAPI.POST("/family/accept-invite", familyHandler.AcceptInvite)

	privateAPI.DELETE("/family/leave", familyHandler.Leave) // native/web app

	familiesJwtAuthAPI.POST("/family/create", familyHandler.CreateFamily)
	familiesJwtAuthAPI.POST("/family/add-member", familyHandler.InviteMember)
	familiesJwtAuthAPI.GET("/family/members", familyHandler.FetchMembers)
	familiesJwtAuthAPI.DELETE("/family/remove-member/:id", familyHandler.RemoveMember)
	familiesJwtAuthAPI.DELETE("/family/revoke-invite/:id", familyHandler.RevokeInvite)

	billingHandler := &api.BillingHandler{
		Controller:          billingController,
		AppStoreController:  appStoreController,
		PlayStoreController: playStoreController,
		StripeController:    stripeController,
	}
	publicAPI.GET("/billing/plans/v2", billingHandler.GetPlansV2)
	privateAPI.GET("/billing/user-plans", billingHandler.GetUserPlans)
	privateAPI.GET("/billing/usage", billingHandler.GetUsage)
	privateAPI.GET("/billing/subscription", billingHandler.GetSubscription)
	privateAPI.POST("/billing/verify-subscription", billingHandler.VerifySubscription)
	publicAPI.POST("/billing/notify/android", billingHandler.AndroidNotificationHandler)
	publicAPI.POST("/billing/notify/ios", billingHandler.IOSNotificationHandler)
	publicAPI.POST("/billing/notify/stripe", billingHandler.StripeINNotificationHandler)
	// after the StripeIN customers are completely migrated, we can change notify/stripe/us to notify/stripe and deprecate this endpoint
	publicAPI.POST("/billing/notify/stripe/us", billingHandler.StripeUSNotificationHandler)
	privateAPI.GET("/billing/stripe/customer-portal", billingHandler.GetStripeCustomerPortal)
	privateAPI.POST("/billing/stripe/cancel-subscription", billingHandler.StripeCancelSubscription)
	privateAPI.POST("/billing/stripe/activate-subscription", billingHandler.StripeActivateSubscription)
	paymentJwtAuthAPI.GET("/billing/stripe-account-country", billingHandler.GetStripeAccountCountry)
	paymentJwtAuthAPI.GET("/billing/stripe/checkout-session", billingHandler.GetCheckoutSession)
	paymentJwtAuthAPI.POST("/billing/stripe/update-subscription", billingHandler.StripeUpdateSubscription)

	storageBonusHandler := &api.StorageBonusHandler{
		Controller: storageBonusCtrl,
	}

	privateAPI.GET("/storage-bonus/details", storageBonusHandler.GetStorageBonusDetails)
	privateAPI.GET("/storage-bonus/referral-view", storageBonusHandler.GetReferralView)
	privateAPI.POST("/storage-bonus/referral-claim", storageBonusHandler.ClaimReferral)

	adminHandler := &api.AdminHandler{
		QueueRepo:               queueRepo,
		UserRepo:                userRepo,
		CollectionRepo:          collectionRepo,
		UserAuthRepo:            userAuthRepo,
		UserController:          userController,
		FamilyController:        familyController,
		RemoteStoreController:   remoteStoreController,
		FileRepo:                fileRepo,
		StorageBonusRepo:        storagBonusRepo,
		BillingRepo:             billingRepo,
		BillingController:       billingController,
		ObjectCleanupController: objectCleanupController,
		MailingListsController:  mailingListsController,
		DiscordController:       discordController,
		HashingKey:              hashingKeyBytes,
		PasskeyController:       passkeyCtrl,
	}
	adminAPI.POST("/mail", adminHandler.SendMail)
	adminAPI.POST("/mail/subscribe", adminHandler.SubscribeMail)
	adminAPI.POST("/mail/unsubscribe", adminHandler.UnsubscribeMail)
	adminAPI.GET("/users", adminHandler.GetUsers)
	adminAPI.GET("/user", adminHandler.GetUser)
	adminAPI.POST("/user/disable-2fa", adminHandler.DisableTwoFactor)
	adminAPI.POST("/user/disable-passkeys", adminHandler.RemovePasskeys)
	adminAPI.POST("/user/close-family", adminHandler.CloseFamily)
	adminAPI.PUT("/user/change-email", adminHandler.ChangeEmail)
	adminAPI.DELETE("/user/delete", adminHandler.DeleteUser)
	adminAPI.POST("/user/recover", adminHandler.RecoverAccount)
	adminAPI.POST("/user/update-flag", adminHandler.UpdateFeatureFlag)
	adminAPI.GET("/email-hash", adminHandler.GetEmailHash)
	adminAPI.POST("/emails-from-hashes", adminHandler.GetEmailsFromHashes)
	adminAPI.PUT("/user/subscription", adminHandler.UpdateSubscription)
	adminAPI.POST("/queue/re-queue", adminHandler.ReQueueItem)
	adminAPI.POST("/user/bf-2013", adminHandler.UpdateBFDeal)
	adminAPI.POST("/job/clear-orphan-objects", adminHandler.ClearOrphanObjects)

	userEntityController := &userEntityCtrl.Controller{Repo: userEntityRepo}
	userEntityHandler := &api.UserEntityHandler{Controller: userEntityController}

	privateAPI.POST("/user-entity/key", userEntityHandler.CreateKey)
	privateAPI.GET("/user-entity/key", userEntityHandler.GetKey)
	privateAPI.POST("/user-entity/entity", userEntityHandler.CreateEntity)
	privateAPI.PUT("/user-entity/entity", userEntityHandler.UpdateEntity)
	privateAPI.DELETE("/user-entity/entity", userEntityHandler.DeleteEntity)
	privateAPI.GET("/user-entity/entity/diff", userEntityHandler.GetDiff)

	authenticatorController := &authenticatorCtrl.Controller{Repo: authRepo}
	authenticatorHandler := &api.AuthenticatorHandler{Controller: authenticatorController}

	privateAPI.POST("/authenticator/key", authenticatorHandler.CreateKey)
	privateAPI.GET("/authenticator/key", authenticatorHandler.GetKey)
	privateAPI.POST("/authenticator/entity", authenticatorHandler.CreateEntity)
	privateAPI.PUT("/authenticator/entity", authenticatorHandler.UpdateEntity)
	privateAPI.DELETE("/authenticator/entity", authenticatorHandler.DeleteEntity)
	privateAPI.GET("/authenticator/entity/diff", authenticatorHandler.GetDiff)

	dataCleanupController := &dataCleanupCtrl.DeleteUserCleanupController{
		Repo:           dataCleanupRepository,
		UserRepo:       userRepo,
		CollectionRepo: collectionRepo,
		TaskLockRepo:   taskLockingRepo,
		TrashRepo:      trashRepo,
		UsageRepo:      usageRepo,
		HostName:       hostName,
	}
	remoteStoreHandler := &api.RemoteStoreHandler{Controller: remoteStoreController}

	privateAPI.POST("/remote-store/update", remoteStoreHandler.InsertOrUpdate)
	privateAPI.GET("/remote-store", remoteStoreHandler.GetKey)
	privateAPI.GET("/remote-store/feature-flags", remoteStoreHandler.GetFeatureFlags)

	pushHandler := &api.PushHandler{PushController: pushController}
	privateAPI.POST("/push/token", pushHandler.AddToken)

	embeddingController := embeddingCtrl.New(embeddingRepo, accessCtrl, objectCleanupController, s3Config, queueRepo, taskLockingRepo, fileRepo, collectionRepo, hostName)
	embeddingHandler := &api.EmbeddingHandler{Controller: embeddingController}

	privateAPI.PUT("/embeddings", embeddingHandler.InsertOrUpdate)
	privateAPI.GET("/embeddings/diff", embeddingHandler.GetDiff)
	privateAPI.POST("/embeddings/files", embeddingHandler.GetFilesEmbedding)
	privateAPI.DELETE("/embeddings", embeddingHandler.DeleteAll)

	offerHandler := &api.OfferHandler{Controller: offerController}
	publicAPI.GET("/offers/black-friday", offerHandler.GetBlackFridayOffers)

	setKnownAPIs(server.Routes())
	setupAndStartBackgroundJobs(objectCleanupController, replicationController3)
	setupAndStartCrons(
		userAuthRepo, publicCollectionRepo, twoFactorRepo, passkeysRepo, fileController, taskLockingRepo, emailNotificationCtrl,
		trashController, pushController, objectController, dataCleanupController, storageBonusCtrl,
		embeddingController, healthCheckHandler, kexCtrl, castDb)

	// Create a new collector, the name will be used as a label on the metrics
	collector := sqlstats.NewStatsCollector("prod_db", db)
	// Register it with Prometheus
	prometheus.MustRegister(collector)

	http.Handle("/metrics", promhttp.Handler())
	go http.ListenAndServe(":2112", nil)
	go runServer(environment, server)
	discordController.NotifyStartup()
	log.Println("We have lift-off.")

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")
	discordController.NotifyShutdown()
}

func runServer(environment string, server *gin.Engine) {
	useTLS := viper.GetBool("http.use-tls")
	if useTLS {
		certPath, err := config.CredentialFilePath("tls.cert")
		if err != nil {
			log.Fatal(err)
		}

		keyPath, err := config.CredentialFilePath("tls.key")
		if err != nil {
			log.Fatal(err)
		}

		log.Fatal(server.RunTLS(":443", certPath, keyPath))
	} else {
		server.Run(":8080")
	}
}

func setupLogger(environment string) {
	log.SetReportCaller(true)
	callerPrettyfier := func(f *runtime.Frame) (string, string) {
		s := strings.Split(f.Function, ".")
		funcName := s[len(s)-1]
		return funcName, fmt.Sprintf("%s:%d", path.Base(f.File), f.Line)
	}
	logFile := viper.GetString("log-file")
	if environment == "local" && logFile == "" {
		log.SetFormatter(&log.TextFormatter{
			CallerPrettyfier: callerPrettyfier,
			DisableQuote:     true,
			ForceColors:      true,
		})
	} else {
		log.SetFormatter(&log.JSONFormatter{
			CallerPrettyfier: callerPrettyfier,
			PrettyPrint:      false,
		})
		log.SetOutput(&lumberjack.Logger{
			Filename: logFile,
			MaxSize:  100,
			MaxAge:   30,
			Compress: true,
		})
	}
}

func setupDatabase() *sql.DB {
	log.Println("Setting up db")
	db, err := sql.Open("postgres", config.GetPGInfo())

	if err != nil {
		log.Panic(err)
		panic(err)
	}
	log.Println("Connected to DB")
	err = db.Ping()
	if err != nil {
		panic(err)
	}
	log.Println("Pinged DB")

	driver, _ := postgres.WithInstance(db, &postgres.Config{})
	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations", "postgres", driver)
	if err != nil {
		log.Panic(err)
		panic(err)
	}
	log.Println("Loaded migration scripts")
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		log.Panic(err)
		panic(err)
	}

	db.SetMaxIdleConns(6)
	db.SetMaxOpenConns(30)

	log.Println("Database was configured successfully.")

	return db
}

func setupAndStartBackgroundJobs(
	objectCleanupController *controller.ObjectCleanupController,
	replicationController3 *controller.ReplicationController3,
) {
	isReplicationEnabled := viper.GetBool("replication.enabled")
	if isReplicationEnabled {
		err := replicationController3.StartReplication()
		if err != nil {
			log.Warnf("Could not start replication v3: %s", err)
		}
	} else {
		log.Info("Skipping Replication as replication is disabled")
	}

	objectCleanupController.StartRemovingUnreportedObjects()
	objectCleanupController.StartClearingOrphanObjects()
}

func setupAndStartCrons(userAuthRepo *repo.UserAuthRepository, publicCollectionRepo *repo.PublicCollectionRepository,
	twoFactorRepo *repo.TwoFactorRepository, passkeysRepo *passkey.Repository, fileController *controller.FileController,
	taskRepo *repo.TaskLockRepository, emailNotificationCtrl *email.EmailNotificationController,
	trashController *controller.TrashController, pushController *controller.PushController,
	objectController *controller.ObjectController,
	dataCleanupCtrl *dataCleanupCtrl.DeleteUserCleanupController,
	storageBonusCtrl *storagebonus.Controller,
	embeddingCtrl *embeddingCtrl.Controller,
	healthCheckHandler *api.HealthCheckHandler,
	kexCtrl *kexCtrl.Controller,
	castDb castRepo.Repository) {
	shouldSkipCron := viper.GetBool("jobs.cron.skip")
	if shouldSkipCron {
		log.Info("Skipping cron jobs")
		return
	}

	c := cron.New()
	schedule(c, "@every 1m", func() {
		_ = userAuthRepo.RemoveExpiredOTTs()
	})

	schedule(c, "@every 24h", func() {
		_ = userAuthRepo.RemoveDeletedTokens(timeUtil.MicrosecondBeforeDays(30))
		_ = castDb.DeleteOldSessions(context.Background(), timeUtil.MicrosecondBeforeDays(7))
		_ = publicCollectionRepo.CleanupAccessHistory(context.Background())
	})

	schedule(c, "@every 1m", func() {
		_ = twoFactorRepo.RemoveExpiredTwoFactorSessions()
	})
	schedule(c, "@every 1m", func() {
		_ = twoFactorRepo.RemoveExpiredTempTwoFactorSecrets()
	})
	schedule(c, "@every 1m", func() {
		_ = passkeysRepo.RemoveExpiredPasskeySessions()
	})
	schedule(c, "@every 1m", func() {
		healthCheckHandler.PerformHealthCheck()
	})

	scheduleAndRun(c, "@every 60m", func() {
		err := taskRepo.CleanupExpiredLocks()
		if err != nil {
			log.Printf("Error while cleaning up lock table, %s", err)
		}
	})

	schedule(c, "@every 2m", func() {
		fileController.CleanupDeletedFiles()
	})
	schedule(c, "@every 101s", func() {
		embeddingCtrl.CleanupDeletedEmbeddings()
	})

	schedule(c, "@every 10m", func() {
		trashController.DropFileMetadataCron()
	})

	schedule(c, "@every 90s", func() {
		objectController.RemoveComplianceHolds()
	})

	schedule(c, "@every 1m", func() {
		trashController.CleanupTrashedCollections()
	})

	// 101s to avoid running too many cron at same time
	schedule(c, "@every 101s", func() {
		trashController.DeleteAgedTrashedFiles()
	})

	schedule(c, "@every 63s", func() {
		storageBonusCtrl.PaymentUpgradeOrDowngradeCron()
	})

	// 67s to avoid running too many cron at same time
	schedule(c, "@every 67s", func() {
		trashController.ProcessEmptyTrashRequests()
	})

	schedule(c, "@every 30m", func() {
		// delete unclaimed codes older than 60 minutes
		_ = castDb.DeleteUnclaimedCodes(context.Background(), timeUtil.MicrosecondsBeforeMinutes(60))
		dataCleanupCtrl.DeleteDataCron()
	})

	schedule(c, "@every 24h", func() {
		emailNotificationCtrl.SendStorageLimitExceededMails()
	})

	schedule(c, "@every 1m", func() {
		pushController.SendPushes()
	})

	schedule(c, "@every 24h", func() {
		pushController.ClearExpiredTokens()
	})

	scheduleAndRun(c, "@every 60m", func() {
		kexCtrl.DeleteOldKeys()
	})

	c.Start()
}

func cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", c.GetHeader("Origin"))
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, X-Auth-Token, X-Auth-Access-Token, X-Cast-Access-Token, X-Auth-Access-Token-JWT, X-Client-Package, X-Client-Version, Authorization, accept, origin, Cache-Control, X-Requested-With, upgrade-insecure-requests")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "X-Request-Id")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, PATCH, DELETE")
		c.Writer.Header().Set("Access-Control-Max-Age", "1728000")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

var knownAPIs = make(map[string]bool)

func urlSanitizer(c *gin.Context) string {
	if c.Request.Method == http.MethodOptions {
		return "/options"
	}
	u := *c.Request.URL
	u.RawQuery = ""
	uri := u.RequestURI()
	for _, p := range c.Params {
		uri = strings.Replace(uri, p.Value, fmt.Sprintf(":%s", p.Key), 1)
	}
	if !knownAPIs[uri] {
		log.Warn("Unknown API: " + uri)
		return "/unknown-api"
	}
	return uri
}

func timeOutResponse(c *gin.Context) {
	c.JSON(http.StatusRequestTimeout, gin.H{"handler": true})
}

func setKnownAPIs(routes []gin.RouteInfo) {
	for _, route := range routes {
		knownAPIs[route.Path] = true
	}
}

// Schedule a cron job
func schedule(c *cron.Cron, spec string, cmd func()) (cron.EntryID, error) {
	return c.AddFunc(spec, cmd)
}

// Schedule a cron job, and run it once immediately too.
func scheduleAndRun(c *cron.Cron, spec string, cmd func()) (cron.EntryID, error) {
	go cmd()
	return schedule(c, spec, cmd)
}

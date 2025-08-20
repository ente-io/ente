package main

import (
	"context"
	"database/sql"
	b64 "encoding/base64"
	"fmt"
	"github.com/ente-io/museum/pkg/controller/collections"
	publicCtrl "github.com/ente-io/museum/pkg/controller/public"
	"github.com/ente-io/museum/pkg/repo/public"
	"net/http"
	"os"
	"os/signal"
	"path"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/ente-io/museum/ente/base"
	"github.com/ente-io/museum/pkg/controller/emergency"
	"github.com/ente-io/museum/pkg/controller/file_copy"
	"github.com/ente-io/museum/pkg/controller/filedata"
	emergencyRepo "github.com/ente-io/museum/pkg/repo/emergency"

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
	fileDataRepo "github.com/ente-io/museum/pkg/repo/filedata"
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

	viper.SetDefault("apps.public-albums", "https://albums.ente.io")
	viper.SetDefault("apps.custom-domain.cname", "my.ente.io")
	viper.SetDefault("apps.public-locker", "https://locker.ente.io")
	viper.SetDefault("apps.accounts", "https://accounts.ente.io")
	viper.SetDefault("apps.cast", "https://cast.ente.io")
	viper.SetDefault("apps.family", "https://family.ente.io")

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
	fileLinkRepo := public.NewFileLinkRepo(db)
	fileDataRepo := &fileDataRepo.Repository{DB: db, ObjectCleanupRepo: objectCleanupRepo}
	familyRepo := &repo.FamilyRepository{DB: db}
	trashRepo := &repo.TrashRepository{DB: db, ObjectRepo: objectRepo, FileRepo: fileRepo, QueueRepo: queueRepo, FileLinkRepo: fileLinkRepo}
	collectionLinkRepo := public.NewCollectionLinkRepository(db, viper.GetString("apps.public-albums"))

	collectionRepo := &repo.CollectionRepository{DB: db, FileRepo: fileRepo, CollectionLinkRepo: collectionLinkRepo,
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
	userCacheCtrl := &usercache.Controller{UserCache: userCache, FileRepo: fileRepo,
		UsageRepo: usageRepo, TrashRepo: trashRepo,
		StoreBonusRepo: storagBonusRepo}
	offerController := offer.NewOfferController(*userRepo, discordController, storagBonusRepo, userCacheCtrl)
	plans := billing.GetPlans()
	defaultPlan := billing.GetDefaultPlans(plans)
	stripeClients := billing.GetStripeClients()
	commonBillController := commonbilling.NewController(emailNotificationCtrl, storagBonusRepo, userRepo, usageRepo, billingRepo)
	appStoreController := controller.NewAppStoreController(defaultPlan,
		billingRepo, fileRepo, userRepo, commonBillController)
	playStoreController := controller.NewPlayStoreController(defaultPlan,
		billingRepo, fileRepo, userRepo, storagBonusRepo, commonBillController)
	stripeController := controller.NewStripeController(plans, stripeClients,
		billingRepo, fileRepo, userRepo, storagBonusRepo, discordController, emailNotificationCtrl, offerController, commonBillController)
	billingController := controller.NewBillingController(plans,
		appStoreController, playStoreController, stripeController,
		discordController, emailNotificationCtrl,
		billingRepo, userRepo, usageRepo, storagBonusRepo, commonBillController)
	remoteStoreController := &remoteStoreCtrl.Controller{Repo: remoteStoreRepository, BillingCtrl: billingController}

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
		BillingCtrl:       billingController,
		StorageBonusCtrl:  storageBonusCtrl,
		UserCacheCtrl:     userCacheCtrl,
		UsageRepo:         usageRepo,
		UserRepo:          userRepo,
		FamilyRepo:        familyRepo,
		FileRepo:          fileRepo,
		UploadResultCache: make(map[int64]bool),
	}

	accessCtrl := access.NewAccessController(collectionRepo, fileRepo)
	fileDataCtrl := filedata.New(fileDataRepo, accessCtrl, objectCleanupController, s3Config, fileRepo, collectionRepo)

	fileController := &controller.FileController{
		FileRepo:              fileRepo,
		ObjectRepo:            objectRepo,
		ObjectCleanupRepo:     objectCleanupRepo,
		TrashRepository:       trashRepo,
		UserRepo:              userRepo,
		UsageCtrl:             usageController,
		AccessCtrl:            accessCtrl,
		CollectionRepo:        collectionRepo,
		TaskLockingRepo:       taskLockingRepo,
		DiscordController:     discordController,
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
		UsageRepo:     usageRepo,
	}

	collectionLinkCtrl := &publicCtrl.CollectionLinkController{
		FileController:        fileController,
		EmailNotificationCtrl: emailNotificationCtrl,
		CollectionLinkRepo:    collectionLinkRepo,
		FileLinkRepo:          fileLinkRepo,
		CollectionRepo:        collectionRepo,
		UserRepo:              userRepo,
		JwtSecret:             jwtSecretBytes,
	}

	collectionController := &collections.CollectionController{
		CollectionRepo:     collectionRepo,
		EmailCtrl:          emailNotificationCtrl,
		AccessCtrl:         accessCtrl,
		CollectionLinkCtrl: collectionLinkCtrl,
		UserRepo:           userRepo,
		FileRepo:           fileRepo,
		CastRepo:           &castDb,
		BillingCtrl:        billingController,
		QueueRepo:          queueRepo,
		TaskRepo:           taskLockingRepo,
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
	fileLinkCtrl := &publicCtrl.FileLinkController{
		FileController: fileController,
		FileLinkRepo:   fileLinkRepo,
		FileRepo:       fileRepo,
		JwtSecret:      jwtSecretBytes,
	}

	passkeyCtrl := &controller.PasskeyController{
		Repo:     passkeysRepo,
		UserRepo: userRepo,
	}

	authMiddleware := middleware.AuthMiddleware{UserAuthRepo: userAuthRepo, Cache: authCache, UserController: userController}
	collectionLinkMiddleware := middleware.CollectionLinkMiddleware{
		CollectionLinkRepo:   collectionLinkRepo,
		PublicCollectionCtrl: collectionLinkCtrl,
		CollectionRepo:       collectionRepo,
		Cache:                accessTokenCache,
		BillingCtrl:          billingController,
		DiscordController:    discordController,
		RemoteStoreRepo:      remoteStoreRepository,
	}
	fileLinkMiddleware := &middleware.FileLinkMiddleware{
		FileLinkRepo:      fileLinkRepo,
		FileLinkCtrl:      fileLinkCtrl,
		Cache:             accessTokenCache,
		BillingCtrl:       billingController,
		DiscordController: discordController,
	}

	if environment != "local" {
		gin.SetMode(gin.ReleaseMode)
	}
	server := gin.New()

	p := ginprometheus.NewPrometheus("museum")
	p.ReqCntURLLabelMappingFn = urlSanitizer
	server.Use(p.HandlerFunc())

	server.LoadHTMLGlob("web-templates/*")
	// note: the recover middleware must be in the last

	server.Use(requestid.New(
		requestid.Config{
			Generator: func() string {
				return base.ServerReqID()
			},
		}),
		middleware.Logger(urlSanitizer), cors(), cacheHeaders(),
		gzip.Gzip(gzip.DefaultCompression), middleware.PanicRecover())

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
	publicCollectionAPI.Use(rateLimiter.GlobalRateLimiter(), collectionLinkMiddleware.Authenticate(urlSanitizer))
	fileLinkApi := server.Group("/file-link")
	fileLinkApi.Use(rateLimiter.GlobalRateLimiter(), fileLinkMiddleware.Authenticate(urlSanitizer))

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
		FileDataCtrl: fileDataCtrl,
		FileUrlCtrl:  fileLinkCtrl,
	}
	privateAPI.GET("/files/upload-urls", fileHandler.GetUploadURLs)
	privateAPI.GET("/files/multipart-upload-urls", fileHandler.GetMultipartUploadURLs)
	privateAPI.GET("/files/download/:fileID", fileHandler.Get)
	privateAPI.GET("/files/download/v2/:fileID", fileHandler.Get)
	privateAPI.GET("/files/preview/:fileID", fileHandler.GetThumbnail)
	privateAPI.GET("/files/preview/v2/:fileID", fileHandler.GetThumbnail)

	privateAPI.POST("/files/share-url", fileHandler.ShareUrl)
	privateAPI.PUT("/files/share-url", fileHandler.UpdateFileURL)
	privateAPI.DELETE("/files/share-url/:fileID", fileHandler.DisableUrl)
	privateAPI.GET("/files/share-urls/", fileHandler.GetUrls)

	privateAPI.PUT("/files/data", fileHandler.PutFileData)
	privateAPI.PUT("/files/video-data", fileHandler.PutVideoData)
	privateAPI.POST("/files/data/status-diff", fileHandler.FileDataStatusDiff)
	privateAPI.POST("/files/data/fetch", fileHandler.GetFilesData)
	privateAPI.GET("/files/data/fetch", fileHandler.GetFileData)
	privateAPI.GET("/files/data/preview-upload-url", fileHandler.GetPreviewUploadURL)
	privateAPI.GET("/files/data/preview", fileHandler.GetPreviewURL)

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

	emergencyCtrl := &emergency.Controller{
		Repo:              &emergencyRepo.Repository{DB: db},
		UserRepo:          userRepo,
		UserCtrl:          userController,
		PasskeyController: passkeyCtrl,
		LockCtrl:          lockController,
	}
	userHandler := &api.UserHandler{
		UserController:      userController,
		EmergencyController: emergencyCtrl,
	}
	publicAPI.POST("/users/ott", userHandler.SendOTT)
	publicAPI.POST("/users/verify-email", userHandler.VerifyEmail)
	publicAPI.POST("/users/two-factor/verify", userHandler.VerifyTwoFactor)
	publicAPI.GET("/users/two-factor/recover", userHandler.RecoverTwoFactor)
	publicAPI.POST("/users/two-factor/remove", userHandler.RemoveTwoFactor)
	publicAPI.POST("/users/two-factor/passkeys/begin", userHandler.BeginPasskeyAuthenticationCeremony)
	publicAPI.POST("/users/two-factor/passkeys/finish", userHandler.FinishPasskeyAuthenticationCeremony)
	publicAPI.GET("/users/two-factor/passkeys/get-token", userHandler.GetTokenForPasskeySession)
	privateAPI.GET("/users/two-factor/recovery-status", userHandler.GetTwoFactorRecoveryStatus)
	privateAPI.POST("/users/two-factor/passkeys/configure-recovery", userHandler.ConfigurePasskeyRecovery)
	privateAPI.GET("/users/two-factor/status", userHandler.GetTwoFactorStatus)
	privateAPI.POST("/users/two-factor/setup", userHandler.SetupTwoFactor)
	privateAPI.POST("/users/two-factor/enable", userHandler.EnableTwoFactor)
	privateAPI.POST("/users/two-factor/disable", userHandler.DisableTwoFactor)
	privateAPI.PUT("/users/attributes", userHandler.SetAttributes)
	privateAPI.PUT("/users/email-mfa", userHandler.UpdateEmailMFA)
	privateAPI.POST("/users/srp/setup", userHandler.SetupSRP)
	privateAPI.POST("/users/srp/complete", userHandler.CompleteSRPSetup)
	privateAPI.POST("/users/srp/update", userHandler.UpdateSrpAndKeyAttributes)
	publicAPI.GET("/users/srp/attributes", userHandler.GetSRPAttributes)
	publicAPI.POST("/users/srp/verify-session", userHandler.VerifySRPSession)
	publicAPI.POST("/users/srp/create-session", userHandler.CreateSRPSession)
	privateAPI.PUT("/users/recovery-key", userHandler.SetRecoveryKey)
	privateAPI.GET("/users/public-key", userHandler.GetPublicKey)
	privateAPI.GET("/users/session-validity/v2", userHandler.GetSessionValidityV2)
	privateAPI.POST("/users/event", userHandler.ReportEvent)
	privateAPI.POST("/users/logout", userHandler.Logout)
	privateAPI.GET("/users/payment-token", userHandler.GetPaymentToken)
	privateAPI.GET("/users/families-token", userHandler.GetFamiliesToken)
	privateAPI.GET("/users/accounts-token", userHandler.GetAccountsToken)
	privateAPI.GET("/users/details/v2", userHandler.GetDetailsV2)
	privateAPI.POST("/users/change-email", userHandler.ChangeEmail)
	privateAPI.GET("/users/sessions", userHandler.GetActiveSessions)
	privateAPI.DELETE("/users/session", userHandler.TerminateSession)
	privateAPI.GET("/users/delete-challenge", userHandler.GetDeleteChallenge)
	privateAPI.DELETE("/users/delete", userHandler.DeleteUser)
	publicAPI.GET("/users/recover-account", userHandler.SelfAccountRecovery)

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
	privateAPI.GET("/collections/v3", collectionHandler.GetWithLimit)
	privateAPI.POST("/collections/share", collectionHandler.Share)
	privateAPI.POST("/collections/join-link", collectionHandler.JoinLink)
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
		Controller:             collectionLinkCtrl,
		FileCtrl:               fileController,
		CollectionCtrl:         collectionController,
		FileDataCtrl:           fileDataCtrl,
		StorageBonusController: storageBonusCtrl,
	}

	fileLinkApi.GET("/info", fileHandler.LinkInfo)
	fileLinkApi.GET("/pass-info", fileHandler.PasswordInfo)
	fileLinkApi.GET("/thumbnail", fileHandler.LinkThumbnail)
	fileLinkApi.GET("/file", fileHandler.LinkFile)
	fileLinkApi.POST("/verify-password", fileHandler.VerifyPassword)

	publicCollectionAPI.GET("/files/preview/:fileID", publicCollectionHandler.GetThumbnail)
	publicCollectionAPI.GET("/files/download/:fileID", publicCollectionHandler.GetFile)
	publicCollectionAPI.GET("/files/data/fetch", publicCollectionHandler.GetFileData)
	publicCollectionAPI.GET("/files/data/preview", publicCollectionHandler.GetPreviewURL)
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

	publicAPI.POST("/cast/device-info", castHandler.RegisterDevice)
	// Deprecated Nov 2024. Remove in a few months.
	//
	// This (and below) are deprecated copy of endpoints with a trailing slash.
	// Kept around because existing desktop clients will not follow the 307
	// redirect because of CORS headers missing on the 307. Can be safely
	// removed in a few months after the desktop apps have updated.
	publicAPI.POST("/cast/device-info/", castHandler.RegisterDevice)
	privateAPI.GET("/cast/device-info/:deviceCode", castHandler.GetDeviceInfo)
	publicAPI.GET("/cast/cast-data/:deviceCode", castHandler.GetCastData)
	privateAPI.POST("/cast/cast-data", castHandler.InsertCastData)
	// Deprecated Nov 2024. Remove in a few months.
	privateAPI.POST("/cast/cast-data/", castHandler.InsertCastData)
	privateAPI.DELETE("/cast/revoke-all-tokens", castHandler.RevokeAllToken)
	// Deprecated Nov 2024. Remove in a few months.
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
	familiesJwtAuthAPI.POST("/family/modify-storage", familyHandler.ModifyStorageLimit)

	emergencyHandler := &api.EmergencyHandler{
		Controller: emergencyCtrl,
	}

	privateAPI.POST("/emergency-contacts/add", emergencyHandler.AddContact)
	privateAPI.GET("/emergency-contacts/info", emergencyHandler.GetInfo)
	privateAPI.POST("/emergency-contacts/update", emergencyHandler.UpdateContact)
	privateAPI.POST("/emergency-contacts/start-recovery", emergencyHandler.StartRecovery)
	privateAPI.POST("/emergency-contacts/stop-recovery", emergencyHandler.StopRecovery)
	privateAPI.POST("/emergency-contacts/reject-recovery", emergencyHandler.RejectRecovery)
	privateAPI.POST("/emergency-contacts/approve-recovery", emergencyHandler.ApproveRecovery)
	privateAPI.GET("/emergency-contacts/recovery-info/:id", emergencyHandler.GetRecoveryInfo)
	privateAPI.POST("/emergency-contacts/init-change-password", emergencyHandler.InitChangePassword)
	privateAPI.POST("/emergency-contacts/change-password", emergencyHandler.ChangePassword)
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
	privateAPI.POST("/storage-bonus/change-code", storageBonusHandler.UpdateReferralCode)
	privateAPI.GET("/storage-bonus/referral-view", storageBonusHandler.GetReferralView)
	privateAPI.POST("/storage-bonus/referral-claim", storageBonusHandler.ClaimReferral)

	adminHandler := &api.AdminHandler{
		QueueRepo:               queueRepo,
		UserRepo:                userRepo,
		CollectionRepo:          collectionRepo,
		AuthenticatorRepo:       authRepo,
		UserAuthRepo:            userAuthRepo,
		UserController:          userController,
		FamilyController:        familyController,
		EmergencyController:     emergencyCtrl,
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
		StorageBonusCtl:         storageBonusCtrl,
	}
	adminAPI.POST("/mail", adminHandler.SendMail)
	adminAPI.POST("/mail/subscribe", adminHandler.SubscribeMail)
	adminAPI.POST("/mail/unsubscribe", adminHandler.UnsubscribeMail)
	adminAPI.GET("/users", adminHandler.GetUsers)
	adminAPI.GET("/user", adminHandler.GetUser)
	adminAPI.POST("/user/disable-2fa", adminHandler.DisableTwoFactor)
	adminAPI.POST("/user/update-referral", adminHandler.UpdateReferral)
	adminAPI.POST("/user/disable-passkeys", adminHandler.RemovePasskeys)
	adminAPI.POST("/user/update-email-mfa", adminHandler.UpdateEmailMFA)
	adminAPI.POST("/user/add-ott", adminHandler.AddOtt)
	adminAPI.POST("/user/terminate-session", adminHandler.TerminateSession)
	adminAPI.POST("/user/close-family", adminHandler.CloseFamily)
	adminAPI.PUT("/user/change-email", adminHandler.ChangeEmail)
	adminAPI.DELETE("/user/delete", adminHandler.DeleteUser)
	adminAPI.POST("/user/recover", adminHandler.RecoverAccount)
	adminAPI.POST("/user/update-flag", adminHandler.UpdateFeatureFlag)
	adminAPI.GET("/email-hash", adminHandler.GetEmailHash)
	adminAPI.POST("/emails-from-hashes", adminHandler.GetEmailsFromHashes)
	adminAPI.PUT("/user/subscription", adminHandler.UpdateSubscription)
	adminAPI.POST("/queue/re-queue", adminHandler.ReQueueItem)
	adminAPI.POST("/user/bonus", adminHandler.UpdateBonus)
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
	privateAPI.DELETE("/remote-store/:key", remoteStoreHandler.RemoveKey)
	privateAPI.GET("/remote-store", remoteStoreHandler.GetKey)
	privateAPI.GET("/remote-store/feature-flags", remoteStoreHandler.GetFeatureFlags)
	publicAPI.GET("/custom-domain", remoteStoreHandler.CheckDomain)

	pushHandler := &api.PushHandler{PushController: pushController}
	privateAPI.POST("/push/token", pushHandler.AddToken)

	embeddingController := embeddingCtrl.New(embeddingRepo, objectCleanupController, queueRepo, taskLockingRepo, fileRepo, hostName)

	offerHandler := &api.OfferHandler{Controller: offerController}
	publicAPI.GET("/offers/black-friday", offerHandler.GetBlackFridayOffers)

	setKnownAPIs(server.Routes())
	setupAndStartBackgroundJobs(objectCleanupController, replicationController3, fileDataCtrl)
	setupAndStartCrons(
		userAuthRepo, collectionLinkRepo, fileLinkRepo, twoFactorRepo, passkeysRepo, fileController, taskLockingRepo, emailNotificationCtrl,
		trashController, pushController, objectController, dataCleanupController, storageBonusCtrl, emergencyCtrl,
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
	db.SetMaxOpenConns(45)

	log.Println("Database was configured successfully.")

	return db
}

func setupAndStartBackgroundJobs(
	objectCleanupController *controller.ObjectCleanupController,
	replicationController3 *controller.ReplicationController3,
	fileDataCtrl *filedata.Controller,
) {
	isReplicationEnabled := viper.GetBool("replication.enabled")
	if isReplicationEnabled {
		err := replicationController3.StartReplication()
		if err != nil {
			log.Warnf("Could not start replication v3: %s", err)
		}
		err = fileDataCtrl.StartReplication()
		if err != nil {
			log.Warnf("Could not start fileData replication: %s", err)
		}
	} else {
		log.Info("Skipping Replication as replication is disabled")
	}

	fileDataCtrl.StartDataDeletion() // Start data deletion for file data;
	objectCleanupController.StartRemovingUnreportedObjects()
	objectCleanupController.StartClearingOrphanObjects()
}

func setupAndStartCrons(userAuthRepo *repo.UserAuthRepository, collectionLinkRepo *public.CollectionLinkRepo,
	fileLinkRepo *public.FileLinkRepository,
	twoFactorRepo *repo.TwoFactorRepository, passkeysRepo *passkey.Repository, fileController *controller.FileController,
	taskRepo *repo.TaskLockRepository, emailNotificationCtrl *email.EmailNotificationController,
	trashController *controller.TrashController, pushController *controller.PushController,
	objectController *controller.ObjectController,
	dataCleanupCtrl *dataCleanupCtrl.DeleteUserCleanupController,
	storageBonusCtrl *storagebonus.Controller,
	emergencyCtrl *emergency.Controller,
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
		_ = userAuthRepo.RemoveDeletedTokens(timeUtil.MicrosecondsBeforeDays(30))
		_ = castDb.DeleteOldSessions(context.Background(), timeUtil.MicrosecondsBeforeDays(7))
		_ = collectionLinkRepo.CleanupAccessHistory(context.Background())
		_ = fileLinkRepo.CleanupAccessHistory(context.Background())
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

	schedule(c, "@every 8m", func() {
		fileController.CleanupDeletedFiles()
	})
	schedule(c, "@every 101s", func() {
		embeddingCtrl.CleanupDeletedEmbeddings()
	})

	schedule(c, "@every 17m", func() {
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

	schedule(c, "@every 45m", func() {
		// delete unclaimed codes older than 60 minutes
		_ = castDb.DeleteUnclaimedCodes(context.Background(), timeUtil.MicrosecondsBeforeMinutes(60))
		dataCleanupCtrl.DeleteDataCron()
	})

	schedule(c, "@every 24h", func() {
		emailNotificationCtrl.SendStorageLimitExceededMails()
	})

	scheduleAndRun(c, "@every 24h", func() {
		emailNotificationCtrl.SayHelloToCustomers()
	})

	scheduleAndRun(c, "@every 24h", func() {
		emailNotificationCtrl.NudgePaidSubscriberForFamily()
	})

	schedule(c, "@every 1m", func() {
		pushController.SendPushes()
	})

	schedule(c, "@every 24h", func() {
		pushController.ClearExpiredTokens()
	})

	scheduleAndRun(c, "@every 60m", func() {
		emergencyCtrl.SendRecoveryReminder()
		kexCtrl.DeleteOldKeys()
	})

	c.Start()
}

func cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", c.GetHeader("Origin"))
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, X-Auth-Token, X-Auth-Access-Token, X-Cast-Access-Token, X-Auth-Access-Token-JWT, X-Client-Package, X-Client-Version, Authorization, accept, origin, Cache-Control, X-Requested-With, upgrade-insecure-requests, Range")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "X-Request-Id")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, PATCH, DELETE")
		c.Writer.Header().Set("Access-Control-Max-Age", "1728000")

		if c.Request.Method == http.MethodOptions {
			// While 204 No Content is more appropriate, Safari intermittently
			// (intermittently!) fails CORS if we return 204 instead of 200 OK.
			c.Status(http.StatusOK)
			return
		}
		c.Next()
	}
}

func cacheHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Add "Cache-Control: no-store" to HTTP GET API responses.
		if c.Request.Method == http.MethodGet {
			reqPath := urlSanitizer(c)
			if strings.HasPrefix(reqPath, "/files/preview/") ||
				strings.HasPrefix(reqPath, "/files/download/") ||
				strings.HasPrefix(reqPath, "/public-collection/files/preview/") ||
				strings.HasPrefix(reqPath, "/public-collection/files/download/") ||
				strings.HasPrefix(reqPath, "/cast/files/preview/") ||
				strings.HasPrefix(reqPath, "/cast/files/download/") {
				// Exclude those that redirect to S3 for file downloads.
			} else {
				c.Writer.Header().Set("Cache-Control", "no-store")
			}
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

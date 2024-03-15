package s3config

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"

	"github.com/ente-io/museum/pkg/utils/array"
)

// S3Config is the file which abstracts away s3 related configs for clients.
//
// Objects are replicated in multiple "data centers". Each data center is an
// S3-compatible provider, and has an associated "bucket".
//
// The list of data centers are not arbitrarily configurable - while we pick the
// exact credentials, endpoint and the bucket from the runtime configuration
// file, the code has specific logic to deal with the quirks of specific data
// centers. So as such, the constants used to specify these data centers in the
// YAML configuration matter.
type S3Config struct {
	// A map from data centers to the name of the bucket used in that DC.
	buckets map[string]string
	// Primary (hot) data center
	hotDC string
	// Secondary (hot) data center
	secondaryHotDC string
	// A map from data centers to S3 configurations
	s3Configs map[string]*aws.Config
	// A map from data centers to pre-created S3 clients
	s3Clients map[string]s3.S3
	// Indicates if compliance is enabled for the Wasabi DC.
	isWasabiComplianceEnabled bool
	// Indicates if local minio buckets are being used. Enables various
	// debugging workarounds; not tested/intended for production.
	areLocalBuckets bool
}

// # Datacenters
//
// Below are some high level details about the three replicas ("data centers")
// that are in use. There are a few other legacy ones too.
//
// # Backblaze (dcB2EuropeCentral)
//
//   - Primary hot storage
//   - Versioned, but with extra code that undoes all overwrites
//
// # Wasabi (dcWasabiEuropeCentral_v3)
//
//   - Secondary hot storage
//   - Objects stay under compliance, which prevents them from being
//     deleted/updated for 21 days.
//   - Not versioned (versioning is not needed since objects cannot be overwritten)
//   - When an user (permanently) deletes an object, we remove the compliance
//     retention. It can then be deleted normally when the scheduled
//     cleanup happens (as long as it happens after 21 days).
//
// # Scaleway (dcSCWEuropeFrance_v3)
//
//   - Cold storage
//   - Specify type GLACIER in API requests

var (
	dcB2EuropeCentral                 string = "b2-eu-cen"
	dcSCWEuropeFranceDeprecated       string = "scw-eu-fr"
	dcSCWEuropeFranceLockedDeprecated string = "scw-eu-fr-locked"
	dcWasabiEuropeCentralDeprecated   string = "wasabi-eu-central-2"
	dcWasabiEuropeCentral_v3          string = "wasabi-eu-central-2-v3"
	dcSCWEuropeFrance_v3              string = "scw-eu-fr-v3"
)

// Number of days that the wasabi bucket is configured to retain objects.
//
// We must wait at least these many days after removing the conditional hold
// before we can delete the object.
const WasabiObjectConditionalHoldDays = 21

func NewS3Config() *S3Config {
	s3Config := new(S3Config)
	s3Config.initialize()
	return s3Config
}

func (config *S3Config) initialize() {
	dcs := [5]string{
		dcB2EuropeCentral, dcSCWEuropeFranceLockedDeprecated, dcWasabiEuropeCentralDeprecated,
		dcWasabiEuropeCentral_v3, dcSCWEuropeFrance_v3}

	config.hotDC = dcB2EuropeCentral
	config.secondaryHotDC = dcWasabiEuropeCentral_v3
	hs1 := viper.GetString("s3.hot_storage.primary")
	hs2 := viper.GetString("s3.hot_storage.secondary")
	if hs1 != "" && hs2 != "" && array.StringInList(hs1, dcs[:]) && array.StringInList(hs2, dcs[:]) {
		config.hotDC = hs1
		config.secondaryHotDC = hs2
		log.Infof("Hot storage: %s (secondary: %s)", hs1, hs2)
	}

	config.buckets = make(map[string]string)
	config.s3Configs = make(map[string]*aws.Config)
	config.s3Clients = make(map[string]s3.S3)

	usePathStyleURLs := viper.GetBool("s3.use_path_style_urls")
	areLocalBuckets := viper.GetBool("s3.are_local_buckets")
	config.areLocalBuckets = areLocalBuckets

	for _, dc := range dcs {
		config.buckets[dc] = viper.GetString("s3." + dc + ".bucket")
		config.buckets[dc] = viper.GetString("s3." + dc + ".bucket")
		s3Config := aws.Config{
			Credentials: credentials.NewStaticCredentials(viper.GetString("s3."+dc+".key"),
				viper.GetString("s3."+dc+".secret"), ""),
			Endpoint: aws.String(viper.GetString("s3." + dc + ".endpoint")),
			Region:   aws.String(viper.GetString("s3." + dc + ".region")),
		}
		if usePathStyleURLs {
			s3Config.S3ForcePathStyle = aws.Bool(true)
		}
		if areLocalBuckets {
			s3Config.DisableSSL = aws.Bool(true)
			s3Config.S3ForcePathStyle = aws.Bool(true)
		}
		session, err := session.NewSession(&s3Config)
		if err != nil {
			log.Fatal("Could not create session for " + dc)
		}
		s3Client := *s3.New(session)
		config.s3Configs[dc] = &s3Config
		config.s3Clients[dc] = s3Client
		if dc == dcWasabiEuropeCentral_v3 {
			config.isWasabiComplianceEnabled = viper.GetBool("s3." + dc + ".compliance")
		}
	}
}

func (config *S3Config) GetBucket(dc string) *string {
	bucket := config.buckets[dc]
	return &bucket
}

func (config *S3Config) GetS3Config(dc string) *aws.Config {
	return config.s3Configs[dc]
}

func (config *S3Config) GetS3Client(dc string) s3.S3 {
	return config.s3Clients[dc]
}

func (config *S3Config) GetHotDataCenter() string {
	return config.hotDC
}

func (config *S3Config) GetSecondaryHotDataCenter() string {
	return config.secondaryHotDC
}

func (config *S3Config) GetHotBucket() *string {
	return config.GetBucket(config.hotDC)
}

func (config *S3Config) GetHotS3Config() *aws.Config {
	return config.GetS3Config(config.hotDC)
}

func (config *S3Config) GetHotS3Client() *s3.S3 {
	s3Client := config.GetS3Client(config.hotDC)
	return &s3Client
}

// Return the name of the hot Backblaze data center
func (config *S3Config) GetHotBackblazeDC() string {
	return dcB2EuropeCentral
}

// Return the name of the hot Wasabi data center
func (config *S3Config) GetHotWasabiDC() string {
	return dcWasabiEuropeCentral_v3
}

// Return the name of the cold Scaleway data center
func (config *S3Config) GetColdScalewayDC() string {
	return dcSCWEuropeFrance_v3
}

// ShouldDeleteFromDataCenter returns true if objects should be deleted from the
// given data center when permanently deleting these objects.
//
// There are some legacy / deprecated data center values which are no longer
// being used, and it returns false for such data centers.
func (config *S3Config) ShouldDeleteFromDataCenter(dc string) bool {
	return dc != dcSCWEuropeFranceDeprecated && dc != dcSCWEuropeFranceLockedDeprecated && dc != dcWasabiEuropeCentralDeprecated
}

// Return the name of the Wasabi DC if objects in that DC are kept under the
// Wasabi compliance lock. Otherwise return the empty string.
func (config *S3Config) WasabiComplianceDC() string {
	if config.isWasabiComplianceEnabled {
		return dcWasabiEuropeCentral_v3
	}
	return ""
}

// Return true if we're using local minio buckets. This can then be used to add
// various workarounds for debugging locally; not meant for production use.
func (config *S3Config) AreLocalBuckets() bool {
	return config.areLocalBuckets
}

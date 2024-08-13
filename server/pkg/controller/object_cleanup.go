package controller

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"sync"
	stime "time"

	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/stacktrace"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/spf13/viper"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/s3config"
	enteString "github.com/ente-io/museum/pkg/utils/string"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
)

// ObjectCleanupController exposes functions to remove orphan and stale entries
// from object storage.
//
// There are 3 main types of orphans that can end up in our object storage:
//
//  1. We create presigned URLs for clients to upload their objects to. It might
//     happen that the client is able to successfully upload to these URLs, but
//     not tell museum about the successful upload.
//
//  2. During replication, we might have half-done multipart uploads.
//
//  3. When an existing object is updated (e.g. the user edits the file on iOS),
//     then the file entry in our DB is updated to point to the new object, and
//     the old object is now meant to be discarded.
//
// ObjectCleanupController is meant to manage all these scenarios over time.
type ObjectCleanupController struct {
	Repo             *repo.ObjectCleanupRepository
	ObjectRepo       *repo.ObjectRepository
	LockController   *lock.LockController
	ObjectController *ObjectController
	S3Config         *s3config.S3Config
	// Prometheus Metrics
	mOrphanObjectsDeleted *prometheus.CounterVec
}

// PreSignedRequestValidityDuration is the lifetime of a pre-signed URL
const PreSignedRequestValidityDuration = 7 * 24 * stime.Hour

// PreSignedPartUploadRequestDuration is the lifetime of a pre-signed multipart URL
const PreSignedPartUploadRequestDuration = 7 * 24 * stime.Hour

// clearOrphanObjectsCheckInterval is the interval after which we check if the
// ClearOrphanObjects job needs to be re-run.
//
// See also, clearOrphanObjectsMinimumJobInterval.
const clearOrphanObjectsCheckInterval = 1 * 24 * stime.Hour

// ClearOrphanObjectsMinimumJobInterval is the minimum interval that must pass
// before we run another instance of the ClearOrphanObjects job.
//
// This interval is enforced across museum instances.
const clearOrphanObjectsMinimumJobInterval = 2 * 24 * stime.Hour

// Return a new instance of ObjectCleanupController
func NewObjectCleanupController(
	objectCleanupRepo *repo.ObjectCleanupRepository,
	objectRepo *repo.ObjectRepository,
	lockController *lock.LockController,
	objectController *ObjectController,
	s3Config *s3config.S3Config,
) *ObjectCleanupController {
	mOrphanObjectsDeleted := promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "museum_orphan_objects_deleted_total",
		Help: "Number of objects successfully deleted when clearing orphan objects",
	}, []string{"dc"})

	return &ObjectCleanupController{
		Repo:                  objectCleanupRepo,
		ObjectRepo:            objectRepo,
		LockController:        lockController,
		ObjectController:      objectController,
		S3Config:              s3Config,
		mOrphanObjectsDeleted: mOrphanObjectsDeleted,
	}
}

// StartRemovingUnreportedObjects starts goroutines to cleanup deletes those
// objects that were possibly uploaded but not reported to the database
func (c *ObjectCleanupController) StartRemovingUnreportedObjects() {
	// TODO: object_cleanup: This code is only currently tested for B2
	if c.S3Config.GetHotDataCenter() != c.S3Config.GetHotBackblazeDC() {
		log.Info("Skipping RemovingUnreportedObjects since the Hot DC is not B2")
		return
	}

	workerCount := viper.GetInt("jobs.remove-unreported-objects.worker-count")
	if workerCount == 0 {
		workerCount = 1
	}

	log.Infof("Starting %d workers to remove-unreported-objects", workerCount)

	for i := 0; i < workerCount; i++ {
		go c.removeUnreportedObjectsWorker(i)
	}
}

// Entry point for the worker goroutine to cleanup unreported objects.
//
// i is an arbitrary index for the current goroutine.
func (c *ObjectCleanupController) removeUnreportedObjectsWorker(i int) {
	for {
		count := c.removeUnreportedObjects()
		if count == 0 {
			stime.Sleep(stime.Duration(5+i) * stime.Minute)
		} else {
			stime.Sleep(stime.Second)
		}
	}
}

func (c *ObjectCleanupController) removeUnreportedObjects() int {
	logger := log.WithFields(log.Fields{
		"task": "remove-unreported-objects",
	})
	logger.Info("Removing unreported objects")

	count := 0

	tx, tempObjects, err := c.Repo.GetAndLockExpiredObjects()
	if err != nil {
		if !errors.Is(err, sql.ErrNoRows) {
			logger.Error(err)
		}
		return count
	}

	for _, tempObject := range tempObjects {
		err = c.removeUnreportedObject(tx, tempObject)
		if err != nil {
			continue
		}
		count += 1
	}

	logger.Infof("Removed %d objects", count)

	// We always commit the transaction, even on errors for individual rows. To
	// avoid object getting stuck in a loop, we increase their expiry times.

	cerr := tx.Commit()
	if cerr != nil {
		cerr = stacktrace.Propagate(err, "Failed to commit transaction")
		logger.Error(cerr)
	}

	return count
}

func (c *ObjectCleanupController) removeUnreportedObject(tx *sql.Tx, t ente.TempObject) error {
	// TODO: object_cleanup
	// This should use the DC from TempObject (once we start persisting it)
	dc := t.BucketId
	if dc == "" {
		dc = c.S3Config.GetHotDataCenter()
	}

	logger := log.WithFields(log.Fields{
		"task":        "remove-unreported-objects",
		"object_key":  t.ObjectKey,
		"data_center": dc,
		"upload_id":   t.UploadID,
	})

	skip := func(err error) error {
		logger.Errorf("Clearing tempObject failed: %v", err)
		newExpiry := time.MicrosecondsAfterDays(1)
		serr := c.Repo.SetExpiryForTempObject(tx, t, newExpiry)
		if serr != nil {
			logger.Errorf("Updating expiry for failed temp object failed: %v", serr)
		}
		return err
	}

	logger.Info("Clearing tempObject")

	exists, err := c.ObjectRepo.DoesObjectExist(tx, t.ObjectKey)
	if err != nil {
		return skip(stacktrace.Propagate(err, ""))
	}

	if exists {
		err := errors.New("aborting attempt to delete an object which has a DB entry")
		return skip(stacktrace.Propagate(err, ""))
	}

	if t.IsMultipart {
		err = c.abortMultipartUpload(t.ObjectKey, t.UploadID, dc)
	} else {
		err = c.DeleteObjectFromDataCenter(t.ObjectKey, dc)
	}
	if err != nil {
		return skip(err)
	}

	err = c.Repo.RemoveTempObject(tx, t)
	if err != nil {
		return skip(err)
	}

	return nil
}

// AddTempObjectKey creates a new temporary object entry.
//
// It persists a given object key as having been provided to a client for
// uploading. If a client does not successfully mark this object's upload as
// having completed within PreSignedRequestValidityDuration, this temp object
// will be cleaned up.
func (c *ObjectCleanupController) AddTempObjectKey(objectKey string, dc string) error {
	expiry := time.Microseconds() + (2 * PreSignedRequestValidityDuration.Microseconds())
	return c.addCleanupEntryForObjectKey(objectKey, dc, expiry)
}

// Add the object to a queue of "temporary" objects that are deleted (if they
// exist) if this entry is not removed from the queue by expirationTime.
func (c *ObjectCleanupController) addCleanupEntryForObjectKey(objectKey string, dc string, expirationTime int64) error {
	err := c.Repo.AddTempObject(ente.TempObject{
		ObjectKey:   objectKey,
		IsMultipart: false,
		BucketId:    dc,
	}, expirationTime)
	return stacktrace.Propagate(err, "")
}

// AddTempObjectMultipartKey creates a new temporary object entry for a
// multlipart upload.
//
// See AddTempObjectKey for more details.
func (c *ObjectCleanupController) AddMultipartTempObjectKey(objectKey string, uploadID string, dc string) error {
	expiry := time.Microseconds() + (2 * PreSignedPartUploadRequestDuration.Microseconds())
	err := c.Repo.AddTempObject(ente.TempObject{
		ObjectKey:   objectKey,
		IsMultipart: true,
		UploadID:    uploadID,
		BucketId:    dc,
	}, expiry)
	return stacktrace.Propagate(err, "")
}

func (c *ObjectCleanupController) DeleteAllObjectsWithPrefix(prefix string, dc string) error {
	s3Client := c.S3Config.GetS3Client(dc)
	bucket := c.S3Config.GetBucket(dc)
	output, err := s3Client.ListObjectsV2(&s3.ListObjectsV2Input{
		Bucket: bucket,
		Prefix: &prefix,
	})
	if err != nil {
		log.WithFields(log.Fields{
			"prefix": prefix,
			"dc":     dc,
		}).WithError(err).Error("Failed to list objects")
		return stacktrace.Propagate(err, "")
	}
	var keys []string
	for _, obj := range output.Contents {
		keys = append(keys, *obj.Key)
	}
	for _, key := range keys {
		err = c.DeleteObjectFromDataCenter(key, dc)
		if err != nil {
			log.WithFields(log.Fields{
				"object_key": key,
				"dc":         dc,
			}).WithError(err).Error("Failed to delete object")
			return stacktrace.Propagate(err, "")
		}
	}
	return nil
}

func (c *ObjectCleanupController) DeleteObjectFromDataCenter(objectKey string, dc string) error {
	log.Info("Deleting " + objectKey + " from " + dc)
	var s3Client = c.S3Config.GetS3Client(dc)
	bucket := c.S3Config.GetBucket(dc)
	_, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = s3Client.WaitUntilObjectNotExists(&s3.HeadObjectInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (c *ObjectCleanupController) abortMultipartUpload(objectKey string, uploadID string, dc string) error {
	s3Client := c.S3Config.GetS3Client(dc)
	bucket := c.S3Config.GetBucket(dc)
	_, err := s3Client.AbortMultipartUpload(&s3.AbortMultipartUploadInput{
		Bucket:   bucket,
		Key:      &objectKey,
		UploadId: &uploadID,
	})
	if err != nil {
		if isUnknownUploadError(err) {
			log.Info("Could not find upload for " + objectKey)
			return nil
		}
		return stacktrace.Propagate(err, "")
	}
	r, err := s3Client.ListParts(&s3.ListPartsInput{
		Bucket:   bucket,
		Key:      &objectKey,
		UploadId: &uploadID,
	})
	if err != nil {
		if isUnknownUploadError(err) {
			// This is expected now, since we just aborted the upload
			return nil
		}
		return stacktrace.Propagate(err, "")
	}
	if len(r.Parts) > 0 {
		return stacktrace.NewError("abort Failed")
	}
	return nil
}

// The original code here checked for NoSuchUpload, presumably because that is
// the error that B2 returns.
//
// Wasabi returns something similar:
//
//	<Error>
//	  <Code>NoSuchUpload</Code>
//	  <Message>The specified upload does not exist. The upload ID may be invalid,
//	           or the upload may have been aborted or completed.</Message>
//	...
//
// However, Scaleway returns a different error, NoSuchKey
//
//	<Error>
//	  <Code>NoSuchKey</Code>
//	  <Message>The specified key does not exist.</Message>
//	...
//
// This method returns true if either of these occur.
func isUnknownUploadError(err error) bool {
	// B2, Wasabi
	if strings.Contains(err.Error(), "NoSuchUpload") {
		return true
	}
	// Scaleway
	if strings.Contains(err.Error(), "NoSuchKey") {
		return true
	}
	return false
}

// StartClearingOrphanObjects is the entry point for the job that goes through
// all the objects in the given datacenter, and deletes orphan objects for which
// we do not have DB entries.
//
// Such orphan objects are expected to have been created because the code for
// updating the DB entries when a file gets updated did not cleanup the
// corresponding objects from object storage. Once we start keeping track of
// such objects in a separate queue, this cron job won't be needed.
func (c *ObjectCleanupController) StartClearingOrphanObjects() {
	// TODO: object_cleanup: This code is only currently tested for B2
	if c.S3Config.GetHotDataCenter() != c.S3Config.GetHotBackblazeDC() {
		log.Info("Skipping ClearingOrphanObjects since the Hot DC is not B2")
		return
	}

	isJobEnabled := viper.GetBool("jobs.clear-orphan-objects.enabled")
	if !isJobEnabled {
		return
	}

	prefix := viper.GetString("jobs.clear-orphan-objects.prefix")

	log.Infof("Starting workers to clear-orphan-objects (prefix %s)", prefix)

	// TODO: object_cleanup: start workers for other DCs once the temp_objects
	// table supports specifying a DC
	go c.clearOrphanObjectsWorker(c.S3Config.GetHotBackblazeDC(), prefix)
}

// clearOrphanObjectsWorker is the entry point for the worker goroutine to
// cleanup objects in a particular DC.
func (c *ObjectCleanupController) clearOrphanObjectsWorker(dc string, prefix string) {
	for {
		c.ClearOrphanObjects(dc, prefix, false)
		stime.Sleep(clearOrphanObjectsCheckInterval)
	}
}

// IsValidClearOrphanObjectsDC verifies that the given DC is valid for use as
// the target of an orphan object cleanup.
func (c *ObjectCleanupController) IsValidClearOrphanObjectsDC(dc string) bool {
	if dc != c.S3Config.GetHotBackblazeDC() {
		return false
	}

	// TODO: object_cleanup: This code is only currently tested for B2
	if c.S3Config.GetHotDataCenter() != c.S3Config.GetHotBackblazeDC() {
		return false
	}

	return true
}

func (c *ObjectCleanupController) ClearOrphanObjects(dc string, prefix string, forceTaskLock bool) {
	logger := log.WithFields(log.Fields{
		"task":        "clear-orphan-objects",
		"data_center": dc,
	})

	if !c.IsValidClearOrphanObjectsDC(dc) {
		logger.Errorf("Unsupported DC %s", dc)
		return
	}

	lockName := clearOrphanObjectsLockName(dc)

	if forceTaskLock {
		logger.Infof("Forcefully removing task lock %s", lockName)
		err := c.LockController.TaskLockingRepo.ReleaseLock(lockName)
		if err != nil {
			logger.Error(stacktrace.Propagate(err, ""))
			return
		}
	}

	if !c.LockController.TryLock(lockName, clearOrphanObjectsNextLockUntil()) {
		logger.Infof("Skipping since a lock could not be obtained")
		return
	}
	// The lock is not released intentionally
	//
	// By keeping the stale entry for the unheld lock in the DB, we will be able
	// to retain the timestamp when this job last ran. This is a kludgy way to
	// guarantee that clearOrphanObjectsMinimumJobInterval is enforced across
	// all museum instances (without introducing a new DB table).
	//
	// defer c.LockController.ReleaseLock(lockName)

	s3Config := c.S3Config
	dest := &CleanupOrphanObjectsDestination{
		DC:                dc,
		Client:            s3Config.GetS3Client(dc),
		Bucket:            s3Config.GetBucket(dc),
		HasComplianceHold: s3Config.WasabiComplianceDC() == dc,
	}

	logger.Infof("Clearing orphan objects from bucket %s (hasComplianceHold %v)",
		*dest.Bucket, dest.HasComplianceHold)

	// Each directory listing of an S3 bucket returns a maximum of 1000 objects,
	// and an optional continuation token. Until there are more objects
	// (indicated by the presence of the continuation token), keep fetching
	// directory listings.
	//
	// For each directory listing, spawn 10 goroutines to go through chunks of
	// 100 each to clear orphan objects.
	//
	// Refresh the lock's acquisition time during each iteration since this job
	// can span hours, and we don't want a different instance to start another
	// run just because it was only considering the start time of the job.

	err := dest.Client.ListObjectVersionsPages(&s3.ListObjectVersionsInput{
		Bucket: dest.Bucket,
		Prefix: &prefix,
	},
		func(page *s3.ListObjectVersionsOutput, lastPage bool) bool {
			c.clearOrphanObjectsPage(page, dest, logger)

			lerr := c.LockController.ExtendLock(lockName, clearOrphanObjectsNextLockUntil())
			if lerr != nil {
				logger.Error(lerr)
				return false
			}

			return true
		})
	if err != nil {
		logger.Error(stacktrace.Propagate(err, ""))
		return
	}

	logger.Info("Cleared orphan objects")
}

func clearOrphanObjectsLockName(dc string) string {
	return fmt.Sprintf("clear-orphan-objects:%s", dc)
}

func clearOrphanObjectsNextLockUntil() int64 {
	return time.Microseconds() + clearOrphanObjectsMinimumJobInterval.Microseconds()
}

type CleanupOrphanObjectsDestination struct {
	DC     string
	Client s3.S3
	Bucket *string
	// If true, this bucket has a compliance hold on objects that needs to be
	// removed first before they can be deleted.
	HasComplianceHold bool
}

// ObjectVersionOrDeleteMarker is an abstraction to allow us to reuse the same
// code to delete both object versions and delete markers
type ObjectVersionOrDeleteMarker struct {
	ObjectVersion *s3.ObjectVersion
	DeleteMarker  *s3.DeleteMarkerEntry
}

func (od ObjectVersionOrDeleteMarker) GetKey() *string {
	if od.ObjectVersion != nil {
		return od.ObjectVersion.Key
	}
	return od.DeleteMarker.Key
}

func (od ObjectVersionOrDeleteMarker) GetLastModified() *stime.Time {
	if od.ObjectVersion != nil {
		return od.ObjectVersion.LastModified
	}
	return od.DeleteMarker.LastModified
}

func (od ObjectVersionOrDeleteMarker) GetVersionId() *string {
	if od.ObjectVersion != nil {
		return od.ObjectVersion.VersionId
	}
	return od.DeleteMarker.VersionId
}

func (c *ObjectCleanupController) clearOrphanObjectsPage(page *s3.ListObjectVersionsOutput, dest *CleanupOrphanObjectsDestination, logger *log.Entry) error {
	// MaxKeys is 1000. Until we can, break it into batches and create a
	// separate goroutine to process each batch.
	batchSize := 10

	versions := page.Versions
	nv := len(versions)
	deleteMarkers := page.DeleteMarkers
	nd := len(deleteMarkers)
	n := nv + nd

	logger.Infof("Processing page containing %d values (%d object versions, %d delete markers)", n, nv, nd)

	ods := make([]ObjectVersionOrDeleteMarker, n)
	for i := 0; i < nv; i++ {
		ods[i] = ObjectVersionOrDeleteMarker{ObjectVersion: versions[i]}
	}
	for i := 0; i < nd; i++ {
		ods[nv+i] = ObjectVersionOrDeleteMarker{DeleteMarker: deleteMarkers[i]}
	}

	var wg sync.WaitGroup

	for i := 0; i < n; i++ {
		end := i + batchSize
		if end > n {
			end = n
		}

		if i >= end {
			// Nothing left
			break
		}

		wg.Add(1)
		go func(i int, end int) {
			defer wg.Done()
			batch := ods[i:end]
			c.clearOrphanObjectsVersionOrDeleteMarkers(batch, dest, logger)
		}(i, end)

		i = end
	}

	wg.Wait()

	return nil
}

func (c *ObjectCleanupController) clearOrphanObjectsVersionOrDeleteMarkers(ods []ObjectVersionOrDeleteMarker, dest *CleanupOrphanObjectsDestination, logger *log.Entry) {
	for _, od := range ods {
		c.clearOrphanObjectsVersionOrDeleteMarker(od, dest, logger)
	}
}

func (c *ObjectCleanupController) clearOrphanObjectsVersionOrDeleteMarker(od ObjectVersionOrDeleteMarker, dest *CleanupOrphanObjectsDestination, logger *log.Entry) {
	if od.GetKey() == nil || od.GetLastModified() == nil {
		logger.Errorf("Ignoring object with missing fields: %v %v", od.GetKey(), od.GetLastModified())
		return
	}

	objectKey := *od.GetKey()
	lastModified := *od.GetLastModified()

	logger = logger.WithFields(log.Fields{
		"object_key":    objectKey,
		"last_modified": lastModified,
	})

	exists, err := c.ObjectRepo.DoesObjectOrTempObjectExist(objectKey)
	if err != nil {
		logger.Error(stacktrace.Propagate(err, "Failed to determine if object already exists in DB"))
		return
	}

	if exists {
		return
	}

	// 2 days ago
	cutoff := stime.Now().AddDate(0, 0, -2)

	// As a safety check, ignore very recent objects from cleanup
	if lastModified.After(cutoff) {
		logger.Warnf("Ignoring too-recent orphan object since it was modified after %v", cutoff)
		return
	}

	logger.Infof("Found orphan object %v", od)

	if dest.HasComplianceHold {
		// Remove compliance hold.
		err := c.ObjectController.DisableObjectConditionalHold(&dest.Client, *dest.Bucket, objectKey)
		if err != nil {
			logger.Error(stacktrace.Propagate(err, "Failed to disable conditional hold on object"))
			return
		}

		// Add the object to the cleanup queue with an expiry time that is after
		// the compliance hold would've passed. Add 2 days of buffer too.
		expiryDays := s3config.WasabiObjectConditionalHoldDays + 2
		expiryTime := time.MicrosecondsAfterDays(expiryDays)
		c.addCleanupEntryForObjectKey(objectKey, dest.DC, expiryTime)

		logger.Infof("Disabled compliance hold and added an entry to cleanup orphan object after %v", expiryTime)
	} else {
		// Delete it right away.
		versionID := od.GetVersionId()
		logger.Infof("Deleting version '%s'", enteString.EmptyIfNil(versionID))
		err := c.DeleteObjectVersion(objectKey, versionID, dest)
		if err != nil {
			logger.Error(stacktrace.Propagate(err, "Failed to delete object"))
		}

		c.mOrphanObjectsDeleted.WithLabelValues(dest.DC).Inc()
	}
}

// DeleteObjectVersion can be used to delete objects from versioned buckets.
//
// If we delete an object in a versioning enabled bucket, deletion does not
// actually remove the object and instead creates a delete marker:
//
//   - When we delete a file, it creates a delete marker
//   - The delete marker becomes the latest version
//   - The old version of the file still remains
//
// If we explicitly pass a version ID in the delete call, then the delete marker
// won't get created.
//
// > To delete versioned objects permanently, use `DELETE Object versionId`
//
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeletingObjectVersions.html
func (c *ObjectCleanupController) DeleteObjectVersion(objectKey string, versionID *string, dest *CleanupOrphanObjectsDestination) error {
	_, err := dest.Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket:    dest.Bucket,
		Key:       &objectKey,
		VersionId: versionID,
	})
	return stacktrace.Propagate(err, "")
}

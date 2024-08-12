package filedata

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/ente"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
	stime "time"
)

const PreSignedRequestValidityDuration = 7 * 24 * stime.Hour

func (c *Controller) getUploadURL(dc string, objectKey string) (*ente.UploadURL, error) {
	s3Client := c.S3Config.GetS3Client(dc)
	r, _ := s3Client.PutObjectRequest(&s3.PutObjectInput{
		Bucket: c.S3Config.GetBucket(dc),
		Key:    &objectKey,
	})
	url, err := r.Presign(PreSignedRequestValidityDuration)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	err = c.ObjectCleanupController.AddTempObjectKey(objectKey, dc)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ente.UploadURL{
		ObjectKey: objectKey,
		URL:       url,
	}, nil
}

func (c *Controller) signedUrlGet(dc string, objectKey string) (*ente.UploadURL, error) {
	s3Client := c.S3Config.GetS3Client(dc)
	r, _ := s3Client.GetObjectRequest(&s3.GetObjectInput{
		Bucket: c.S3Config.GetBucket(dc),
		Key:    &objectKey,
	})
	url, err := r.Presign(PreSignedRequestValidityDuration)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ente.UploadURL{ObjectKey: objectKey, URL: url}, nil
}

func (c *Controller) downloadObject(ctx context.Context, objectKey string, dc string) (fileData.S3FileMetadata, error) {
	var obj fileData.S3FileMetadata
	buff := &aws.WriteAtBuffer{}
	bucket := c.S3Config.GetBucket(dc)
	downloader := c.downloadManagerCache[dc]
	_, err := downloader.DownloadWithContext(ctx, buff, &s3.GetObjectInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	if err != nil {
		return obj, err
	}
	err = json.Unmarshal(buff.Bytes(), &obj)
	if err != nil {
		return obj, stacktrace.Propagate(err, "unmarshal failed")
	}
	return obj, nil
}

// uploadObject uploads the embedding object to the object store and returns the object size
func (c *Controller) uploadObject(obj fileData.S3FileMetadata, objectKey string, dc string) (int64, error) {
	embeddingObj, _ := json.Marshal(obj)
	s3Client := c.S3Config.GetS3Client(dc)
	s3Bucket := c.S3Config.GetBucket(dc)
	uploader := s3manager.NewUploaderWithClient(&s3Client)
	up := s3manager.UploadInput{
		Bucket: s3Bucket,
		Key:    &objectKey,
		Body:   bytes.NewReader(embeddingObj),
	}
	result, err := uploader.Upload(&up)
	if err != nil {
		log.Error(err)
		return -1, stacktrace.Propagate(err, "")
	}
	log.Infof("Uploaded to bucket %s", result.Location)
	return int64(len(embeddingObj)), nil
}

// copyObject copies the object from srcObjectKey to destObjectKey in the same bucket and returns the object size
func (c *Controller) copyObject(srcObjectKey string, destObjectKey string, bucketID string) error {
	bucket := c.S3Config.GetBucket(bucketID)
	s3Client := c.S3Config.GetS3Client(bucketID)
	copySource := fmt.Sprintf("%s/%s", *bucket, srcObjectKey)
	copyInput := &s3.CopyObjectInput{
		Bucket:     bucket,
		CopySource: &copySource,
		Key:        aws.String(destObjectKey),
	}

	_, err := s3Client.CopyObject(copyInput)
	if err != nil {
		return fmt.Errorf("failed to copy (%s) from %s to %s: %v", bucketID, srcObjectKey, destObjectKey, err)
	}
	log.Infof("Copied (%s) from %s to %s", bucketID, srcObjectKey, destObjectKey)
	return nil
}

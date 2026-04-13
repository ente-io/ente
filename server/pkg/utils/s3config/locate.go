package s3config

import (
	"net/http"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
)

// ResolveKey is a convenience wrapper around LocateKey that performs the
// existence check against the S3 client for the given data center.
//
// When no prefix is configured for dc, it returns the database key unchanged
// without issuing any S3 requests. When a prefix is configured, it issues
// at most two HEAD requests (prefixed path, then legacy root path) to find
// where the object actually lives.
//
// This should be used in read paths (presigned GET URL, HEAD, replication
// download, deletion) so that deployments which turn on the prefix after
// accumulating data continue to serve files uploaded under the old root
// path. Write paths (upload, multipart) should always use FullKey so that
// new objects land under the configured prefix.
func (config *S3Config) ResolveKey(dc, dbKey string) (string, error) {
	if config.bucketPrefixes[dc] == "" {
		return dbKey, nil
	}

	client, ok := config.s3Clients[dc]
	if !ok {
		// No S3 client for this DC; return the prefixed path as the
		// best-effort guess and let the caller's later operation fail
		// with a clearer error than a nil panic here.
		return config.FullKey(dc, dbKey), nil
	}

	bucket := config.buckets[dc]
	exists := func(key string) (bool, error) {
		_, err := client.HeadObject(&s3.HeadObjectInput{
			Bucket: aws.String(bucket),
			Key:    aws.String(key),
		})
		if err == nil {
			return true, nil
		}
		if isNotFound(err) {
			return false, nil
		}
		return false, err
	}
	return config.LocateKey(dc, dbKey, exists)
}

// isNotFound reports whether the given error represents an S3 NotFound or
// NoSuchKey response (both map to HTTP 404 depending on the endpoint). All
// other errors are propagated up so that transient failures don't silently
// degrade into a false fallback.
func isNotFound(err error) bool {
	if awsErr, ok := err.(awserr.Error); ok {
		switch awsErr.Code() {
		case s3.ErrCodeNoSuchKey, "NotFound":
			return true
		}
		if reqErr, ok := err.(awserr.RequestFailure); ok {
			return reqErr.StatusCode() == http.StatusNotFound
		}
	}
	return false
}

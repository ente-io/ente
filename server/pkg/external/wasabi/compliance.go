// S3 service style operations for Wasabi specific compliance functionality.
//
// This file contains various service operations for interacting with the Wasabi
// compliance functions. These are based on standard operations templates taken
// from the source code in the AWS S3 Go SDK (v1), and modified to use the
// custom payloads expected by Wasabi.
//
// # Wasabi Compliance
//
// Wasabi supports a compliance policy that prevents the deletion of objects.
//
// Compliance is different from the object lock setting for a bucket, and is
// mutually exclusive with it - a particular bucket can have only one of these
// enabled at a time.
//
// There are compliance settings on a bucket level, which apply the policy that
// is applied to all objects added to that bucket. In addition, there are also
// compliance settings at the object level.
//
// Operations
//
//   - GetBucketCompliance
//
//   - PutBucketCompliance
//
//   - GetObjectCompliance
//
//   - PutObjectCompliance
//
// References
//
//   - Blog post: Custom S3 requests with AWS Go SDK
//     https://ente.io/blog/tech/custom-s3-requests/
//
//   - AWS Go SDK examples:
//     https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/common-examples.html
//
//   - AWS Go SDK API template:
//     https://github.com/aws/aws-sdk-go/blob/main/service/s3/api.go
//
//   - Wasabi Compliance:
//     https://wasabi.com/wp-content/themes/wasabi/docs/API_Guide/index.html#t=topics%2FCompliance.htm&rhsyns=%20
//
//   - Wasabi Compliance - Operations on objects:
//     https://wasabi.com/wp-content/themes/wasabi/docs/API_Guide/index.html#t=topics%2FCompliance1.htm%23XREF_26008_Compliance&rhsyns=%20
package wasabi

import (
	"github.com/aws/aws-sdk-go/aws/awsutil"
	"github.com/aws/aws-sdk-go/aws/request"
	"github.com/aws/aws-sdk-go/service/s3"
)

// newRequest creates a new request for a S3 operation and runs any
// custom request initialization.
func newRequest(c *s3.S3, op *request.Operation, params, data interface{}) *request.Request {
	req := c.NewRequest(op, params, data)

	// Run custom request initialization if present
	// if initRequest != nil {
	// 	initRequest(req)
	// }

	return req
}

const opGetBucketCompliance = "GetBucketCompliance"

// GetBucketCompliance API operation for Wasabi S3 API.
//
// Returns the compliance state of a bucket.
//
// See also: Wasabi compliance
func GetBucketCompliance(c *s3.S3, input *GetBucketComplianceInput) (*GetBucketComplianceOutput, error) {
	req, out := GetBucketComplianceRequest(c, input)
	return out, req.Send()
}

// See also: GetBucketCompliance, Wasabi compliance
func GetBucketComplianceRequest(c *s3.S3, input *GetBucketComplianceInput) (req *request.Request, output *GetBucketComplianceOutput) {
	op := &request.Operation{
		Name:       opGetBucketCompliance,
		HTTPMethod: "GET",
		HTTPPath:   "/{Bucket}?compliance",
	}

	if input == nil {
		input = &GetBucketComplianceInput{}
	}

	output = &GetBucketComplianceOutput{}
	req = newRequest(c, op, input, output)
	return
}

type GetBucketComplianceInput struct {
	_ struct{} `locationName:"GetBucketComplianceRequest" type:"structure"`

	// The name of the bucket for which to get the compliance information.
	//
	// Bucket is a required field
	Bucket *string `location:"uri" locationName:"Bucket" type:"string" required:"true"`
}

// String returns the string representation.
func (s GetBucketComplianceInput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s GetBucketComplianceInput) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *GetBucketComplianceInput) Validate() error {
	invalidParams := request.ErrInvalidParams{Context: "GetBucketComplianceInput"}
	if s.Bucket == nil {
		invalidParams.Add(request.NewErrParamRequired("Bucket"))
	}
	if s.Bucket != nil && len(*s.Bucket) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Bucket", 1))
	}

	if invalidParams.Len() > 0 {
		return invalidParams
	}
	return nil
}

// SetBucket sets the Bucket field's value.
func (s *GetBucketComplianceInput) SetBucket(v string) *GetBucketComplianceInput {
	s.Bucket = &v
	return s
}

// Example response:
//
//	 <BucketComplianceConfiguration xml ns="http://s3.amazonaws.com/doc/2006-03-01/">
//		   <Status>enabled</Status>
//		   <LockTime>2016-11-07T15:08:05Z</LockTime>
//		   <IsLocked>false</IsLocked>
//		   <RetentionDays>0</RetentionDays>
//		   <ConditionalHold>false</ConditionalHold>
//		   <DeleteAfterRetention>false</DeleteAfterRetention>
//	 </BucketComplianceConfiguration>
type GetBucketComplianceOutput struct {
	_ struct{} `type:"structure"`

	// The compliance state of the bucket.
	Status *string `type:"string" enum:"BucketComplianceStatus"`

	// The time at which the compliance settings are "locked".
	LockTime *string `type:"string"`

	// Minimum number of days that objects are retained after their creation
	// date or release from conditional hold.
	RetentionDays *int64 `type:"integer"`

	// Indicates if newly created objects are placed on conditional hold.
	ConditionalHold *bool `type:"boolean"`

	// Indicates if objects should be deleted automatically at the end of the
	// retention period.
	DeleteAfterRetention *bool `type:"boolean"`
}

// String returns the string representation.
func (s GetBucketComplianceOutput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s GetBucketComplianceOutput) GoString() string {
	return s.String()
}

// SetStatus sets the Status field's value.
func (s *GetBucketComplianceOutput) SetStatus(v string) *GetBucketComplianceOutput {
	s.Status = &v
	return s
}

// SetLockTime sets the LockTime field's value.
func (s *GetBucketComplianceOutput) SetLockTime(v string) *GetBucketComplianceOutput {
	s.LockTime = &v
	return s
}

// SetRetentionDays sets the RetentionDays field's value.
func (s *GetBucketComplianceOutput) SetRetentionDays(v int64) *GetBucketComplianceOutput {
	s.RetentionDays = &v
	return s
}

// SetConditionalHold sets the ConditionalHold field's value.
func (s *GetBucketComplianceOutput) SetConditionalHold(v bool) *GetBucketComplianceOutput {
	s.ConditionalHold = &v
	return s
}

// SetDeleteAfterRetention sets the DeleteAfterRetention field's value.
func (s *GetBucketComplianceOutput) SetDeleteAfterRetention(v bool) *GetBucketComplianceOutput {
	s.DeleteAfterRetention = &v
	return s
}

const (
	// BucketComplianceStatusEnabled is a BucketComplianceStatus enum value
	BucketComplianceStatusEnabled = "enabled"

	// BucketVersioningStatusDisabled is a BucketComplianceStatus enum value
	BucketComplianceStatusDisabled = "disabled"
)

// BucketComplianceStatus_Values returns all elements of the BucketComplianceStatus enum
func BucketComplianceStatus_Values() []string {
	return []string{
		BucketComplianceStatusEnabled,
		BucketComplianceStatusDisabled,
	}
}

const opPutBucketCompliance = "PutBucketCompliance"

// PutBucketCompliance API operation for Wasabi.
//
// Sets the compliance state of an existing bucket.
//
// The compliance settings for a bucket are specified using the "?compliance"
// query string along with the com­pliance settings as the XML body in the
// request. For example:
//
//		  PUT http://s3.wasabisys.com/my-bucket?compliance HTTP/1.1
//
//		  <BucketComplianceConfiguration>
//		    <Status>enabled</Status>
//		    <LockTime>off</LockTime>
//		    <RetentionDays>365</RetentionDays>
//	        <DeleteAfterRetention>true</DeleteAfterRetention>
//		  </BucketComplianceConfiguration>
//
// After compliance is enabled for a bucket, the policy is immediately applied
// to all objects in the bucket. An attempt to delete an object before the
// retention period will return an error.
//
// See also: Wasabi compliance
func PutBucketCompliance(c *s3.S3, input *PutBucketComplianceInput) (*PutBucketComplianceOutput, error) {
	req, out := PutBucketComplianceRequest(c, input)
	return out, req.Send()
}

// See also: PutBucketCompliance, Wasabi compliance
func PutBucketComplianceRequest(c *s3.S3, input *PutBucketComplianceInput) (req *request.Request, output *PutBucketComplianceOutput) {
	op := &request.Operation{
		Name:       opPutBucketCompliance,
		HTTPMethod: "PUT",
		HTTPPath:   "/{Bucket}?compliance",
	}

	if input == nil {
		input = &PutBucketComplianceInput{}
	}

	output = &PutBucketComplianceOutput{}
	req = newRequest(c, op, input, output)
	// req.Handlers.Unmarshal.Swap(restxml.UnmarshalHandler.Name, protocol.UnmarshalDiscardBodyHandler)
	// req.Handlers.Build.PushBackNamed(request.NamedHandler{
	// 	Name: "contentMd5Handler",
	// 	Fn:   checksum.AddBodyContentMD5Handler,
	// })
	return
}

type PutBucketComplianceInput struct {
	_ struct{} `locationName:"PutBucketComplianceRequest" type:"structure" payload:"BucketComplianceConfiguration"`

	// The bucket name.
	//
	// Bucket is a required field
	Bucket *string `location:"uri" locationName:"Bucket" type:"string" required:"true"`

	// A container for the compliance configuration.
	//
	// BucketComplianceConfiguration is a required field
	BucketComplianceConfiguration *BucketComplianceConfiguration `locationName:"BucketComplianceConfiguration" type:"structure" required:"true"`
}

// A container for the bucket compliance configuration.
type BucketComplianceConfiguration struct {
	_ struct{} `type:"structure"`

	// The compliance state of the bucket.
	//
	// Either "enabled" or "disabled" to turn compliance on and off,
	// respectively. Enabling will immediately apply to all objects in the
	// bucket.
	Status *string `type:"string" enum:"BucketComplianceStatus"`

	// The time at which the compliance settings are "locked".
	//
	// The time at which the compliance settings are "locked"— the settings
	// cannot be reduced by any API call. Once the settings are locked, they
	// cannot be unlocked without the intervention of Wasabi Customer Support.
	// The lock time allows you to support two use cases:
	//
	// 1) testing that your software works properly before locking the
	//    compliance feature; or
	//
	// 2) never locking which means that data can be deleted with an additional
	//    step of an administrator turning compliance off.
	//
	// The lock time parameter may be:
	//
	// - an ISO date (for example, 2016-11-07T15:08:05Z),
	//
	// - the string "now" to force immediate locking, or
	//
	// - the string "off" to not lock the compliance settings. This is the default.
	LockTime *string `type:"string"`

	// An integer for the minimum number of days that objects are always
	// retained after their creation date or release from conditional hold. You
	// can extend the retention date for any individual object, but may not
	// shorten the date. This parameter is always required.
	RetentionDays *int64 `type:"integer"`

	// A Boolean value indicating if newly created objects are placed on
	// conditional hold, meaning that they cannot be deleted until the
	// con­ditional hold is explicitly turned off. The default is false if this
	// parameter is not given. Note that this setting may be changed even after
	// the settings are locked.
	ConditionalHold *bool `type:"boolean"`

	// A Boolean value indicating if the object should be deleted automatically
	// at the end of the retention period. The default is to not delete objects
	// after the reten­tion period. Note that this setting may be changed even
	// after the settings are locked.
	DeleteAfterRetention *bool `type:"boolean"`
}

// String returns the string representation.
func (s PutBucketComplianceInput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s PutBucketComplianceInput) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *PutBucketComplianceInput) Validate() error {
	invalidParams := request.ErrInvalidParams{Context: "PutBucketComplianceInput"}
	if s.Bucket == nil {
		invalidParams.Add(request.NewErrParamRequired("Bucket"))
	}
	if s.Bucket != nil && len(*s.Bucket) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Bucket", 1))
	}
	if s.BucketComplianceConfiguration == nil {
		invalidParams.Add(request.NewErrParamRequired("BucketComplianceConfiguration"))
	}
	if s.BucketComplianceConfiguration != nil {
		if err := s.BucketComplianceConfiguration.Validate(); err != nil {
			invalidParams.AddNested("BucketComplianceConfiguration", err.(request.ErrInvalidParams))
		}
	}

	if invalidParams.Len() > 0 {
		return invalidParams
	}
	return nil
}

// SetBucket sets the Bucket field's value.
func (s *PutBucketComplianceInput) SetBucket(v string) *PutBucketComplianceInput {
	s.Bucket = &v
	return s
}

// SetBucket sets the BucketComplianceConfiguration field's value.
func (s *PutBucketComplianceInput) SetBucketComplianceConfiguration(v BucketComplianceConfiguration) *PutBucketComplianceInput {
	s.BucketComplianceConfiguration = &v
	return s
}

// String returns the string representation.
func (s BucketComplianceConfiguration) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s BucketComplianceConfiguration) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *BucketComplianceConfiguration) Validate() error {
	invalidParams := request.ErrInvalidParams{Context: "BucketComplianceConfiguration"}
	if s.RetentionDays == nil {
		invalidParams.Add(request.NewErrParamRequired("RetentionDays"))
	}

	if invalidParams.Len() > 0 {
		return invalidParams
	}
	return nil
}

// SetStatus sets the Status field's value.
func (s *BucketComplianceConfiguration) SetStatus(v string) *BucketComplianceConfiguration {
	s.Status = &v
	return s
}

// SetLockTime sets the LockTime field's value.
func (s *BucketComplianceConfiguration) SetLockTime(v string) *BucketComplianceConfiguration {
	s.LockTime = &v
	return s
}

// SetRetentionDays sets the RetentionDays field's value.
func (s *BucketComplianceConfiguration) SetRetentionDays(v int64) *BucketComplianceConfiguration {
	s.RetentionDays = &v
	return s
}

// SetConditionalHold sets the ConditionalHold field's value.
func (s *BucketComplianceConfiguration) SetConditionalHold(v bool) *BucketComplianceConfiguration {
	s.ConditionalHold = &v
	return s
}

// SetDeleteAfterRetention sets the DeleteAfterRetention field's value.
func (s *BucketComplianceConfiguration) SetDeleteAfterRetention(v bool) *BucketComplianceConfiguration {
	s.DeleteAfterRetention = &v
	return s
}

type PutBucketComplianceOutput struct {
	_ struct{} `type:"structure"`
}

// String returns the string representation.
func (s PutBucketComplianceOutput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s PutBucketComplianceOutput) GoString() string {
	return s.String()
}

const opGetObjectCompliance = "GetObjectCompliance"

// GetObjectCompliance API operation for Wasabi S3 API.
//
// Returns the compliance state of an object.
//
// The compliance settings for any specific object can also be retrieved using
// the "?compliance" query string. In addition to the object compliance settings
// above, the query returns the calculated SHA256 hash for the object, which can
// be used to determine that the object has not been modified. Note that the
// SHA256 value is only available for objects that are uploaded as a single
// object and is not available for multi-part or composed objects.
//
// The following is an example of getting the compliance on an object:
//
//		GET http://s3.wasabisys.com/my-bucket/my-object?compliance HTTP/1.1
//
//		<ObjectComplianceConfiguration xml ns="http://s3.amazonaws.com/doc/2006-03-01/">
//		  <RetentionTime>2016-10-31T15:08:05Z</RetentionTime>
//		  <ConditionalHold>false</ConditionalHold>
//		  <LegalHold>false</LegalHold>
//	      <SHA256>14b4be3894e92166b508007b6c2e4fb6e88d3d0ad652c76475089a50ebe6e33b</SHA256>
//		</ObjectComplianceConfiguration>
//
// See also: Wasabi compliance
func GetObjectCompliance(c *s3.S3, input *GetObjectComplianceInput) (*GetObjectComplianceOutput, error) {
	req, out := GetObjectComplianceRequest(c, input)
	return out, req.Send()
}

// See also: GetObjectCompliance, Wasabi compliance
func GetObjectComplianceRequest(c *s3.S3, input *GetObjectComplianceInput) (req *request.Request, output *GetObjectComplianceOutput) {
	op := &request.Operation{
		Name:       opGetObjectCompliance,
		HTTPMethod: "GET",
		HTTPPath:   "/{Bucket}/{Key+}?compliance",
	}

	if input == nil {
		input = &GetObjectComplianceInput{}
	}

	output = &GetObjectComplianceOutput{}
	req = newRequest(c, op, input, output)
	return
}

type GetObjectComplianceInput struct {
	_ struct{} `locationName:"GetObjectComplianceRequest" type:"structure"`

	// The bucket name of the bucket containing the object.
	//
	// Bucket is a required field
	Bucket *string `location:"uri" locationName:"Bucket" type:"string" required:"true"`

	// Key name of the object to get the compliance information of.
	//
	// Key is a required field
	Key *string `location:"uri" locationName:"Key" min:"1" type:"string" required:"true"`
}

// String returns the string representation.
func (s GetObjectComplianceInput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s GetObjectComplianceInput) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *GetObjectComplianceInput) Validate() error {
	invalidParams := request.ErrInvalidParams{Context: "GetObjectComplianceInput"}
	if s.Bucket == nil {
		invalidParams.Add(request.NewErrParamRequired("Bucket"))
	}
	if s.Bucket != nil && len(*s.Bucket) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Bucket", 1))
	}
	if s.Key == nil {
		invalidParams.Add(request.NewErrParamRequired("Key"))
	}
	if s.Key != nil && len(*s.Key) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Key", 1))
	}

	if invalidParams.Len() > 0 {
		return invalidParams
	}
	return nil
}

// SetBucket sets the Bucket field's value.
func (s *GetObjectComplianceInput) SetBucket(v string) *GetObjectComplianceInput {
	s.Bucket = &v
	return s
}

// SetKey sets the Key field's value.
func (s *GetObjectComplianceInput) SetKey(v string) *GetObjectComplianceInput {
	s.Key = &v
	return s
}

// See also: PutObjectComplianceInput
type GetObjectComplianceOutput struct {
	_ struct{} `type:"structure"`

	// The time before which the object cannot be deleted.
	RetentionTime *string `type:"string"`

	// Indicates if the object is under conditional hold.
	ConditionalHold *bool `type:"boolean"`

	// Indicates if the object is under legal hold.
	LegalHold *bool `type:"boolean"`

	// The calculated SHA256 hash for the object
	SHA256 *string `type:"string"`
}

// String returns the string representation.
func (s GetObjectComplianceOutput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s GetObjectComplianceOutput) GoString() string {
	return s.String()
}

// SetRetentionTime sets the RetentionTime field's value.
func (s *GetObjectComplianceOutput) SetRetentionTime(v string) *GetObjectComplianceOutput {
	s.RetentionTime = &v
	return s
}

// SetConditionalHold sets the ConditionalHold field's value.
func (s *GetObjectComplianceOutput) SetConditionalHold(v bool) *GetObjectComplianceOutput {
	s.ConditionalHold = &v
	return s
}

// SetConditionalHold sets the ConditionalHold field's value.
func (s *GetObjectComplianceOutput) SetLegalHold(v bool) *GetObjectComplianceOutput {
	s.LegalHold = &v
	return s
}

// SetRetentionTime sets the SHA256 field's value.
func (s *GetObjectComplianceOutput) SetSHA256(v string) *GetObjectComplianceOutput {
	s.SHA256 = &v
	return s
}

const opPutObjectCompliance = "PutObjectCompliance"

// PutObjectCompliance API operation for Wasabi.
//
// Sets the compliance state of an existing object.
//
// The compliance settings for any one object in a bucket with compliance can
// also be changed within the lim­its of the compliance on the bucket.
//
// See also: PutObjectComplianceInput, Wasabi compliance
func PutObjectCompliance(c *s3.S3, input *PutObjectComplianceInput) (*PutObjectComplianceOutput, error) {
	req, out := PutObjectComplianceRequest(c, input)
	return out, req.Send()
}

// See also: PutObjectCompliance, Wasabi compliance
func PutObjectComplianceRequest(c *s3.S3, input *PutObjectComplianceInput) (req *request.Request, output *PutObjectComplianceOutput) {
	op := &request.Operation{
		Name:       opPutObjectCompliance,
		HTTPMethod: "PUT",
		HTTPPath:   "/{Bucket}/{Key+}?compliance",
	}

	if input == nil {
		input = &PutObjectComplianceInput{}
	}

	output = &PutObjectComplianceOutput{}
	req = newRequest(c, op, input, output)
	// req.Handlers.Unmarshal.Swap(restxml.UnmarshalHandler.Name, protocol.UnmarshalDiscardBodyHandler)
	// req.Handlers.Build.PushBackNamed(request.NamedHandler{
	// 	Name: "contentMd5Handler",
	// 	Fn:   checksum.AddBodyContentMD5Handler,
	// })
	return
}

// The following is an example of setting the compliance on an object:
//
//		PUT http://s3.wasabisys.com/my-bucket/my-object?compliance HTTP/1.1
//
//		<ObjectComplianceConfiguration>
//		  <ConditionalHold>false</ConditionalHold>
//	      <RetentionTime>2018-03-13T10:45:00Z</RetentionTime>
//		</ObjectComplianceConfiguration>
type PutObjectComplianceInput struct {
	_ struct{} `locationName:"PutObjectComplianceRequest" type:"structure" payload:"ObjectComplianceConfiguration"`

	// The bucket name of the bucket containing the object.
	//
	// Bucket is a required field
	Bucket *string `location:"uri" locationName:"Bucket" type:"string" required:"true"`

	// Key name of the object to put the compliance information to.
	//
	// Key is a required field
	Key *string `location:"uri" locationName:"Key" min:"1" type:"string" required:"true"`

	// A container for object compliance configuration.
	//
	// ObjectComplianceConfiguration is a required field
	ObjectComplianceConfiguration *ObjectComplianceConfiguration `locationName:"ObjectComplianceConfiguration" type:"structure" required:"true"`
}

// A container for object compliance configuration.
type ObjectComplianceConfiguration struct {
	_ struct{} `type:"structure"`

	// An ISO time giving a new retention time for the object in which the
	// object cannot be deleted before this time. Note that the new retention
	// time must be past the reten­tion period given by the bucket policy or an
	// error is returned.
	RetentionTime *string `type:"string"`

	// A Boolean value "false" to release the object from the conditional hold
	// setting in the bucket policy. The retention period in days is started
	// from the point when the con­ditional hold is released. Once the
	// conditional hold is set false, it may not be returned to conditional
	// hold.
	ConditionalHold *bool `type:"boolean"`

	// A Boolean value "true" or "false" to set the legal hold status. When an
	// object has a legal hold status of true, the object cannot be deleted
	// regardless of the retention period.
	LegalHold *bool `type:"boolean"`
}

// String returns the string representation.
func (s PutObjectComplianceInput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s PutObjectComplianceInput) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *PutObjectComplianceInput) Validate() error {
	invalidParams := request.ErrInvalidParams{Context: "PutObjectComplianceInput"}
	if s.Bucket == nil {
		invalidParams.Add(request.NewErrParamRequired("Bucket"))
	}
	if s.Bucket != nil && len(*s.Bucket) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Bucket", 1))
	}
	if s.Key == nil {
		invalidParams.Add(request.NewErrParamRequired("Key"))
	}
	if s.Key != nil && len(*s.Key) < 1 {
		invalidParams.Add(request.NewErrParamMinLen("Key", 1))
	}
	if s.ObjectComplianceConfiguration == nil {
		invalidParams.Add(request.NewErrParamRequired("ObjectComplianceConfiguration"))
	}
	if s.ObjectComplianceConfiguration != nil {
		if err := s.ObjectComplianceConfiguration.Validate(); err != nil {
			invalidParams.AddNested("ObjectComplianceConfiguration", err.(request.ErrInvalidParams))
		}
	}

	if invalidParams.Len() > 0 {
		return invalidParams
	}
	return nil
}

// SetBucket sets the Bucket field's value.
func (s *PutObjectComplianceInput) SetBucket(v string) *PutObjectComplianceInput {
	s.Bucket = &v
	return s
}

// SetKey sets the Key field's value.
func (s *PutObjectComplianceInput) SetKey(v string) *PutObjectComplianceInput {
	s.Key = &v
	return s
}

// String returns the string representation.
func (s ObjectComplianceConfiguration) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s ObjectComplianceConfiguration) GoString() string {
	return s.String()
}

// Validate inspects the fields of the type to determine if they are valid.
func (s *ObjectComplianceConfiguration) Validate() error {
	return nil
}

// SetRetentionTime sets the RetentionTime field's value.
func (s *ObjectComplianceConfiguration) SetRetentionTime(v string) *ObjectComplianceConfiguration {
	s.RetentionTime = &v
	return s
}

// SetConditionalHold sets the ConditionalHold field's value.
func (s *ObjectComplianceConfiguration) SetConditionalHold(v bool) *ObjectComplianceConfiguration {
	s.ConditionalHold = &v
	return s
}

// SetLegalHold sets the LegalHold field's value.
func (s *ObjectComplianceConfiguration) SetLegalHold(v bool) *ObjectComplianceConfiguration {
	s.LegalHold = &v
	return s
}

type PutObjectComplianceOutput struct {
	_ struct{} `type:"structure"`
}

// String returns the string representation.
func (s PutObjectComplianceOutput) String() string {
	return awsutil.Prettify(s)
}

// GoString returns the string representation.
func (s PutObjectComplianceOutput) GoString() string {
	return s.String()
}

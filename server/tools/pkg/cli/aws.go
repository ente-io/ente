package cli

import (
	"flag"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
)

// ParseAndCreateSession returns a Session object, emulating AWS CLI
// configuration.
//
// This is a convenience method to create CLI tools that behave similar to AWS
// CLI tools in where they pick up their configuration and credential from.
//
// It'll add and parse two command line flags: `--profile` and `--endpoint-url`.
//
// Beyond that, the method will pick up the S3 configuration and credentials
// from the same standard places where aws-cli looks for them:
//
// https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html
//
// As a tldr, the easiest way to use this might be to add a new AWS profile:
//
//	# ~/.aws/config
//	[profile wasabi-test-compliance]
//	region = eu-central-2
//
//	# ~/.aws/credentials
//	[wasabi-test-compliance]
//	aws_access_key_id = test
//	aws_secret_access_key = test
//
// And `export AWS_PROFILE=wasabi-test-compliance`, or provide it to the
// commands via the `--profile` flag.
//
// Alternatively, if you don't wish to use AWS profiles, then you can provide
// these values using the standard AWS environment variables.
//
//	export AWS_REGION=eu-central-2
//	export AWS_ACCESS_KEY_ID=test
//	export AWS_SECRET_ACCESS_KEY=test
//
// > Tip: If your shell is configured to do so, you can add a leading space `
//
//	export AWS_SECRET_....` to avoid preserving these secrets in your shell
//	history.
//
// The endpoint to connect to can be either passed as an (optional) method
// parameter, or can be specified at runtime using the `--endpoint-url` flag.
//
// S3ForcePathStyle can be set to true when connecting to locally running MinIO
// instances where each bucket will not have a DNS.
func ParseAndCreateSession(endpointURL string, S3ForcePathStyle bool) (*session.Session, error) {
	logLevel := aws.LogDebugWithHTTPBody
	cliProfile := flag.String("profile", "AWS_PROFILE",
		"The profile to use from the S3 config file")
	cliEndpointURL := flag.String("endpoint-url", "",
		"The root URL of the S3 compatible API (excluding the bucket)")
	flag.Parse()

	profile := *cliProfile
	if profile == "" {
		profile = os.Getenv("AWS_PROFILE")
	}

	// Override the passed in value with the CLI always.
	if *cliEndpointURL != "" {
		endpointURL = *cliEndpointURL
	}

	fmt.Printf("Using profile %s, endpoint %s\n", profile, endpointURL)

	sess, err := session.NewSessionWithOptions(session.Options{
		Profile: profile,
		// Needed to read region from .aws/profile
		SharedConfigState: session.SharedConfigEnable,
		Config: aws.Config{
			Endpoint:         aws.String(endpointURL),
			S3ForcePathStyle: aws.Bool(S3ForcePathStyle),
			LogLevel:         &logLevel,
		},
	})
	if err != nil {
		fmt.Printf("NewSessionWithOptions error: %s\n", err)
		return sess, err
	}

	return sess, err
}

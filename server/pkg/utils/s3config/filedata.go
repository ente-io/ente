package s3config

import "github.com/ente-io/museum/ente"

type ObjectBucketConfig struct {
	PrimaryBucket  string   `mapstructure:"primary"`
	ReplicaBuckets []string `mapstructure:"replicas"`
}

type FileDataConfig struct {
	ObjectBucketConfig map[ente.ObjectType]ObjectBucketConfig `mapstructure:"objectBuckets"`
}

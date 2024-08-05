package s3config

import (
	"fmt"
	"github.com/ente-io/museum/ente"
)

type ObjectBucketConfig struct {
	PrimaryBucket  string   `mapstructure:"primaryBucket"`
	ReplicaBuckets []string `mapstructure:"replicaBuckets"`
}

type FileDataConfig struct {
	ObjectBucketConfig map[ente.ObjectType]ObjectBucketConfig `mapstructure:"file-data-config"`
}

func (f FileDataConfig) HasConfig(objectType ente.ObjectType) bool {
	if objectType == "" || objectType == ente.FILE || objectType == ente.THUMBNAIL {
		panic(fmt.Sprintf("Invalid object type: %s", objectType))
	}
	_, ok := f.ObjectBucketConfig[objectType]
	return ok
}

func (f FileDataConfig) GetPrimaryBucketID(objectType ente.ObjectType) string {
	config, ok := f.ObjectBucketConfig[objectType]
	if !ok {
		panic(fmt.Sprintf("No config for object type: %s, use HasConfig", objectType))
	}
	return config.PrimaryBucket
}

func (f FileDataConfig) GetReplicaBuckets(objectType ente.ObjectType) []string {
	config, ok := f.ObjectBucketConfig[objectType]
	if !ok {
		panic(fmt.Sprintf("No config for object type: %s, use HasConfig", objectType))
	}
	return config.ReplicaBuckets
}

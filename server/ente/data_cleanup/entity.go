package data_cleanup

// Stage represents the action to be taken on the next scheduled run for a particular stage
type Stage string

const (
	// Scheduled means user data is scheduled for deletion
	Scheduled Stage = "scheduled"
	// Collection means trash all collections for the user
	Collection Stage = "collection"
	// Trash means trigger empty trash for the user
	Trash Stage = "trash"
	// Storage means check for consumed storage
	Storage Stage = "storage"
	// Completed means data clean up is done
	Completed Stage = "completed"
)

type DataCleanup struct {
	UserID int64
	Stage  Stage
	// StageScheduleTime indicates when should we process current stage
	StageScheduleTime int64
	// StageAttemptCount refers to number of attempts made to execute current stage
	StageAttemptCount int
	CreatedAt         int64
	UpdatedAt         int64
}

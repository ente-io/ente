package llmchat

func isPaidUser(checker SubscriptionChecker, userID int64) bool {
	if checker == nil {
		return false
	}
	return checker.HasActiveSelfOrFamilySubscription(userID, false) == nil
}

func maxAttachmentSizeForUser(checker SubscriptionChecker, userID int64) int64 {
	if isPaidUser(checker, userID) {
		return llmChatMaxAttachmentPaid
	}
	return llmChatMaxAttachmentFree
}

func maxAttachmentStorageForUser(checker SubscriptionChecker, userID int64) int64 {
	if isPaidUser(checker, userID) {
		return llmChatMaxAttachmentStoragePaid
	}
	return llmChatMaxAttachmentStorageFree
}

package usercache

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
)

func (c *Controller) GetUserFileCountWithCache(userID int64, app ente.App) (int64, error) {
	// Check if the value is present in the cache
	if count, ok := c.UserCache.GetFileCount(userID, app); ok {
		// Cache hit, update the cache asynchronously
		go func() {
			_, _ = c.getUserCountAndUpdateCache(userID, app)
		}()
		return count, nil
	}
	return c.getUserCountAndUpdateCache(userID, app)
}

func (c *Controller) getUserCountAndUpdateCache(userID int64, app ente.App) (int64, error) {
	count, err := c.FileRepo.GetFileCountForUser(userID, app)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	c.UserCache.SetFileCount(userID, count, app)
	return count, nil
}

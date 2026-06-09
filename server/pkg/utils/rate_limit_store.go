package utils

import (
	"context"
	"sync"
	"time"

	"github.com/ulule/limiter/v3"
	"github.com/ulule/limiter/v3/drivers/store/common"
)

// memoryLimiterStore keeps rate-limit keys as owned strings. This is needed
// because the limiter/v3 memory driver stores keys derived from pooled byte
// buffers, which can mutate after insertion and break sync.Map's hash invariant.
type memoryLimiterStore struct {
	mu          sync.Mutex
	prefix      string
	nextCleanup time.Time
	counters    map[string]memoryLimiterCounter
}

type memoryLimiterCounter struct {
	value      int64
	expiration time.Time
}

func newMemoryLimiterStore() *memoryLimiterStore {
	return &memoryLimiterStore{
		prefix:      limiter.DefaultPrefix,
		nextCleanup: time.Now().Add(limiter.DefaultCleanUpInterval),
		counters:    make(map[string]memoryLimiterCounter),
	}
}

func (store *memoryLimiterStore) Get(_ context.Context, key string, rate limiter.Rate) (limiter.Context, error) {
	now := time.Now()
	expiration := now.Add(rate.Period)
	cacheKey := store.cacheKey(key)

	store.mu.Lock()
	defer store.mu.Unlock()

	store.cleanup(now)
	counter := store.counters[cacheKey]
	if !counter.expiration.After(now) {
		counter.value = 1
		counter.expiration = expiration
	} else {
		counter.value++
	}
	store.counters[cacheKey] = counter
	return common.GetContextFromState(now, rate, counter.expiration, counter.value), nil
}

func (store *memoryLimiterStore) Peek(_ context.Context, key string, rate limiter.Rate) (limiter.Context, error) {
	now := time.Now()
	expiration := now.Add(rate.Period)
	count := int64(0)
	cacheKey := store.cacheKey(key)

	store.mu.Lock()
	defer store.mu.Unlock()

	store.cleanup(now)
	if counter, ok := store.counters[cacheKey]; ok && counter.expiration.After(now) {
		count = counter.value
		expiration = counter.expiration
	}
	return common.GetContextFromState(now, rate, expiration, count), nil
}

func (store *memoryLimiterStore) Reset(_ context.Context, key string, rate limiter.Rate) (limiter.Context, error) {
	now := time.Now()
	expiration := now.Add(rate.Period)

	store.mu.Lock()
	defer store.mu.Unlock()

	store.cleanup(now)
	delete(store.counters, store.cacheKey(key))
	return common.GetContextFromState(now, rate, expiration, 0), nil
}

func (store *memoryLimiterStore) cacheKey(key string) string {
	return store.prefix + ":" + key
}

func (store *memoryLimiterStore) cleanup(now time.Time) {
	if now.Before(store.nextCleanup) {
		return
	}
	for key, counter := range store.counters {
		if !counter.expiration.After(now) {
			delete(store.counters, key)
		}
	}
	store.nextCleanup = now.Add(limiter.DefaultCleanUpInterval)
}

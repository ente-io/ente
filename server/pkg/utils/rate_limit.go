package utils

import (
	"github.com/ulule/limiter/v3"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

// NewRateLimiter will return instance of limiter.Limiter based on internal <limit>-<period>
// Examples: 5 reqs/sec: "5-S", 10 reqs/min: "10-M"
// 1000 reqs/hour: "1000-H", 2000 reqs/day: "2000-D"
// https://github.com/ulule/limiter/
func NewRateLimiter(interval string) *limiter.Limiter {
	store := memory.NewStore()
	rate, err := limiter.NewRateFromFormatted(interval)
	if err != nil {
		panic(err)
	}
	return limiter.New(store, rate)
}

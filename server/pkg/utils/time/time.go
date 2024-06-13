package time

import (
	"fmt"
	"math"
	"strings"
	"time"
)

const (
	MicroSecondsInOneSecond int64 = 1000 * 1000
	MicroSecondsInOneMinute       = 60 * MicroSecondsInOneSecond
	MicroSecondsInOneHour         = 60 * MicroSecondsInOneMinute

	minutesInOneDay  = time.Minute * 60 * 24
	minutesInOneYear = 365 * minutesInOneDay
	minutesInOneHour = 60
	hoursInOneDay    = 24
)

// Microseconds returns the time in micro seconds
func Microseconds() int64 {
	return time.Now().UnixNano() / 1000
}

// Nanoseconds returns the time in nano seconds
func Nanoseconds() int64 {
	return time.Now().UnixNano()
}

// MicrosecondsAfterHours returns the time in micro seconds after noOfHours
func MicrosecondsAfterHours(noOfHours int8) int64 {
	return Microseconds() + int64(noOfHours)*MicroSecondsInOneHour
}

// MicrosecondsAfterDays returns the time in micro seconds after noOfDays
func MicrosecondsAfterDays(noOfDays int) int64 {
	return Microseconds() + int64(noOfDays*24)*MicroSecondsInOneHour
}

// MicrosecondBeforeDays returns the time in micro seconds before noOfDays
func MicrosecondBeforeDays(noOfDays int) int64 {
	return Microseconds() - int64(noOfDays*24)*MicroSecondsInOneHour
}

// NDaysFromNow returns the time n days from now in micro seconds
func NDaysFromNow(n int) int64 {
	return time.Now().AddDate(0, 0, n).UnixNano() / 1000
}

// NMinFromNow returns the time n min from now in micro seconds
func NMinFromNow(n int64) int64 {
	return time.Now().Add(time.Minute*time.Duration(n)).UnixNano() / 1000
}

// MicrosecondsBeforeMinutes returns the unix time n minutes before now in micro seconds
func MicrosecondsBeforeMinutes(noOfMinutes int64) int64 {
	return Microseconds() - (MicroSecondsInOneMinute * noOfMinutes)
}

// MicrosecondsAfterMinutes returns the unix time n minutes from now in micro seconds
func MicrosecondsAfterMinutes(noOfMinutes int64) int64 {
	return Microseconds() + (MicroSecondsInOneMinute * noOfMinutes)
}

func HumanFriendlyDuration(d time.Duration) string {
	if d < minutesInOneDay {
		return d.String()
	}
	var b strings.Builder
	if d >= minutesInOneYear {
		years := d / minutesInOneYear
		fmt.Fprintf(&b, "%dy", years)
		d -= years * minutesInOneYear
	}

	days := d / minutesInOneDay
	d -= days * minutesInOneDay
	fmt.Fprintf(&b, "%dd%s", days, d)

	return b.String()
}

func DaysOrHoursOrMinutes(d time.Duration) string {
	minutes := d.Minutes()
	if minutes < minutesInOneHour {
		return pluralIfNecessary(int(minutes), "minute")
	}
	hours := math.Round(d.Hours())
	if hours < hoursInOneDay {
		return pluralIfNecessary(int(hours), "hour")
	}
	days := int(hours / hoursInOneDay)
	return pluralIfNecessary(int(days), "day")
}

func pluralIfNecessary(amount int, unit string) string {
	if amount == 1 {
		return fmt.Sprintf("%d %s", amount, unit)
	}
	return fmt.Sprintf("%d %ss", amount, unit)
}

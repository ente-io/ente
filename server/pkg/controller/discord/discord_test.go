package discord

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/bwmarrin/discordgo"
	"github.com/stretchr/testify/require"
)

func TestPotentialAbuseThrottle(t *testing.T) {
	c, sent := recordingController(t)
	const mismatch = "custom domain - domainMismatch"
	const invalidDomain = "custom domain - domainToASCIIFailed"
	c.NotifyPotentialAbuse(mismatch)

	var wg sync.WaitGroup
	for range 32 {
		wg.Go(func() { c.NotifyPotentialAbuse(mismatch) })
	}
	wg.Wait()
	require.Equal(t, []string{"host: " + mismatch}, sent.messages)

	c.NotifyPotentialAbuse(invalidDomain)
	require.Equal(t, []string{"host: " + mismatch, "host: " + invalidDomain}, sent.messages)

	key := sha256.Sum256([]byte("host: " + mismatch))
	c.lastSent[key] = time.Now().Add(-2 * time.Minute)
	c.NotifyPotentialAbuse(mismatch)
	require.Equal(t, []string{"host: " + mismatch, "host: " + invalidDomain, "host: " + mismatch}, sent.messages)
}

func TestNotifyThrottledBoundsCache(t *testing.T) {
	c, sent := recordingController(t)
	base := time.Now().Add(-30 * time.Second)
	for i := range maxThrottleEntries {
		key := sha256.Sum256([]byte(fmt.Sprintf("message %d", i)))
		c.lastSent[key] = base.Add(time.Duration(i) * time.Millisecond)
	}

	c.NotifyThrottled("new message", time.Minute)
	c.NotifyThrottled("new message", time.Minute)
	require.Equal(t, []string{"new message"}, sent.messages)
	require.Len(t, c.lastSent, maxThrottleEntries)
	require.NotContains(t, c.lastSent, sha256.Sum256([]byte("message 0")))
	require.Contains(t, c.lastSent, sha256.Sum256([]byte("new message")))

	// Eviction admits new alerts at the cost of allowing an early repeat.
	c.NotifyThrottled("message 0", time.Minute)
	require.Equal(t, []string{"new message", "message 0"}, sent.messages)
	var wg sync.WaitGroup
	for i := range 2 * maxThrottleEntries {
		wg.Go(func() { c.NotifyThrottled(fmt.Sprintf("distinct message %d", i), time.Minute) })
	}
	wg.Wait()
	require.Len(t, c.lastSent, maxThrottleEntries)
	require.Len(t, sent.messages, 2+2*maxThrottleEntries)
}

// Capture Discord payloads without contacting Discord or adding production hooks.
type recordingTransport struct {
	messages []string
}

func (r *recordingTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	var message discordgo.MessageSend
	if err := json.NewDecoder(req.Body).Decode(&message); err != nil {
		return nil, err
	}
	r.messages = append(r.messages, message.Content)
	return &http.Response{
		StatusCode: http.StatusOK,
		Header:     make(http.Header),
		Body:       io.NopCloser(strings.NewReader(`{}`)),
	}, nil
}

func recordingController(t *testing.T) (*DiscordController, *recordingTransport) {
	t.Helper()
	bot, err := discordgo.New("")
	require.NoError(t, err)
	sent := &recordingTransport{}
	bot.Client = &http.Client{Transport: sent}
	return &DiscordController{
		MonaLisa: bot,
		HostName: "host",
		lastSent: make(map[[sha256.Size]byte]time.Time),
	}, sent
}

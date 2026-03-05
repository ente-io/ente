package api

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/external/listmonk"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/crypto"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

const listmonkMissingSubscribersDefaultPageSize = 10000
const listmonkMissingSubscribersMaxLoggedEmails = 10

var listminkMissingSubscribersInFlight atomic.Bool

type listminkMissingSubscribersJobConfig struct {
	Endpoint         string
	Username         string
	Password         string
	PageSize         int
	HasUpperLimit    bool
	UpperLimit       int
	LogMissingEmails bool
	TargetListIDSet  map[int]struct{}
}

type listminkMissingSubscribersJobSummary struct {
	StartedAt     int64
	CompletedAt   int64
	MissingCount  int
	MatchedCount  int
	ScannedCount  int
	FetchedCount  int
	PagesFetched  int
	ListmonkTotal int
	StopReason    string
	Capped        bool
}

func (h *AdminHandler) GetListmonkMissingSubscribersCount(c *gin.Context) {
	baseURL := strings.TrimRight(viper.GetString("listmonk.server-url"), "/")
	username := viper.GetString("listmonk.username")
	password := viper.GetString("listmonk.password")
	listIDs := viper.GetIntSlice("listmonk.list-ids")
	pageSize := listmonkMissingSubscribersDefaultPageSize
	if pageSizeParam := strings.TrimSpace(c.Query("pageSize")); pageSizeParam != "" {
		parsedPageSize, err := strconv.Atoi(pageSizeParam)
		if err != nil || parsedPageSize <= 0 {
			handler.Error(c, stacktrace.Propagate(
				ente.NewBadRequestWithMessage("invalid pageSize query param, expected positive integer"),
				"",
			))
			return
		}
		pageSize = parsedPageSize
	}

	hasUpperLimit := false
	upperLimit := 0
	if upperLimitParam := strings.TrimSpace(c.Query("upperLimit")); upperLimitParam != "" {
		parsedUpperLimit, err := strconv.Atoi(upperLimitParam)
		if err != nil || parsedUpperLimit <= 0 {
			handler.Error(c, stacktrace.Propagate(
				ente.NewBadRequestWithMessage("invalid upperLimit query param, expected positive integer"),
				"",
			))
			return
		}
		hasUpperLimit = true
		upperLimit = parsedUpperLimit
	}

	logMissingEmails := false
	if logMissingEmailsParam := strings.TrimSpace(c.Query("logMissingEmails")); logMissingEmailsParam != "" {
		parsed, err := strconv.ParseBool(logMissingEmailsParam)
		if err != nil {
			handler.Error(c, stacktrace.Propagate(
				ente.NewBadRequestWithMessage("invalid logMissingEmails query param, expected boolean"),
				"",
			))
			return
		}
		logMissingEmails = parsed
	}

	upperLimitLogValue := interface{}("none")
	if hasUpperLimit {
		upperLimitLogValue = upperLimit
	}
	upperLimitResponseValue := interface{}(nil)
	if hasUpperLimit {
		upperLimitResponseValue = upperLimit
	}

	adminID := auth.GetUserID(c.Request.Header)
	reqID := requestid.Get(c)
	logger := logrus.WithFields(logrus.Fields{
		"admin_id":      adminID,
		"req_id":        reqID,
		"req_ctx":       "listmonk_missing_subscribers_count",
		"page_size":     pageSize,
		"upper_limit":   upperLimitLogValue,
		"log_missing":   logMissingEmails,
		"listmonk_user": username,
	})

	if baseURL == "" || username == "" || password == "" || len(listIDs) == 0 {
		logger.Warn("listmonk missing-subscribers count requested without required listmonk config")
		handler.Error(c, stacktrace.Propagate(
			ente.NewBadRequestWithMessage("listmonk is not configured (server-url, username, password, list-ids are required)"),
			"",
		))
		return
	}

	if !listminkMissingSubscribersInFlight.CompareAndSwap(false, true) {
		logger.Warn("listmonk missing-subscribers job already in progress on this host")
		c.JSON(http.StatusConflict, gin.H{
			"error": "listmonk missing-subscribers processing is already in progress on this host",
		})
		return
	}

	targetListSet := make(map[int]struct{}, len(listIDs))
	for _, listID := range listIDs {
		targetListSet[listID] = struct{}{}
	}

	jobConfig := listminkMissingSubscribersJobConfig{
		Endpoint:         baseURL + "/api/subscribers",
		Username:         username,
		Password:         password,
		PageSize:         pageSize,
		HasUpperLimit:    hasUpperLimit,
		UpperLimit:       upperLimit,
		LogMissingEmails: logMissingEmails,
		TargetListIDSet:  targetListSet,
	}

	go h.runListminkMissingSubscribersJobAsync(logger, jobConfig)

	responsePayload := gin.H{
		"status":           "started",
		"requestID":        reqID,
		"pageSize":         pageSize,
		"upperLimit":       upperLimitResponseValue,
		"logMissingEmails": logMissingEmails,
		"acceptedAt":       time.Microseconds(),
	}
	logger.WithField("response_payload", responsePayload).Info("accepted listmonk missing-subscribers async job")
	c.JSON(http.StatusAccepted, responsePayload)
}

func (h *AdminHandler) runListminkMissingSubscribersJobAsync(logger *logrus.Entry, cfg listminkMissingSubscribersJobConfig) {
	defer func() {
		if r := recover(); r != nil {
			logger.WithField("panic", r).Error("listmonk missing-subscribers async job panicked")
			if h.DiscordController != nil {
				h.DiscordController.Notify(fmt.Sprintf("Listmonk missing-subscribers job panicked on `%s`", h.DiscordController.HostName))
			}
		}
		listminkMissingSubscribersInFlight.Store(false)
	}()

	logger.Info("starting listmonk missing-subscribers async job")
	summary, err := h.runListminkMissingSubscribersJob(cfg, logger)
	if err != nil {
		logger.WithError(err).Error("listmonk missing-subscribers async job failed")
		if h.DiscordController != nil {
			h.DiscordController.Notify(
				fmt.Sprintf("Listmonk missing-subscribers job failed on `%s`", h.DiscordController.HostName),
			)
		}
		return
	}

	durationMs := (summary.CompletedAt - summary.StartedAt) / 1000
	logger.WithFields(logrus.Fields{
		"pages_fetched":  summary.PagesFetched,
		"fetched_count":  summary.FetchedCount,
		"scanned_count":  summary.ScannedCount,
		"matched_count":  summary.MatchedCount,
		"missing_count":  summary.MissingCount,
		"listmonk_total": summary.ListmonkTotal,
		"stop_reason":    summary.StopReason,
		"capped":         summary.Capped,
		"duration_ms":    durationMs,
	}).Info("completed listmonk missing-subscribers async job")

	if h.DiscordController != nil {
		// Summary intentionally contains no PII.
		h.DiscordController.Notify(fmt.Sprintf(
			"Listmonk missing-subscribers summary on `%s`: missing=%d, matched=%d, scanned=%d, fetched=%d, pages=%d, total=%d, capped=%t, stop_reason=%s, duration_ms=%d",
			h.DiscordController.HostName,
			summary.MissingCount,
			summary.MatchedCount,
			summary.ScannedCount,
			summary.FetchedCount,
			summary.PagesFetched,
			summary.ListmonkTotal,
			summary.Capped,
			summary.StopReason,
			durationMs,
		))
	}
}

func (h *AdminHandler) runListminkMissingSubscribersJob(cfg listminkMissingSubscribersJobConfig, logger *logrus.Entry) (listminkMissingSubscribersJobSummary, error) {
	summary := listminkMissingSubscribersJobSummary{
		StartedAt:  time.Microseconds(),
		StopReason: "exhausted_pages",
	}

	pageNumber := 1
	seenHashes := make(map[string]struct{})

	for {
		if cfg.HasUpperLimit && summary.FetchedCount >= cfg.UpperLimit {
			summary.StopReason = "upper_limit_reached"
			summary.Capped = true
			logger.WithFields(logrus.Fields{
				"fetched_count": summary.FetchedCount,
				"stop_reason":   summary.StopReason,
			}).Info("stopping listmonk scan after upper limit")
			break
		}

		page, err := listmonk.ListSubscribers(cfg.Endpoint, cfg.Username, cfg.Password, pageNumber, cfg.PageSize)
		if err != nil {
			return summary, stacktrace.Propagate(err, "failed to fetch listmonk subscribers page %d", pageNumber)
		}

		summary.PagesFetched++
		if pageNumber == 1 {
			summary.ListmonkTotal = page.Total
		}
		originalPageResultsCount := len(page.Results)
		if originalPageResultsCount == 0 {
			summary.StopReason = "empty_page"
			break
		}

		pageResults := page.Results
		if cfg.HasUpperLimit {
			remaining := cfg.UpperLimit - summary.FetchedCount
			if remaining < len(pageResults) {
				pageResults = pageResults[:remaining]
				summary.Capped = true
				summary.StopReason = "upper_limit_reached"
			}
		}
		summary.FetchedCount += len(pageResults)

		pageHashes := make([]string, 0, len(pageResults))
		pageHashToEmail := make(map[string]string, len(pageResults))
		for _, subscriber := range pageResults {
			if !subscriberInTargetLists(subscriber.ListIDs, cfg.TargetListIDSet) {
				continue
			}
			email := emailUtil.NormalizeEmail(subscriber.Email)
			if email == "" {
				continue
			}
			emailHash, err := crypto.GetHash(email, h.HashingKey)
			if err != nil {
				return summary, stacktrace.Propagate(err, "failed to hash subscriber email")
			}
			if _, exists := seenHashes[emailHash]; exists {
				continue
			}
			seenHashes[emailHash] = struct{}{}
			pageHashes = append(pageHashes, emailHash)
			pageHashToEmail[emailHash] = email
		}

		summary.ScannedCount += len(pageHashes)
		matchedHashes, err := h.UserRepo.GetActiveUserEmailHashes(pageHashes)
		if err != nil {
			return summary, stacktrace.Propagate(err, "failed to count matched users")
		}
		pageMatchedCount := len(matchedHashes)
		summary.MatchedCount += pageMatchedCount
		matchedHashSet := make(map[string]struct{}, len(matchedHashes))
		for _, hash := range matchedHashes {
			matchedHashSet[hash] = struct{}{}
		}

		pageMissingCount := len(pageHashes) - pageMatchedCount
		if cfg.LogMissingEmails && pageMissingCount > 0 {
			missingEmailSamples := make([]string, 0, listmonkMissingSubscribersMaxLoggedEmails)
			for _, hash := range pageHashes {
				if _, exists := matchedHashSet[hash]; exists {
					continue
				}
				missingEmailSamples = append(missingEmailSamples, pageHashToEmail[hash])
				if len(missingEmailSamples) >= listmonkMissingSubscribersMaxLoggedEmails {
					break
				}
			}
			logger.WithFields(logrus.Fields{
				"page":                 pageNumber,
				"page_missing_count":   pageMissingCount,
				"missing_email_sample": missingEmailSamples,
				"sample_count":         len(missingEmailSamples),
			}).Info("missing emails sample for listmonk page")
		}

		logger.WithFields(logrus.Fields{
			"page":               pageNumber,
			"page_results":       originalPageResultsCount,
			"processed_results":  len(pageResults),
			"page_unique_hashes": len(pageHashes),
			"page_matched":       pageMatchedCount,
			"page_missing":       pageMissingCount,
			"fetched_count":      summary.FetchedCount,
			"scanned_count":      summary.ScannedCount,
			"matched_count":      summary.MatchedCount,
		}).Info("processed listmonk subscribers page")

		if summary.StopReason == "upper_limit_reached" {
			logger.WithFields(logrus.Fields{
				"fetched_count": summary.FetchedCount,
				"stop_reason":   summary.StopReason,
			}).Info("stopping listmonk scan after upper limit")
			break
		}

		effectivePerPage := cfg.PageSize
		if page.PerPage > 0 {
			effectivePerPage = page.PerPage
		}
		if originalPageResultsCount < effectivePerPage {
			summary.StopReason = "last_partial_page"
			break
		}
		pageNumber++
	}

	summary.CompletedAt = time.Microseconds()
	summary.MissingCount = summary.ScannedCount - summary.MatchedCount
	logger.WithField("missing_count", summary.MissingCount).Info("final missing subscribers count for async job")
	return summary, nil
}

func subscriberInTargetLists(subscriberListIDs []int, targetListSet map[int]struct{}) bool {
	for _, subscriberListID := range subscriberListIDs {
		if _, ok := targetListSet[subscriberListID]; ok {
			return true
		}
	}
	return false
}

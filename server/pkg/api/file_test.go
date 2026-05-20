package api

import (
	"net/http"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestFusedLookupV2FileRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	handler := &FileHandler{}
	router := gin.New()
	router.GET("/files/download/:fileID", handler.Get)
	router.GET("/files/download/v2/:fileID", handler.GetUsingFusedLookup)
	router.GET("/files/preview/:fileID", handler.GetThumbnail)
	router.GET("/files/preview/v2/:fileID", handler.GetThumbnailUsingFusedLookup)

	routes := router.Routes()
	assertRouteUsesHandler(t, routes, "/files/download/v2/:fileID", "GetUsingFusedLookup")
	assertRouteUsesHandler(t, routes, "/files/preview/v2/:fileID", "GetThumbnailUsingFusedLookup")
}

func assertRouteUsesHandler(t *testing.T, routes gin.RoutesInfo, path string, handlerName string) {
	t.Helper()

	for _, route := range routes {
		if route.Method == http.MethodGet && route.Path == path {
			if !strings.Contains(route.Handler, handlerName) {
				t.Fatalf("route %s uses handler %q, want %q", path, route.Handler, handlerName)
			}
			return
		}
	}
	t.Fatalf("route %s was not registered", path)
}

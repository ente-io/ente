package api

import "fmt"

type App string

const (
	AppPhotos App = "photos"
	AppAuth   App = "auth"
	AppLocker App = "locker"
)

func StringToApp(s string) App {
	switch s {
	case "photos":
		return AppPhotos
	case "auth":
		return AppAuth
	case "locker":
		return AppLocker
	default:
		panic(fmt.Sprintf("invalid app: %s", s))
	}
}
func (a App) ClientPkg() string {
	switch a {
	case AppPhotos:
		return "io.ente.photos"
	case AppAuth:
		return "io.ente.auth"
	case AppLocker:
		return "io.ente.locker"
	}
	return ""
}

package auth

import (
	"encoding/json"
	"errors"
	"net/http"
)

func getUserInfoFromHeaders(r *http.Request) (error, string, string) {
	userId := r.Header.Get("x-user-id")
	userEmail := r.Header.Get("x-user-email")

	if userId == "" || userEmail == "" {
		return errors.New("Unauthenticated"), "", ""
	}
	return nil, userId, userEmail
}

func UserInfo(w http.ResponseWriter, r *http.Request) {
	authErr, userId, userEmail := getUserInfoFromHeaders(r)
	if authErr != nil {
		http.Error(w, authErr.Error(), http.StatusUnauthorized)
		return
	} else {
		response, err := json.Marshal(map[string]string{
			"id":    userId,
			"email": userEmail,
		})
		if err == nil {
			w.Header().Set("Content-Type", "application/json")
			w.Write(response)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	}

}

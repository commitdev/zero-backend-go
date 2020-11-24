package auth

import (
	"encoding/json"
	"errors"
	"net/http"
)

type UserInfo struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

func GetUserInfoFromHeaders(r *http.Request) (error, UserInfo) {
	userId := r.Header.Get("x-user-id")
	userEmail := r.Header.Get("x-user-email")

	if userId == "" || userEmail == "" {
		return errors.New("Unauthenticated"), UserInfo{}
	}
	return nil, UserInfo{userId, userEmail}
}

func GetUserInfo(w http.ResponseWriter, r *http.Request) {
	authErr, userInfo := GetUserInfoFromHeaders(r)
	if authErr != nil {
		http.Error(w, authErr.Error(), http.StatusUnauthorized)
		return
	} else {
		response, err := json.Marshal(userInfo)
		if err == nil {
			w.Header().Set("Content-Type", "application/json")
			w.Write(response)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	}

}

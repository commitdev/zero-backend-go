package file

import (
	"context"
	"encoding/json"
	"fmt"
	"html"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"<% .Files.Repository %>/storagecloud"
)

type FileUrl struct {
	Url    string `json:"url"`
	Method string `json:"method"`
}


/**
The path variable :key doesn't allow the value is a path which includes '/' so that
we change :key from path variable to a query string 
*/
func PresignedUploadURL(w http.ResponseWriter, r *http.Request) {
	var fileUrl FileUrl
	var bucket string

	var key = r.URL.Query().Get("key")

	if len(r.URL.Query().Get("bucket")) > 0 {
		bucket = r.URL.Query().Get("bucket")
	} else {
		bucket = os.Getenv("AWS_S3_DEFAULT_BUCKET")
	}

	urlStr, err := storagecloud.GetPresignedUploadURL(bucket, key)
	fileUrl.Url = urlStr
	fileUrl.Method = "PUT"
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fileUrlJson, err := json.Marshal(fileUrl)
	if err != nil {
		panic(err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(fileUrlJson)
}

func PresignedDownloadURL(w http.ResponseWriter, r *http.Request) {
	var fileUrl FileUrl
	var bucket string

	var key = r.URL.Query().Get("key")

	if len(r.URL.Query().Get("bucket")) > 0 {
		bucket = r.URL.Query().Get("bucket")
	} else {
		bucket = os.Getenv("AWS_S3_DEFAULT_BUCKET")
	}

	urlStr, err := storagecloud.GetPresignedDownloadURL(bucket, key)
	fileUrl.Url = urlStr
	fileUrl.Method = "GET"
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fileUrlJson, err := json.Marshal(fileUrl)
	if err != nil {
		panic(err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(fileUrlJson)
}
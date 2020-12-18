package main

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

	"<% .Files.Repository %>/file"
	"<% .Files.Repository %>/database"
<%if eq (index .Params `userAuth`) "yes" %>	"<% .Files.Repository %>/internal/auth"
<% end %>)

const gracefulShutdownTimeout = 10 * time.Second

func main() {
	go heartbeat()

	// start database connection and run a query
	db := database.Connect()
	db.TestConnection()

	r := http.NewServeMux()
	r.HandleFunc("/status/ready", readinessCheckEndpoint)

	// Something for the example frontend to hit
	r.HandleFunc("/status/about", func(w http.ResponseWriter, r *http.Request) {
		response, err := json.Marshal(map[string]string{"podName": os.Getenv("POD_NAME")})
		if err == nil {
			w.Header().Set("Content-Type", "application/json")
			w.Write(response)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})

<%if eq (index .Params `userAuth`) "yes" %>	r.HandleFunc("/auth/userInfo", auth.GetUserInfo)

<% end %>	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
		log.Printf("Hello, %q", html.EscapeString(r.URL.Path))
	})


	r.HandleFunc("/file/presigned", getPresignedUploadURL)
	r.HandleFunc("/file", getPresignedDownloadURL)


	serverAddress := fmt.Sprintf("0.0.0.0:%s", os.Getenv("SERVER_PORT"))
	server := &http.Server{Addr: serverAddress, Handler: r}

	// Watch for signals to handle graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	// Run the server in a goroutine
	go func() {
		log.Printf("Serving at http://%s/", serverAddress)
		err := server.ListenAndServe()
		if err != http.ErrServerClosed {
			log.Fatalf("Fatal error while serving HTTP: %v\n", err)
			close(stop)
		}
	}()

	// Block while reading from the channel until we receive a signal
	sig := <-stop
	log.Printf("Received signal %s, starting graceful shutdown", sig)

	// Give connections some time to drain
	ctx, cancel := context.WithTimeout(context.Background(), gracefulShutdownTimeout)
	defer cancel()
	err := server.Shutdown(ctx)
	if err != nil {
		log.Fatalf("Error during shutdown, client requests have been terminated: %v\n", err)
	} else {
		log.Println("Graceful shutdown complete")
	}
}

// Simple health check endpoint
func readinessCheckEndpoint(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, strconv.Quote("OK"))
}

func heartbeat() {
	for range time.Tick(4 * time.Second) {
		fh, err := os.Create("/tmp/service-alive")
		if err != nil {
			log.Println("Unable to write file for liveness check!")
		} else {
			fh.Close()
		}
	}
}

type FileUrl struct {
	Url    string `json:"url"`
	Method string `json:"method"`
}


/**
The path variable :key doesn't allow the value is a path which includes '/' so that
we change :key from path variable to a query string 
*/
func getPresignedUploadURL(w http.ResponseWriter, r *http.Request) {
	var fileUrl FileUrl
	var bucket string

	var key = r.URL.Query().Get("key")

	if len(r.URL.Query().Get("bucket")) > 0 {
		bucket = r.URL.Query().Get("bucket")
	} else {
		bucket = os.Getenv("AWS_S3_DEFAULT_BUCKET")
	}

	urlStr, err := file.GetPresignedUploadURL(bucket, key)
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

func getPresignedDownloadURL(w http.ResponseWriter, r *http.Request) {
	var fileUrl FileUrl
	var bucket string

	var key = r.URL.Query().Get("key")

	if len(r.URL.Query().Get("bucket")) > 0 {
		bucket = r.URL.Query().Get("bucket")
	} else {
		bucket = os.Getenv("AWS_S3_DEFAULT_BUCKET")
	}

	urlStr, err := file.GetPresignedDownloadURL(bucket, key)
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

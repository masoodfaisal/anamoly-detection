package main

import (
	"bytes"
	"context"
	"fmt"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/push"
	"gocv.io/x/gocv"
	"log"
	"math/rand"
	"os"
	"time"
)

func RecordClassification(img gocv.Mat, classification string) {

	publishToPrometheus(img, classification)
	//publishToS3(img)

}

func publishToS3(img gocv.Mat) {
	endpoint := os.Getenv("MINIO_SERVER")
	accessKeyID := os.Getenv("MINIO_USER")
	secretAccessKey := os.Getenv("MINIO_PASSWORD")
	useSSL := true

	// Initialize minio client object.
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		log.Fatalln(err)
	}

	file := bytes.NewBufferString("ANAMOLY")

	_, err = minioClient.PutObject(context.Background(), "image-prediction", randomString(16),
		file, int64(file.Len()),
		minio.PutObjectOptions{ContentType: "application/octet-stream"})

	//gocv.IMWrite("/tmp/dyn.jpg", img)
	//_, err = minioClient.FPutObject(context.Background(), "image-prediction", "file",
	//	"a.jpg", minio.PutObjectOptions{ContentType: "application/octet-stream"})

	if err != nil {
		println(err.Error())
	}
}

var promserver = os.Getenv("PROMETHEUS_SERVER")

var (
	person_count = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "Person",
		Help: "Total number of person detected",
	})

	background_count = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "Background",
		Help: "Total number of background detected",
	})

	midfinger_count = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "MidFinger",
		Help: "Total number of Midfinger detected",
	})
)

func publishToPrometheus(img gocv.Mat, classification string) {
	var counter prometheus.Collector

	if classification == "Person" {
		person_count.Inc()
		counter = person_count
	} else if classification == "Background" {
		background_count.Inc()
		counter = background_count
	} else if classification == "MidFinger" {
		midfinger_count.Inc()
		counter = midfinger_count
	}
	err := push.New(promserver, "pred_maint_job").
		Collector(counter).
		Grouping("pred_maint", "customers").
		Push()

	if err != nil {
		fmt.Printf(err.Error())
		fmt.Printf("Error in pushing to prometheus")
	}
}

func randomString(length int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, length)
	rand.Read(b)
	return fmt.Sprintf("%x", b)[:length]
}

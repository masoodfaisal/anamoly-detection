package main

import (
	"bytes"
	"context"
	"fmt"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"gocv.io/x/gocv"
	"log"
	"math/rand"
	"os"
	"time"
)

func PublishAnamoly(img gocv.Mat) {

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

func randomString(length int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, length)
	rand.Read(b)
	return fmt.Sprintf("%x", b)[:length]
}

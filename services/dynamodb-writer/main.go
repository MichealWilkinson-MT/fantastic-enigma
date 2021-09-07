package main

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

type dynamoDBClient interface {
	PutItem(*dynamodb.PutItemInput) (*dynamodb.PutItemOutput, error)
}

type Handler struct {
	db dynamoDBClient
	tableName string
}

func (h *Handler) Run(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		messageString := message.Body
		hashString := h.hashInput(messageString)
		h.putHashInDatabase(messageString, hashString)
	}
	return nil
}

func (h *Handler) hashInput(input string) string {
	hash := sha1.New()
	hash.Write([]byte(input))
	byteSlice := hash.Sum(nil)
	hashString := hex.EncodeToString(byteSlice)
	return hashString
}

func (h *Handler) putHashInDatabase(messageString, hashedResult string) error {
	input := &dynamodb.PutItemInput {
		TableName: aws.String(h.tableName),
		Item: map[string]*dynamodb.AttributeValue {
			"InputString" : {
				S: aws.String(messageString),
			},
			"Sha" : {
				S: aws.String(hashedResult),
			},
		},
	}

	_, err := h.db.PutItem(input)
	if err != nil {
		fmt.Printf("ERROR: %s\n" , err)
	}
	return err
}

func NewHandler(dbClient dynamoDBClient, tableName string) *Handler {
	return &Handler{
		db: dbClient,
		tableName: tableName,
	}
}

func main() {
	region := os.Getenv("DATABASE_REGION")
	tableName := os.Getenv("DYNAMODB_TABLE_NAME") 
	session, _ := session.NewSession()
	db := dynamodb.New(session, aws.NewConfig().WithRegion(region))
	handler := NewHandler(db, tableName)
	lambda.Start(handler.Run)
}

package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var databaseRegion string = os.Getenv("DATABASE_REGION")
var dynamodbTableName string = os.Getenv("DYNAMODB_TABLE_NAME")
var db = dynamodb.New(session.New(), aws.NewConfig().WithRegion(databaseRegion))

func handleRequest(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	input := event.QueryStringParameters["string"]
	output, _ := retrieveHashFromDatabase(input)
	return events.APIGatewayV2HTTPResponse{StatusCode: 200, Body: output}, nil
}

func retrieveHashFromDatabase(query string) (hash string, err error) {
	fmt.Printf("Retrieving %s from store", query)
	input := &dynamodb.GetItemInput{
		TableName: aws.String(dynamodbTableName),
		Key: map[string]*dynamodb.AttributeValue{
			"InputString": {
				S: aws.String(query),
			},
		},
	}

	itemOutput, err := db.GetItem(input)
	if err != nil {
		fmt.Printf("ERROR: %s\n", err)
	} else {
		fmt.Printf("output = %v", itemOutput.Item)
		hash = itemOutput.Item["Sha"].String()
	}
	return
}

func main() {
	lambda.Start(handleRequest)
}

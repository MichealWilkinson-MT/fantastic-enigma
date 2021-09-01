package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	input := event.Body
	fmt.Println(input)
	return events.APIGatewayV2HTTPResponse{StatusCode: 200, Body: input}, nil
}

func main() {
	lambda.Start(handleRequest)
}

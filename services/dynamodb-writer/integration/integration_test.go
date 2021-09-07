//go:build !integration
// +build !integration

package integration

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/stretchr/testify/assert"
)

func testInput (test *testing.T) {
	test.Run("Trigging lambda puts hash in db", func (test *testing.T) {
		sess := session.Must(session.NewSessionWithOptions(session.Options{
			SharedConfigState: session.SharedConfigEnable,
		}))
		
		client := lambda.New(sess, &aws.Config{Region: aws.String("eu-west-2")})

		request := events.SQSEvent{
			Records: []events.SQSMessage{
				{
					Body: "Rishi is the best!",
				},
			},
		}

		payload, _ := json.Marshal(request)

		// Need to figure out how to mutate based on "Stage"
		result, err := client.Invoke(&lambda.InvokeInput{FunctionName: aws.String("fantastic-enigma-it-123-dynamodb-writer"), Payload: payload})

		if err != nil {
			fmt.Println("Its all gone wrong")
			os.Exit(1)
		}
	})
}
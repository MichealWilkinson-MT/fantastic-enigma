package main

import (
	"testing"

	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestHashInput(test *testing.T) {

	test.Run("Returns a hashed string", func (test *testing.T) {
		
		expected := "2582c03f8bbd94611a6d24df12b9ab218a2a3db9"
		actual := hashInput("Rishi is cool")

		assert.Equal(test, expected, actual)	
		
	})

}

type MockDyamodb struct {
	mock.Mock
}

func (db *MockDyamodb) PutItem(dynamodb.PutItemInput) (dynamodb.PutItemResponse, error) {
	return nil, nil
}

func TestPutHashDatabase(test *testing.T) {

	test.Run("Given a valid string dynamo-db does not throw an error", func(test *testing.T) {
		db = new(MockDyamodb)

	})

}
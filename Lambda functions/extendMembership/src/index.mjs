import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  // Parse the request body
  const body = JSON.parse(event.body);

  // Extract email and expires fields
  const { email, expires } = body;

  // Validate required fields
  if (!email || !expires) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: "Missing required fields: 'email' and 'expires'",
        statusCode: 400
      }),
    };
  }

  // Prepare the update expression to set membershipStatus to 'Active' and update the expiration date
  const updateExpression = "set #ms = :ms, #exp = :exp";
  const expressionAttributeNames = {
    "#ms": "membershipStatus",
    "#exp": "expires",
  };
  const expressionAttributeValues = {
    ":ms": "Active",
    ":exp": expires,
  };

  // DynamoDB update parameters
  const params = {
    TableName: "Users",  // Your DynamoDB table name
    Key: { email },
    UpdateExpression: updateExpression,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: "UPDATED_NEW",
  };

  try {
    // Send the update command to DynamoDB
    const data = await dynamoDb.send(new UpdateCommand(params));
    
    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Membership updated successfully",
        data,
        statusCode: 200
      }),
    };
  } catch (error) {
    // Return error response
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Error updating membership: " + error.message,
        statusCode: 500
      }),
    };
  }
};

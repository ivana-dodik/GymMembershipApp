import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  const body = JSON.parse(event.body);

  const { email, firstName, lastName, dob } = body;
  if (!email || !firstName || !lastName || !dob) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: "Missing required fields",
        statusCode: 400
      }),
    };
  }

  // Prepare the update expression
  const updateExpression = "set #fn = :fn, #ln = :ln, #dob = :dob";
  const expressionAttributeNames = {
    "#fn": "firstName",
    "#ln": "lastName",
    "#dob": "dob",
  };
  const expressionAttributeValues = {
    ":fn": firstName,
    ":ln": lastName,
    ":dob": dob,
  };

  // Update the user in DynamoDB
  const params = {
    TableName: "Users",
    Key: { email },
    UpdateExpression: updateExpression,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: "UPDATED_NEW",
  };

  try {
    const data = await dynamoDb.send(new UpdateCommand(params));
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "User profile updated successfully",
        data,
        statusCode: 200
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Error updating user: " + error.message,
        statusCode: 500
      }),
    };
  }
};

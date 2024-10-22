import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  try {
    console.log("Event:", JSON.stringify(event));

    // Get all users with role 'user'
    const params = {
      TableName: 'Users',
      FilterExpression: '#role = :roleValue',
      ExpressionAttributeNames: { '#role': 'role' },
      ExpressionAttributeValues: { ':roleValue': 'user' },
    };

    console.log("Params:", JSON.stringify(params));

    const result = await dynamoDb.send(new ScanCommand(params));

    console.log("Result:", JSON.stringify(result));

    if (!result.Items) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'No users found', statusCode: 404 }),
      };
    }

    const members = result.Items.map(item => ({
      email: item.email,
      firstName: item.firstName,
      lastName: item.lastName,
      membershipStatus: item.membershipStatus,
      expires: item.expires,
      dob: item.dob,
      role: item.role,
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Members data fetched successfully.',
        members,
        statusCode: 200,
      }),
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error', statusCode: 500 }),
    };
  }
};

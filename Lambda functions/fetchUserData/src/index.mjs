import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

const getStartOfDay = (dateString) => {
  const date = new Date(dateString);
  date.setHours(0, 0, 0, 0); // Set to start of the day
  return date;
};

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { email } = body;

    // Validate input
    if (!email) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Email is required', statusCode: 400 }),
      };
    }

    // Get user from DynamoDB
    const params = {
      TableName: 'Users',
      Key: { email },
    };

    const result = await dynamoDb.send(new GetCommand(params));

    if (!result.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'User not found', statusCode: 404 }),
      };
    }

    const user = result.Item;
    const today = getStartOfDay(new Date().toISOString().split('T')[0]);
    const expiresDate = getStartOfDay(user.expires);

    let membershipStatus = user.membershipStatus;

    // Update membership status if expired
    if (expiresDate < today) {
      membershipStatus = 'Expired';
      await dynamoDb.send(new UpdateCommand({
        TableName: 'Users',
        Key: { email },
        UpdateExpression: 'SET membershipStatus = :status',
        ExpressionAttributeValues: {
          ':status': membershipStatus,
        },
      }));
    }

    const response = {
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      membershipStatus,
      expires: user.expires,
      dob: user.dob,
      role: user.role
    };

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User data fetched successfully.',
        userData: response,
        statusCode: 200
      }),
    };

  } catch (error) {
    console.error('Error fetching user data:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal server error', statusCode: 500 }),
    };
  }
};

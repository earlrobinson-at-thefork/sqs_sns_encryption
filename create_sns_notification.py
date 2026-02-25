import boto3
import os
import time

# Replace with your queue URL
TOPIC_ARN = os.environ["TOPIC_ARN"]

# Create SQS client
sns = boto3.client("sns")

for i in range(1, 31):
    message_body = {
        "sequence_number": i,
        "message": f"This is message number {i}"
    }

    response = sns.publish(
        TopicArn=TOPIC_ARN,
        Message=str(message_body)
    )

    print(f"Sent message {i} | MessageId: {response['MessageId']}")

    # Wait 1 second before sending next message
    time.sleep(1)

print("Finished sending 30 messages.")

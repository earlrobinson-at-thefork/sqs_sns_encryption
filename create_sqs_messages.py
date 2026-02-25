import boto3
import os
import time

# Replace with your queue URL
QUEUE_URL = os.environ["SQS_URL"]

# Create SQS client
sqs = boto3.client("sqs")

for i in range(1, 61):
    message_body = {
        "sequence_number": i,
        "message": f"This is message number {i}"
    }

    response = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=str(message_body)
    )

    print(f"Sent message {i} | MessageId: {response['MessageId']}")

    # Wait 1 second before sending next message
    time.sleep(1)

print("Finished sending 30 messages.")

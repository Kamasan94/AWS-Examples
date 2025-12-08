import boto3
import time

sqs = boto3.client('sqs')
queue_url = 'https://sqs.us-east-1.amazonaws.com/137263334750/job-queue'

# Invia 1000 messaggi
for i in range(1000):
    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=f'Messaggio di test {i}'
    )
    print(f"Inviato messaggio {i}")

print("Stress test completato.")   
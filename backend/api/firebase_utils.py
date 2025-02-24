# firebase_utils.py
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import json
import os


class FirebaseManager:
    def __init__(self):
        try:
            if not firebase_admin._apps:
                cred_path = settings.FIREBASE_SERVICE_ACCOUNT_KEY
                print(f"Loading Firebase credentials from: {cred_path}")

                if not os.path.exists(cred_path):
                    raise FileNotFoundError(
                        f"Firebase credentials file not found at {cred_path}")

                # Load credentials and verify project details
                with open(cred_path, 'r') as f:
                    cred_json = json.load(f)
                    print(
                        f"Initializing Firebase for project: {cred_json.get('project_id')}")
                    print(
                        f"Using service account: {cred_json.get('client_email')}")

                cred = credentials.Certificate(cred_path)
                self.app = firebase_admin.initialize_app(cred, {
                    'project_id': cred_json['project_id']
                })
                print(
                    f"Firebase Admin SDK initialized successfully for project: {self.app.project_id}")
            else:
                self.app = firebase_admin.get_app()
                print(f"Using existing Firebase app: {self.app.project_id}")

        except Exception as e:
            print(f"Error initializing Firebase: {str(e)}")
            raise

    def send_notification(self, tokens, title, body, data=None):
        if not tokens:
            print("❌ No tokens provided for notification")
            return

        try:
            print(f"📨 Sending notification to {len(tokens)} devices")
            print(f"🎯 Firebase Project ID: {self.app.project_id}")
            print(f"📝 Notification Title: {title}")
            print(f"📩 Notification Body: {body}")
            print(f"🔹 Data Payload: {json.dumps(data, indent=2)}")

            # Ensure data is string-based
            if data:
                data = {str(k): str(v) for k, v in data.items()}

            success_count = 0
            failure_count = 0
            failed_tokens = []

            for token in tokens:
                try:
                    print(f"📩 Sending to token: {token[:20]}...")

                    message = messaging.Message(
                        notification=messaging.Notification(
                            title=title,
                            body=body
                        ),
                        data=data or {},
                        token=token
                    )

                    response = messaging.send(message, app=self.app)
                    print(f"✅ Message sent successfully. Response: {response}")
                    success_count += 1

                except Exception as e:
                    print(f"❌ Error sending to token {token[:20]}: {str(e)}")
                    failure_count += 1
                    failed_tokens.append({
                        'token': token,
                        'error': str(e)
                    })

            result = {
                'success_count': success_count,
                'failure_count': failure_count,
                'failed_tokens': failed_tokens
            }

            print(f"📊 Firebase Notification Result: {json.dumps(result, indent=2)}")
            return result

        except Exception as e:
            print(f"❌ Error in send_notification: {str(e)}")
            return {'error': str(e)}




import requests
import uuid
import json

class IAEduAPI:
    def __init__(self, api_key, endpoint, channel_id):
        self.api_key = api_key
        self.endpoint = endpoint
        self.channel_id = channel_id
        self.thread_id = str(uuid.uuid4())

    def invoke(self, prompt):
        form_data = {
            "channel_id": self.channel_id,
            "thread_id": self.thread_id,
            "user_info": "{}",
            "message": prompt,
        }
        response = requests.post(
            self.endpoint,
            headers={"x-api-key": self.api_key},
            data=form_data
        )

        if response.status_code == 429:
            print(f"DEBUG - Headers: {dict(response.headers)}")
            raise Exception("Rate limit atingido (429). Aguarda alguns segundos e tenta novamente.", dict(response.headers))

        response.raise_for_status()

        content = ""
        token_parts = []
        final_message_content = None
        stream_error = None

        for line in response.text.strip().split("\n"):
            line = line.strip()
            if not line:
                continue


            if line.startswith("data:"):
                line = line[5:].strip()

            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type")
            if msg_type == "text":
                content += data.get("content", "")
            elif msg_type == "token":
                token_parts.append(data.get("content", ""))
            elif msg_type == "message":
                message_payload = data.get("content")
                if isinstance(message_payload, dict):
                    final_message_content = message_payload.get("content")
                elif isinstance(message_payload, str):
                    final_message_content = message_payload
            elif msg_type == "error":
                stream_error = data.get("content") or "Erro desconhecido no stream."

        if stream_error:
            raise Exception(stream_error)

        if final_message_content:
            content = final_message_content
        elif token_parts:
            content = "".join(token_parts)
        elif not content:
            content = response.text

        class Result:
            def __init__(self, content):
                self.content = content

        return Result(content)
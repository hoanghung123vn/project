import base64
import requests
import json
import sys
# import time

headers = {
    "x-origin": "https://explorer.apis.google.com",
    "content-type": "application/json",
    "Content-Type": "text/plain",
}

params = (("key", "AIzaSyAa8yy0GdcGPHdtD083HiGGx_S0vMPScDM"),("alt", "json"))

speakers = ["vi-VN-Wavenet-A", "vi-VN-Wavenet-B", "vi-VN-Wavenet-C", "vi-VN-Wavenet-D"]
savespeakers = ["XHUSTSPK01", "XHUSTSPK02", "XHUSTSPK03", "XHUSTSPK04"]

file = open("train.txt", mode="r", encoding="utf-8")
lines = file.readlines()

loop = int(sys.argv[1])

for i in range(943, 250 * loop):
    data_request = {
        "input": {
            "text": lines[i].rstrip()
        },
        "voice": {
            "languageCode": "vi-VN",
            "name": speakers[loop - 1]
        },
        "audioConfig": {
            "audioEncoding": "LINEAR16",
            "pitch": 1,
            "speakingRate": 1,
            "sampleRateHertz": 16000
        }
    }
    response = requests.post("https://texttospeech.googleapis.com/v1/text:synthesize", headers=headers, params=params, json=data_request)
    data = json.loads(response.text)
    base64_message = data["audioContent"]
    base64_bytes = base64_message.encode("ascii")
    audio_bytes = base64.b64decode(base64_bytes)

    filename = None
    if i < 9:
        filename = f"data/{savespeakers[loop - 1]}/{savespeakers[loop - 1]}_R00{i + 1}.wav"
    elif i < 99:
        filename = f"data/{savespeakers[loop - 1]}/{savespeakers[loop - 1]}_R0{i + 1}.wav"
    else:
        filename = f"data/{savespeakers[loop - 1]}/{savespeakers[loop - 1]}_R{i + 1}.wav"

    with open(filename, "wb") as file_to_save:
        file_to_save.write(audio_bytes)

    if (i + 1) % 25 == 0:
        print(f"done part:{(i + 1) / 25}")
        # time.sleep(5 * 60)

import json
import base64
import requests
from io import BytesIO

# 1. Configuration
IMAGE_URL = "https://cloud.rishabhroy.com/misc/repl.jpg?k=fM7t4g5g"
OUTPUT_FILENAME = "repl.jpg"

# 2. Download and Convert to Base64
print(f"Fetching image from {IMAGE_URL}...")
response = requests.get(IMAGE_URL)
if response.status_code == 200:
    # Encode the binary content to base64 string
    base64_image = base64.b64encode(response.content).decode('utf-8')
    print("Successfully encoded image to base64.")
else:
    print(f"Failed to download image. Status code: {response.status_code}")
    exit()

# 3. Load your actual workflow
with open('seethrough-api.json', 'r') as f:
    workflow = json.load(f)

# Ensure Node 27 is looking for the filename we'll give it
if "27" in workflow:
    workflow["27"]["inputs"]["image"] = OUTPUT_FILENAME

# 4. Construct the RunPod Test Input
# When the 'image' key starts with a base64 string, the handler decodes it.
test_input = {
    "input": {
        "workflow": workflow,
        "images": [
            {
                "name": OUTPUT_FILENAME,
                "image": base64_image
            }
        ]
    }
}

# 5. Save the test file
with open('test_input.json', 'w') as f:
    json.dump(test_input, f, indent=4)

print(f"Built test_input.json with base64 data. Ready for 'docker run'.")
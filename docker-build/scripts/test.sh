sudo docker run --runtime=nvidia --gpus all --rm \
  -v "$(pwd)/test_input.json:/test_input.json" \
  -v "$(pwd)/output:/comfyui/output" \
  seethrough-test
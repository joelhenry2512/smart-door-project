#!/bin/bash
# Start Video Stream to Kinesis Video Streams
# Usage: ./start-video-stream.sh [rtsp_url]

set -e

REGION=${AWS_REGION:-us-east-1}
STREAM_NAME=${KVS_STREAM_NAME:-smartdoor-video-stream-dev}
RTSP_URL=${1:-"rtsp://localhost:8554/stream"}

echo "=========================================="
echo "Smart Door - Video Streaming Setup"
echo "=========================================="
echo ""
echo "Stream Name: $STREAM_NAME"
echo "Region: $REGION"
echo "RTSP URL: $RTSP_URL"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required but not installed."
    echo ""
    echo "Install Docker and try again, or use the manual GStreamer method below."
    exit 1
fi

# Method 1: Using Docker with KVS Producer SDK
echo "=========================================="
echo "Method 1: Docker-based streaming"
echo "=========================================="
echo ""

# Pull the KVS producer Docker image
echo "Pulling KVS Producer Docker image..."
docker pull amazon/kinesis-video-streams-producer-sdk-cpp-amazon-linux 2>/dev/null || true

# Get AWS credentials
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$(aws configure get aws_access_key_id)}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$(aws configure get aws_secret_access_key)}

echo ""
echo "Starting video stream..."
echo "Press Ctrl+C to stop"
echo ""

# Start the producer
docker run --rm -it \
    --network host \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$REGION" \
    amazon/kinesis-video-streams-producer-sdk-cpp-amazon-linux \
    /opt/amazon-kinesis-video-streams-producer-sdk-cpp/build/kvs_gstreamer_sample \
    "$STREAM_NAME" \
    "$RTSP_URL"

# Alternative: If the above doesn't work, try this command format
# docker run --rm -it \
#     --network host \
#     -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
#     -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
#     -e AWS_DEFAULT_REGION="$REGION" \
#     amazon/kinesis-video-streams-producer-sdk-cpp-amazon-linux \
#     gst-launch-1.0 rtspsrc location="$RTSP_URL" short-header=TRUE ! \
#     rtph264depay ! video/x-h264,format=avc,alignment=au ! \
#     kvssink stream-name="$STREAM_NAME" storage-size=512

echo ""
echo "Stream stopped."

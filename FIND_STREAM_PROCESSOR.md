# How to Find Stream Processor in AWS Console

## ✅ Stream Processor Created

Your stream processor **does exist** and is running:
- **Name:** `smartdoor-face-processor-dev`
- **Status:** RUNNING
- **Region:** us-east-1 (N. Virginia)

## 🔍 How to Find It in AWS Console

### Method 1: Direct Link

Go directly to Rekognition Stream Processors:
**https://console.aws.amazon.com/rekognition/home?region=us-east-1#/stream-processors**

### Method 2: Step-by-Step Navigation

1. **Go to AWS Console:**
   - https://console.aws.amazon.com/

2. **Navigate to Rekognition:**
   - Click "Services" at the top
   - Search for "Rekognition" or type it in
   - Click "Amazon Rekognition"

3. **Open Stream Processors:**
   - In the left sidebar, look for "Stream processors"
   - Click on "Stream processors"
   - Make sure you're in the **us-east-1 (N. Virginia)** region (check the region selector at the top right)

4. **Find Your Processor:**
   - You should see: `smartdoor-face-processor-dev`
   - Status should show: **RUNNING**

### Method 3: Verify via AWS CLI

Run this command to verify it exists:

```bash
aws rekognition list-stream-processors --region us-east-1
```

You should see:
```json
{
    "StreamProcessors": [
        {
            "Name": "smartdoor-face-processor-dev",
            "Status": "RUNNING"
        }
    ]
}
```

## ⚠️ If You Still Can't See It

### Check the Region

**IMPORTANT:** Make sure you're viewing the **us-east-1 (N. Virginia)** region in the console!

1. Look at the top-right corner of the AWS Console
2. Click the region selector
3. Select **US East (N. Virginia) us-east-1**

The stream processor is region-specific, so if you're in a different region, you won't see it.

### Check Permissions

Make sure your user has permissions to view Rekognition resources:
- `rekognition:ListStreamProcessors`
- `rekognition:DescribeStreamProcessor`

### Refresh the Page

Sometimes the console needs a refresh:
- Press `Ctrl+F5` (or `Cmd+Shift+R` on Mac) to hard refresh
- Or log out and log back in

## 📊 Stream Processor Details

**Name:** `smartdoor-face-processor-dev`

**Input:**
- Type: Kinesis Video Stream
- Stream: `smartdoor-video-stream-dev`

**Output:**
- Type: Kinesis Data Stream
- Stream: `smartdoor-face-events-dev`

**Settings:**
- Collection: `smartdoor-faces-dev`
- Face Match Threshold: 80%

**Status:** RUNNING

**ARN:**
```
arn:aws:rekognition:us-east-1:437794636369:streamprocessor/smartdoor-face-processor-dev
```

## 🔗 Quick Links

- **Stream Processors Page:** https://console.aws.amazon.com/rekognition/home?region=us-east-1#/stream-processors
- **Rekognition Console:** https://console.aws.amazon.com/rekognition/home?region=us-east-1

---

**The stream processor definitely exists!** Make sure you're in the **us-east-1** region and refresh the page if needed.


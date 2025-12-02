# Quick Testing Guide

## ✅ System Status: Ready for Testing

All components deployed and API verified working!

---

## 🚀 Quick Tests (5 minutes)

### Test 1: OTP Validation (Already Working! ✓)

**Test OTP:** `123456` (valid for 5 minutes)

**Option A: Via Web Page**
1. Open: http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp2/index.html
2. Enter OTP: `123456`
3. Click "Validate OTP"
4. Expected: "Access granted!" message

**Option B: Via API**
```bash
curl -X POST https://1elw5cppd8.execute-api.us-east-1.amazonaws.com/dev/validate \
  -H "Content-Type: application/json" \
  -d '{"otp":"123456"}'
```

### Test 2: Create New Test OTP

```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"
./scripts/create-test-otp.sh 999999 "New Test User"
```

Then test with the new OTP.

### Test 3: Web Pages

**WP1 - Owner Approval:**
- http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp1/index.html

**WP2 - Virtual Door:**
- http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp2/index.html

---

## 🔧 Helper Scripts

### Create Test OTP
```bash
./scripts/create-test-otp.sh [otp] [name]
```

Examples:
```bash
# Random OTP
./scripts/create-test-otp.sh

# Specific OTP
./scripts/create-test-otp.sh 888888 "John Doe"
```

### Create Test Visitor (with photo)
```bash
./scripts/create-test-visitor.sh photo.jpg "John Doe" "+19472464522"
```

---

## ✅ Testing Checklist

- [x] API Gateway working
- [x] OTP validation working
- [ ] WP2 page tested
- [ ] WP1 page tested
- [ ] SNS subscription confirmed
- [ ] Test face added to Rekognition
- [ ] Visitor registration tested

---

## 📚 Complete Testing Guide

For detailed testing procedures, see: **TESTING_GUIDE.md**

---

**Current Test OTP:** `123456` (test it now!)


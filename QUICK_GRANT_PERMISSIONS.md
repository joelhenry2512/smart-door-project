# Quick Guide: Grant Permissions via AWS Console

## 🎯 Quick Steps (5 minutes)

### 1. Open AWS Console
- Go to: **https://console.aws.amazon.com/**
- **Log in with root/admin credentials** (not pantrypal-admin)

### 2. Go to IAM
- Search for "IAM" in services
- Or go directly: **https://console.aws.amazon.com/iam/**

### 3. Open User
- Click **"Users"** in left sidebar
- Click **"pantrypal-admin"**

### 4. Add Permissions
- Click **"Add permissions"** button
- Select **"Attach policies directly"**
- Click **"Next"**

### 5. Select Policies
Search and check:
- ✅ **AWSCloudFormationFullAccess** (required)
- ✅ **PowerUserAccess** (recommended - includes everything)

### 6. Apply
- Click **"Next"**
- Click **"Add permissions"**

### 7. Done!
Wait 10 seconds, then test:
```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"
aws cloudformation list-stacks --region us-east-1
```

---

## 🚀 Then Deploy

```bash
source .deployment-config.sh
./scripts/deploy-all.sh dev
```

---

## 📸 Visual Guide

**Step 3-4:**
```
IAM Console → Users → pantrypal-admin → Add permissions
```

**Step 5:**
```
Search: "AWSCloudFormationFullAccess" → Check ✓
Search: "PowerUserAccess" → Check ✓
```

---

**That's it!** After adding permissions, you can deploy immediately.


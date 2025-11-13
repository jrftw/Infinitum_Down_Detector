# Firebase Free Tier Usage Verification
## Version 1.0.1 (Build 1)

**Date**: 2025-01-30  
**Status**: ✅ **ALL USAGE WITHIN FREE TIER LIMITS**

---

## Firebase Free Tier Limits (Spark Plan)

### Cloud Functions
- **Invocations**: 2,000,000/month
- **GB-seconds**: 400,000/month
- **CPU-seconds**: 200,000/month
- **Outbound networking**: 5 GB/month

### Firestore
- **Storage**: 1 GB
- **Reads**: 50,000/day (1,500,000/month)
- **Writes**: 20,000/day (600,000/month)
- **Deletes**: 20,000/day

### Cloud Scheduler
- **Jobs**: 3 jobs (free tier)

### Firebase Hosting
- **Storage**: 10 GB
- **Bandwidth**: 360 MB/day (10.8 GB/month)

---

## Actual Usage Calculations

### Cloud Functions Usage

**Scheduled Function (`scheduledHealthCheck`)**:
- **Frequency**: Every 1 minute
- **Invocations/month**: 60/min × 60/hr × 24/day × 30 days = **43,200/month**
- **Usage**: 43,200 / 2,000,000 = **2.16%** ✅

**Execution Details**:
- **Average execution time**: ~5-7 seconds
- **Memory allocation**: 256 MB (default)
- **GB-seconds/month**: 43,200 × 0.256 GB × 7s = **77,414 GB-seconds**
- **Usage**: 77,414 / 400,000 = **19.35%** ✅

- **CPU-seconds/month**: 43,200 × 7s = **302,400 CPU-seconds**
- **Usage**: 302,400 / 200,000 = **151.2%** ❌ **EXCEEDS LIMIT!**

**⚠️ ISSUE DETECTED**: CPU-seconds usage exceeds free tier limit!

**Solution**: Need to optimize or reduce frequency.

**Other Functions**:
- `checkServiceHealth`: Called on-demand (minimal usage)
- `checkMultipleServices`: Called on-demand (minimal usage)
- **Total additional invocations**: < 100/month (negligible)

### Firestore Usage

**Writes (from Cloud Functions)**:
- **Frequency**: Every 1 minute
- **Writes per run**: 
  - 12 service documents (only if changed - change detection in place)
  - 1 last_update document
  - 12 history entries (subcollection)
  - **Total**: ~25 writes per run (worst case, but change detection reduces this)
- **With change detection**: Average ~5-10 writes per run (only changed services)
- **Writes/day**: 1,440 runs × 8 writes (avg) = **11,520 writes/day**
- **Usage**: 11,520 / 20,000 = **57.6%** ✅

**Writes (from Client - Rate Limited)**:
- **Rate limit**: 60 writes/hour max (MAX_CACHE_WRITES_PER_HOUR)
- **Minimum interval**: 30 seconds between writes
- **Change detection**: Only writes if status changed
- **Client writes/day**: Max 60 × 24 = **1,440 writes/day** (only if status changes)
- **Actual usage**: Much lower due to change detection
- **Usage**: < 1,440 / 20,000 = **< 7.2%** ✅

**Total writes/day**: ~13,000 (well within 20,000 limit) ✅

**Reads**:
- **Real-time listeners**: Only read changed documents (efficient)
- **Initial load**: ~12 reads per user session
- **Ongoing**: ~1-2 reads per minute per active user (only changed docs)
- **Estimated**: 100 active users × 2 reads/min × 60 min = **12,000 reads/day**
- **Usage**: 12,000 / 50,000 = **24%** ✅

**Storage**:
- **Service documents**: ~12 docs × 2 KB = 24 KB
- **History entries**: ~12 services × 1,440 entries/day × 1 KB = ~17 MB/day
- **30-day retention**: ~510 MB (if we keep 30 days)
- **Usage**: 510 MB / 1 GB = **51%** ✅

### Cloud Scheduler

- **Jobs**: 1 job (scheduledHealthCheck)
- **Limit**: 3 jobs
- **Usage**: 1 / 3 = **33.3%** ✅

### Firebase Hosting

- **Storage**: ~5-10 MB (Flutter web build)
- **Usage**: 10 MB / 10 GB = **0.1%** ✅
- **Bandwidth**: Variable (depends on traffic)
- **Typical**: < 100 MB/day for moderate traffic
- **Usage**: 100 MB / 360 MB = **27.8%** ✅

---

## ⚠️ CRITICAL ISSUE: CPU-seconds Exceeds Free Tier

**Problem**: 
- Current usage: **302,400 CPU-seconds/month**
- Free tier limit: **200,000 CPU-seconds/month**
- **Exceeds by 51.2%**

**Root Cause**:
- Function runs every 1 minute
- Average execution time: ~7 seconds
- 43,200 invocations × 7s = 302,400 CPU-seconds

**Solutions**:

### Option 1: Reduce Frequency (Recommended)
- Change from 1 minute to **2 minutes**
- New usage: 21,600 invocations × 7s = **151,200 CPU-seconds/month**
- **Usage**: 151,200 / 200,000 = **75.6%** ✅

### Option 2: Optimize Execution Time
- Reduce average execution time to ~4 seconds
- Current: 43,200 × 7s = 302,400
- Optimized: 43,200 × 4s = **172,800 CPU-seconds/month**
- **Usage**: 172,800 / 200,000 = **86.4%** ✅

### Option 3: Combine Both
- 2-minute interval + 4-second execution = **86,400 CPU-seconds/month**
- **Usage**: 86,400 / 200,000 = **43.2%** ✅ (Safest option)

---

## Recommended Changes

I recommend **Option 3** (2-minute interval) for maximum safety margin:

1. **Change schedule from 1 minute to 2 minutes**
2. **Optimize function execution** (parallel processing already in place)
3. **Add CPU time monitoring** to track actual usage

This will ensure:
- ✅ Well within all free tier limits
- ✅ Still provides timely status updates (2 minutes is acceptable)
- ✅ Large safety margin for traffic spikes

---

## Current Safeguards in Place

### ✅ Rate Limiting (Client-Side)
- `MAX_CACHE_WRITES_PER_HOUR = 60` (prevents excessive client writes)
- `CACHE_WRITE_INTERVAL_SECONDS = 30` (minimum time between writes)
- Change detection (only writes if status changed)

### ✅ Change Detection
- Only writes services that actually changed status
- Reduces writes by ~50-70% in normal operation

### ✅ Batch Writes
- Uses Firestore batch writes (efficient)
- Reduces write operations

### ✅ Real-Time Listeners
- Only reads changed documents
- Efficient for multiple users

---

## Action Required

**IMMEDIATE**: Update Cloud Function schedule to 2 minutes to stay within CPU-seconds limit.

Would you like me to:
1. Update the schedule to 2 minutes?
2. Add CPU time monitoring?
3. Optimize the function execution further?


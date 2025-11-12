# Firebase Functions for Infinitum Down Detector

This directory contains Firebase Cloud Functions that handle health checks server-side to bypass CORS restrictions on web.

## Setup

1. **Install Node.js dependencies:**
```bash
cd functions
npm install
```

2. **Deploy the functions:**
```bash
npm run deploy
```

Or from the project root:
```bash
firebase deploy --only functions
```

## Functions

### `checkServiceHealth`
Checks the health of a single service. Called from the Flutter app on web to bypass CORS.

**Parameters:**
- `url` (string, required): The URL to check
- `serviceId` (string, optional): Service identifier
- `serviceName` (string, optional): Service display name

**Returns:**
- `success` (boolean): Whether the check succeeded
- `status` (string): 'operational', 'degraded', 'down', or 'unknown'
- `statusCode` (number): HTTP status code
- `responseTime` (number): Response time in milliseconds
- `errorMessage` (string, optional): Error message if any
- `hasDataFeedIssue` (boolean): Whether a data feed issue was detected (for iView)

### `checkMultipleServices`
Checks multiple services in parallel. Currently not used but available for future optimization.

## Local Development

To test functions locally:

```bash
npm run serve
```

This starts the Firebase emulator. The functions will be available at `http://localhost:5001/infinitum-down-detector/us-central1/checkServiceHealth`

## Notes

- Functions run server-side, so CORS is not an issue
- The free tier includes 2 million invocations per month
- Functions automatically scale based on demand
- Response times may be slightly higher due to function cold starts


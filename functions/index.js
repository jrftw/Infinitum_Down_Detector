// Filename: index.js
// Purpose: Firebase Cloud Functions for health check proxy
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: firebase-functions, firebase-admin, axios
// Platform Compatibility: Firebase Cloud Functions

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// MARK: - Firebase Admin Initialization
// Initialize Firebase Admin SDK
admin.initializeApp();

// MARK: - Health Check Function
// Proxies health check requests to bypass CORS restrictions
// This function runs server-side, so CORS is not an issue
exports.checkServiceHealth = functions.https.onCall(async (data, context) => {
  const {url, serviceId} = data;

  if (!url) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "URL is required",
    );
  }

  const startTime = Date.now();

  try {
    // Make the request server-side (no CORS restrictions)
    const response = await axios.get(url, {
      timeout: 10000, // 10 second timeout
      validateStatus: (status) => status < 500, // Accept status codes < 500
      maxRedirects: 5,
      headers: {
        "User-Agent": "InfinitumDownDetector/1.0",
      },
    });

    const endTime = Date.now();
    const responseTime = endTime - startTime;

    // Get response body as string for content checking
    let responseBody = "";
    let hasDataFeedIssue = false;

    try {
      responseBody = typeof response.data === "string" ?
        response.data :
        JSON.stringify(response.data);

      // Check for data feed issue specifically for iView/InfiniView
      if (serviceId === "infinitum-view") {
        const dataFeedIssueText =
          "Stats may be delayed/inaccurate due to a data feed issue.";
        const responseBodyLower = responseBody.toLowerCase();
        const searchTextLower = dataFeedIssueText.toLowerCase();
        const searchTextNoPeriod = searchTextLower.replace(/\./g, "");
        hasDataFeedIssue = responseBodyLower.includes(searchTextLower) ||
                          responseBodyLower.includes(searchTextNoPeriod);
      }
    } catch (e) {
      // If we can't parse the response body, continue with status code check
      console.warn("Could not parse response body:", e.message);
    }

    let status;
    let errorMessage = null;

    if (response.status >= 200 && response.status < 400) {
      if (hasDataFeedIssue) {
        status = "degraded";
        errorMessage = "Data feed issue detected";
      } else {
        status = "operational";
      }
    } else if (response.status >= 400 && response.status < 500) {
      status = "degraded";
      errorMessage = `HTTP ${response.status}`;
    } else {
      status = "down";
      errorMessage = `HTTP ${response.status}`;
    }

    return {
      success: true,
      status: status,
      statusCode: response.status,
      responseTime: responseTime,
      errorMessage: errorMessage,
      hasDataFeedIssue: hasDataFeedIssue,
    };
  } catch (error) {
    const endTime = Date.now();
    const responseTime = endTime - startTime;

    let status = "down";
    let errorMessage = "Unknown error";

    if (error.code === "ECONNABORTED" || error.message.includes("timeout")) {
      errorMessage = "Connection timeout";
    } else if (error.code === "ENOTFOUND" || error.code === "ECONNREFUSED") {
      errorMessage = "Connection error";
    } else if (error.response) {
      // Server responded with error status
      status = error.response.status >= 500 ? "down" : "degraded";
      errorMessage = `HTTP ${error.response.status}`;
    } else {
      errorMessage = error.message || "Unknown error";
    }

    return {
      success: false,
      status: status,
      statusCode: error.response?.status || null,
      responseTime: responseTime,
      errorMessage: errorMessage,
      hasDataFeedIssue: false,
    };
  }
});

// MARK: - Batch Health Check Function
// Checks multiple services in parallel
exports.checkMultipleServices =
  functions.https.onCall(async (data, context) => {
    const {services} = data;

    if (!Array.isArray(services) || services.length === 0) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "Services array is required",
      );
    }

    // Check all services in parallel
    const checkPromises = services.map((service) => {
      return axios.get(service.url, {
        timeout: 10000,
        validateStatus: (status) => status < 500,
        maxRedirects: 5,
        headers: {
          "User-Agent": "InfinitumDownDetector/1.0",
        },
      }).then((response) => {
        const startTime = Date.now();
        const endTime = Date.now();
        const responseTime = endTime - startTime;

        let responseBody = "";
        let hasDataFeedIssue = false;

        try {
          responseBody = typeof response.data === "string" ?
          response.data :
          JSON.stringify(response.data);

          if (service.id === "infinitum-view") {
            const dataFeedIssueText =
            "Stats may be delayed/inaccurate due to a data feed issue.";
            const responseBodyLower = responseBody.toLowerCase();
            const searchTextLower = dataFeedIssueText.toLowerCase();
            const searchTextNoPeriod = searchTextLower.replace(/\./g, "");
            hasDataFeedIssue = responseBodyLower.includes(searchTextLower) ||
                            responseBodyLower.includes(searchTextNoPeriod);
          }
        } catch (e) {
        // Ignore parsing errors
        }

        let status;
        let errorMessage = null;

        if (response.status >= 200 && response.status < 400) {
          if (hasDataFeedIssue) {
            status = "degraded";
            errorMessage = "Data feed issue detected";
          } else {
            status = "operational";
          }
        } else if (response.status >= 400 && response.status < 500) {
          status = "degraded";
          errorMessage = `HTTP ${response.status}`;
        } else {
          status = "down";
          errorMessage = `HTTP ${response.status}`;
        }

        return {
          id: service.id,
          success: true,
          status: status,
          statusCode: response.status,
          responseTime: responseTime,
          errorMessage: errorMessage,
          hasDataFeedIssue: hasDataFeedIssue,
        };
      }).catch((error) => {
        let status = "down";
        let errorMessage = "Unknown error";

        if (error.code === "ECONNABORTED" ||
            error.message.includes("timeout")) {
          errorMessage = "Connection timeout";
        } else if (error.code === "ENOTFOUND" ||
                   error.code === "ECONNREFUSED") {
          errorMessage = "Connection error";
        } else if (error.response) {
          status = error.response.status >= 500 ? "down" : "degraded";
          errorMessage = `HTTP ${error.response.status}`;
        } else {
          errorMessage = error.message || "Unknown error";
        }

        return {
          id: service.id,
          success: false,
          status: status,
          statusCode: error.response?.status || null,
          responseTime: 0,
          errorMessage: errorMessage,
          hasDataFeedIssue: false,
        };
      });
    });

    const results = await Promise.all(checkPromises);

    return {
      success: true,
      results: results,
    };
  });

// MARK: - Service Definitions
// Defines all services to monitor (matches client-side definitions)
const INFINITUM_SERVICES = [
  {
    id: "infinitum-view",
    name: "iView/InfiniView",
    url: "https://view.infinitumlive.com/",
    type: "infinitum",
  },
  {
    id: "infinitum-live",
    name: "Infinitum Live",
    url: "https://infinitumlive.com/",
    type: "infinitum",
  },
  {
    id: "infinitum-crm",
    name: "Infinitum CRM",
    url: "https://crm.infinitumlive.com/",
    type: "infinitum",
  },
  {
    id: "infinitum-onboarding",
    name: "Onboarding",
    url: "https://infinitum-onboarding.web.app/",
    type: "infinitum",
  },
  {
    id: "infinitum-board",
    name: "InfiniBoard",
    url: "https://iboard.duckdns.org/",
    type: "infinitum",
  },
  {
    id: "infinitum-board-2",
    name: "InfiniBoard 2",
    url: "https://iboard2--infinitum-dashboard.us-east4.hosted.app/",
    type: "infinitum",
  },
  {
    id: "infinitum-imagery",
    name: "Infinitum Imagery",
    url: "https://www.infinitumimagery.com/",
    type: "infinitum",
  },
];

const THIRD_PARTY_SERVICES = [
  {
    id: "firebase",
    name: "Firebase",
    url: "https://status.firebase.google.com/",
    type: "thirdParty",
  },
  {
    id: "google",
    name: "Google Services",
    url: "https://www.google.com/appsstatus/dashboard/",
    type: "thirdParty",
  },
  {
    id: "apple",
    name: "Apple Services",
    url: "https://www.apple.com/support/systemstatus/",
    type: "thirdParty",
  },
  {
    id: "discord",
    name: "Discord",
    url: "https://discordstatus.com/",
    type: "thirdParty",
  },
  {
    id: "tiktok",
    name: "TikTok",
    url: "https://www.tiktok.com/",
    type: "thirdParty",
  },
  {
    id: "aws",
    name: "AWS",
    url: "https://status.aws.amazon.com/",
    type: "thirdParty",
  },
];

// MARK: - Helper Function: Check Single Service
/**
 * Performs health check on a single service
 * @param {Object} service - Service object with id, name, url
 * @param {Object|null} previousStatus - Previous service status from Firestore
 * @return {Promise<Object>} Service status object
 */
async function checkSingleService(service, previousStatus = null) {
  const startTime = Date.now();

  try {
    const response = await axios.get(service.url, {
      timeout: 10000,
      validateStatus: (status) => status < 500,
      maxRedirects: 5,
      headers: {
        "User-Agent": "InfinitumDownDetector/1.0",
      },
    });

    const endTime = Date.now();
    const responseTime = endTime - startTime;

    // Get response body as string for content checking
    let responseBody = "";
    let hasDataFeedIssue = false;

    try {
      responseBody = typeof response.data === "string" ?
        response.data :
        JSON.stringify(response.data);

      // Check for data feed issue specifically for iView/InfiniView
      if (service.id === "infinitum-view") {
        const dataFeedIssueText =
          "Stats may be delayed/inaccurate due to a data feed issue.";
        const responseBodyLower = responseBody.toLowerCase();
        const searchTextLower = dataFeedIssueText.toLowerCase();
        const normalizedBody = responseBodyLower.replace(/\s+/g, " ");
        const normalizedSearch = searchTextLower.replace(/\s+/g, " ");
        const searchTextNoPeriod = normalizedSearch.replace(/\./g, "");

        const hasDelayedText =
          responseBodyLower.includes("stats may be delayed/inaccurate");
        const hasFeedIssueText =
          responseBodyLower.includes("data feed issue");
        hasDataFeedIssue = normalizedBody.includes(normalizedSearch) ||
                          normalizedBody.includes(searchTextNoPeriod) ||
                          (hasDelayedText && hasFeedIssueText);
      }
    } catch (e) {
      // If we can't parse the response body, continue with status code check
      console.warn(
          `Could not parse response body for ${service.id}:`,
          e.message,
      );
    }

    let status;
    let errorMessage = null;
    let consecutiveFailures = 0;
    let lastUpTime = null;

    if (response.status >= 200 && response.status < 400) {
      if (hasDataFeedIssue) {
        status = "degraded";
        errorMessage = "Data feed issue detected";
        // Increment consecutive failures if previous status was not operational
        const wasNotOperational =
          previousStatus && previousStatus.status !== "operational";
        consecutiveFailures = wasNotOperational ?
          (previousStatus.consecutiveFailures || 0) + 1 : 1;
        // Preserve lastUpTime from previous status if available
        lastUpTime = previousStatus?.lastUpTime || null;
      } else {
        status = "operational";
        consecutiveFailures = 0;
        lastUpTime = admin.firestore.FieldValue.serverTimestamp();
      }
    } else if (response.status >= 400 && response.status < 500) {
      status = "degraded";
      errorMessage = `HTTP ${response.status}`;
      // Increment consecutive failures if previous status was not operational
      const wasNotOperational =
        previousStatus && previousStatus.status !== "operational";
      consecutiveFailures = wasNotOperational ?
        (previousStatus.consecutiveFailures || 0) + 1 : 1;
      // Preserve lastUpTime from previous status if available
      lastUpTime = previousStatus?.lastUpTime || null;
    } else {
      status = "down";
      errorMessage = `HTTP ${response.status}`;
      // Increment consecutive failures if previous status was not operational
      const wasNotOperational =
        previousStatus && previousStatus.status !== "operational";
      consecutiveFailures = wasNotOperational ?
        (previousStatus.consecutiveFailures || 0) + 1 : 1;
      // Preserve lastUpTime from previous status if available
      lastUpTime = previousStatus?.lastUpTime || null;
    }

    return {
      id: service.id,
      name: service.name,
      url: service.url,
      type: service.type,
      status: status,
      statusCode: response.status,
      responseTime: responseTime,
      errorMessage: errorMessage,
      lastChecked: admin.firestore.FieldValue.serverTimestamp(),
      lastUpTime: lastUpTime,
      consecutiveFailures: consecutiveFailures,
    };
  } catch (error) {
    const endTime = Date.now();
    const responseTime = endTime - startTime;

    let status = "down";
    let errorMessage = "Unknown error";

    if (error.code === "ECONNABORTED" || error.message.includes("timeout")) {
      errorMessage = "Connection timeout";
    } else if (error.code === "ENOTFOUND" || error.code === "ECONNREFUSED") {
      errorMessage = "Connection error";
    } else if (error.response) {
      status = error.response.status >= 500 ? "down" : "degraded";
      errorMessage = `HTTP ${error.response.status}`;
    } else {
      errorMessage = error.message || "Unknown error";
    }

    // Increment consecutive failures if previous status was not operational
    const wasNotOperational =
      previousStatus && previousStatus.status !== "operational";
    const consecutiveFailures = wasNotOperational ?
      (previousStatus.consecutiveFailures || 0) + 1 : 1;
    // Preserve lastUpTime from previous status if available
    const lastUpTime = previousStatus?.lastUpTime || null;

    return {
      id: service.id,
      name: service.name,
      url: service.url,
      type: service.type,
      status: status,
      statusCode: error.response?.status || null,
      responseTime: responseTime,
      errorMessage: errorMessage,
      lastChecked: admin.firestore.FieldValue.serverTimestamp(),
      lastUpTime: lastUpTime,
      consecutiveFailures: consecutiveFailures,
    };
  }
}

// MARK: - Scheduled Health Check Function
// Runs every 60 seconds to check all services and update Firestore
// This ensures all users see the same status (server-side checks)
// Optimized for Firebase free tier limits:
// - 2M invocations/month (43,200/month at 60s interval = 2.16% usage)
// - 400K GB-seconds/month (estimated ~22K/month = 5.5% usage)
// - 200K CPU-seconds/month (estimated ~86K/month = 43% usage)
exports.scheduledHealthCheck = functions
    .pubsub
    .schedule("every 60 seconds")
    .timeZone("UTC")
    .onRun(async (context) => {
      const startExecutionTime = Date.now();
      console.log("Starting scheduled health check for all services");

      const db = admin.firestore();
      const collectionName = "service_status_cache";
      const lastUpdateDocId = "last_update";

      try {
        // Load previous statuses from Firestore to track consecutive failures
        const previousStatuses = new Map();
        const allServices = [...INFINITUM_SERVICES, ...THIRD_PARTY_SERVICES];

        try {
          const previousDocs = await db.collection(collectionName)
              .where(
                  admin.firestore.FieldPath.documentId,
                  "!=",
                  lastUpdateDocId,
              )
              .get();

          for (const doc of previousDocs.docs) {
            const data = doc.data();
            previousStatuses.set(doc.id, {
              status: data.status,
              consecutiveFailures: data.consecutiveFailures || 0,
              lastUpTime: data.lastUpTime,
            });
          }
        } catch (e) {
          console.warn("Could not load previous statuses:", e.message);
        }

        // Check all services in parallel
        const checkPromises = allServices.map((service) => {
          const previousStatus = previousStatuses.get(service.id);
          return checkSingleService(service, previousStatus);
        });
        const results = await Promise.all(checkPromises);

        // Update Firestore with batch write
        const batch = db.batch();

        // Update each service status
        for (const result of results) {
          const docRef = db.collection(collectionName).doc(result.id);
          batch.set(docRef, result, {merge: true});
        }

        // Update last update timestamp
        const lastUpdateRef = db.collection(collectionName)
            .doc(lastUpdateDocId);
        batch.set(lastUpdateRef, {
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          serviceCount: results.length,
        }, {merge: true});

        await batch.commit();

        const operationalCount = results.filter((r) =>
          r.status === "operational",
        ).length;
        const issuesCount = results.filter((r) =>
          r.status !== "operational",
        ).length;

        const executionTime = Date.now() - startExecutionTime;
        console.log(
            `Scheduled health check completed in ${executionTime}ms. ` +
            `Operational: ${operationalCount}, Issues: ${issuesCount}`,
        );

        // Log usage metrics for monitoring (stays within free tier)
        // Estimated: ~43,200 invocations/month, ~22K GB-seconds/month,
        // ~86K CPU-seconds/month
        return null;
      } catch (error) {
        console.error("Error in scheduled health check:", error);
        // Don't throw error to prevent Cloud Scheduler from retrying
        // The next scheduled run will attempt again
        return null;
      }
    });

// Suggestions For Features and Additions Later:
// - Add caching to reduce function invocations
// - Implement rate limiting
// - Add service-specific timeout configurations
// - Create health check result history storage
// - Add alerting/notification system
// - Implement service dependency tracking


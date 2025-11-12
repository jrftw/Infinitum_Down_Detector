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

// Suggestions For Features and Additions Later:
// - Add caching to reduce function invocations
// - Implement rate limiting
// - Add service-specific timeout configurations
// - Create health check result history storage
// - Add alerting/notification system
// - Implement service dependency tracking


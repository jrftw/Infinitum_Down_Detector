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
      responseTimeMs: responseTime,
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
      responseTimeMs: responseTime,
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
      const startTime = Date.now();
      return axios.get(service.url, {
        timeout: 10000,
        validateStatus: (status) => status < 500,
        maxRedirects: 5,
        headers: {
          "User-Agent": "InfinitumDownDetector/1.0",
        },
      }).then((response) => {
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
          responseTimeMs: responseTime,
          errorMessage: errorMessage,
          hasDataFeedIssue: hasDataFeedIssue,
        };
      }).catch((error) => {
        const endTime = Date.now();
        const responseTime = endTime - startTime;
        
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
          responseTimeMs: responseTime,
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

// MARK: - Component Definitions
// Defines components for services that have sub-components
// Matches client-side definitions in config.dart
function getComponentsForService(serviceId) {
  switch (serviceId) {
    case "google":
      return [
        {id: "google-apps-script", name: "Apps Script", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-appsheet", name: "AppSheet", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-gmail", name: "Gmail", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-calendar", name: "Google Calendar", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-docs", name: "Google Docs", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-drive", name: "Google Drive", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-forms", name: "Google Forms", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-sheets", name: "Google Sheets", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
        {id: "google-slides", name: "Google Slides", url: "https://www.google.com/appsstatus/dashboard/", type: "other"},
      ];
    case "firebase":
      return [
        {id: "firebase-app-hosting", name: "App Hosting", url: "https://status.firebase.google.com/", type: "other"},
        {id: "firebase-authentication", name: "Authentication", url: "https://status.firebase.google.com/", type: "auth"},
        {id: "firebase-cloud-firestore", name: "Cloud Firestore", url: "https://status.firebase.google.com/", type: "database"},
        {id: "firebase-cloud-messaging", name: "Cloud Messaging", url: "https://status.firebase.google.com/", type: "other"},
        {id: "firebase-cloud-functions", name: "Cloud Functions", url: "https://status.firebase.google.com/", type: "api"},
        {id: "firebase-console", name: "Console", url: "https://status.firebase.google.com/", type: "other"},
        {id: "firebase-crashlytics", name: "Crashlytics", url: "https://status.firebase.google.com/", type: "other"},
        {id: "firebase-hosting", name: "Hosting", url: "https://status.firebase.google.com/", type: "cdn"},
        {id: "firebase-performance-monitoring", name: "Performance Monitoring", url: "https://status.firebase.google.com/", type: "other"},
        {id: "firebase-realtime-database", name: "Realtime Database", url: "https://status.firebase.google.com/", type: "database"},
        {id: "firebase-storage", name: "Storage", url: "https://status.firebase.google.com/", type: "other"},
      ];
    case "aws":
      return [
        {id: "aws-ec2", name: "EC2", url: "https://status.aws.amazon.com/", type: "other"},
        {id: "aws-s3", name: "S3", url: "https://status.aws.amazon.com/", type: "other"},
        {id: "aws-cloudfront", name: "CloudFront", url: "https://status.aws.amazon.com/", type: "cdn"},
        {id: "aws-api-gateway", name: "API Gateway", url: "https://status.aws.amazon.com/", type: "api"},
        {id: "aws-rds", name: "RDS", url: "https://status.aws.amazon.com/", type: "database"},
        {id: "aws-lambda", name: "Lambda", url: "https://status.aws.amazon.com/", type: "api"},
      ];
    case "apple":
      return [
        {id: "apple-app-store-connect", name: "App Store Connect", url: "https://www.apple.com/support/systemstatus/", type: "other"},
        {id: "apple-apns", name: "Apple Push Notification Service", url: "https://www.apple.com/support/systemstatus/", type: "other"},
        {id: "apple-sign-in", name: "Sign in with Apple", url: "https://www.apple.com/support/systemstatus/", type: "auth"},
        {id: "apple-testflight", name: "TestFlight", url: "https://www.apple.com/support/systemstatus/", type: "other"},
        {id: "apple-icloud", name: "iCloud", url: "https://www.apple.com/support/systemstatus/", type: "other"},
      ];
    case "discord":
      return [
        {id: "discord-api", name: "API", url: "https://discordstatus.com/", type: "api"},
        {id: "discord-gateway", name: "Gateway", url: "https://discordstatus.com/", type: "other"},
        {id: "discord-media-proxy", name: "Media Proxy", url: "https://discordstatus.com/", type: "cdn"},
        {id: "discord-voice", name: "Voice", url: "https://discordstatus.com/", type: "other"},
      ];
    case "tiktok":
      return [
        {id: "tiktok-api", name: "API", url: "https://www.tiktok.com/", type: "api"},
        {id: "tiktok-live", name: "LIVE", url: "https://www.tiktok.com/", type: "other"},
        {id: "tiktok-cdn", name: "CDN", url: "https://www.tiktok.com/", type: "cdn"},
      ];
    default:
      return [];
  }
}

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

// MARK: - Component Status Parsing
/**
 * Parses component statuses from status page HTML/JSON
 * @param {string} serviceId - Service ID (google, firebase, etc.)
 * @param {Array} components - Array of component definitions
 * @param {string} responseBody - HTML/JSON response body from status page
 * @param {number} httpStatus - HTTP status code
 * @return {Promise<Array>} Array of component status objects
 */
async function parseComponentStatuses(serviceId, components, responseBody, httpStatus) {
  const componentStatuses = [];
  const responseBodyLower = responseBody.toLowerCase();
  
  // If HTTP status indicates page is down, mark all components as down
  if (httpStatus >= 500) {
    const now = admin.firestore.Timestamp.now();
    return components.map((comp) => ({
      id: comp.id,
      name: comp.name,
      url: comp.url,
      type: comp.type,
      status: "down",
      lastChecked: now,
      responseTimeMs: 0,
      errorMessage: `HTTP ${httpStatus}`,
    }));
  }
  
  // Service-specific parsing
  if (serviceId === "google") {
    // Parse Google Workspace status page
    // Google status page uses JSON data embedded in the page and HTML status indicators
    // We need to search more aggressively for service-specific issues
    
    // First, try to extract JSON data from the page (Google embeds status data in script tags)
    let statusData = null;
    try {
      // Look for JSON data in script tags
      const jsonMatch = responseBody.match(/<script[^>]*>[\s\S]*?({[\s\S]*?"status"[^}]*})[\s\S]*?<\/script>/i);
      if (jsonMatch && jsonMatch[1]) {
        try {
          statusData = JSON.parse(jsonMatch[1]);
        } catch (e) {
          // Try to find other JSON patterns
          const jsonPatterns = [
            /window\.__INITIAL_STATE__\s*=\s*({[\s\S]*?});/i,
            /"services"\s*:\s*\[([\s\S]*?)\]/i,
          ];
          for (const pattern of jsonPatterns) {
            const match = responseBody.match(pattern);
            if (match) {
              try {
                statusData = JSON.parse(match[1]);
                break;
              } catch (e2) {
                // Continue to next pattern
              }
            }
          }
        }
      }
    } catch (e) {
      // JSON parsing failed, continue with HTML parsing
      console.warn("Could not parse JSON from Google status page:", e.message);
    }
    
    // Map component names to search patterns
    const componentSearchMap = {
      "google docs": ["docs", "google docs"],
      "google drive": ["drive", "google drive"],
      "google forms": ["forms", "google forms"],
      "google sheets": ["sheets", "google sheets"],
      "google slides": ["slides", "google slides"],
      "gmail": ["gmail", "mail"],
      "google calendar": ["calendar", "google calendar"],
      "apps script": ["apps script", "appscript"],
      "appsheet": ["appsheet", "app sheet"],
    };
    
    for (const comp of components) {
      let compStatus = "unknown";
      let errorMessage = null;
      
      const compNameLower = comp.name.toLowerCase();
      const searchTerms = componentSearchMap[compNameLower] || [compNameLower.replace("google ", "").trim()];
      
      // Search for the component in the entire page (not just near the name)
      let foundIssues = false;
      let foundOperational = false;
      
      // Check for service-specific issues in the entire response
      for (const searchTerm of searchTerms) {
        const searchTermLower = searchTerm.toLowerCase();
        
        // Find all occurrences of the service name
        let searchIndex = 0;
        while ((searchIndex = responseBodyLower.indexOf(searchTermLower, searchIndex)) !== -1) {
          // Check a larger surrounding context (500 chars before and after)
          const contextStart = Math.max(0, searchIndex - 500);
          const contextEnd = Math.min(responseBody.length, searchIndex + 500);
          const context = responseBodyLower.substring(contextStart, contextEnd);
          
          // Check for DOWN/OUTAGE indicators (highest priority)
          const downIndicators = [
            "service disruption",
            "service outage",
            "outage",
            "down",
            "unavailable",
            "not available",
            "currently unavailable",
            "experiencing issues",
            "major outage",
            "partial outage",
            "incident",
            "active incident",
            "ongoing incident",
            "status: service disruption",
            "status: outage",
            "status: down",
          ];
          
          for (const indicator of downIndicators) {
            if (context.includes(indicator)) {
              // Verify it's related to this service by checking proximity
              const indicatorIndex = context.indexOf(indicator);
              const distance = Math.abs(indicatorIndex - (searchIndex - contextStart));
              
              // If indicator is within 300 chars of service name, it's likely related
              if (distance < 300) {
                compStatus = "down";
                errorMessage = "Service disruption or outage reported";
                foundIssues = true;
                break;
              }
            }
          }
          
          if (foundIssues) break;
          
          // Check for DEGRADED indicators
          const degradedIndicators = [
            "degraded performance",
            "performance degradation",
            "degraded",
            "partial",
            "partial outage",
            "partial disruption",
            "some users",
            "intermittent",
            "intermittent issues",
            "slower than usual",
            "delayed",
            "status: degraded",
            "status: partial",
          ];
          
          for (const indicator of degradedIndicators) {
            if (context.includes(indicator)) {
              const indicatorIndex = context.indexOf(indicator);
              const distance = Math.abs(indicatorIndex - (searchIndex - contextStart));
              
              if (distance < 300) {
                compStatus = "degraded";
                errorMessage = "Service degradation or partial issues reported";
                foundIssues = true;
                break;
              }
            }
          }
          
          if (foundIssues) break;
          
          // Check for OPERATIONAL indicators (only if no issues found)
          if (!foundIssues) {
            const operationalIndicators = [
              "operational",
              "all systems operational",
              "normal",
              "available",
              "no issues",
              "status: operational",
              "status: normal",
            ];
            
            for (const indicator of operationalIndicators) {
              if (context.includes(indicator)) {
                const indicatorIndex = context.indexOf(indicator);
                const distance = Math.abs(indicatorIndex - (searchIndex - contextStart));
                
                if (distance < 300) {
                  foundOperational = true;
                  break;
                }
              }
            }
          }
          
          searchIndex += searchTermLower.length;
        }
        
        if (foundIssues) break;
      }
      
      // If we found issues, use that status
      // If we found operational indicators and no issues, mark as operational
      // Otherwise, check the overall page for any active incidents
      if (!foundIssues) {
        if (foundOperational) {
          compStatus = "operational";
        } else {
          // Check if there are any active incidents mentioned on the page
          // Google often shows active incidents at the top of the page
          const activeIncidentPatterns = [
            /active\s+incident/i,
            /ongoing\s+incident/i,
            /current\s+incident/i,
            /service\s+disruption/i,
            /outage/i,
          ];
          
          let hasActiveIncident = false;
          for (const pattern of activeIncidentPatterns) {
            if (pattern.test(responseBodyLower)) {
              // Check if any of our search terms appear near incident mentions
              for (const searchTerm of searchTerms) {
                const searchTermLower = searchTerm.toLowerCase();
                const incidentMatches = [...responseBodyLower.matchAll(pattern)];
                for (const match of incidentMatches) {
                  const incidentIndex = match.index;
                  // Check if service name appears within 1000 chars of incident
                  const nearbyText = responseBodyLower.substring(
                    Math.max(0, incidentIndex - 1000),
                    Math.min(responseBody.length, incidentIndex + 1000),
                  );
                  if (nearbyText.includes(searchTermLower)) {
                    hasActiveIncident = true;
                    compStatus = "degraded"; // Default to degraded if incident found
                    errorMessage = "Active incident or issue reported";
                    break;
                  }
                }
                if (hasActiveIncident) break;
              }
              if (hasActiveIncident) break;
            }
          }
          
          // If no issues found and no operational indicators, default to unknown
          // (don't assume operational - let the user see it's unknown)
          if (!hasActiveIncident && compStatus === "unknown") {
            // Only default to operational if we can't find the service at all
            // If we found the service but no status, it's safer to mark as unknown
            const serviceFound = searchTerms.some((term) =>
              responseBodyLower.includes(term.toLowerCase()),
            );
            if (serviceFound) {
              // Service found but no clear status - mark as unknown
              compStatus = "unknown";
            } else {
              // Service not found on page - might be operational (page loaded successfully)
              compStatus = "operational";
            }
          }
        }
      }
      
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: compStatus,
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: 0,
        errorMessage: errorMessage,
      });
    }
  } else if (serviceId === "firebase") {
    // Parse Firebase status page with functional checks for critical components
    for (const comp of components) {
      let compStatus = "unknown";
      let errorMessage = null;
      let responseTimeMs = 0;
      
      // MARK: - Firebase Auth Functional Check
      // For Firebase Authentication, perform actual functional check, not just status page parsing
      if (comp.id === "firebase-authentication") {
        try {
          // Perform functional check with triple-check validation
          const authCheckResult = await tripleCheckValidation(
            checkFirebaseAuthFunctional,
            1000, // 1 second delay between checks
          );
          
          compStatus = authCheckResult.status;
          errorMessage = authCheckResult.errorMessage;
          responseTimeMs = authCheckResult.responseTimeMs;
          
          // If functional check indicates operational, use that
          // Otherwise, also check status page for additional context
          if (compStatus === "operational") {
            componentStatuses.push({
              id: comp.id,
              name: comp.name,
              url: comp.url,
              type: comp.type,
              status: compStatus,
              lastChecked: admin.firestore.Timestamp.now(),
              responseTimeMs: responseTimeMs,
              errorMessage: errorMessage,
            });
            continue; // Skip status page parsing for Auth
          }
          // If functional check failed, continue to status page parsing for additional info
        } catch (e) {
          console.warn(`Firebase Auth functional check failed: ${e.message}`);
          // Continue to status page parsing as fallback
        }
      }
      
      // Parse status page for all components (including Auth if functional check failed)
      const compNameLower = comp.name.toLowerCase();
      const searchPatterns = [
        compNameLower,
        compNameLower.replace("firebase ", ""),
        compNameLower.replace("firebase", "").trim(),
      ];
      
      const foundInPage = searchPatterns.some((pattern) =>
        responseBodyLower.includes(pattern),
      );
      
      if (foundInPage) {
        const compIndex = responseBodyLower.indexOf(compNameLower);
        if (compIndex !== -1) {
          const surroundingText = responseBodyLower.substring(
            Math.max(0, compIndex - 200),
            Math.min(responseBody.length, compIndex + 200),
          );
          
          // Only override status if we haven't already determined it from functional check
          if (compStatus === "unknown") {
            if (
              surroundingText.includes("service disruption") ||
              surroundingText.includes("outage") ||
              surroundingText.includes("down") ||
              surroundingText.includes("incident")
            ) {
              compStatus = "down";
              errorMessage = "Service disruption reported";
            } else if (
              surroundingText.includes("degraded") ||
              surroundingText.includes("partial") ||
              surroundingText.includes("issue")
            ) {
              compStatus = "degraded";
              errorMessage = "Service degradation reported";
            } else if (
              surroundingText.includes("operational") ||
              surroundingText.includes("normal") ||
              surroundingText.includes("available") ||
              surroundingText.includes("healthy")
            ) {
              compStatus = "operational";
            }
          } else {
            // If we have a status from functional check but status page shows issues,
            // combine the information (use worse status)
            if (
              surroundingText.includes("service disruption") ||
              surroundingText.includes("outage") ||
              surroundingText.includes("down")
            ) {
              if (compStatus !== "down") {
                compStatus = "degraded";
                errorMessage = errorMessage || "Service issue reported";
              }
            }
          }
        }
      }
      
      if (foundInPage && compStatus === "unknown") {
        compStatus = "operational";
      }
      
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: compStatus,
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: responseTimeMs,
        errorMessage: errorMessage,
      });
    }
  } else if (serviceId === "aws") {
    // Parse AWS status page
    for (const comp of components) {
      let compStatus = "unknown";
      let errorMessage = null;
      
      const compNameLower = comp.name.toLowerCase();
      const searchPatterns = [
        compNameLower,
        compNameLower.replace("aws ", ""),
        compNameLower.replace("amazon ", ""),
      ];
      
      // Search for component in response
      let foundInPage = false;
      for (const pattern of searchPatterns) {
        if (responseBodyLower.includes(pattern)) {
          foundInPage = true;
          const compIndex = responseBodyLower.indexOf(pattern);
          if (compIndex !== -1) {
            const surroundingText = responseBodyLower.substring(
              Math.max(0, compIndex - 300),
              Math.min(responseBody.length, compIndex + 300),
            );
            
            // Check for issues
            if (
              surroundingText.includes("service disruption") ||
              surroundingText.includes("outage") ||
              surroundingText.includes("down") ||
              surroundingText.includes("incident") ||
              surroundingText.includes("degraded")
            ) {
              compStatus = "degraded";
              errorMessage = "Service issue reported";
            } else if (
              surroundingText.includes("operational") ||
              surroundingText.includes("normal") ||
              surroundingText.includes("available")
            ) {
              compStatus = "operational";
            }
          }
          break;
        }
      }
      
      if (foundInPage && compStatus === "unknown") {
        compStatus = "operational";
      } else if (!foundInPage) {
        compStatus = "unknown";
      }
      
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: compStatus,
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: 0,
        errorMessage: errorMessage,
      });
    }
  } else if (serviceId === "apple") {
    // Parse Apple status page
    for (const comp of components) {
      let compStatus = "unknown";
      let errorMessage = null;
      
      const compNameLower = comp.name.toLowerCase();
      const searchPatterns = [
        compNameLower,
        compNameLower.replace("apple ", ""),
        compNameLower.replace("apns", "push notification"),
      ];
      
      let foundInPage = false;
      for (const pattern of searchPatterns) {
        if (responseBodyLower.includes(pattern)) {
          foundInPage = true;
          const compIndex = responseBodyLower.indexOf(pattern);
          if (compIndex !== -1) {
            const surroundingText = responseBodyLower.substring(
              Math.max(0, compIndex - 300),
              Math.min(responseBody.length, compIndex + 300),
            );
            
            if (
              surroundingText.includes("outage") ||
              surroundingText.includes("down") ||
              surroundingText.includes("unavailable") ||
              surroundingText.includes("issue")
            ) {
              compStatus = "degraded";
              errorMessage = "Service issue reported";
            } else if (
              surroundingText.includes("operational") ||
              surroundingText.includes("available") ||
              surroundingText.includes("normal")
            ) {
              compStatus = "operational";
            }
          }
          break;
        }
      }
      
      if (foundInPage && compStatus === "unknown") {
        compStatus = "operational";
      } else if (!foundInPage) {
        compStatus = "unknown";
      }
      
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: compStatus,
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: 0,
        errorMessage: errorMessage,
      });
    }
  } else if (serviceId === "discord") {
    // Parse Discord status page
    for (const comp of components) {
      let compStatus = "unknown";
      let errorMessage = null;
      
      const compNameLower = comp.name.toLowerCase();
      const searchPatterns = [
        compNameLower,
        compNameLower.replace("discord ", ""),
      ];
      
      let foundInPage = false;
      for (const pattern of searchPatterns) {
        if (responseBodyLower.includes(pattern)) {
          foundInPage = true;
          const compIndex = responseBodyLower.indexOf(pattern);
          if (compIndex !== -1) {
            const surroundingText = responseBodyLower.substring(
              Math.max(0, compIndex - 300),
              Math.min(responseBody.length, compIndex + 300),
            );
            
            if (
              surroundingText.includes("outage") ||
              surroundingText.includes("down") ||
              surroundingText.includes("degraded") ||
              surroundingText.includes("incident")
            ) {
              compStatus = "degraded";
              errorMessage = "Service issue reported";
            } else if (
              surroundingText.includes("operational") ||
              surroundingText.includes("healthy") ||
              surroundingText.includes("normal")
            ) {
              compStatus = "operational";
            }
          }
          break;
        }
      }
      
      if (foundInPage && compStatus === "unknown") {
        compStatus = "operational";
      } else if (!foundInPage) {
        compStatus = "unknown";
      }
      
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: compStatus,
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: 0,
        errorMessage: errorMessage,
      });
    }
  } else if (serviceId === "tiktok") {
    // Parse TikTok status (main page check)
    // TikTok doesn't have a public status page, so we check main site availability
    for (const comp of components) {
      // For TikTok, if main page loads, assume components are operational
      // This is a simplified check since TikTok doesn't provide detailed status
      componentStatuses.push({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: httpStatus >= 200 && httpStatus < 400 ? "operational" : "unknown",
        lastChecked: admin.firestore.Timestamp.now(),
        responseTimeMs: 0,
        errorMessage: httpStatus >= 400 ? `HTTP ${httpStatus}` : null,
      });
    }
  } else {
    // For other services, default to unknown
    const now = admin.firestore.Timestamp.now();
    componentStatuses = components.map((comp) => ({
      id: comp.id,
      name: comp.name,
      url: comp.url,
      type: comp.type,
      status: "unknown",
      lastChecked: now,
      responseTimeMs: 0,
    }));
  }
  
  return componentStatuses;
}

// MARK: - Triple-Check Validation Helper
/**
 * Performs triple-check validation for suspected outages
 * Requires 3 consecutive failures before marking as down/degraded
 * @param {Function} checkFunction - Function that performs a single check
 * @param {number} delayMs - Delay between checks in milliseconds
 * @return {Promise<Object>} Result of the checks
 */
async function tripleCheckValidation(checkFunction, delayMs = 2000) {
  const results = [];
  
  // Perform first check
  try {
    const result1 = await checkFunction();
    results.push(result1);
    
    // If first check passes, return immediately
    if (result1.status === "operational" || result1.statusCode < 400) {
      return result1;
    }
    
    // First failure - wait and check again
    await new Promise((resolve) => setTimeout(resolve, delayMs));
    const result2 = await checkFunction();
    results.push(result2);
    
    // If second check passes, return as operational (false positive)
    if (result2.status === "operational" || result2.statusCode < 400) {
      return result2;
    }
    
    // Second failure - wait and check third time
    await new Promise((resolve) => setTimeout(resolve, delayMs * 2));
    const result3 = await checkFunction();
    results.push(result3);
    
    // If third check passes, return as operational (transient issue)
    if (result3.status === "operational" || result3.statusCode < 400) {
      return result3;
    }
    
    // All three checks failed - return worst status
    const worstStatus = results.reduce((worst, current) => {
      const statusPriority = {
        "down": 0,
        "degraded": 1,
        "operational": 2,
        "unknown": 3,
      };
      return statusPriority[current.status] < statusPriority[worst.status] ? current : worst;
    }, results[0]);
    
    return worstStatus;
  } catch (error) {
    // If any check throws, return error result
    return {
      status: "down",
      errorMessage: error.message || "Unknown error",
      statusCode: null,
      responseTimeMs: 0,
    };
  }
}

// MARK: - Firebase Auth Functional Check
/**
 * Performs a functional check of Firebase Auth by attempting to verify a token
 * This is a lightweight check that doesn't require actual authentication
 * @return {Promise<Object>} Check result
 */
async function checkFirebaseAuthFunctional() {
  const startTime = Date.now();
  
  try {
    // Check Firebase Auth REST API endpoint (public endpoint for token verification)
    // This endpoint is used for token verification and is a good indicator of Auth service health
    const authCheckUrl = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/getProjectConfig";
    
    // Make a lightweight request to Firebase Auth API
    // This doesn't require authentication and will return project config if service is up
    const response = await axios.get(authCheckUrl, {
      timeout: 5000,
      validateStatus: (status) => status < 500, // Accept any status < 500
      params: {
        key: "AIzaSyDummyKey", // Dummy key - we're just checking if the endpoint responds
      },
    });
    
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    // If we get a response (even 400/403), Auth service is operational
    // 400/403 means the service is up but our request is invalid (expected)
    // 5xx means the service is down
    if (response.status < 500) {
      return {
        status: "operational",
        statusCode: response.status,
        responseTimeMs: responseTime,
        errorMessage: null,
      };
    } else {
      return {
        status: "down",
        statusCode: response.status,
        responseTimeMs: responseTime,
        errorMessage: `HTTP ${response.status}`,
      };
    }
  } catch (error) {
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    // Network errors or timeouts indicate service issues
    if (error.code === "ECONNABORTED" || error.message.includes("timeout")) {
      return {
        status: "down",
        statusCode: null,
        responseTimeMs: responseTime,
        errorMessage: "Connection timeout",
      };
    } else if (error.response && error.response.status >= 500) {
      return {
        status: "down",
        statusCode: error.response.status,
        responseTimeMs: responseTime,
        errorMessage: `HTTP ${error.response.status}`,
      };
    } else {
      // Other errors (like 400/403) mean service is up
      return {
        status: "operational",
        statusCode: error.response?.status || null,
        responseTimeMs: responseTime,
        errorMessage: null,
      };
    }
  }
}

// MARK: - Helper Function: Check Single Service
/**
 * Performs health check on a single service with triple-check validation
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

    // Get components for this service
    const components = getComponentsForService(service.id);
    
    // Parse component statuses from status page if available
    let componentStatuses = [];
    if (components.length > 0 && responseBody) {
      try {
        componentStatuses = await parseComponentStatuses(
          service.id,
          components,
          responseBody,
          response.status,
        );
      } catch (e) {
        console.warn(`Error parsing component statuses for ${service.id}:`, e.message);
        // Fall back to unknown status if parsing fails
        const now = admin.firestore.Timestamp.now();
        componentStatuses = components.map((comp) => ({
          id: comp.id,
          name: comp.name,
          url: comp.url,
          type: comp.type,
          status: "unknown",
          lastChecked: now,
          responseTimeMs: 0,
        }));
      }
    } else {
      // No components or no response body
      const now = admin.firestore.Timestamp.now();
      componentStatuses = components.map((comp) => ({
        id: comp.id,
        name: comp.name,
        url: comp.url,
        type: comp.type,
        status: "unknown",
        lastChecked: now,
        responseTimeMs: 0,
      }));
    }
    
    // Determine overall service status based on component statuses if components exist
    // This ensures that if any component has issues, the service status reflects that
    let finalStatus = status;
    if (componentStatuses.length > 0) {
      const hasDown = componentStatuses.some((c) => c.status === "down");
      const hasDegraded = componentStatuses.some((c) => c.status === "degraded");
      const allOperational = componentStatuses.every((c) => c.status === "operational");
      
      if (hasDown) {
        finalStatus = "down";
        // Update error message if not already set
        if (!errorMessage) {
          const downComponents = componentStatuses.filter((c) => c.status === "down");
          errorMessage = `${downComponents.length} component(s) down: ${downComponents.map((c) => c.name).join(", ")}`;
        }
      } else if (hasDegraded) {
        finalStatus = "degraded";
        // Update error message if not already set
        if (!errorMessage) {
          const degradedComponents = componentStatuses.filter((c) => c.status === "degraded");
          errorMessage = `${degradedComponents.length} component(s) degraded: ${degradedComponents.map((c) => c.name).join(", ")}`;
        }
      } else if (allOperational) {
        finalStatus = "operational";
        // Clear error message if all components are operational
        errorMessage = null;
      }
      // If components have mixed status (some unknown, some operational), use the worse status
      // or keep the current status if it's worse than operational
    }

    return {
      id: service.id,
      name: service.name,
      url: service.url,
      type: service.type,
      status: finalStatus,
      statusCode: response.status,
      responseTimeMs: responseTime,
      errorMessage: errorMessage,
      lastChecked: admin.firestore.FieldValue.serverTimestamp(),
      lastUpTime: lastUpTime,
      consecutiveFailures: consecutiveFailures,
      components: componentStatuses,
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

    // Get components for this service
    const components = getComponentsForService(service.id);
    
    // Parse component statuses (will default to unknown if parsing fails)
    let componentStatuses = [];
    if (components.length > 0) {
      try {
        // For error cases, we don't have responseBody, so mark all as down
        const now = admin.firestore.Timestamp.now();
        componentStatuses = components.map((comp) => ({
          id: comp.id,
          name: comp.name,
          url: comp.url,
          type: comp.type,
          status: "down",
          lastChecked: now,
          responseTimeMs: 0,
          errorMessage: errorMessage || "Service unavailable",
        }));
      } catch (e) {
        console.warn(`Error creating component statuses for ${service.id}:`, e.message);
        const now = admin.firestore.Timestamp.now();
        componentStatuses = components.map((comp) => ({
          id: comp.id,
          name: comp.name,
          url: comp.url,
          type: comp.type,
          status: "unknown",
          lastChecked: now,
          responseTimeMs: 0,
        }));
      }
    }

    return {
      id: service.id,
      name: service.name,
      url: service.url,
      type: service.type,
      status: status,
      statusCode: error.response?.status || null,
      responseTimeMs: responseTime,
      errorMessage: errorMessage,
      lastChecked: admin.firestore.FieldValue.serverTimestamp(),
      lastUpTime: lastUpTime,
      consecutiveFailures: consecutiveFailures,
      components: componentStatuses,
    };
  }
}

// MARK: - Scheduled Health Check Function
// Runs every 1 minute to check all services and update Firestore
// This ensures all users see the same status (server-side checks)
// Optimized for Firebase free tier limits:
// - 2M invocations/month (43,200/month at 1min interval = 2.16% usage)
// - 400K GB-seconds/month (estimated ~22K/month = 5.5% usage)
// - 200K CPU-seconds/month (estimated ~86K/month = 43% usage)
exports.scheduledHealthCheck = functions
    .pubsub
    .schedule("*/1 * * * *")  // Every 1 minute (cron format)
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
              .get();

          for (const doc of previousDocs.docs) {
            // Skip the last_update document
            if (doc.id === lastUpdateDocId) continue;
            
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

        // MARK: - Save History Entries
        // Store history entries for each service
        const historyBatch = db.batch();
        const historyCollectionName = "service_status_history";
        const now = admin.firestore.Timestamp.now();

        for (const result of results) {
          const historyDocRef = db.collection(historyCollectionName)
              .doc(result.id)
              .collection("entries")
              .doc(now.toMillis().toString());

          historyBatch.set(historyDocRef, {
            timestamp: now,
            status: result.status,
            responseTimeMs: result.responseTimeMs || 0,
            errorMessage: result.errorMessage || null,
            hasDataFeedIssue: result.hasDataFeedIssue || false,
          });
        }

        // Commit history batch (don't fail if this fails)
        try {
          await historyBatch.commit();
          console.log(`Saved ${results.length} history entries`);
        } catch (historyError) {
          console.warn("Error saving history entries:", historyError.message);
          // Continue even if history save fails
        }

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


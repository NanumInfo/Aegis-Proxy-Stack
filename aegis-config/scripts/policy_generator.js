/**
 * Aegis Policy Generator
 * Generates open-appsec local_policy.yaml based on NPM Proxy Hosts.
 */

const fs = require('fs');
const axios = require('axios');
const yaml = require('js-yaml');
const _ = require('lodash');

// --- [Configuration Injection] ---
const CONFIG = {
    NPM_API: process.env.NPM_API || 'http://localhost:81/api',
    IDENTITY: process.env.NPM_USER,
    SECRET: process.env.NPM_PASS,
    POLICY_FILE: process.env.POLICY_FILE || '../policy/local_policy.yaml',
    MODE: process.env.APPSEC_MODE || 'prevent-learn',
    CONFIDENCE: process.env.APPSEC_CONFIDENCE || 'medium'
};

// ANSI Codes for Logging
const STYLE = {
    INFO: '\x1b[46m\x1b[37m\x1b[1m INFO \x1b[0m',
    DONE: '\x1b[42m\x1b[37m\x1b[1m DONE \x1b[0m',
    FAIL: '\x1b[41m\x1b[37m\x1b[1m FAIL \x1b[0m',
    WARN: '\x1b[43m\x1b[37m\x1b[1m WARN \x1b[0m'
};

// Validation
if (!CONFIG.IDENTITY || !CONFIG.SECRET) {
    console.error(`   ${STYLE.FAIL} Missing NPM Credentials (NPM_USER, NPM_PASS).`);
    process.exit(1);
}

// [TEMPLATE] Base Policy Structure
const templateStr = `
policies:
  default:
    triggers:
    - appsec-default-log-trigger
    mode: inactive
    practices:
    - webapp-default-practice
    custom-response: appsec-default-web-user-response
  specific-rules: []

practices:
  - name: webapp-default-practice
    web-attacks:
      max-body-size-kb: 1000000
      max-header-size-bytes: 102400
      max-object-depth: 40
      max-url-size-bytes: 32768
      minimum-confidence: high
      override-mode: inactive
      protections:
        csrf-protection: inactive
        error-disclosure: inactive
        non-valid-http-methods: false
        open-redirect: inactive
    anti-bot:
      injected-URIs: []
      validated-URIs: []
      override-mode: inactive
    snort-signatures:
      configmap: []
      override-mode: inactive
    openapi-schema-validation:
      configmap: []
      override-mode: inactive

log-triggers:
  - name: appsec-default-log-trigger
    access-control-logging:
      allow-events: false
      drop-events: true
    additional-suspicious-events-logging:
      enabled: true
      minimum-severity: high
      response-body: false
      response-code: true
    appsec-logging:
      all-web-requests: false
      detect-events: true
      prevent-events: true
    extended-logging:
      http-headers: false
      request-body: false
      url-path: true
      url-query: true
    log-destination:
      cloud: false
      stdout:
        format: json

custom-responses:
  - name: appsec-default-web-user-response
    mode: response-code-only
    http-response-code: 403
`;

// Reference Objects for Cloning
const referenceObjects = {
    practice: {
        name: "npm-managed-practice-proxyhost-X",
        "web-attacks": {
            "max-body-size-kb": 1000000,
            "max-header-size-bytes": 102400,
            "max-object-depth": 40,
            "max-url-size-bytes": 32768,
            "minimum-confidence": "medium",
            "override-mode": "inactive",
            protections: {
                "csrf-protection": "inactive",
                "error-disclosure": "inactive",
                "non-valid-http-methods": false,
                "open-redirect": "inactive"
            }
        },
        "anti-bot": { "injected-URIs": [], "validated-URIs": [], "override-mode": "inactive" },
        "snort-signatures": { configmap: [], "override-mode": "inactive" },
        "openapi-schema-validation": { configmap: [], "override-mode": "inactive" }
    },
    logTrigger: {
        name: "npm-managed-log-trigger-proxyhost-X",
        "access-control-logging": { "allow-events": false, "drop-events": true },
        "additional-suspicious-events-logging": { enabled: true, "minimum-severity": "high", "response-body": false },
        "appsec-logging": { "all-web-requests": false, "detect-events": true, "prevent-events": true },
        "extended-logging": { "http-headers": false, "request-body": false, "url-path": false, "url-query": false },
        "log-destination": { cloud: false, stdout: { format: "json" } }
    }
};

// --- [Main Logic] ---

async function getToken() {
    try {
        const res = await axios.post(`${CONFIG.NPM_API}/tokens`, {
            identity: CONFIG.IDENTITY,
            secret: CONFIG.SECRET
        });
        return res.data.token;
    } catch (error) {
        console.error(`   ${STYLE.FAIL} Token Error:`, error.message);
        if (error.response) console.error(`         Status: ${error.response.status}`);
        process.exit(1);
    }
}

async function getHosts(token) {
    try {
        const res = await axios.get(`${CONFIG.NPM_API}/nginx/proxy-hosts`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        return res.data;
    } catch (error) {
        console.error(`   ${STYLE.FAIL} Fetch Hosts Error:`, error.message);
        return [];
    }
}

async function generatePolicy() {
    console.log(`   ${STYLE.INFO} Starting Policy Generation...`);
    // Detailed config logging removed per user request

    const token = await getToken();
    const hosts = await getHosts(token);

    console.log(`   ${STYLE.INFO} Found ${hosts.length} proxy hosts in NPM.`);

    const basePolicy = yaml.load(templateStr);
    
    // Filter hosts where openappsec is enabled
    const activeHosts = hosts.filter(h => h.meta && h.meta.openappsec && h.meta.openappsec.enabled);
    console.log(`   ${STYLE.INFO} open-appsec enabled hosts: ${activeHosts.length}`);

    if (activeHosts.length === 0) {
        console.log(`   ${STYLE.WARN} No active hosts found. Policy will be empty.`);
    }

    activeHosts.forEach(host => {
        const id = host.id;
        const mode = CONFIG.MODE; 
        const confidence = CONFIG.CONFIDENCE;
        
        const specificRuleName = `npm-managed-specific-rule-proxyhost-${id}`;
        const practiceName = `npm-managed-practice-proxyhost-${id}`;
        const logTriggerName = `npm-managed-log-trigger-proxyhost-${id}`;

        // 1. Create Practice
        const practice = _.cloneDeep(referenceObjects.practice);
        practice.name = practiceName;
        practice['web-attacks']['override-mode'] = mode;
        practice['web-attacks']['minimum-confidence'] = confidence;
        basePolicy.practices.push(practice);

        // 2. Create Log Trigger
        const trigger = _.cloneDeep(referenceObjects.logTrigger);
        trigger.name = logTriggerName;
        basePolicy['log-triggers'].push(trigger);

        // 3. Create Specific Rules (Mapping Domains)
        host.domain_names.forEach((domain, idx) => {
            const ruleName = idx > 0 ? `${specificRuleName}.${idx}` : specificRuleName;
            basePolicy.policies['specific-rules'].push({
                host: domain,
                name: ruleName,
                triggers: [logTriggerName],
                mode: mode,
                practices: [practiceName]
            });
        });
    });

    const yamlStr = yaml.dump(basePolicy, { lineWidth: -1, noRefs: true });
    const finalOutput = `# Generated by Aegis Policy Controller at ${new Date().toISOString()}\n${yamlStr}`;
    
    try {
        fs.writeFileSync(CONFIG.POLICY_FILE, finalOutput, 'utf8');
        console.log(`   ${STYLE.DONE} Policy generated at ${CONFIG.POLICY_FILE}`);
    } catch (err) {
        console.error(`   ${STYLE.FAIL} Failed to write policy file:`, err.message);
        process.exit(1);
    }
}

generatePolicy();
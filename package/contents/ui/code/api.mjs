// @ts-check
// Minimal client for the Airthings Consumer API.
// Docs: https://consumer-api-doc.airthings.com/

const TOKEN_URL = "https://accounts-api.airthings.com/v1/token";
const API_URL = "https://consumer-api.airthings.com/v1";
const SCOPE = "read:device:current_values";

/** @typedef {{ status: number, message: string, auth?: boolean }} ApiError  status 0 = network error; auth = credentials rejected */
/** @typedef {{ id: string, name: string }} Account */
/** @typedef {{ serialNumber: string, name: string, type: string, sensors: string[] }} Device */
/** @typedef {{ sensorType: string, value: number, unit: string }} SensorReading */
/** @typedef {{ serialNumber: string, sensors: SensorReading[], recorded: string, batteryPercentage?: number }} LatestResult */

// Marks messages for extraction into the translation template; QML translates them with i18n().
/** @param {string} text */
const I18N_NOOP = text => text;

/**
 * @param {number} status
 * @param {string} message
 * @returns {ApiError}
 */
function apiError(status, message) {
    return { status, message };
}

/** @param {XMLHttpRequest} xhr */
function errorMessage(xhr) {
    if (xhr.status === 0) {
        return I18N_NOOP("Network error");
    }
    try {
        const body = JSON.parse(xhr.responseText);
        return body.message || body.error_description || body.error || xhr.statusText;
    } catch (e) {
        return xhr.statusText || "HTTP " + xhr.status;
    }
}

/**
 * Sends a request and resolves with the parsed JSON body, or rejects with an ApiError.
 * @param {string} method
 * @param {string} url
 * @param {Record<string, string>} headers
 * @param {string} [body]
 * @returns {Promise<any>}
 */
function send(method, url, headers, body) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== 4) {
                return;
            }
            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    resolve(JSON.parse(xhr.responseText));
                } catch (e) {
                    reject(apiError(xhr.status, I18N_NOOP("Invalid response from server")));
                }
            } else {
                reject(apiError(xhr.status, errorMessage(xhr)));
            }
        };
        xhr.open(method, url);
        for (const name of Object.keys(headers)) {
            xhr.setRequestHeader(name, headers[name]);
        }
        xhr.send(body);
    });
}

export class Client {
    /**
     * @param {string} clientId
     * @param {string} clientSecret
     */
    constructor(clientId, clientSecret) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.token = "";
        this.tokenExpiresAt = 0; // epoch ms
    }

    /**
     * Returns a cached access token, or requests a new one when it is about to expire.
     * @returns {Promise<string>}
     */
    accessToken() {
        if (this.token && Date.now() < this.tokenExpiresAt) {
            return Promise.resolve(this.token);
        }
        const body = JSON.stringify({
            grant_type: "client_credentials",
            client_id: this.clientId,
            client_secret: this.clientSecret,
            scope: [SCOPE],
        });
        return send("POST", TOKEN_URL, { "Content-Type": "application/json" }, body).then(
            (response) => {
                this.token = response.access_token;
                // Renew one minute early to avoid using a token that expires mid-request.
                this.tokenExpiresAt = Date.now() + (response.expires_in - 60) * 1000;
                return this.token;
            },
            (/** @type {ApiError} */ error) => {
                error.auth = error.status === 400 || error.status === 401 || error.status === 403;
                throw error;
            }
        );
    }

    /**
     * GET an API path. If the token is rejected, gets a new token and retries once.
     * @param {string} path
     * @returns {Promise<any>}
     */
    get(path) {
        return this.getOnce(path).catch((/** @type {ApiError} */ error) => {
            if (error.status !== 401 || error.auth) {
                throw error;
            }
            this.token = "";
            return this.getOnce(path);
        });
    }

    /**
     * @param {string} path
     * @returns {Promise<any>}
     */
    getOnce(path) {
        return this.accessToken().then((token) =>
            send("GET", API_URL + path, { Authorization: "Bearer " + token, Accept: "application/json" })
        );
    }

    /** @returns {Promise<Account[]>} */
    accounts() {
        return this.get("/accounts").then((response) => response.accounts || []);
    }

    /**
     * @param {string} accountId
     * @returns {Promise<Device[]>}
     */
    devices(accountId) {
        return this.get(`/accounts/${encodeURIComponent(accountId)}/devices`).then(
            (response) => response.devices || []
        );
    }

    /**
     * Latest readings of one device, or null if the API has none.
     * @param {string} accountId
     * @param {string} serial
     * @param {"metric" | "imperial"} unit
     * @returns {Promise<LatestResult | null>}
     */
    latest(accountId, serial, unit) {
        const path = `/accounts/${encodeURIComponent(accountId)}/sensors`
            + `?sn=${encodeURIComponent(serial)}&unit=${unit === "imperial" ? "imperial" : "metric"}`;
        return this.get(path).then((response) => {
            /** @type {LatestResult[]} */
            const results = response.results || [];
            return results.find((result) => result.serialNumber === serial) || null;
        });
    }
}

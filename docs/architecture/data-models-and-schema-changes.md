# Data Models and Schema Changes

## New Data Models

### AuthToken

-   [cite_start]**Purpose:** To store the OAuth access and refresh tokens[cite: 194].
-   [cite_start]**Integration:** This model will be used by the `AuthService` and `KeychainService`[cite: 195].
-   **Key Attributes:**
    -   [cite_start]`accessToken`: String - The OAuth access token[cite: 197].
    -   [cite_start]`refreshToken`: String - The OAuth refresh token[cite: 198].
    -   [cite_start]`expiresIn`: Date - The expiration date of the access token[cite: 199].
-   **Relationships:**
    -   [cite_start]**With Existing:** This model will replace the existing PAT stored in the `KeychainService`[cite: 201].
    -   [cite_start]**With New:** This model will be used by the new `AuthService`[cite: 202].

## Schema Integration Strategy

-   **Database Changes Required:**
    -   [cite_start]**New Tables:** None [cite: 205]
    -   [cite_start]**Modified Tables:** The `KeychainService` will be updated to store the `AuthToken` model instead of a PAT[cite: 206].
    -   [cite_start]**New Indexes:** None [cite: 207]
    -   [cite_start]**Migration Strategy:** A migration path for existing PATs will be provided[cite: 208]. [cite_start]Users will be prompted to re-authenticate using the new OAuth flow, and their existing PAT will be removed from the Keychain[cite: 209].
-   **Backward Compatibility:**
    -   The application will no longer support PAT-based authentication. [cite_start]Users will be required to use the new OAuth flow[cite: 211].

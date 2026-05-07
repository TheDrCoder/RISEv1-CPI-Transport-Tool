# API Migration Map

This document maps the current frontend calls in `public/script.js` to the legacy PowerShell backend in `legacy-powershell/server.ps1` and related helper scripts. It is an analysis-only migration guide; no application code was changed.

## Scope Inspected

- Frontend: `public/script.js`
- Primary backend: `legacy-powershell/server.ps1`
- Legacy helper/reference scripts:
  - `FunctionExtractManifest.ps1`
  - `Manifestextract.ps1`
  - `ModifyandArchiveManifest.ps1`
  - `Modular manifest Replacement function.ps1`
  - `Modular manifest Replacement functionv4.ps1`
  - `Server_Backup.ps1`
  - `Server_Backup_270225_v1.ps1`
  - `Server_originalWorkingtillStep2.ps1`
  - `sseServer.ps1`
  - `subscript.ps1`
  - `TestManifest andCompression.ps1`
  - `TestManifest andCompressionv2.ps1`
  - `upload artifact.ps1`
  - `uploadartifact.ps1`
  - `uploadv2.ps1`
  - `uploadv3.ps1`

## Backend Shape To Preserve Initially

The legacy backend listens on `http://localhost:9090/` using `System.Net.HttpListener`. Most frontend API calls use `POST /` and are routed by flags or fields in the JSON body. Dedicated POST endpoints also exist for reset, deployment status, abort, download, and a frontend-only `/deploy` call.

Important migration rule: the first Express implementation should keep port `9090` and preserve the current request and response formats so the existing frontend can continue to run unchanged.

## Frontend API Calls

| Frontend function or fetch call | Current endpoint URL | Request payload | Expected response | Matching PowerShell logic | Proposed Node.js route | Proposed Node.js service | Migration priority | Notes and risks |
|---|---|---|---|---|---|---|---|---|
| Step 1 credentials/package fetch, `fetch()` at `public/script.js:463` | `POST http://localhost:9090/` | JSON with `fetchPackages: true`, `selectedTenantType`, `sourceBaseUrl`, `sourceClientId`, `sourceClientSecret`, `sourceTokenUrl`, `targetBaseUrl`, `targetClientId`, `targetClientSecret`, `targetTokenUrl` | JSON object with `Status: "success"`, `sourcePackages: []`, `targetPackages: []` | `server.ps1` stores source/target credentials and tenant type, then `elseif($body.fetchPackages -eq $true)` calls `Fetch-IntegrationPackages` for source and target | `POST /` legacy-compatible; internally route to `POST /api/packages/fetch` later | `tenantSessionService`, `oauthTokenService`, `packageService` | P0 | Do not log `sourceClientSecret`, `targetClientSecret`, or access tokens. PowerShell currently logs some request/body information elsewhere; Node should redact secrets from all logs. |
| Step 2 artifact fetch, `fetch()` at `public/script.js:623` | `POST http://localhost:9090/` | JSON with `sourcePackageId`, `targetPackageId` | JSON object with `sourceArtifacts: []`, `targetArtifacts: []`; each artifact is expected to include `Id`, `Name`, `Version`, `DeployedOn`, `Status` | `if ($body.sourcePackageId -and $body.targetPackageId)` calls `Fetch-IntegrationArtifacts` for both packages, then calls `Fetch-ArtifactStatus` for each artifact | `POST /` legacy-compatible; internally route to `POST /api/artifacts/fetch` later | `artifactService`, `artifactStatusService`, `tenantSessionService` | P0 | Potentially slow because it fetches runtime status for every artifact synchronously. Cache semantics should be reproduced first, optimized later. |
| Step 3 ZIP export, `fetch()` at `public/script.js:875` | `POST http://localhost:9090/` | JSON with `fetchArtifactZip: true`, `sourceArtifactId`, `sourceArtifactVersion`, `targetArtifactId`, `targetArtifactVersion`, `targetArtifactName` | Frontend checks `data.Status === "success"` and stores `data.zipFilePath`, although backend does not return `zipFilePath` | `if ($body.fetchArtifactZip -eq $true)` calls `Export-Artifact` for source and target and sets global paths; then later the independent artifact-id branch can overwrite the response with manifest/config data | `POST /` legacy-compatible; internally route to `POST /api/artifacts/export-zips` later | `artifactExportService`, `zipWorkspaceService`, `tenantSessionService` | P0 | Legacy response likely gets overwritten because the next branch also matches `sourceArtifactId` and `targetArtifactId`. Preserve frontend success behavior first; document/fix response cleanup as a later logical change. |
| Step 3 manifest/config fetch helper `fetchManifestAndConfigs()`, `fetch()` at `public/script.js:827` | `POST http://localhost:9090/` | JSON with `fetchManifestAndConfigs: true`, `sourceArtifactId`, `sourceArtifactVersion`, `targetArtifactId`, `targetArtifactVersion` | JSON with `Status: "success"`, `sourceManifest`, `targetManifest`, `sourceConfigurations`, `targetConfigurations` | `elseif ($body.sourceArtifactId -and $body.targetArtifactId)` ignores the `fetchManifestAndConfigs` flag, calls `Extract-Manifest`, `Read-ManifestFile`, `Extract-ManifestValues`, and `Fetch-ArtifactConfigurations` | `POST /` legacy-compatible; internally route to `POST /api/artifacts/manifest-configs` later | `manifestService`, `configurationService`, `zipWorkspaceService` | P0 | Backend appears to read target manifest content from `$sourceManifestPath` instead of `$targetManifestPath`. Node migration should first match UI contract, then fix this with a targeted test. |
| Step 3 multiple deployment initiation, active `sendDeploymentRequest()`, `fetch()` at `public/script.js:1302` | `POST http://localhost:9090/` | JSON with `deployMultipleArtifacts: true`, `artifactPairs: [{ sourceArtifactId, sourceArtifactName, sourceArtifactVersion, targetArtifactId, targetArtifactName, targetArtifactVersion }]`; uses `keepalive: true` | Frontend does not wait for JSON in the active call; it only logs network failure. Legacy backend returns `{ status: "success", message: "Deployment Process Started" }` after processing | `elseif ($body.deployMultipleArtifacts -eq $true)` loops through pairs, backs up configs, exports zips, reads/modifies manifests, creates zip, uploads, deploys, updates `$global:DeploymentStatus` | `POST /` legacy-compatible; internally route to `POST /api/deployments/bulk` later | `bulkDeploymentService`, `deploymentStatusService`, `configurationBackupService`, `artifactExportService`, `manifestService`, `artifactUploadService`, `deploymentService` | P0 | Despite the message, current code processes inline, not truly backgrounded. Express must avoid request timeouts for long runs; use a job/status model while keeping the frontend-compatible immediate response. |
| Step 3 multiple deployment initiation, commented block, `fetch()` at `public/script.js:1004` | `POST http://localhost:9090/` | Same as multiple deployment payload above | Expected JSON with `status: "success"` | Same as active `deployMultipleArtifacts` branch | Same as active bulk deployment route | Same as active bulk deployment services | P3 | This call is inside a block comment and is inactive. Keep it in mind only when cleaning old frontend code later. |
| Step 4 multiple polling `fetchDeploymentStatus()`, `fetch()` at `public/script.js:1236` | `POST http://localhost:9090/deploymentStatus` | No JSON body | JSON object keyed by target artifact id, each `{ status, progress }`; may also contain `completed` | `if ($urlPath -eq "/deploymentStatus")` serializes `$global:DeploymentStatus` | `POST /deploymentStatus` legacy-compatible; internally route to `GET /api/deployments/status` later | `deploymentStatusService` | P0 | PowerShell path sets `$jsonResponse` but continues to parse body afterward; empty body can cause parse errors depending on flow. Node should return status immediately for this path. |
| Step 4 multiple abort, `fetch()` at `public/script.js:1340` | `POST http://localhost:9090/abortDeployment` | No JSON body | JSON `{ status: "aborted", message: "Deployment aborted by user." }` | `elseif ($urlPath -eq "/abortDeployment")` sets `$global:DeploymentStatus = @{ status = "..."; progress = 100 }` and returns aborted response | `POST /abortDeployment` legacy-compatible; internally route to `POST /api/deployments/abort` later | `deploymentStatusService`, `bulkDeploymentService` | P1 | Current PowerShell does not cancel an active long-running loop robustly; it mainly updates status. Node should have an abort flag/cancellation check between deployment stages. |
| Step 4 multiple original config download, `fetch()` at `public/script.js:1363` | `POST http://localhost:9090/downloadConfigs` | No JSON body | Blob download named `Original_Configurations.txt` | `elseif ($urlPath -eq "/downloadConfigs")` streams `$PSScriptRoot\Original_Configurations.txt`, or returns JSON error | `POST /downloadConfigs` legacy-compatible; internally route to `GET /api/deployments/config-backup` later | `configurationBackupService` | P1 | Must set compatible file headers. Missing file currently returns JSON even though frontend expects a blob. |
| Step 4 compile/modify manifest, `fetch()` at `public/script.js:1593` | `POST http://localhost:9090/` | JSON with `modifyManifestFile: true` | JSON with `Status: "success"` and message on success, or `Status: "error"` | `elseif ($body.modifyManifestFile -eq $true)` validates extracted paths, calls `Process-ManifestReplacement`, then `Create-Zip`, stores `$global:modifiedZipPath` | `POST /` legacy-compatible; internally route to `POST /api/artifacts/modify-manifest` later | `manifestService`, `zipWorkspaceService` | P0 | The legacy branch calls `Create-Zip -ExtractedPath $SourceExtractPath`, but `$SourceExtractPath` may be undefined in this scope. Verify behavior before porting exact implementation. |
| Step 4 upload modified artifact, chained `fetch()` at `public/script.js:1633` | `POST http://localhost:9090/` | JSON with `uploadArtifact: true` | JSON with `Status: "success"`, `Message`, `targetArtifactId`, `targetArtifactVersion` | `elseif ($body.uploadArtifact -eq $true)` calls `Upload-Artifact` using global `modifiedZipPath`, target artifact id/name/version, and target access token | `POST /` legacy-compatible; internally route to `POST /api/artifacts/upload` later | `artifactUploadService`, `tenantSessionService` | P0 | `Upload-Artifact` writes/logs request details and appears to write an undefined `$base64String` to a `.base64.txt` file. Node must never log base64 artifact content or tokens. |
| Step 5 deploy and configure, `fetch()` at `public/script.js:1703` | `POST http://localhost:9090/deploy` | No JSON body | Frontend expects JSON and alerts success unconditionally in `.then()` | No explicit `/deploy` handler found in `server.ps1`; likely falls through to JSON body parsing and fails for empty body | `POST /deploy` legacy-compatible; internally route to `POST /api/deployments/deploy-and-configure` later | `deploymentService`, `configurationApplyService` | P2 | This looks currently unimplemented or broken. Need decide intended behavior before Node migration. Could return a clear not-implemented JSON while preserving frontend compatibility, but that would change current behavior. |
| Step 5 deploy only, `fetch()` at `public/script.js:1749` | `POST http://localhost:9090/` | JSON with `deployArtifact: true`, `targetArtifactId`, `targetArtifactVersion` | JSON with `status: "success"` or `Status: "success"` and `message`; frontend accepts either case | `elseif ($body.deployArtifact -eq $true)` calls `Deploy-Artifact-CF` when tenant type is `cloudFoundry`, otherwise `Deploy-Artifact` | `POST /` legacy-compatible; internally route to `POST /api/deployments/deploy-only` later | `deploymentService`, `tenantSessionService` | P0 | Preserve both Neo and Cloud Foundry URL variants. Normalize response casing internally, but keep frontend-compatible casing. |
| Floating reset transport button, `fetch()` at `public/script.js:1880` | `POST http://localhost:9090/resetTransport` | No JSON body | JSON `{ status: "success", message: "Transport Reset Successfully!" }` | `if ($urlPath -eq "/resetTransport")` clears global credentials, tokens, caches, workspace path variables, and artifact variables | `POST /resetTransport` legacy-compatible; internally route to `POST /api/session/reset` later | `tenantSessionService`, `workspaceService`, `deploymentStatusService` | P0 | Should clear sensitive in-memory values and temporary workspace state. Avoid deleting legacy files or unrelated data. |

## Additional Backend Endpoints Found

| Endpoint | Current behavior | Frontend usage | Proposed Node.js handling |
|---|---|---|---|
| `GET /deployment.json` | Serves `legacy-powershell/deployment.json` if present, otherwise JSON 404 | No active `public/script.js` fetch found | Optional compatibility route if status file remains useful; prefer in-memory status plus optional persisted JSON |
| `GET /deploymentStatusStream` | Opens server-sent event stream and repeatedly calls `Send-Update` | No active `public/script.js` EventSource usage found | Defer unless SSE is reintroduced; polling endpoint is the active frontend path |
| `GET /stop` | Stops the PowerShell listener | No active frontend usage found | Do not expose by default in Node unless explicitly needed for local dev |
| Static file GETs | Serves files from the PowerShell script directory | Browser loads HTML/CSS/JS/assets | Express should serve `public/` as static assets |

## Proposed Service Boundaries

| Service | Responsibility | Legacy source logic |
|---|---|---|
| `tenantSessionService` | Store current source/target tenant config, tenant type, cached access tokens, and reset state | Global variables near top of `server.ps1`; credential storage in main loop |
| `oauthTokenService` | Fetch and cache OAuth client-credentials tokens without logging secrets/tokens | `Get-AccessToken` |
| `packageService` | Fetch CPI integration packages from source/target tenants | `Fetch-IntegrationPackages` |
| `artifactService` | Fetch design-time artifacts by package | `Fetch-IntegrationArtifacts` |
| `artifactStatusService` | Fetch runtime artifact status and deployed timestamp | `Fetch-ArtifactStatus` |
| `configurationService` | Fetch artifact configurable parameters | `Fetch-ArtifactConfigurations` |
| `artifactExportService` | Download CPI artifact ZIPs and prepare extracted workspace directories | `Export-Artifact` |
| `manifestService` | Locate/read/extract/replace manifest values | `Extract-Manifest`, `Read-ManifestFile`, `Extract-ManifestValues`, `Replace-ManifestValues`, `Process-ManifestReplacement` |
| `zipWorkspaceService` | Create modified ZIP archives and manage temporary ZIP/extract paths | `Create-Zip`, ZIP path globals |
| `artifactUploadService` | Base64 encode modified ZIP and PUT to CPI target design-time artifact endpoint | `Upload-Artifact` |
| `deploymentService` | Deploy target artifacts for Neo and Cloud Foundry tenants | `Deploy-Artifact`, `Deploy-Artifact-CF` |
| `bulkDeploymentService` | Orchestrate multi-artifact transport jobs | `deployMultipleArtifacts` branch in main loop |
| `deploymentStatusService` | Track progress by target artifact id, expose polling response, support abort | `$global:DeploymentStatus`, `Send-Update`, `/deploymentStatus`, `/abortDeployment` |
| `configurationBackupService` | Write and stream original source/target configuration backups | `Original_Configurations.txt` writes and `/downloadConfigs` |
| `workspaceService` | Create/clear transport working directories under Node-controlled data root | PowerShell `CPITransportTool_Data`, `ZIPs`, `Extracted` setup |

## Migration Order Recommendation

1. Express shell on port `9090`, static `public/` serving, JSON parsing, and legacy-compatible route dispatcher for `POST /`.
2. Session/token/package fetch: `fetchPackages`.
3. Artifact listing and artifact runtime status enrichment.
4. ZIP export plus manifest/config fetch, preserving current frontend response expectations.
5. Single-artifact modify/upload/deploy-only flow.
6. Reset endpoint and workspace cleanup.
7. Multiple-artifact deployment job model, status polling, abort, and config download.
8. Investigate `/deploy` deploy-and-configure behavior separately, because no matching PowerShell implementation was found.

## Cross-Cutting Risks

- Secrets and tokens: Node logs must redact client secrets, bearer tokens, OAuth responses, and base64 artifact content.
- Stateful globals: PowerShell uses process-wide globals. Node should introduce an explicit session/state object while preserving the single-user local-tool assumption initially.
- Long-running requests: multi-deploy should become a background job with polling, but the frontend currently sends a `keepalive` request and polls status separately.
- Response casing: frontend checks both `Status` and `status` in places. Preserve existing casing per endpoint until the frontend is migrated.
- Legacy bugs: several branches appear to have variable-scope or response-overwrite issues. Fix them only as separate logical changes with tests or manual verification.
- File paths: legacy writes under `CPITransportTool_Data` beside PowerShell scripts. Node should use a controlled data directory and avoid touching `legacy-powershell/` except for read-only reference.

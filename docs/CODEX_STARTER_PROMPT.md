# Codex Starter Prompt for RISEv1 CPI Transport Tool

I have an existing SAP CPI Transport Tool that has now been copied into this Node.js migration workspace.

Current structure:

- Existing frontend files are in:
  public/

- Old PowerShell backend files are in:
  legacy-powershell/

- Old data/config/zip/json/xml files are in:
  legacy-data/

- New Node.js backend should be built in:
  server/

Goal:
Migrate the backend from PowerShell to Node.js + Express while keeping the existing frontend initially.

Important rules:
1. Do not rewrite the frontend yet.
2. Do not delete legacy PowerShell files.
3. First inspect public/script.js and legacy-powershell/server.ps1.
4. Identify every frontend API call.
5. Match each frontend API call to the old PowerShell backend logic.
6. Create Node.js routes and services gradually.
7. Preserve frontend-compatible request and response formats.
8. Do not log CPI client secrets or access tokens.
9. Keep port 9090.
10. Make only one logical change at a time.

First task:
Inspect public/script.js and all files inside legacy-powershell/.

Then create docs/API_MIGRATION_MAP.md with:

- Frontend function or fetch call
- Current endpoint URL
- Request payload
- Expected response
- Matching PowerShell logic
- Proposed Node.js route
- Proposed Node.js service
- Migration priority
- Notes and risks

Do not modify application code in the first step. Only analyze and document.

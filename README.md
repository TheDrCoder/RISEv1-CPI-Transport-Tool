# RISEv1 CPI Transport Tool

This is the Node.js migration workspace for the existing SAP CPI Transport Tool.

## Original Tool Location

```
D:\RunITSimple\Downloads\CPi Transport Tool\CPi Transport Tool
```

## New Node.js Tool Location

```
D:\RunITSimple\Downloads\RISEv1
```

## Folder Structure

```
RISEv1/
├─ public/
│  └─ Existing HTML/CSS/JS frontend files
│
├─ server/
│  ├─ app.js
│  ├─ routes/
│  ├─ services/
│  ├─ utils/
│  └─ storage/
│
├─ legacy-powershell/
│  └─ Old PowerShell scripts
│
├─ legacy-data/
│  └─ Old data/config/zip/json/xml files
│
├─ docs/
│  └─ Codex instructions and migration notes
│
├─ .env
├─ package.json
└─ README.md
```

## First Run

Open this folder in VS Code:

```
D:\RunITSimple\Downloads\RISEv1
```

Then run:

```
npm install
npm run dev
```

Open:

```
http://localhost:9090
```

Health check:

```
http://localhost:9090/health
```

## Migration Strategy

1. Keep old frontend initially.
2. Replace PowerShell backend with Node.js + Express route by route.
3. Use Codex to inspect `legacy-powershell/server.ps1` and `public/script.js`.
4. Create matching Node.js APIs.
5. Only after backend migration, modernize frontend if required.

document.addEventListener("DOMContentLoaded", function() {
    console.log("JavaScript Loaded");

    // =============================
    // ✅ Modal Handling for Configuration Modals
    // =============================
    const saveConfigModal = document.getElementById("saveConfigModal");
    const loadConfigModal = document.getElementById("loadConfigModal");
    const saveConfigBtn = document.getElementById("saveConfigBtn");
    const loadConfigBtn = document.getElementById("loadConfigBtn");
    const saveConfigConfirm = document.getElementById("saveConfigConfirm");
    const fetchConfigBtn = document.getElementById("fetchConfigBtn");
    const deleteConfigBtn = document.getElementById("deleteConfigBtn");
    const configList = document.getElementById("configList");
    const closeModalButtons = document.querySelectorAll(".close");
    const Step1to2 = document.getElementById("nextStep1");
    // Modal Elements
    const aboutModal = document.getElementById("aboutModal");
    const instructionsModal = document.getElementById("instructionsModal");
    const releaseNotesModal = document.getElementById("releaseNotesModal");
    const closeButtons = document.querySelectorAll(".close");
    // ✅ Ensure Buttons Exist Before Adding Event Listeners
    const prevStep2 = document.getElementById("prevStep2");
    const nextStep2 = document.getElementById("nextStep2");
    const clearTestDataBtn = document.getElementById("clearTestDataBtn");

    //Step 3 buttons

    const singleIflowBtn = document.getElementById("singleIflowDeployment");
    const multipleIflowBtn = document.getElementById("multipleIflowDeployment");
    const deploymentContainer = document.querySelector(".deployment-container");
    const artifactSelection = document.getElementById("artifactSelection");

    const singleIflowSection = document.getElementById("singleIflowSelection");
    const multipleIflowSection = document.getElementById("multipleIflowSelection");

    const nextSingleIflowBtn = document.getElementById("nextSingleIflow");
    const nextMultipleIflowBtn = document.getElementById("nextMultipleIflow");
    const prevIflowBtnStep3 = document.getElementById("prevStep3");

    // =============================
    // ✅ Function to Load Available Configurations
    // =============================
    function loadAvailableConfigs() {
        configList.innerHTML = ""; // Clear previous list

        let storedConfigs = JSON.parse(localStorage.getItem("savedConfigs")) || [];

        if (storedConfigs.length === 0) {
            configList.innerHTML = "<p>No saved configurations found.</p>";
            return;
        }

        storedConfigs.forEach((config, index) => {
            let listItem = document.createElement("li");
            listItem.textContent = config.name;
            listItem.classList.add("config-item");
            listItem.dataset.index = index;
            listItem.addEventListener("click", function() {
                document.querySelectorAll(".config-item").forEach(item => item.classList.remove("selected"));
                listItem.classList.add("selected");
            });
            configList.appendChild(listItem);
        });
    }

    // Function to navigate to next step

    function goToNextStep(nextStep) {
        window.location.href = nextStep;
    }

    // Function to persist user input across pages
    function saveData() {
        document.querySelectorAll("input, select").forEach(input => {
            if (input.type === "radio") {
                if (input.checked) {
                    localStorage.setItem(input.name, input.value);
                }
            } else {
                localStorage.setItem(input.id, input.value);
            }
        });
    }

    // Function to restore saved values on page load
    // ✅ Function to restore saved values on page load
    function restoreData() {
        document.querySelectorAll("input, select").forEach(input => {
            if (input.type === "radio") {
                let storedValue = localStorage.getItem(input.name);
                if (storedValue && input.value === storedValue) {
                    input.checked = true;
                }
            } else {
                if (localStorage.getItem(input.id)) {
                    input.value = localStorage.getItem(input.id);
                }
            }
        });
    }
    // Function to Generate Dummy Rows for packages
    function generateTestData(tableBody, type) {
        for (let i = 1; i <= 15; i++) { // Generates 15 rows (only 10 visible)
            let row = document.createElement("tr");
            row.innerHTML = `
                <td><input type="radio" name="${type}Package" data-id="${type}-pkg-${i}" data-name="Long names 1234 Tets Nineeshu_Suite_Replication_LongName  ${i}" data-version="1.0${i}"></td>
                <td>${i}</td>
                <td>Long names 1234 Tets Nineeshu_Suite_Replication_LongName ${i}</td>
                <td>1.0${i}</td>
            `;
            tableBody.appendChild(row);
        }
    }

    // ✅ Function to Generate Dummy Rows for Artifacts
    function generateTestDataArtifacts(tableBody, type) {
        if (!tableBody) {
            console.warn(`⚠️ Table body for ${type} not found.`);
            return;
        }

        for (let i = 1; i <= 15; i++) { // Generates 15 rows (only 10 visible)
            let row = document.createElement("tr");
            row.innerHTML = `
            <td><input type="radio" name="${type}Artifact" data-id="${type}-artifact-${i}" data-name="Artifact Long names 1234 Tets Nineeshu_Suite_Replication_LongName${i}" 
                       data-version="1.0${i}"></td>
            <td>${i}</td>
            <td>Artifact Long names 1234 Tets Nineeshu_Suite_Replication_LongName ${i}</td>
            <td>1.0${i}</td>
            <td>01-02-25</td> <!-- ✅ Removed Unnecessary Quotes -->
            <td>Active</td>   
        `;


            tableBody.appendChild(row);
        }

        console.log(`✅ Test Data Added for ${type} Artifacts`);
    }

    // ** Functions: 2️⃣ Show & Hide Loading Popup (Packages) **
    // ✅ Dynamically Inject Loading Popup into All Pages
    const loadingPopup = document.createElement("div");
    loadingPopup.id = "loadingPopup";
    loadingPopup.style.display = "none";
    loadingPopup.innerHTML = `
        <div style="
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            font-size: 18px;
            z-index: 1000;">
            ⏳ Loading... Please Wait
        </div>
    `;
    document.body.appendChild(loadingPopup);

    // ✅ Show Loading Popup
    function showLoadingPopup() {
        document.getElementById("loadingPopup").style.display = "block";
        console.log("⏳ Showing loading popup...");
    }

    // ✅ Hide Loading Popup
    function hideLoadingPopup() {
        document.getElementById("loadingPopup").style.display = "none";
        console.log("✅ Hiding loading popup...");
    }

    // ✅ Attach Loading Popup Functions to Global Scope (So They Can Be Used Anywhere)
    window.showLoadingPopup = showLoadingPopup;
    window.hideLoadingPopup = hideLoadingPopup;



    //INDEX STEP
    // Open About Modal
    document.getElementById("aboutBtn")?.addEventListener("click", function() {
        aboutModal.style.display = "block";
    });

    // Open Instructions Modal
    document.getElementById("instructionsBtn")?.addEventListener("click", function() {
        instructionsModal.style.display = "block";
    });
    // Open Release Notes Modal
    document.getElementById("releaseNotesBtn")?.addEventListener("click", function() {
        releaseNotesModal.style.display = "block";
    });

    // Close Modal on Clicking "X"
    closeButtons.forEach(button => {
        button.addEventListener("click", function() {
            aboutModal.style.display = "none";
            instructionsModal.style.display = "none";
            releaseNotesModal.style.display = "none";

        });
    });

    // Close Modal When Clicking Outside
    window.addEventListener("click", function(event) {
        if (event.target === aboutModal) {
            aboutModal.style.display = "none";
        }
        if (event.target === instructionsModal) {
            instructionsModal.style.display = "none";
        }
        if (event.target === releaseNotesModal) {
            releaseNotesModal.style.display = "none";
        }
    });
    // Go to Step 1
    document.getElementById("startBtn")?.addEventListener("click", function() {
        goToNextStep("step1.html");
    });




    /*
    // =============================
    // ✅ Restore Selected Package When Returning to Step 2
    // =============================
    let storedSource = JSON.parse(localStorage.getItem("selectedSourcePackage"));
    let storedTarget = JSON.parse(localStorage.getItem("selectedTargetPackage"));

    if (storedSource) {
        document.querySelector(`input[name="sourcePackage"][data-id="${storedSource.id}"]`)?.setAttribute("checked", true);
    }

    if (storedTarget) {
        document.querySelector(`input[name="targetPackage"][data-id="${storedTarget.id}"]`)?.setAttribute("checked", true);
    }

    */




    //STEP-1
    // =============================
    // ✅ Switch Source & Target Details
    // =============================
    document.getElementById("switchValuesBtn")?.addEventListener("click", function() {
        console.log("🔄 Swapping Source and Target Values...");

        // Get Current Values
        let sourceBaseUrl = document.getElementById("sourceBaseUrl").value;
        let sourceClientId = document.getElementById("sourceClientId").value;
        let sourceClientSecret = document.getElementById("sourceClientSecret").value;
        let sourceTokenUrl = document.getElementById("sourceTokenUrl").value;

        let targetBaseUrl = document.getElementById("targetBaseUrl").value;
        let targetClientId = document.getElementById("targetClientId").value;
        let targetClientSecret = document.getElementById("targetClientSecret").value;
        let targetTokenUrl = document.getElementById("targetTokenUrl").value;

        // Swap Values
        document.getElementById("sourceBaseUrl").value = targetBaseUrl;
        document.getElementById("sourceClientId").value = targetClientId;
        document.getElementById("sourceClientSecret").value = targetClientSecret;
        document.getElementById("sourceTokenUrl").value = targetTokenUrl;

        document.getElementById("targetBaseUrl").value = sourceBaseUrl;
        document.getElementById("targetClientId").value = sourceClientId;
        document.getElementById("targetClientSecret").value = sourceClientSecret;
        document.getElementById("targetTokenUrl").value = sourceTokenUrl;

        console.log("✅ Source & Target Values Swapped!");
    });

    // ✅ Open "Save Configuration" Modal
    saveConfigBtn?.addEventListener("click", function() {
        saveConfigModal.style.display = "block";
    });

    // ✅ Open "Load Configuration" Modal
    loadConfigBtn?.addEventListener("click", function() {
        loadConfigModal.style.display = "block";
        loadAvailableConfigs(); // Dynamically load configurations when modal opens
    });

    // ✅ Close Modals on Clicking "X"
    closeModalButtons.forEach(button => {
        button.addEventListener("click", function() {
            saveConfigModal.style.display = "none";
            loadConfigModal.style.display = "none";
        });
    });

    // ✅ Close Modals When Clicking Outside
    window.addEventListener("click", function(event) {
        if (event.target === saveConfigModal) {
            saveConfigModal.style.display = "none";
        }
        if (event.target === loadConfigModal) {
            loadConfigModal.style.display = "none";
        }
    });


    // =============================
    // ✅  Save a New Configuration
    // =============================
    saveConfigConfirm?.addEventListener("click", function() {
        let configName = document.getElementById("configName").value.trim();

        if (!configName) {
            alert("⚠️ Please enter a configuration name.");
            return;
        }

        let configData = {
            name: configName,
            selectedtenantType: document.querySelector('input[name="tenantType"]:checked').value,
            sourceBaseUrl: document.getElementById("sourceBaseUrl")?.value,
            sourceClientId: document.getElementById("sourceClientId")?.value,
            sourceClientSecret: document.getElementById("sourceClientSecret")?.value,
            sourceTokenUrl: document.getElementById("sourceTokenUrl")?.value,
            targetBaseUrl: document.getElementById("targetBaseUrl")?.value,
            targetClientId: document.getElementById("targetClientId")?.value,
            targetClientSecret: document.getElementById("targetClientSecret")?.value,
            targetTokenUrl: document.getElementById("targetTokenUrl")?.value
        };

        let storedConfigs = JSON.parse(localStorage.getItem("savedConfigs")) || [];
        storedConfigs.push(configData);
        localStorage.setItem("savedConfigs", JSON.stringify(storedConfigs));

        alert("✅ Configuration saved successfully!");
        saveConfigModal.style.display = "none";
    });



    // =============================
    // ✅ Open Available Configurations"
    // =============================
    // ✅ Ensure config selection is visible
    document.querySelectorAll(".config-item").forEach(item => {
        item.addEventListener("click", function() {
            document.querySelectorAll(".config-item").forEach(i => i.classList.remove("selected"));
            item.classList.add("selected");
        });
    });

    // =============================
    // ✅ Delete Selected Configuration
    // =============================
    deleteConfigBtn?.addEventListener("click", function() {
        let selectedConfig = document.querySelector(".config-item.selected");

        if (!selectedConfig) {
            alert("⚠️ Please select a configuration to delete.");
            return;
        }

        let storedConfigs = JSON.parse(localStorage.getItem("savedConfigs")) || [];
        let selectedIndex = selectedConfig.dataset.index;

        if (confirm("🗑 Are you sure you want to delete this configuration?")) {
            storedConfigs.splice(selectedIndex, 1);
            localStorage.setItem("savedConfigs", JSON.stringify(storedConfigs));

            alert("✅ Configuration deleted successfully!");
            loadAvailableConfigs(); // Reload the list after deletion
        }
    });
    // =============================
    // ✅ Load Selected Configuration
    // =============================
    fetchConfigBtn?.addEventListener("click", function() {
        let selectedConfig = document.querySelector(".config-item.selected");

        if (!selectedConfig) {
            alert("⚠️ Please select a configuration to load.");
            return;
        }

        let storedConfigs = JSON.parse(localStorage.getItem("savedConfigs")) || [];
        let selectedIndex = selectedConfig.dataset.index;
        let selectedData = storedConfigs[selectedIndex];

        if (selectedData) {
            // ✅ Select the correct tenant type radio button
            if (selectedData.selectedtenantType) {
                let tenantRadio = document.querySelector(`input[name="tenantType"][value="${selectedData.selectedtenantType}"]`);
                if (tenantRadio) {
                    tenantRadio.checked = true; // ✅ Correct way to set selected radio button
                } else {
                    console.warn("⚠️ No matching tenant type radio button found.");
                }
            }
            document.getElementById("sourceBaseUrl").value = selectedData.sourceBaseUrl || "";
            document.getElementById("sourceClientId").value = selectedData.sourceClientId || "";
            document.getElementById("sourceClientSecret").value = selectedData.sourceClientSecret || "";
            document.getElementById("sourceTokenUrl").value = selectedData.sourceTokenUrl || "";
            document.getElementById("targetBaseUrl").value = selectedData.targetBaseUrl || "";
            document.getElementById("targetClientId").value = selectedData.targetClientId || "";
            document.getElementById("targetClientSecret").value = selectedData.targetClientSecret || "";
            document.getElementById("targetTokenUrl").value = selectedData.targetTokenUrl || "";

            alert("✅ Configuration loaded successfully!");
            loadConfigModal.style.display = "none";
        }
    });

    try {
        localStorage.setItem("test", "value");
        console.log("✅ localStorage is accessible.");
    } catch (error) {
        console.error("❌ localStorage is blocked!", error);
    }
    //STEP 1 - Events
    Step1to2?.addEventListener("click", function() {
        console.log("✅ Clicked step 1");
        saveData();
        let selectedTenant = document.querySelector('input[name="tenantType"]:checked');

        if (!selectedTenant) {
            alert("⚠️ Please select a Tenant Type (Neo or Cloud Foundry) before proceeding.");
            return;
        }

        console.log("✅ Selected Tenant Type:", selectedTenant.value);


        // Collect user input values
        let requestData = {
            fetchPackages: true,
            selectedTenantType: document.querySelector('input[name="tenantType"]:checked').value.trim(),
            sourceBaseUrl: document.getElementById("sourceBaseUrl").value.trim(),
            sourceClientId: document.getElementById("sourceClientId").value.trim(),
            sourceClientSecret: document.getElementById("sourceClientSecret").value.trim(),
            sourceTokenUrl: document.getElementById("sourceTokenUrl").value.trim(),
            targetBaseUrl: document.getElementById("targetBaseUrl").value.trim(),
            targetClientId: document.getElementById("targetClientId").value.trim(),
            targetClientSecret: document.getElementById("targetClientSecret").value.trim(),
            targetTokenUrl: document.getElementById("targetTokenUrl").value.trim()
        };
        // ✅ Input Validation - Check for Empty Fields
        for (let key in requestData) {
            if (!requestData[key]) {
                alert("⚠️ Please fill in all fields before proceeding.");
                console.error(`❌ Missing field: ${key}`);
                return;
            }
        }


        // Show loading indicator (optional)
        showLoadingPopup();

        // Send Data to PowerShell Server
        fetch("http://localhost:9090/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.text())
            .then(text => {
                console.log("🔍 Raw Response from PowerShell:", text);

                let data;
                try {
                    data = JSON.parse(text); // Try to parse as JSON
                    console.log("✅ Parsed JSON Data:", data);
                } catch (error) {
                    console.warn("⚠️ Response is not valid JSON, returning as plain text.");
                    data = text;
                }

                if (typeof data === "string") {
                    alert("⚠️ Unexpected response format received. Check the backend logs.");
                    return;
                }

                // ✅ Handle valid JSON response
                if (!data || !data.sourcePackages || !data.targetPackages) {
                    console.warn("⚠️ API returned an empty response.");
                    alert("⚠️ No integration packages found.");
                    return;
                }

                // ✅ Retrieve Existing Stored Packages from Local Storage
                let storedPackages = JSON.parse(localStorage.getItem("storedPackages")) || {};

                // ✅ Store Packages Directly Without Nesting
                localStorage.setItem("sourcePackages", JSON.stringify(data.sourcePackages));
                localStorage.setItem("targetPackages", JSON.stringify(data.targetPackages));

                console.log("✅ Stored Source Packages:", data.sourcePackages);
                console.log("✅ Stored Target Packages:", data.targetPackages);


                hideLoadingPopup();
                goToNextStep("step2.html");
            })
            .catch(error => {
                console.error("❌ Error fetching integration packages:", error);
                hideLoadingPopup();
                alert("⚠ Error fetching packages. Check console.");
            });

    });




    //STEP-2
    // ✅ Check if the user is on "step2.html" before running table logic

    if (window.location.pathname.includes("step2.html")) {
        console.log("✅ Detected Step 2 - Fetching Stored Packages...");


        // ✅ Retrieve Stored Packages from Local Storage
        let storedSourcePackages = JSON.parse(localStorage.getItem("sourcePackages")) || [];
        let storedTargetPackages = JSON.parse(localStorage.getItem("targetPackages")) || [];

        console.log("📦 Retrieved Source Packages:", storedSourcePackages);
        console.log("📦 Retrieved Target Packages:", storedTargetPackages);


        // ✅ Function to Populate Package Tables
        function populatePackagesTable(packages, tableId) {
            let tableBody = document.querySelector(`#${tableId} tbody`);
            if (!tableBody) {
                console.error(`❌ Table not found: ${tableId}`);
                return;
            }

            tableBody.innerHTML = ""; // Clear existing rows

            if (packages.length === 0) {
                console.warn(`⚠️ No packages found for table: ${tableId}`);
                tableBody.innerHTML = `<tr><td colspan="4">No packages available.</td></tr>`;
                return;
            }

            packages.forEach((pkg, index) => {
                let row = `
                <tr>
                    <td><input type="radio" name="${tableId}-selection" data-id="${pkg.Id}" data-name="${pkg.Name}" data-version="${pkg.Version}"></td>
                    <td>${index + 1}</td>
                    <td>${pkg.Name}</td>
                    <td>${pkg.Version}</td>
                </tr>
            `;
                tableBody.innerHTML += row;
            });

            console.log(`✅ Populated ${tableId} with ${packages.length} packages.`);
        }

        // ✅ Populate Source and Target Package Tables
        populatePackagesTable(storedSourcePackages, "sourcePackagesTable");
        populatePackagesTable(storedTargetPackages, "targetPackagesTable");
    }
    if (prevStep2) {
        console.log("✅ prevStep2 Button Found");
        prevStep2.addEventListener("click", function() {
            console.log("🔄 Navigating to Step 1...");
            goToNextStep("step1.html");
        });
    } else {
        console.warn("⚠️ prevStep2 button not found.");
    }
    document.getElementById("nextStep2")?.addEventListener("click", function() {
        console.log("➡ Next button clicked in Step 2...");

        saveData(); // ✅ Save input data to Local Storage

        // ✅ Get Selected Source & Target Package
        let selectedSourcePackage = document.querySelector('input[name="sourcePackagesTable-selection"]:checked');
        let selectedTargetPackage = document.querySelector('input[name="targetPackagesTable-selection"]:checked');

        console.log("🎯 Selected Source Element:", selectedSourcePackage);
        console.log("🎯 Selected Target Element:", selectedTargetPackage);

        if (!selectedSourcePackage || !selectedTargetPackage) {
            alert("🚨 Please select one Source and one Target package.");
            console.error("❌ Package Selection Error: One or both packages not selected.");
            return;
        }

        let sourcePackageId = selectedSourcePackage.dataset.id;
        let targetPackageId = selectedTargetPackage.dataset.id;
        let sourcePackageName = selectedSourcePackage.dataset.name;
        let targetPackageName = selectedTargetPackage.dataset.name;

        console.log("✅ Selected Source Package ID:", sourcePackageId, "| Name:", sourcePackageName);
        console.log("✅ Selected Target Package ID:", targetPackageId, "| Name:", targetPackageName);
        // ✅ Save Selected Packages in Local Storage for Step 3
        // ✅ Store Selected Package IDs for Retrieval in Step 3
        localStorage.setItem("selectedSourcePackageId", sourcePackageId);
        localStorage.setItem("selectedTargetPackageId", targetPackageId);



        // ✅ Prepare Data to Send to PowerShell
        let requestData = {
            sourcePackageId: sourcePackageId,
            targetPackageId: targetPackageId
        };

        console.log("📡 Sending Request to PowerShell for Artifacts:", requestData);

        // ✅ Show "Fetching Artifacts" Popup
        showLoadingPopup();

        // ✅ Send Request to PowerShell Server
        fetch("http://localhost:9090/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.json())
            .then(data => {
                console.log("✅ Response received from PowerShell:", data);
                hideLoadingPopup();

                // ✅ Ensure Valid Response
                if (!data || !Array.isArray(data.sourceArtifacts) || !Array.isArray(data.targetArtifacts)) {
                    console.warn("⚠️ API returned an empty or invalid response.");
                    alert("⚠️ No integration artifacts found. Check SAP CPI credentials.");
                    return;
                }

                if (data.sourceArtifacts.length === 0 || data.targetArtifacts.length === 0) {
                    console.warn("⚠️ No artifacts found for selected packages.");
                    alert("⚠️ No artifacts found in selected packages.");
                    return;
                }

                console.log("🔍 Debug: Source Artifacts Received:", data.sourceArtifacts);
                console.log("🔍 Debug: Target Artifacts Received:", data.targetArtifacts);

                // ✅ Store Artifacts Directly for Easy Access
                localStorage.setItem("sourceArtifacts", JSON.stringify(data.sourceArtifacts));
                localStorage.setItem("targetArtifacts", JSON.stringify(data.targetArtifacts));

                console.log("✅ Stored Source Artifacts:", data.sourceArtifacts);
                console.log("✅ Stored Target Artifacts:", data.targetArtifacts);



                // ✅ Proceed to Step 3
                goToNextStep("step3.html");
            })
            .catch(error => {
                console.error("❌ Error fetching artifacts:", error);
                hideLoadingPopup();
                alert("⚠ Error fetching artifacts. Check console.");
            });
    });
    //Step for returning to Step 1
    document.getElementById("prevStep2")?.addEventListener("click", function() {
        goToNextStep("step1.html");
    });
    //Clear test data for table
    if (clearTestDataBtn) {
        console.log("✅ clearTestDataBtn Button Found");
        clearTestDataBtn.addEventListener("click", function() {
            document.querySelector("#sourcePackagesTable tbody").innerHTML = "";
            document.querySelector("#targetPackagesTable tbody").innerHTML = "";
            console.log("🚮 Test Data Cleared");
            alert("✅ Test Data has been cleared.");
        });
    } else {
        console.warn("⚠️ clearTestDataBtn button not found.");
    }
    // =============================
    // ✅ Clear Test Data from Tables
    // =============================
    document.getElementById("clearTestDataBtn")?.addEventListener("click", function() {
        document.querySelector("#sourcePackagesTable tbody").innerHTML = "";
        document.querySelector("#targetPackagesTable tbody").innerHTML = "";
        console.log("🚮 Test Data Cleared");
    });




    //STEP-3
    // ✅ Check if the user is on "step3.html" before running table logic
    if (window.location.pathname.includes("step3.html")) {
        console.log("✅ Detected Step 3 - Initializing Package Tables");
        // =============================
        // ✅ Generated Table data
        // =============================
        let sourceTableBody = document.querySelector("#sourceArtifactsTable tbody");
        let targetTableBody = document.querySelector("#targetArtifactsTable tbody");

        // ✅ Retrieve Selected Packages
        let selectedSourcePackageId = localStorage.getItem("selectedSourcePackageId");
        let selectedTargetPackageId = localStorage.getItem("selectedTargetPackageId");

        // ✅ Retrieve Artifacts
        let sourceArtifacts = JSON.parse(localStorage.getItem("sourceArtifacts")) || [];
        let targetArtifacts = JSON.parse(localStorage.getItem("targetArtifacts")) || [];

        console.log("✅ Retrieved Source Package ID:", selectedSourcePackageId);
        console.log("✅ Retrieved Target Package ID:", selectedTargetPackageId);
        console.log("✅ Retrieved Source Artifacts:", sourceArtifacts);
        console.log("✅ Retrieved Target Artifacts:", targetArtifacts);

        // ✅ Ensure Artifacts Exist Before Proceeding
        if (sourceArtifacts.length === 0 || targetArtifacts.length === 0) {
            console.warn("⚠️ No artifacts found in storage.");
            alert("⚠️ Please complete Step 2 first.");
            goToNextStep("step2.html");
            return;
        }
        // ✅ Populate Artifacts Table
        function populateArtifactsTable(artifacts, tableId) {
            let tableBody = document.querySelector(`#${tableId} tbody`);
            tableBody.innerHTML = "";

            artifacts.forEach((artifact, index) => {
                let row = `
                <tr>
                    <td><input type="radio" name="${tableId}-selection" data-id="${artifact.Id}" data-name="${artifact.Name}" data-version="${artifact.Version}"></td>
                    <td>${index + 1}</td>
                    <td>${artifact.Name}</td>
                    <td>${artifact.Version}</td>
                    <td>${artifact.DeployedOn || "N/A"}</td>
                    <td>${artifact.Status || "Unknown"}</td>
                </tr>
            `;
                tableBody.innerHTML += row;
            });
        }

        // ✅ Populate Tables for Source & Target
        populateArtifactsTable(sourceArtifacts, "sourceArtifactsTable");
        populateArtifactsTable(targetArtifacts, "targetArtifactsTable");

        console.log("✅ Artifacts Table Populated Successfully.");

    }
    // ✅ Hide deployment selection and show Single IFlow selection
    singleIflowBtn?.addEventListener("click", function() {
        deploymentContainer.style.display = "none"; // Hide selection buttons
        singleIflowSelection.style.display = "block"; // Show radio button table
        // Show correct buttons
        nextSingleIflowBtn.style.display = "inline-block";
        nextMultipleIflowBtn.style.display = "none";
        prevIflowBtnStep3.style.display = "inline-block";
    });

    // ✅ Hide deployment selection and show Multiple IFlow selection
    multipleIflowBtn?.addEventListener("click", function() {
        /*
        deploymentContainer.style.display = "none"; // Hide selection buttons
        multipleIflowSelection.style.display = "block"; // Show checkbox table
        // Show correct buttons
        nextMultipleIflowBtn.style.display = "inline-block";
        nextSingleIflowBtn.style.display = "none";
        prevIflowBtnStep3.style.display = "inline-block";
        */
        goToNextStep("step3_multiple.html");
    });
    //Go back to Step 2
    document.getElementById("prevStep3")?.addEventListener("click", function() {
        goToNextStep("step2.html");
    });
    //Single iflow Step 4 
    document.getElementById("nextSingleIflow")?.addEventListener("click", function() {
        console.log("🔍 Checking Selected Artifacts...");

        let selectedArtifact = document.querySelector('input[name="sourceArtifactsTable-selection"]:checked');
        let selectedTargetArtifact = document.querySelector('input[name="targetArtifactsTable-selection"]:checked');

        console.log("🎯 Selected Source Artifact:", selectedArtifact);
        console.log("🎯 Selected Target Artifact:", selectedTargetArtifact);

        // ✅ Check if artifacts are selected
        if (!selectedArtifact || !selectedTargetArtifact) {
            alert("⚠️ Please select one artifact from both Source and Target before proceeding.");
            console.error("❌ Artifact Selection Error: One or both artifacts are not selected.");
            return;
        }

        let sourceArtifactId = selectedArtifact.dataset.id;
        let targetArtifactId = selectedTargetArtifact.dataset.id;
        let sourceArtifactName = selectedArtifact.dataset.name;
        let targetArtifactName = selectedTargetArtifact.dataset.name;
        let sourceArtifactVersion = selectedArtifact.dataset.version;
        let targetArtifactVersion = selectedTargetArtifact.dataset.version;

        console.log("✅ Selected Source Artifact ID:", sourceArtifactId, "| Name:", sourceArtifactName, "| Version:", sourceArtifactVersion);
        console.log("✅ Selected Target Artifact ID:", targetArtifactId, "| Name:", targetArtifactName, "| Version:", targetArtifactVersion);

        // ✅ Store Artifacts in Local Storage for Step 4
        localStorage.setItem("selectedSourceArtifactId", sourceArtifactId);
        localStorage.setItem("selectedTargetArtifactId", targetArtifactId);
        localStorage.setItem("selectedSourceArtifactName", sourceArtifactName);
        localStorage.setItem("selectedTargetArtifactName", targetArtifactName);
        localStorage.setItem("selectedSourceArtifactVersion", sourceArtifactVersion);
        localStorage.setItem("selectedTargetArtifactVersion", targetArtifactVersion);

        function fetchManifestAndConfigs(sourceArtifactId, sourceArtifactVersion, targetArtifactId, targetArtifactVersion) {
            return new Promise((resolve, reject) => {
                console.log("📡 Requesting Manifest & Configurations...");

                let manifestRequestData = {
                    fetchManifestAndConfigs: true,
                    sourceArtifactId: sourceArtifactId,
                    sourceArtifactVersion: sourceArtifactVersion,
                    targetArtifactId: targetArtifactId,
                    targetArtifactVersion: targetArtifactVersion
                };

                fetch("http://localhost:9090/", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify(manifestRequestData)
                    })
                    .then(response => response.json())
                    .then(data => {
                        console.log("✅ Manifest & Configurations Response:", data);

                        if (!data || !data.sourceManifest || !data.targetManifest || !data.sourceConfigurations || !data.targetConfigurations) {
                            throw new Error("⚠️ Manifest or Configuration Data Missing.");
                        }

                        // ✅ Store Manifest & Configuration Data in Local Storage
                        localStorage.setItem("sourceManifest", JSON.stringify(data.sourceManifest));
                        localStorage.setItem("targetManifest", JSON.stringify(data.targetManifest));
                        localStorage.setItem("sourceConfig", JSON.stringify(data.sourceConfigurations));
                        localStorage.setItem("targetConfig", JSON.stringify(data.targetConfigurations));

                        console.log("✅ Manifest & Configurations Stored Successfully!");
                        resolve();
                    })
                    .catch(error => {
                        console.error("❌ Error Fetching Manifest & Configurations:", error);
                        reject(error);
                    });
            });
        }


        // ✅ Prepare Data for PowerShell Request
        let requestData = {
            fetchArtifactZip: true,
            sourceArtifactId: sourceArtifactId,
            sourceArtifactVersion: sourceArtifactVersion,
            targetArtifactId: targetArtifactId,
            targetArtifactVersion: targetArtifactVersion,
            targetArtifactName: targetArtifactName
        };

        console.log("📡 Sending Request to PowerShell for ZIP Export:", requestData);

        // ✅ Show Loading Popup
        showLoadingPopup();

        // ✅ AJAX Request to Fetch ZIP File
        fetch("http://localhost:9090/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(requestData)
            })
            .then(response => response.json())
            .then(data => {
                console.log("✅ ZIP File Response from PowerShell:", data);
                hideLoadingPopup();

                if (data.Status === "success") {
                    //alert("✔ Artifact ZIP downloaded successfully!");
                    localStorage.setItem("zipFilePath", data.zipFilePath); // Store ZIP File Path
                    console.log("🔄 Fetching Manifest & Configurations...");

                    // ✅ Step 2: Call Another AJAX to Fetch Manifest & Configurations
                    return fetchManifestAndConfigs(sourceArtifactId, sourceArtifactVersion, targetArtifactId, targetArtifactVersion);
                } else {
                    throw new Error("⚠ Error downloading artifact ZIP. Please check logs.");
                }
            })
            .then(() => {
                console.log("🚀 Proceeding to Step 4...");
                goToNextStep("step4.html");
            })
            .catch(error => {
                console.error("❌ Error in Artifact Fetching Process:", error);
                hideLoadingPopup();
                alert(error.message);
            });
    });



    // ✅ Navigation for Multiple IFlow Deployment
    document.getElementById("nextMultipleIflow")?.addEventListener("click", function() {
        let selectedSourceArtifacts = document.querySelectorAll('input[name="sourceArtifactMulti"]:checked');
        let selectedTargetArtifacts = document.querySelectorAll('input[name="targetArtifactMulti"]:checked');

        if (selectedSourceArtifacts.length === 0 || selectedTargetArtifacts.length === 0) {
            alert("⚠️ Please select at least one artifact from both Source and Target before proceeding.");
            return;
        }

        let sourceArtifacts = [...selectedSourceArtifacts].map(artifact => ({
            id: artifact.dataset.id,
            name: artifact.dataset.name,
            version: artifact.dataset.version
        }));

        let targetArtifacts = [...selectedTargetArtifacts].map(artifact => ({
            id: artifact.dataset.id,
            name: artifact.dataset.name,
            version: artifact.dataset.version
        }));

        localStorage.setItem("selectedSourceArtifacts", JSON.stringify(sourceArtifacts));
        localStorage.setItem("selectedTargetArtifacts", JSON.stringify(targetArtifacts));

        console.log("✅ Selected Multiple Artifacts:", sourceArtifacts, targetArtifacts);
        goToNextStep("step4_multiple.html");
    });




    //STEP-3 Multiple
    if (window.location.pathname.includes("step3_multiple.html")) {

        console.log("✅ Step 3 Multiple Deployment Initialized");


        // ✅ Table References
        const sourceTable = document.querySelector("#sourceArtifactsTableMulti tbody");
        const targetTable = document.querySelector("#targetArtifactsTableMulti tbody");
        const pairTable = document.querySelector("#pairedSelectionsTable tbody");
        const addPairBtn = document.getElementById("addPairBtn");
        const deployMultipleBtn = document.getElementById("deployMultipleIflows");
        console.log("🔍 Checking Deploy Button:", deployMultipleBtn ? "Found ✅" : "Not Found ❌");


        // ✅ Retrieve Stored Artifacts from Local Storage
        let sourceArtifacts = JSON.parse(localStorage.getItem("sourceArtifacts")) || [];
        let targetArtifacts = JSON.parse(localStorage.getItem("targetArtifacts")) || [];
        let pairedArtifacts = JSON.parse(localStorage.getItem("pairedArtifacts")) || [];

        console.log("📦 Retrieved Source Artifacts:", sourceArtifacts);
        console.log("📦 Retrieved Target Artifacts:", targetArtifacts);
        console.log("📦 Retrieved Paired Artifacts:", pairedArtifacts);
        addPairBtn.disabled = true;
        addPairBtn.style.background = "#ccc";
        addPairBtn.style.cursor = "not-allowed";
        addPairBtn.style.opacity = "0.6";
        deployMultipleBtn.style.display = "none";
        deployMultipleBtn.disabled = false;


        // ✅ Deploy Multiple IFlows
        deployMultipleBtn?.addEventListener("click", function() {
            console.log("🚀 Deploying Multiple IFlows...");


            if (pairedArtifacts.length === 0) {
                alert("⚠️ No pairs selected for deployment.");
                return;
            }


            // ✅ Store artifact pairs in local storage for Step 4 tracking
            localStorage.setItem("deploymentPairs", JSON.stringify(pairedArtifacts));

            let requestData = {
                deployMultipleArtifacts: true,
                artifactPairs: pairedArtifacts.map(pair => ({
                    sourceArtifactId: pair.sourceId, // ✅ Corrected Key
                    sourceArtifactName: pair.sourceName,
                    sourceArtifactVersion: pair.sourceVersion,
                    targetArtifactId: pair.targetId, // ✅ Corrected Key
                    targetArtifactName: pair.targetName,
                    targetArtifactVersion: pair.targetVersion
                }))
            };
            goToNextStep("step4_multiple.html");
            /*
                console.log("📡 Sending Deployment Request:", requestData);
                //goToNextStep("step4_multiple.html");

                fetch("http://localhost:9090/", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify(requestData)
                    })
                    .then(response => response.json())
                    .then(deployResponse => {
                        console.log("✅ Deployment Response from PowerShell:", deployResponse);


                        if (deployResponse.status?.toLowerCase() === "success") {
                            console.log("✅ Multiple IFlows Deployment Initiated!");

                        } else {
                            alert("❌ Deployment Failed. Check Logs.");
                        }
                    })
                    .catch(error => {
                        console.error("❌ Deployment Error:", error);
                        alert("⚠ Deployment Failed! Check Console for Errors.");
                    });

                    */
            
        });


        console.log("✅ Deploy button event listener attached!");



        // ✅ Populate Artifacts Table
        function populateArtifactsTable(artifacts, tableId) {
            let tableBody = document.querySelector(`#${tableId} tbody`);
            tableBody.innerHTML = "";

            artifacts.forEach((artifact, index) => {
                let row = `
                <tr>
                    <td><input type="radio" name="${tableId}-selection" data-id="${artifact.Id}" data-name="${artifact.Name}" data-version="${artifact.Version}"></td>
                    <td>${index + 1}</td>
                    <td>${artifact.Name}</td>
                    <td>${artifact.Version}</td>
                    <td>${artifact.DeployedOn || "N/A"}</td>
                    <td>${artifact.Status || "Unknown"}</td>
                </tr>`;
                tableBody.innerHTML += row;
            });
        }

        // ✅ Populate Source & Target Tables
        populateArtifactsTable(sourceArtifacts, "sourceArtifactsTableMulti");
        populateArtifactsTable(targetArtifacts, "targetArtifactsTableMulti");

        function checkSelection() {
            let selectedSource = document.querySelector('input[name="sourceArtifactsTableMulti-selection"]:checked');
            let selectedTarget = document.querySelector('input[name="targetArtifactsTableMulti-selection"]:checked');

            // ✅ Disable Add Pair button if no selection is made
            if (selectedSource && selectedTarget) {
                addPairBtn.disabled = false;
                addPairBtn.style.background = "#ffeb3b"; // Restore button color
                addPairBtn.style.cursor = "pointer";
                addPairBtn.style.opacity = "1";
            } else {
                addPairBtn.disabled = true;
                addPairBtn.style.background = "#ccc"; // Grey out button
                addPairBtn.style.cursor = "not-allowed";
                addPairBtn.style.opacity = "0.6";
            }

            console.log("🔍 Add Pair Button Status:", addPairBtn.disabled ? "DISABLED" : "ENABLED");
        }
        document.querySelectorAll('input[name="sourceArtifactsTableMulti-selection"]').forEach(radio => {
            radio.addEventListener("change", checkSelection);
        });
        document.querySelectorAll('input[name="targetArtifactsTableMulti-selection"]').forEach(radio => {
            radio.addEventListener("change", checkSelection);
        });


        sourceTable.addEventListener("change", checkSelection);
        targetTable.addEventListener("change", checkSelection);

        // ✅ Function to Check for Duplicate Pairs
        function isPairAlreadyAdded(sourceId, targetId) {
            return pairedArtifacts.some(pair => pair.sourceId === sourceId && pair.targetId === targetId);
        }

        // ✅ Function to Update Pair Table
        function updatePairTable() {
            pairTable.innerHTML = "";

            pairedArtifacts.forEach((pair, index) => {
                let row = `
        <tr>
            <td>${index + 1}</td>
            <td>${pair.sourceName} (v${pair.sourceVersion})</td>
            <td>${pair.targetName} (v${pair.targetVersion})</td>
            <td><button class="delete-pair-btn" data-index="${index}">❌</button></td>
        </tr>`;
                pairTable.innerHTML += row;
            });


            // ✅ Hide Deploy Button if no pairs exist
            deployMultipleBtn.style.display = pairedArtifacts.length > 0 ? "inline-block" : "none";

            // Attach delete event listeners
            document.querySelectorAll(".delete-pair-btn").forEach(button => {
                button.addEventListener("click", function() {
                    let index = this.dataset.index;
                    pairedArtifacts.splice(index, 1);
                    localStorage.setItem("pairedArtifacts", JSON.stringify(pairedArtifacts));
                    updatePairTable();
                });
            });

            console.log("🔍 Deploy Button Status:", deployMultipleBtn.style.display);
        }


        // ✅ Add Pair to Table
        addPairBtn.addEventListener("click", function() {
            let selectedSource = document.querySelector('input[name="sourceArtifactsTableMulti-selection"]:checked');
            let selectedTarget = document.querySelector('input[name="targetArtifactsTableMulti-selection"]:checked');

            if (!selectedSource || !selectedTarget) {
                alert("⚠️ Please select one artifact from both Source and Target before adding a pair.");
                return;
            }

            let sourceId = selectedSource.dataset.id;
            let targetId = selectedTarget.dataset.id;
            let sourceName = selectedSource.dataset.name;
            let targetName = selectedTarget.dataset.name;
            let sourceVersion = selectedSource.dataset.version;
            let targetVersion = selectedTarget.dataset.version;

            if (isPairAlreadyAdded(sourceId, targetId)) {
                alert("⚠️ This pair has already been added!");
                return;
            }

            // ✅ Add to paired list
            pairedArtifacts.push({
                sourceId,
                targetId,
                sourceName,
                targetName,
                sourceVersion,
                targetVersion
            });

            // ✅ Store in Local Storage
            localStorage.setItem("pairedArtifacts", JSON.stringify(pairedArtifacts));

            // ✅ Update UI
            updatePairTable();
            addPairBtn.disabled = true; // Reset button until new selection is made
        });




        // ✅ Initialize Pair Table
        updatePairTable();

    }
    //Go back to Step 2
    document.getElementById("prevStep3Multi")?.addEventListener("click", function() {
        goToNextStep("step2.html");
    });







    //STEP-4 Multiple

    // ✅ Step 4 Multiple: Real-Time Deployment Tracking
    if (window.location.pathname.includes("step4_multiple.html")) {
        console.log("✅ Detected Step 4 Multiple - Initializing Deployment Tracking");

        // ✅ Retrieve artifact pairs from local storage
        let deploymentPairs = JSON.parse(localStorage.getItem("deploymentPairs")) || [];

        if (deploymentPairs.length === 0) {
            alert("⚠️ No artifact pairs found. Redirecting to Step 3...");
            goToNextStep("step3_multiple.html");
            return;
        }

        console.log("🔍 Deployment Pairs:", deploymentPairs);

        // ✅ Populate Deployment Tracking Table (Fixed for New Structure)
        function populateDeploymentTable() {
            let tableBody = document.querySelector("#deploymentTable tbody");
            tableBody.innerHTML = ""; // Clear previous data

            deploymentPairs.forEach((pair, index) => {
                let row = document.createElement("tr");
                row.innerHTML = `
            <td>${index + 1}</td>
            <td>${pair.sourceName} (v${pair.sourceVersion})</td>  <!-- ✅ Updated Key -->
            <td>${pair.targetName} (v${pair.targetVersion})</td>  <!-- ✅ Updated Key -->
            <td>
                <div class="progress-bar-container">
                    <div class="progress-bar" id="progress-${index}" style="width: 0%;"></div>
                </div>
            </td>
            <td id="status-${index}">🟡 Pending...</td>
        `;
                tableBody.appendChild(row);
            });

            console.log("✅ Deployment Tracking Table Initialized");
        }
        // ✅ Start Deployment Status Polling (Every 5s)
        populateDeploymentTable();
       

                    

        // ✅ Fetch Real-Time Deployment Updates (Fixed for New Structure)
     // ✅ Function to Fetch Deployment Status from PowerShell Server
        // ✅ Fetch Real-Time Deployment Updates (Fixed for New Structure)
        function fetchDeploymentStatus() {
            fetch("http://localhost:9090/deploymentStatus", {
                    method: "POST"
                })
                .then(response => response.json())
                .then(data => {
                    console.log("✅ Deployment Status Update Received:", data);

                    let allCompleted = true; // ✅ Check if all are done

                    deploymentPairs.forEach((pair, index) => {
                        let statusElement = document.querySelector(`#status-${index}`);
                        let progressBar = document.querySelector(`#progress-${index}`);

                        if (data[pair.targetId]) {
                            let status = data[pair.targetId].status;
                            let progress = data[pair.targetId].progress;

                            console.log(`✅ Updating UI for: ${pair.targetId} | Status: ${status} | Progress: ${progress}%`);

                            statusElement.innerHTML = status;
                            progressBar.style.width = `${progress}%`;

                            if (progress === 100) {
                                progressBar.classList.add("completed");
                            } else {
                                allCompleted = false; // ✅ At least one is still running
                            }
                        }
                    });

                    // ✅ Stop Fetching Once All Are Done
                    if (allCompleted) {
                        console.log("✅ All Deployments Completed! Stopping Status Updates.");
                        clearInterval(deploymentStatusInterval); // ✅ Stop Fetching
                        // ✅ Show the Transport Another IFlow button
                        document.getElementById("transportAnotherBtn").style.display = "inline-block";
                    }
                })
                .catch(error => console.error("❌ Error Fetching Deployment Status:", error));
        }

// ✅ Start Polling Every 5 Seconds
let deploymentStatusInterval = setInterval(fetchDeploymentStatus, 5000);



       

        

        // ✅ STEP 3: Send Deployment Request to PowerShell
    function sendDeploymentRequest() {
        let requestData = {
            deployMultipleArtifacts: true,
            artifactPairs: deploymentPairs.map(pair => ({
                sourceArtifactId: pair.sourceId,
                sourceArtifactName: pair.sourceName,
                sourceArtifactVersion: pair.sourceVersion,
                targetArtifactId: pair.targetId,
                targetArtifactName: pair.targetName,
                targetArtifactVersion: pair.targetVersion
            }))
        };

        console.log("📡 Sending Deployment Request:", requestData);

        fetch("http://localhost:9090/", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(requestData),
            keepalive: true // ✅ Allows request to be sent without blocking
        }).catch(error => console.error("❌ Deployment Request Failed:", error));
    }
/*
        fetch("http://localhost:9090/", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(requestData)
        })
        .then(response => response.json())
        .then(deployResponse => {
            console.log("✅ Deployment Response from PowerShell:", deployResponse);

            if (deployResponse.status?.toLowerCase() === "success") {
                console.log("✅ Multiple IFlows Deployment Initiated!");
            } else {
                alert("❌ Deployment Failed. Check Logs.");
            }
        })
        .catch(error => {
            console.error("❌ Deployment Error:", error);
            alert("⚠ Deployment Failed! Check Console for Errors.");
        });
        */
    

    sendDeploymentRequest(); // ✅ Step 3: Only now trigger the deployment


        // ✅ Abort Deployment Button
        document.getElementById("abortDeploymentBtn").addEventListener("click", function() {
            if (confirm("⚠️ Are you sure you want to abort deployment?")) {
                fetch("http://localhost:9090/abortDeployment", {
                        method: "POST"
                    })
                    .then(response => response.json())
                    .then(data => {
                        alert("❌ Deployment Aborted!");
                        console.log("🛑 Deployment Aborted:", data);
                        goToNextStep("step3_multiple.html");
                    })
                    .catch(error => console.error("❌ Error Aborting Deployment:", error));
            }
        });


        // ✅ Transport Another IFlow Button
        document.getElementById("transportAnotherBtn").addEventListener("click", function() {
            // ✅ Clear Deployment Status before navigating back
            localStorage.removeItem("deploymentPairs");
            goToNextStep("step3_multiple.html");
        });

        // ✅ Download Original Configurations Button
        document.getElementById("downloadConfigBtn").addEventListener("click", function() {
            fetch("http://localhost:9090/downloadConfigs", {
                    method: "POST"
                })
                .then(response => response.blob())
                .then(blob => {
                    let link = document.createElement("a");
                    link.href = window.URL.createObjectURL(blob);
                    link.download = "Original_Configurations.txt";
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                })
                .catch(error => console.error("❌ Error Downloading Configurations:", error));
        });
    }






    //STEP-4    

    if (window.location.pathname.includes("step4.html")) {
        console.log("✅ Detected Step 4 - Initializing Artifact Manifest & Config Tables");

        // ✅ Function to Handle Configuration Deletion
        function deleteConfigRow(button) {
            let row = button.closest("tr"); // Get the row where the button is clicked
            let tableBody = document.querySelector("#targetConfigTable tbody");

            console.log("🗑 Attempting to Delete Row:", row);

            // Ensure at least one row remains
            if (tableBody.rows.length > 1) {
                row.remove();
                console.log("✅ Deleted Row Successfully");
            } else {
                alert("⚠️ At least one configuration must be present.");
                console.warn("⚠️ Prevented Deleting Last Row");
            }
        }

        // ✅ Attach Event Listener to All Existing Delete Buttons
        function initializeDeleteButtons() {
            setTimeout(() => {
                let buttons = document.querySelectorAll("#targetConfigTable .delete-btn");
                console.log("🔍 Found Delete Buttons After Delay:", buttons.length);

                buttons.forEach(button => {
                    button.removeEventListener("click", function() {}); // Remove previous event listener if any
                    button.addEventListener("click", function() {
                        console.log("🖱️ Delete Button Clicked:", this);
                        deleteConfigRow(this);
                    });
                });

                console.log("✅ Initialized Delete Buttons Successfully");
            }, 500); // Delay execution by 500ms to ensure table is loaded
        }

        // ✅ 1. Retrieve & Populate Manifest Tables
        function populateManifestTable(keys, manifestData) {
            Object.keys(keys).forEach(key => {
                let element = document.getElementById(keys[key]);

                if (element) {
                    element.textContent = manifestData[key] || "N/A"; // Fill with data or "N/A" if missing
                } else {
                    console.error(`❌ Missing element: ${keys[key]}`);
                }
            });
        }

        // ✅ 2. Retrieve Manifest & Configurations from Local Storage
        let sourceManifest = JSON.parse(localStorage.getItem("sourceManifest")) || {};
        let targetManifest = JSON.parse(localStorage.getItem("targetManifest")) || {};
        let sourceConfigs = JSON.parse(localStorage.getItem("sourceConfig")) || [];
        let targetConfigs = JSON.parse(localStorage.getItem("targetConfig")) || [];

        console.log("📜 Retrieved Source Manifest:", sourceManifest);
        console.log("📜 Retrieved Target Manifest:", targetManifest);
        console.log("⚙️ Retrieved Source Configurations:", sourceConfigs);
        console.log("⚙️ Retrieved Target Configurations:", targetConfigs);

        // ✅ 3. Define Manifest Keys Mapping
        const targetkeys = {
            "Bundle-SymbolicName": "targetBundleSymbolicName",
            "Origin-Bundle-SymbolicName": "targetOriginBundleSymbolicName",
            "Origin-Bundle-Name": "targetOriginBundleName",
            "Bundle-Name": "targetBundleName"
        };
        const sourcekeys = {
            "Bundle-SymbolicName": "sourceBundleSymbolicName",
            "Origin-Bundle-SymbolicName": "sourceOriginBundleSymbolicName",
            "Origin-Bundle-Name": "sourceOriginBundleName",
            "Bundle-Name": "sourceBundleName"
        };

        // ✅ Populate Manifest Tables with Retrieved Data
        populateManifestTable(sourcekeys, sourceManifest);
        populateManifestTable(targetkeys, targetManifest);

        console.log("✅ Populated Manifest Tables with Retrieved Data");

        // ✅ 4. Populate Configuration Tables (Make Target Editable)
        function populateConfigTable(tableId, data, isEditable) {
            const tableBody = document.querySelector(`#${tableId} tbody`);
            tableBody.innerHTML = "";

            data.forEach((config, index) => {
                let row = `
                <tr>
                    <td>${config.Name}</td>
                    <td><input type="text" value="${config.Value}" ${isEditable ? "" : "readonly"}></td>
                    ${isEditable ? `<td><button class="delete-btn" data-index="${index}">❌</button></td>` : ""}
                </tr>
            `;
                tableBody.innerHTML += row;
            });
        }

        // ✅ Populate Config Tables
        populateConfigTable("sourceConfigTable", sourceConfigs, false); // Source: Read-only
        populateConfigTable("targetConfigTable", targetConfigs, true); // Target: Editable

        console.log("✅ Populated Configuration Tables");
        // =============================
        // ✅ Copy Config from the Source and add to Target Configs table
        // =============================
        document.getElementById("copyConfigBtn")?.addEventListener("click", function() {
            console.log("🔄 Copy Button Clicked");

            // Get Source and Target Table Bodies
            let sourceTable = document.querySelector("#sourceConfigTable tbody");
            let targetTable = document.querySelector("#targetConfigTable tbody");

            if (!sourceTable || !targetTable) {
                console.error("❌ Source or Target Table not found.");
                return;
            }

            let sourceRows = sourceTable.querySelectorAll("tr");
            let targetRows = targetTable.querySelectorAll("tr");

            // Create a Set of Existing Target Config Names to Prevent Duplicates
            let targetConfigNames = new Set();
            targetRows.forEach(row => {
                let paramName = row.cells[0]?.textContent.trim();
                if (paramName) {
                    targetConfigNames.add(paramName);
                }
            });

            let copied = 0;
            sourceRows.forEach(row => {
                let paramName = row.cells[0]?.textContent.trim();
                let paramValue = row.cells[1]?.querySelector("input")?.value || row.cells[1]?.textContent.trim();

                if (!targetConfigNames.has(paramName)) {
                    // Create a new row for the target table
                    let newRow = document.createElement("tr");
                    newRow.innerHTML = `
                <td>${paramName}</td>
                <td><input type="text" value="${paramValue}" class="editable-input"></td>
                <td><button class="delete-btn">❌</button></td>
            `;

                    // Append to target table
                    targetTable.appendChild(newRow);
                    copied++;
                    targetConfigNames.add(paramName); // Avoid duplicates
                    // Attach event listener to the new delete button
                    newRow.querySelector(".delete-btn")?.addEventListener("click", function() {
                        deleteConfigRow(this);
                    });
                }
            });

            console.log(`✅ ${copied} New Configurations with Values Copied`);
        });


        // ✅ Initialize Delete Buttons
        initializeDeleteButtons();
    }

    // ✅ 3. Copy Missing Configurations
    document.getElementById("copyConfigsBtn")?.addEventListener("click", function() {
        console.log("🔄 Copying Missing Configurations...");
        const existingKeys = new Set(targetConfigs.map(item => item.param));

        sourceConfigs.forEach(config => {
            if (!existingKeys.has(config.param)) {
                targetConfigs.push(config); // Add missing config to target
            }
        });

        populateConfigTable("targetConfigTable", targetConfigs, true);
        console.log("✅ Missing Configurations Copied!");
    });

    // ✅ 4. Transport Button Logic
    // ✅ Transport Button Logic - Step 4
    document.getElementById("transportButton")?.addEventListener("click", function() {
        console.log("🚀 Transport Process Started...");

        let finalTargetConfigs = [];
        document.querySelectorAll("#targetConfigTable tbody tr").forEach(row => {
            let param = row.cells[0].innerText;
            let value = row.cells[1].querySelector("input").value;
            finalTargetConfigs.push({
                param,
                value
            });
        });

        console.log("✅ Final Target Configuration Data:", finalTargetConfigs);

        // ✅ Step 1: Show Compilation Popup
        showLoadingPopup("🔄 Compiling the new IFlow... Please Wait");

        // ✅ Step 2: Prepare Request Data for Modify-Manifest
        let modifyManifestRequest = {
            modifyManifestFile: true
        };

        console.log("📡 Sending Modify-Manifest Request:", modifyManifestRequest);

        // ✅ Step 3: Send Modify-Manifest Request to PowerShell
        fetch("http://localhost:9090/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(modifyManifestRequest)
            })
            .then(response => response.json())
            .then(data => {
                console.log("✅ Modify-Manifest Response from PowerShell:", data);
                hideLoadingPopup();

                // ✅ Handle String Response & Convert to JSON
                if (typeof data === "string") {
                    console.warn("⚠️ Response received as a string, attempting to parse...");
                    try {
                        data = JSON.parse(data);
                        console.log("✅ Parsed JSON Response:", data);
                    } catch (error) {
                        console.error("❌ JSON Parsing Failed:", error);
                        alert("⚠ Error: Response is not valid JSON. Check console.");
                        return;
                    }
                }

                // ✅ Step 4: Check Manifest Modification Status
                if (data.Status?.toLowerCase() === "success" || data.status?.toLowerCase() === "success") {
                    alert("✅ Compilation Successful! Uploading the Artifact...");

                    // ✅ Step 5: Show Upload Popup
                    showLoadingPopup("✅ Compilation Successful! Uploading the Artifact...");

                    // ✅ Step 6: Prepare Upload Request
                    let uploadRequest = {
                        uploadArtifact: true
                    };

                    console.log("📡 Sending Upload Request:", uploadRequest);

                    // ✅ Step 7: Send Upload Request to PowerShell
                    return fetch("http://localhost:9090/", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify(uploadRequest)
                    });
                } else {
                    alert("❌ Compilation Failed. Please check logs.");
                    throw new Error("❌ Compilation Process Failed.");
                }
            })
            .then(response => response.json())
            .then(uploadData => {
                console.log("✅ Upload Response from PowerShell:", uploadData);
                hideLoadingPopup();

                // ✅ Handle String Response & Convert to JSON
                if (typeof uploadData === "string") {
                    console.warn("⚠️ Response received as a string, attempting to parse...");
                    try {
                        uploadData = JSON.parse(uploadData);
                        console.log("✅ Parsed JSON Response:", uploadData);
                    } catch (error) {
                        console.error("❌ JSON Parsing Failed:", error);
                        alert("⚠ Error: Response is not valid JSON. Check console.");
                        return;
                    }
                }

                // ✅ Step 8: Check Upload Status & Proceed to Step 5
                if (uploadData.Status?.toLowerCase() === "success") {
                    console.log("🚀 Upload Successful! Redirecting to Step 5...");
                    goToNextStep("step5.html");
                } else {
                    alert("❌ Upload Failed. Please check logs.");
                    throw new Error("❌ Upload Process Failed.");
                }
            })
            .catch(error => {
                console.error("❌ Error in Transport Process:", error);
                hideLoadingPopup();
                alert("⚠ Transport Failed! Check Console for Errors.");
            });
    });


    //Go back to Step 3
    document.getElementById("prevStep4")?.addEventListener("click", function() {
        goToNextStep("step3.html");
    });








    //STEP-5
    // ✅ Navigate Back to Step 4
    document.getElementById("prevStep5")?.addEventListener("click", function() {
        console.log("🔄 Returning to Step 4...");
        window.location.href = "step4.html";
    });

    // ✅ Deployment & Configuration
    document.getElementById("deployAndConfigure")?.addEventListener("click", function() {
        console.log("🚀 Deploying & Configuring...");

        fetch("http://localhost:9090/deploy", {
                method: "POST"
            })
            .then(response => response.json())
            .then(data => {
                alert("✅ Deployment Successful with Configuration!");
                console.log("Response:", data);
            })
            .catch(error => {
                console.error("❌ Deployment Failed:", error);
                alert("❌ Deployment Failed!");
            });
    });

    // ✅ Deployment Only
    // ✅ Step 5: Deploy Only Button Event Listener
    document.getElementById("deployOnly")?.addEventListener("click", function() {
        console.log("🚀 Deploying Artifact without Configuration...");

        // ✅ Step 1: Show Deployment Popup
        showLoadingPopup("🔄 Deploying Artifact... Please Wait");

        // ✅ Step 2: Retrieve Target Artifact ID & Version
        let targetArtifactId = localStorage.getItem("selectedTargetArtifactId");
        let targetArtifactVersion = localStorage.getItem("selectedTargetArtifactVersion");

        if (!targetArtifactId || !targetArtifactVersion) {
            console.error("❌ Deployment Error: Target Artifact ID or Version Not Found.");
            alert("⚠️ Error: Missing Artifact Details. Check Console.");
            hideLoadingPopup();
            return;
        }

        console.log("🎯 Target Artifact ID:", targetArtifactId);
        console.log("🎯 Target Artifact Version:", targetArtifactVersion);

        // ✅ Step 3: Prepare Deployment Request
        let deployRequest = {
            deployArtifact: true,
            targetArtifactId: targetArtifactId,
            targetArtifactVersion: targetArtifactVersion
        };

        console.log("📡 Sending Deployment Request to PowerShell:", deployRequest);

        // ✅ Step 4: Send Deployment Request
        fetch("http://localhost:9090/", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(deployRequest)
            })
            .then(response => response.json())
            .then(deployResponse => {
                console.log("✅ Deployment Response from PowerShell:", deployResponse);
                hideLoadingPopup();

                // ✅ Handle String Response & Convert to JSON if necessary
                if (typeof deployResponse === "string") {
                    console.warn("⚠️ Response received as a string, attempting to parse...");
                    try {
                        deployResponse = JSON.parse(deployResponse);
                        console.log("✅ Parsed JSON Response:", deployResponse);
                    } catch (error) {
                        console.error("❌ JSON Parsing Failed:", error);
                        alert("⚠ Error: Response is not valid JSON. Check console.");
                        return;
                    }
                }

                // ✅ Normalize response key handling to avoid case-sensitivity issues
                let deploymentStatus = deployResponse.Status?.toLowerCase() || deployResponse.status?.toLowerCase();
                console.log("🔍 Deployment Status:", deploymentStatus);

                // ✅ Check if deployment was successful
                if (deploymentStatus === "success") {


                    // ✅ Show Modal
                    document.getElementById("deploymentSuccessModal").style.display = "block";

                    // ✅ Close Modal Functionality
                    document.querySelector(".close").addEventListener("click", function() {
                        document.getElementById("deploymentSuccessModal").style.display = "none";
                    });

                    // ✅ Transport Another IFlow Button
                    document.getElementById("transportAnotherBtn").addEventListener("click", function() {
                        console.log("🔄 Redirecting to Step 2...");
                        // ✅ Clear Stored Artifacts from Local Storage
                        console.log("🗑 Clearing stored artifacts...");
                        localStorage.removeItem("sourceArtifacts");
                        localStorage.removeItem("targetArtifacts");

                        console.log("✅ Artifacts Cleared. Fetching new data...");
                        goToNextStep("step2.html");
                    });

                    // ✅ End Session Button
                    document.getElementById("endSessionBtn").addEventListener("click", function() {
                        console.log("🛑 Ending Session & Closing Browser Tab...");
                        endPowershellSession();
                        window.close();
                    });

                } else {
                    alert("❌ Deployment Failed: " + (deployResponse.message || "Unknown error"));
                    console.error("❌ Deployment Failed:", deployResponse);
                }
            })

            .catch(error => {
                console.error("❌ Deployment Error:", error);
                hideLoadingPopup();
                alert("⚠ Deployment Failed! Check Console for Errors.");
            });
    });




    // ✅ Check if the page is NOT index.html before adding the reset button
    if (!window.location.pathname.includes("index.html")) {
        console.log("🔄 Adding Reset Transport Button...");

        // ✅ Create Reset Button
        const resetButton = document.createElement("button");
        resetButton.innerHTML = "⭮"; // Unicode Reset Icon
        resetButton.id = "resetTransportBtn";
        resetButton.title = "Reset Transport";

        // ✅ Apply Floating Button Styles
        resetButton.style.position = "fixed";
        resetButton.style.bottom = "20px";
        resetButton.style.right = "20px";
        resetButton.style.width = "50px";
        resetButton.style.height = "50px";
        resetButton.style.border = "none";
        resetButton.style.borderRadius = "50%";
        resetButton.style.background = "red";
        resetButton.style.color = "white";
        resetButton.style.fontSize = "24px";
        resetButton.style.cursor = "pointer";
        resetButton.style.boxShadow = "0px 4px 10px rgba(0, 0, 0, 0.2)";
        resetButton.style.transition = "0.3s";

        // ✅ Hover Effect
        resetButton.addEventListener("mouseover", function() {
            resetButton.style.transform = "scale(1.1)";
        });
        resetButton.addEventListener("mouseleave", function() {
            resetButton.style.transform = "scale(1)";
        });

        // ✅ Append Button to Body
        document.body.appendChild(resetButton);

        // ✅ Reset Transport Data on Click
        resetButton.addEventListener("click", function() {
            console.log("🔄 Reset Transport Button Clicked!");

            // ✅ Confirm Reset
            if (!confirm("⚠️ Are you sure you want to reset the transport session? This cannot be undone.")) {
                return;
            }

            // ✅ Clear Local Storage (Except Saved Configs)
            Object.keys(localStorage).forEach(key => {
                if (!key.includes("savedConfigs")) {
                    localStorage.removeItem(key);
                }
            });

            console.log("✅ Local Storage Cleared!");

            // ✅ Call PowerShell API to Reset Global Variables
            fetch("http://localhost:9090/resetTransport", {
                    method: "POST"
                })
                .then(response => response.json())
                .then(data => {
                    console.log("✅ PowerShell Reset Response:", data);
                    alert("✅ Transport Reset Successfully!");
                    window.location.href = "step1.html"; // Redirect to Step 1
                })
                .catch(error => {
                    console.error("❌ Error Resetting Transport:", error);
                    alert("❌ Failed to reset transport. Check console logs.");
                });
        });
    }


    // Restore input data when the page loads
    restoreData();
});
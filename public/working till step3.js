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




    // Attach event listeners for buttons
    // =============================
    // ✅ Clear Test Data from Tables
    // =============================
    document.getElementById("clearTestDataBtn")?.addEventListener("click", function() {
        document.querySelector("#sourcePackagesTable tbody").innerHTML = "";
        document.querySelector("#targetPackagesTable tbody").innerHTML = "";
        console.log("🚮 Test Data Cleared");
    });

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


    document.getElementById("startBtn")?.addEventListener("click", function() {
        goToNextStep("step1.html");
    });

    document.getElementById("prevStep2")?.addEventListener("click", function() {
        goToNextStep("step1.html");
    });

    document.getElementById("prevStep3")?.addEventListener("click", function() {
        goToNextStep("step2.html");
    });
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

    // ✅ Navigation for Single IFlow Deployment
    document.getElementById("nextSingleIflow")?.addEventListener("click", function() {
        let selectedArtifact = document.querySelector('input[name="sourceArtifact"]:checked');
        let selectedTargetArtifact = document.querySelector('input[name="targetArtifact"]:checked');

        if (!selectedArtifact || !selectedTargetArtifact) {
            alert("⚠️ Please select one artifact from both Source and Target before proceeding.");
            return;
        }

        console.log("✅ Selected Artifacts: ", selectedArtifact.value, selectedTargetArtifact.value);

        // Proceed to Next Step for Single IFlow Deployment
        goToNextStep("step4.html");
    });

    // ✅ Navigation for Multiple IFlow Deployment
    document.getElementById("nextMultipleIflow")?.addEventListener("click", function() {
        let selectedArtifacts = document.querySelectorAll('input[name="sourceArtifact"]:checked');
        let selectedTargetArtifacts = document.querySelectorAll('input[name="targetArtifact"]:checked');

        if (selectedArtifacts.length === 0 || selectedTargetArtifacts.length === 0) {
            alert("⚠️ Please select at least one artifact from both Source and Target before proceeding.");
            return;
        }

        console.log("✅ Selected Multiple Artifacts:", selectedArtifacts.length, selectedTargetArtifacts.length);

        // Proceed to Next Step for Multiple IFlow Deployment
        goToNextStep("step4_multiple.html");
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
        deploymentContainer.style.display = "none"; // Hide selection buttons
        multipleIflowSelection.style.display = "block"; // Show checkbox table
        // Show correct buttons
        nextMultipleIflowBtn.style.display = "inline-block";
        nextSingleIflowBtn.style.display = "none";
        prevIflowBtnStep3.style.display = "inline-block";
    });


    if (prevStep2) {
        console.log("✅ prevStep2 Button Found");
        prevStep2.addEventListener("click", function() {
            console.log("🔄 Navigating to Step 1...");
            goToNextStep("step1.html");
        });
    } else {
        console.warn("⚠️ prevStep2 button not found.");
    }



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

    // ✅ Function to Handle Configuration Deletion

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

    // ✅ Attach Event Listener to All Existing Delete Buttons on Page Load
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

    // ✅ Check if the user is on "step2.html" before running table logic
    // ✅ Fetch & Populate Packages in Step 2
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


    // ✅ Check if the user is on "step3.html" before running table logic
    if (window.location.pathname.includes("step3.html")) {
        console.log("✅ Detected Step 3 - Initializing Package Tables");
        // =============================
        // ✅ Generated Table data
        // =============================
        let sourceTableBody = document.querySelector("#sourceArtifactsTable tbody");
        let targetTableBody = document.querySelector("#targetArtifactsTable tbody");

        // Add Test Data to Source & Target Tables
        generateTestDataArtifacts(sourceArtifactsTable, "source");
        generateTestDataArtifacts(targetArtifactsTable, "target");

        console.log("✅ Test Data Added to Tables");
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

    //STEP-4

    // ✅ 1. Populate Manifest Tables
    const sourceManifestData = {
        "Bundle-SymbolicName": "com.sap.example.source",
        "Origin-Bundle-SymbolicName": "com.sap.origin.source",
        "Origin-Bundle-Name": "SAP CPI Source",
        "Bundle-Name": "SAP Source IFlow"
    };

    const targetManifestData = {
        "Bundle-SymbolicName": "com.sap.example.target",
        "Origin-Bundle-SymbolicName": "com.sap.origin.target",
        "Origin-Bundle-Name": "SAP CPI Target",
        "Bundle-Name": "SAP Target IFlow"
    };
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
    document.getElementById("deployOnly")?.addEventListener("click", function() {
        console.log("🚀 Deploying without Configuration...");

        fetch("http://localhost:9090/deployOnly", {
                method: "POST"
            })
            .then(response => response.json())
            .then(data => {
                alert("✅ Deployment Successful!");
                console.log("Response:", data);
            })
            .catch(error => {
                console.error("❌ Deployment Failed:", error);
                alert("❌ Deployment Failed!");
            });
    });


    if (window.location.pathname.includes("step4.html")) {
        console.log("✅ Detected Step 4 - Initializing Artifact manifest Tables");
        // =============================
        // ✅ Generated Table data
        // =============================
        populateManifestTable(sourcekeys, sourceManifestData);
        populateManifestTable(targetkeys, targetManifestData);

        console.log("✅ Test Data Added to Tables");
        // =============================
        // ✅ Initialize Delte Buttons
        // =============================
        initializeDeleteButtons();



    }



    // ✅ 2. Populate Configuration Tables (Dummy Data for Now)
    const sourceConfigs = [{
            param: "API_ENDPOINT",
            value: "https://source.api.com"
        },
        {
            param: "USERNAME",
            value: "admin_source"
        },
        {
            param: "TIMEOUT",
            value: "5000"
        },
        {
            param: "ENABLED",
            value: "true"
        }
    ];

    const targetConfigs = [{
            param: "API_ENDPOINT",
            value: "https://target.api.com"
        },
        {
            param: "USERNAME",
            value: "admin_target"
        }
    ];

    function populateConfigTable(tableId, data, isEditable) {
        const tableBody = document.querySelector(`#${tableId} tbody`);
        tableBody.innerHTML = "";

        data.forEach((config, index) => {
            let row = `
                <tr>
                    <td>${config.param}</td>
                    <td><input type="text" value="${config.value}" ${isEditable ? "" : "readonly"}></td>
                    ${isEditable ? `<td><button class="delete-btn" data-index="${index}">❌</button></td>` : ""}
                </tr>
            `;
            tableBody.innerHTML += row;
        });
    }
    if (window.location.pathname.includes("step4.html")) {
        console.log("✅ Detected Step 4 - Initializing Artifact Config Tables");
        // =============================
        // ✅ Generated Table data
        // =============================
        populateConfigTable("sourceConfigTable", sourceConfigs, false); // Source: Read-only
        populateConfigTable("targetConfigTable", targetConfigs, true); // Target: Editable

        console.log("✅ Test Data Added to Tables");
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
    document.getElementById("transportButton")?.addEventListener("click", function() {
        console.log("🚀 Preparing Transport Data...");

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
        alert("Transport Ready! Now we integrate with PowerShell.");
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
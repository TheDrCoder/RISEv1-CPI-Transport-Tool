self.addEventListener("message", function(event) {
    let requestData = event.data;
    console.log("📡 Worker: Starting Deployment Request:", requestData);

    fetch("http://localhost:9090/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestData)
    })
    .then(response => response.json())
    .then(deployResponse => {
        console.log("✅ Worker: Deployment Response from PowerShell:", deployResponse);
        self.postMessage(deployResponse); // Send response back to main script
    })
    .catch(error => {
        console.error("❌ Worker: Deployment Error:", error);
        self.postMessage({ error: error.message });
    });
});

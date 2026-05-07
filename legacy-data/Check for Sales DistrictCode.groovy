import com.sap.gateway.ip.core.customdev.util.Message;

def Message processData(Message message) {
    def body = message.getBody(java.lang.String) as String;

    // Regex to match each Customer block including its inner content
    def customerTagPattern = /<Customer\s+[^>]*>((?s:.*?))<\/Customer>/
    def allCustomersHaveEmptySalesDistrictCodes = true

    // Find each Customer block
    def matcher = body =~ customerTagPattern
    while (matcher.find()) {
        def customerBlock = matcher.group(1)

        // Now check each SalesDistrictCode within this Customer block
        def salesCodePattern = /<SalesDistrictCode>(.*?)<\/SalesDistrictCode>/
        def salesMatcher = customerBlock =~ salesCodePattern
        boolean customerHasOnlyEmptySalesCodes = true

        // Check all SalesDistrictCode instances within this customer
        while (salesMatcher.find()) {
            if (salesMatcher.group(1).trim()) { // If not empty
                customerHasOnlyEmptySalesCodes = false
                allCustomersHaveEmptySalesDistrictCodes = false
                break
            }
        }

        // If any customer has non-empty SalesDistrictCode, stop checking further
        if (!customerHasOnlyEmptySalesCodes) {
            println("Non-empty SalesDistrictCode found in a customer")
            break
        }
    }

    // Replace RoleCode if all customers have empty SalesDistrictCode
    if (allCustomersHaveEmptySalesDistrictCodes) {
        println("All customers have empty SalesDistrictCodes, replacing RoleCode.")
        body = body.replaceAll("<RoleCode>ZFLCU1</RoleCode>", "<RoleCode>Z00003</RoleCode>")
    } else {
        println("Not all customers have empty SalesDistrictCodes, not replacing RoleCode.")
    }

    // Set the modified body back to the message
    message.setBody(body);
    return message;
}

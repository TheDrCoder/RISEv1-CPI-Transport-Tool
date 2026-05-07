import com.sap.it.api.mapping.*;

// Function to check if the Party Role Code is valid
def String CheckPartyRole(String arg1) {
    // List of valid role codes
    def validCodes = ['ZM']
    // Check if the codeToCheck is in the list of valid codes
    def result = validCodes.contains(arg1)
    
    // Return the result as a string (true/false)
    return result.toString()
}
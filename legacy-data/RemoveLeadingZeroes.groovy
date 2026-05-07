import com.sap.it.api.mapping.*;

// Function to remove leading zeros
def String RemoveLeadingZeroes(String arg1){
    // Use a regular expression to remove leading zeros
    def result = arg1.replaceFirst("^0+", "")
    
    // Return the result string without leading zeros
    return result
}
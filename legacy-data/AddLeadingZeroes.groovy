import com.sap.it.api.mapping.*;

/* 
This function takes an ID as input and adds leading zeroes 
to ensure the total length is 18.
*/
def String AddLeadingZeroes(String inputID) {
    // Check if input is null or empty
    if (inputID == null || inputID.trim().isEmpty()) {
        return inputID; // Return as is if null or empty
    }

    // Ensure input is treated as a string
    String id = inputID.toString();

    // Add leading zeroes to make the total length 18
    String paddedID = id.padLeft(18, '0');

    return paddedID;
}


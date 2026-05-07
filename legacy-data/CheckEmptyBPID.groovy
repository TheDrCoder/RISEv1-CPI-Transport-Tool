import com.sap.it.api.mapping.*;

def String checkInput(String input1, String input2) {
    if (input1 == null || input1.trim().isEmpty()) {
        return input2
    } else {
        return input1
    }
}
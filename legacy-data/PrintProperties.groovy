import com.sap.gateway.ip.core.customdev.util.Message;

def Message processData(Message message) {
    def messageLog = messageLogFactory.getMessageLog(message)
    def properties = message.getProperties()

    // Retrieve the incoming payload from exchange property
    def incomingPayload = properties.get("P_IncomingPayloadSource")?.toString() ?: "No Incoming Payload Available"

    // Retrieve the exception message from exchange property
    def exceptionMessage = properties.get("P_ExceptionMessage")?.toString() ?: "No Exception Message Available"

    if (messageLog != null) {
        // Log the incoming payload
        messageLog.setStringProperty("Logging#1", "Captured Incoming Payload")
        messageLog.addAttachmentAsString("IncomingPayload", incomingPayload, "text/plain")

        // Log the exception message
        messageLog.setStringProperty("Logging#2", "Captured Exception Message")
        messageLog.addAttachmentAsString("ExceptionMessage", exceptionMessage, "text/plain")
    }

    return message
}

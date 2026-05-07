import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
def Message processData(Message message) {
    def body = message.getBody(java.lang.String) as String;
    //body = body.replace("<RoleCode>BUP010</RoleCode>","<RoleCode>BUP003</RoleCode>")
    def messageLog = messageLogFactory.getMessageLog(message);
    //message.setBody(body) as java.lang.String;
    if(messageLog != null){
        messageLog.setStringProperty("Logging#1", "Printing Payload As Attachment")
        messageLog.addAttachmentAsString("PostMappingPayload:", body, "text/plain");
     }
    return message;
}
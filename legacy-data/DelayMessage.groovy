/*
Delay Message for 20 seconds
 */
import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
def Message processData(Message message) {
    //Body 
       def body = message.getBody();
       sleep(20000);
       message.setBody(body);
       return message;
}

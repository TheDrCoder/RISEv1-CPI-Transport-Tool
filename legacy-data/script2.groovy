/*
 The integration developer needs to create the method processData 
 This method takes Message object of package com.sap.gateway.ip.core.customdev.util 
which includes helper methods useful for the content developer:
The methods available are:
    public java.lang.Object getBody()
	public void setBody(java.lang.Object exchangeBody)
    public java.util.Map<java.lang.String,java.lang.Object> getHeaders()
    public void setHeaders(java.util.Map<java.lang.String,java.lang.Object> exchangeHeaders)
    public void setHeader(java.lang.String name, java.lang.Object value)
    public java.util.Map<java.lang.String,java.lang.Object> getProperties()
    public void setProperties(java.util.Map<java.lang.String,java.lang.Object> exchangeProperties) 
    public void setProperty(java.lang.String name, java.lang.Object value)
    public java.util.List<com.sap.gateway.ip.core.customdev.util.SoapHeader> getSoapHeaders()
    public void setSoapHeaders(java.util.List<com.sap.gateway.ip.core.customdev.util.SoapHeader> soapHeaders) 
       public void clearSoapHeaders()
 */
import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
def Message processData(Message message) {
    //Body 
       def body = message.getBody(java.lang.String) as String;
       // Remove any XML declarations from the string
    body = body.replaceAll(/<\?xml.*?\?>/, '');

    // Set the cleaned-up body as the new body of the message
    message.setBody(body);
       def completeXml= new XmlSlurper().parseText(body)
       def roles = completeXml.Message1.BusinessPartnerSUITEBulkReplicateRequest.BusinessPartnerSUITEReplicateRequestMessage.BusinessPartner.'**'.findAll{ node-> node.name() == 'RoleCode'}*.text()
       
       if(( roles.contains('ZFLVN0') || roles.contains('ZFLVN1'))  && roles.contains('ZFLCU1')){
            message.setHeader("roles_set", "customer_supplier");
          }
       else if( roles.contains('ZFLVN0') || roles.contains('ZFLVN1')){
            message.setHeader("roles_set", "remove");
        }
        else{
            message.setHeader("roles_set", "any_role");
        }

       return message;
}
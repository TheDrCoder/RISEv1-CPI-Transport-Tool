import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*
import groovy.xml.Namespace
import groovy.xml.XmlUtil
import java.io.StringWriter
import java.io.PrintWriter
import java.net.HttpURLConnection
import com.sap.it.api.securestore.*
import java.net.URLEncoder

def Message processData(Message message) {
    // Get the C4C payload from the exchange property
    def inputPayload = message.getProperty("InputPayload")
    println "Input C4C Payload: ${inputPayload}"
    // Define namespaces
    def ns2 = new Namespace("http://sap.com/xi/XI/SplitAndMerge", "ns2")
    def ns0 = new Namespace("http://sap.com/xi/SAPGlobal20/Global", "ns0")
    // Parse the C4C payload using XmlParser with namespaces
    def parser = new XmlParser(false, false)
    parser.setFeature("http://apache.org/xml/features/disallow-doctype-decl", false)
    parser.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false)
    def c4cXml = parser.parseText(inputPayload)
    println "Parsed C4C XML with namespaces using XmlParser"
    // Parse the S/4HANA payload (assuming no namespaces)
    def s4Xml = parser.parseText(message.getBody(String))
    println "Parsed S4 XML without namespaces using XmlParser"
    // Since there are multiple A_CustomerSalesAreaType elements, we iterate over each
    def s4SalesAreas = s4Xml.A_CustomerSalesAreaType
    def counter = 1000  // Initialize the number variable

    // Debug: Print each SalesArrangement in S/4HANA
    s4SalesAreas.each {
        s4SalesArr -> println "S4 SalesArrangement: SalesOrganization=${s4SalesArr.SalesOrganization?.text()}, DistributionChannel=${s4SalesArr.DistributionChannel?.text()}, Division=${s4SalesArr.Division?.text()}"
    }
    // Navigate through the XML using the namespaces for the top levels and no namespaces for inner nodes
    def c4cSalesArrangements = c4cXml[ns2.Message1][ns0.BusinessPartnerSUITEBulkReplicateRequest].BusinessPartnerSUITEReplicateRequestMessage.BusinessPartner.Customer.SalesArrangement
    c4cSalesArrangements.each {
        c4cSalesArr -> def c4cSalesOrg = c4cSalesArr.SalesOrganisationID.text()
        def c4cDistChannel = c4cSalesArr.DistributionChannelCode.text()
        def c4cDivision = c4cSalesArr.DivisionCode.text()
        println "Processing SalesArrangement from C4C"
        println "C4C SalesOrganisationID: ${c4cSalesOrg}"
        println "C4C DistributionChannelCode: ${c4cDistChannel}"
        println "C4C DivisionCode: ${c4cDivision}"
        // Find the matching SalesArrangement in the S/4HANA payload
        def matchingS4SalesArr = s4SalesAreas.find {
            s4SalesArr -> def s4SalesOrg = s4SalesArr.SalesOrganization?.text()
            def s4DistChannel = s4SalesArr.DistributionChannel?.text()
            def s4Division = s4SalesArr.Division?.text()
            // Print the values being compared
            println "Comparing with S4 SalesOrganisationID: ${s4SalesOrg}, DistributionChannel: ${s4DistChannel}, Division: ${s4Division}"
            return s4SalesOrg == c4cSalesOrg && s4DistChannel == c4cDistChannel && s4Division == c4cDivision
        }
        if (matchingS4SalesArr) {
            println "Matching SalesArrangement found in S4: ${matchingS4SalesArr.SalesOrganization?.text()}-${matchingS4SalesArr.Division?.text()}-${matchingS4SalesArr.DistributionChannel?.text()}"
            // Access the PartnerFunctions node in the C4C payload
            def c4cPartnerFunctionsNode = c4cSalesArr.PartnerFunctions
            // Collect all partner function codes from C4C
            def c4cPartnerFunctionCodes = c4cPartnerFunctionsNode.collect {
                it.PartyRoleCode.text()
            }
            def messageLog = messageLogFactory.getMessageLog(message)
            println "C4C Partner Function Codes: ${c4cPartnerFunctionCodes}"
            if (messageLog != null) {
                counter++  // Increment the value
                messageLog.addAttachmentAsString("${counter}.${matchingS4SalesArr.SalesOrganization?.text()}-${matchingS4SalesArr.Division?.text()}-${matchingS4SalesArr.DistributionChannel?.text()}=C4C Partner Function Codes:", c4cPartnerFunctionCodes.join(", "), "text/plain")
            }
            // Iterate over each PartnerFunction in the matching S/4HANA SalesArrangement
            matchingS4SalesArr.to_PartnerFunction?.A_CustSalesPartnerFuncType?.each {s4PartnerFunction -> 
                def s4PartnerFunctionCode = s4PartnerFunction.PartnerFunction?.text()
                def s4PartnerFunctionDefaultIndicator = s4PartnerFunction.DefaultPartner?.text()
                 // Define S/4HANA Sales Organization and Distribution Channel within the loop
                def s4SalesOrg = matchingS4SalesArr?.SalesOrganization?.text()
                def s4DistChannel = matchingS4SalesArr?.DistributionChannel?.text()
                def s4Division =  matchingS4SalesArr?.Division?.text()
                println "Processing S4 Partner Function: ${s4PartnerFunctionCode}"
                // If the PartnerFunction code from S/4HANA does not exist in C4C, add it to C4C
                if (!c4cPartnerFunctionCodes.contains(s4PartnerFunctionCode)) {
                    println "Adding missing Partner Function from S4 to C4C: ${s4PartnerFunctionCode}"

                    if (messageLog != null) {
                        counter++  // Increment the value
                messageLog.addAttachmentAsString("${counter}.${s4SalesOrg}-${s4Division}-${s4DistChannel}=Adding missing Partner Function from S4 to C4C", s4PartnerFunctionCode, "text/plain")
            }
                    // Determine the correct ReceiverPartyInternalID
                    def receiverPartyInternalID = ""
                    def SenderPartyInternalID = ""
                    if (s4PartnerFunction.BPCustomerNumber?.text()) {
                        receiverPartyInternalID = s4PartnerFunction.BPCustomerNumber.text()
                    } 
                    else if ( s4PartnerFunction.ContactPerson?.text() && s4PartnerFunction.ContactPerson.text()!= "0") 
                    {
                        receiverPartyInternalID = s4PartnerFunction.ContactPerson.text()
                        // Log the OData URL and response code for debugging purposes
                        
                        try {
                            // Step 1: Get the required properties and variables
                            def c4cUrl = message.getProperty("P_C4C_Url")
                            def credentialsName = message.getProperty("P_C4C_CredentialsName")
                            // Step 2: Construct the OData URL
                            def remoteObjectID = URLEncoder.encode(receiverPartyInternalID, "UTF-8")
                            def schemeCode = URLEncoder.encode("927", "UTF-8")
                            def odataUrl = "${c4cUrl}/sap/c4c/odata/v1/c4codataapi/ObjectIdentifierMappingCollection?\$filter=RemoteObjectID%20eq%20'${remoteObjectID}'%20and%20RemoteIdentifierDefiningSchemeCode%20eq%20'${schemeCode}'"
                            //def odataUrl = "${c4cUrl}/sap/c4c/odata/v1/c4codataapi/ObjectIdentifierMappingCollection?\$filter=RemoteObjectID eq '${receiverPartyInternalID}' and RemoteIdentifierDefiningSchemeCode eq '927'"
                            if (messageLog != null) {
                                counter++  // Increment the value
                                messageLog.addAttachmentAsString("${counter}.OData URL -${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", odataUrl, "text/plain")
                            }
                            // Step 3: Retrieve credentials from security material
                            def clientHttp = new com.sap.it.api.ITApiFactory().getApi(com.sap.it.api.securestore.SecureStoreService. class , null)
                            def credentials = clientHttp.getUserCredential(credentialsName)
                            def username = new String(credentials.getUsername())
                            def password = new String(credentials.getPassword())
                           // messageLog.addAttachmentAsString("Username-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", username, "text/plain")
                            //messageLog.addAttachmentAsString("Pwd-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", password, "text/plain")
                            // Step 4: Set up HTTP connection for the OData call
                            def url = new URL(odataUrl)
                            def connection = (HttpURLConnection) url.openConnection()
                            connection.setRequestMethod("GET")
                            connection.setRequestProperty("Authorization", "Basic " + "${username}:${password}".bytes.encodeBase64().toString())
                            connection.setRequestProperty("Accept", "*/*")
                            // Step 5: Execute the OData request
                            def responseCode = connection.getResponseCode()
                            if (messageLog != null) {
                                counter++  // Increment the value
                                messageLog.addAttachmentAsString("${counter}.OData Response Code-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", responseCode.toString(), "text/plain")
                            }
                            if (responseCode == 400) {
                                // Capture and log error response body
                                def errorResponse = connection.getErrorStream()?.getText()
                                if (messageLog != null) {
                                    counter++  // Increment the value
                                    messageLog.addAttachmentAsString("${counter}.OData Error Response Body-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", errorResponse ?: "No response body", "text/plain")
                                    counter++  // Increment the value
                                    messageLog.addAttachmentAsString("${counter}.Response Body-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", connection.getInputStream().getText(), "text/plain")
                                    counter++  // Increment the value
                                    messageLog.addAttachmentAsString("${counter}.Authorization Header-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", authHeader, "text/plain")
                                }
                            }
                            try {

                                if (responseCode == 200) {
                                    // Step 6: Parse the XML response
                                  //  messageLog.addAttachmentAsString("FirstOdataResult-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", "Passed", "text/plain")
                                    def response = connection.getInputStream().getText()
                                    def xmlParser = new XmlSlurper().parseText(response)
                                    if (messageLog != null) {
                                        counter++  // Increment the value
                                        messageLog.addAttachmentAsString("${counter}.Full XML Response-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", response, "text/xml")
                                    }
                                    // Step 7: Extract the LocalObjectID from the response
                                    if (xmlParser.entry.size() > 0 && xmlParser.entry.content.size() > 0 && xmlParser.entry.content.properties.size() > 0) {
                                          // Extract LocalObjectID safely
                                          def localObjectID = xmlParser.entry.content.'properties'.'LocalObjectID'.text()
                                          
                                          // Log the extracted LocalObjectID for debugging
                                          if (messageLog != null && localObjectID) {
                                              counter++  // Increment the value
                                              messageLog.addAttachmentAsString("${counter}.Extracted LocalObjectID-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", localObjectID, "text/plain")
                                          }
      
                  
                                          SenderPartyInternalID = localObjectID
                                          // Perform a second OData call with the LocalObjectID
                                          schemeCode = URLEncoder.encode("888", "UTF-8")
                                          remoteObjectID = URLEncoder.encode(localObjectID, "UTF-8")
                                          // odataUrl = "${c4cUrl}/sap/c4c/odata/v1/c4codataapi/ObjectIdentifierMappingCollection?\$filter=RemoteObjectID eq '${localObjectID}' and RemoteIdentifierDefiningSchemeCode eq '888'"
                                          odataUrl = "${c4cUrl}/sap/c4c/odata/v1/c4codataapi/ObjectIdentifierMappingCollection?\$filter=LocalObjectID%20eq%20'${remoteObjectID}'%20and%20RemoteIdentifierDefiningSchemeCode%20eq%20'${schemeCode}'"
                                          url1 = new URL(odataUrl)
                                          def connection1 = (HttpURLConnection) url1.openConnection()
                                          connection1.setRequestMethod("GET")
                                          connection1.setRequestProperty("Authorization", "Basic " + "${username}:${password}".bytes.encodeBase64().toString())
                                          connection1.setRequestProperty("Accept", "application/xml")
                                          def responseCode1 = connection1.getResponseCode()
                                          if (messageLog != null) {
                                              counter++  // Increment the value
                                              messageLog.addAttachmentAsString("${counter}.Second OData Response Code-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", responseCode1.toString(), "text/plain")
                                          }
                                          if (responseCode1 == 200) {
                                              counter++  // Increment the value
                                              messageLog.addAttachmentAsString("${counter}.SecondtOdataResult-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", "Passed", "text/plain")
                                              def response1 = connection1.getInputStream().getText()
                                              def xmlParser1 = new XmlSlurper().parseText(response1)
                                              def RemoteObjectID = xmlParser1.entry.content.'properties'.'RemoteObjectID'.text()
                                              // Set the RemoteObjectID into the ReceiverPartyInternalID variable
                                              if (messageLog != null) {
                                                  counter++  // Increment the value
                                                  messageLog.addAttachmentAsString("${counter}.Extracted RemoteObjectID-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", RemoteObjectID, "text/plain")
                                              }
                                              receiverPartyInternalID = RemoteObjectID
                                          }
                                    }//if (xmlParser.entry.size() > 0 && xmlParser.entry.content.size() > 0 && xmlParser.entry.content.properties.size() > 0)
                                    else {
                                        if (messageLog != null) {
                                            counter++  // Increment the value
                                            messageLog.addAttachmentAsString("${counter}.Error-XML Element Missing-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", "Error: Necessary XML elements are missing in the response", "text/plain")
                                        }
                                        // Handle the error, e.g., retry the request, skip this iteration, etc.
                                    }
                                }//if (responseCode == 200) 
                                else {
                                    if (messageLog != null) {
                                        counter++  // Increment the value
                                        messageLog.addAttachmentAsString("${counter}.OData Error-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", "Error: Received HTTP response code " + responseCode, "text/plain")
                                    }
                                }
                            }
                            catch (Exception e) {
                                def sw = new StringWriter()
                                def pw = new PrintWriter(sw)
                                e.printStackTrace(pw)
                                if (messageLog != null) {
                                    counter++  // Increment the value
                                    messageLog.addAttachmentAsString("${counter}.Error during First OData-${s4SalesOrg}-${s4DistChannel}-${s4Division}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", sw.toString(), "text/plain")
                                }
                            }
                        } catch (Exception e) {
                            def sw = new StringWriter()
                            def pw = new PrintWriter(sw)
                            e.printStackTrace(pw)
                            if (messageLog != null) {
                                counter++  // Increment the value
                                messageLog.addAttachmentAsString("${counter}.OData Exception-${c4cSalesOrg}-${s4PartnerFunctionCode}-${receiverPartyInternalID}", sw.toString(), "text/plain")
                            }
                        }
                    } else {
                        receiverPartyInternalID = s4PartnerFunction.PartyInternalID.text()
                    }
                    if (c4cPartnerFunctionsNode instanceof NodeList) {
                        // Get the first node from the NodeList
                    } else if (!c4cPartnerFunctionsNode) {
                        println "No PartnerFunctions node found in C4C. Creating new one."
                        c4cPartnerFunctionsNode = c4cSalesArr.appendNode('PartnerFunctions')
                    }
                    if (s4PartnerFunctionCode != "AG" && s4PartnerFunctionCode != "RE" && s4PartnerFunctionCode 
                        != "WE" && s4PartnerFunctionCode != "RG") {                        
                        def newNode = c4cSalesArr.appendNode('PartnerFunctions')
                        //messageLog.addAttachmentAsString("ReceiverPartyInternalID", receiverPartyInternalID, "text/plain")
                        newNode.@actionCode = "04"
                        newNode.appendNode('PartyRoleCode', s4PartnerFunctionCode)
                        newNode.appendNode('PartyInternalID', SenderPartyInternalID)
                        newNode.appendNode('ReceiverPartyInternalID', receiverPartyInternalID)
                        //newNode.appendNode('PartyRoleCode', "Z4")
                        //newNode.appendNode('PartyInternalID', SenderPartyInternalID)
                        //newNode.appendNode('ReceiverPartyInternalID', "70012157")
                        newNode.appendNode('DefaultIndicator', s4PartnerFunctionDefaultIndicator)
                        // Print the newly added node
                        println "Newly Added PartnerFunction Node: ${XmlUtil.serialize(newNode)}"
                    }
                } 
                else {
                    println "Partner Function already exists in C4C: ${s4PartnerFunctionCode}"
                }
            }
        } 
        else {
            println "No matching SalesArrangement found in S4 for C4C SalesOrganisationID: ${c4cSalesOrg}"
        }
    }
    // Serialize the enriched C4C XML back to a string
    def outputXml = XmlUtil.serialize(c4cXml)
    println "Final enriched C4C Payload: ${outputXml}"
    message.setBody(outputXml)
    return message
}

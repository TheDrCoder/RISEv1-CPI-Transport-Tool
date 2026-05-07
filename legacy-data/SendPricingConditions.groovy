import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*
import java.net.HttpURLConnection
import java.net.URL
import com.sap.it.api.securestore.*
import com.sap.it.api.ITApiFactory
import java.util.HashMap
import groovy.xml.Namespace
import groovy.xml.XmlUtil
import java.io.StringWriter
import java.io.PrintWriter
import java.net.URLEncoder

def Message processData(Message message) {
    def body = message.getBody(java.lang.String) as String
    def xml = new XmlSlurper().parseText(body)
    def messageLog = messageLogFactory.getMessageLog(message)

    // Step 1: Check if <E1KOMG> node has <KUNNR> value and remove leading zeros
    def C4CExternalID = xml.IDOC.E1KOMG.KUNNR?.text()?.replaceFirst('^0+(?!$)', '')
    if (!C4CExternalID) {
        throw new Exception("No KUNNR found in the payload.")
    }

    // Log the modified C4CExternalID value for debugging
    //messageLog.addAttachmentAsString("Modified C4CExternalID (no leading zeros)", C4CExternalID, "text/plain")

    // Step 3: Check if <E1KOMG> has <KONDM> value and assign SalesOrgC4CCode
    def SalesOrgC4CCode = xml.IDOC.E1KOMG.KONDM?.text()
    if (!SalesOrgC4CCode) {
        throw new Exception("No KONDM found in the payload.")
    }
   // messageLog.addAttachmentAsString("SalesOrgC4CCode", SalesOrgC4CCode, "text/plain")

    // Step 4: Determine SalesOrgC4C based on SalesOrgC4CCode
    def SalesOrgC4C = ""
    switch (SalesOrgC4CCode) {
        case 'M': SalesOrgC4C = "_10"; break
        case 'T': SalesOrgC4C = "_20"; break
        case 'E': SalesOrgC4C = "_30"; break
        default: throw new Exception("Unknown SalesOrgC4CCode value: ${SalesOrgC4CCode}")
    }
    //messageLog.addAttachmentAsString("SalesOrgC4C", SalesOrgC4C, "text/plain")

    // Step 5: Check for <E1KONH> and <E1KONP> and <KSCHL> in the payload
   // def E1KONP = xml.IDOC.E1KOMG.E1KONH.E1KONP
   // def KSCHL = E1KONP.KSCHL?.text()
     // Step 5: Select the <E1KONH> segment with <DATBI> value of '99991231'
    def E1KONHs = xml.IDOC.E1KOMG.'E1KONH'
    def latestE1KONH = E1KONHs[0]  // Default to the first segment in case there is only one
    def latestDate = latestE1KONH.DATBI.text() as String

    E1KONHs.each { segment ->
        def currentDate = segment.DATBI.text() as String
        if (currentDate.compareTo(latestDate) > 0) {
            latestDate = currentDate
            latestE1KONH = segment
        }
    }
    def E1KONP = latestE1KONH.E1KONP
    def KSCHL = E1KONP.KSCHL?.text()
    if (!KSCHL) {
        throw new Exception("No KSCHL found in selected <E1KONP> node.")
    }
    if (!KSCHL) {
        throw new Exception("No KSCHL found in <E1KONP> node.")
    }
    //messageLog.addAttachmentAsString("KSCHL", KSCHL, "text/plain")

    // Step 6: Create C4CPricingFieldName with conditional logic
    def C4CPricingFieldName = SalesOrgC4C == "_10" ? "Z_" + KSCHL + "_KUT" : "Z_" + KSCHL + SalesOrgC4C + "_KUT"
   // messageLog.addAttachmentAsString("C4CPricingFieldName", C4CPricingFieldName, "text/plain")


    // Step 7: Retrieve <KBETR> for C4CPricingFieldValue
    def KBETR = E1KONP.KBETR?.text()
    if (!KBETR) {
        throw new Exception("No KBETR found in <E1KONP> node.")
    }
    def C4CPricingFieldValue = KBETR + "%"
   // messageLog.addAttachmentAsString("C4CPricingFieldValue", C4CPricingFieldValue, "text/plain")

    // Step 8: OData GET call to C4C to fetch CustomerObject ID
    def c4cHost = message.getProperty("P_C4CHost") as String
    def credentialName = message.getProperty("P_CredentialName") as String

   // messageLog.addAttachmentAsString("C4C_Host", c4cHost, "text/plain")
  //  messageLog.addAttachmentAsString("CredentialName", credentialName, "text/plain")

    def securityStore = ITApiFactory.getApi(SecureStoreService.class, null)
    def credential = securityStore.getUserCredential(credentialName)
    if (!credential) {
        throw new Exception("Credential ${credentialName} not found.")
    }
    def username = credential.getUsername()
    def password = new String(credential.getPassword())

    // Construct the OData GET URL with only ExternalID encoded
    def finalUrl = "${c4cHost}/sap/c4c/odata/v1/c4codataapi/CorporateAccountCollection?\$filter=ExternalID%20eq%20'${C4CExternalID}'"

    // Log the generated URL for debugging
   // messageLog.addAttachmentAsString("Generated OData URL", finalUrl, "text/plain")

    def url = new URL(finalUrl)
    def connection = url.openConnection() as HttpURLConnection
    connection.setRequestMethod("GET")
    connection.setRequestProperty("Authorization", "Basic " + "${username}:${password}".bytes.encodeBase64().toString())

    def responseCode = connection.responseCode
    def C4CObjectID = null
    if (responseCode == 200) {
        def responseXml = new XmlSlurper().parse(connection.inputStream)
        def entries = responseXml.'**'.findAll { it.name() == 'ObjectID' }

        // Check if only one entry is returned, else throw an exception
        if (entries.size() != 1) {
            throw new Exception("External ID is not correct: found ${entries.size()} entries")
        }

        // Retrieve the single ObjectID
        C4CObjectID = entries[0].text()
        if (!C4CObjectID) {
            throw new Exception("No ObjectID found in C4C response.")
        }
    } else {
        throw new Exception("Failed to fetch ObjectID: HTTP ${responseCode}")
    }

    // Step 9: OData PATCH call to update C4C CorporateAccount
    def patchUrl = "${c4cHost}/sap/c4c/odata/v1/c4codataapi/CorporateAccountCollection('${C4CObjectID}')"
    //messageLog.addAttachmentAsString("Generated PATCH URL", patchUrl, "text/plain")
    

    def patchConnection
    def patchResponseCode
    def retryCount = 0
    def maxRetries = 5

    // Retry mechanism
    while (retryCount < maxRetries) {
        try {
            patchConnection = new URL(patchUrl).openConnection() as HttpURLConnection
            patchConnection.setDoOutput(true)  // Enable output for writing to the connection
            patchConnection.setRequestMethod("POST")  // Workaround for PATCH
            patchConnection.setRequestProperty("Authorization", "Basic " + "${username}:${password}".bytes.encodeBase64().toString())
            patchConnection.setRequestProperty("Content-Type", "application/json")
            patchConnection.setRequestProperty("X-HTTP-Method-Override", "PATCH")  // Specify PATCH override

            // Construct JSON body and log it for debugging
            def jsonBody = """{
                "${C4CPricingFieldName}": "${C4CPricingFieldValue}"
            }"""
            messageLog.addAttachmentAsString("PATCH JSON Body", jsonBody, "application/json")

            patchConnection.outputStream.withWriter("UTF-8") { writer -> writer << jsonBody }
            patchResponseCode = patchConnection.responseCode

            if (patchResponseCode == 204) {
                message.setBody("Patch operation successful")
                break // Exit loop if successful
            } else {
                def responseMessage = patchConnection.errorStream?.text
                messageLog.addAttachmentAsString("PATCH Error Response", responseMessage, "text/plain")
                throw new Exception("Patch operation failed: HTTP ${patchResponseCode}")
            }
        } catch (Exception e) {
            retryCount++
            messageLog.addAttachmentAsString("PATCH Retry Attempt", "Attempt ${retryCount}: ${e.message}", "text/plain")
            if (retryCount == maxRetries) {
                throw new Exception("Patch operation failed after ${maxRetries} attempts: ${e.message}")
            }
            // Optional: Add sleep between retries
            Thread.sleep(2000) // Sleep for 2 seconds before retrying
        }
    }

/*
    def patchConnection = new URL(patchUrl).openConnection() as HttpURLConnection
    patchConnection.setDoOutput(true)  // Enable output for writing to the connection
    patchConnection.setRequestMethod("POST")  // Workaround for PATCH
    patchConnection.setRequestProperty("Authorization", "Basic " + "${username}:${password}".bytes.encodeBase64().toString())
    patchConnection.setRequestProperty("Content-Type", "application/json")
    patchConnection.setRequestProperty("X-HTTP-Method-Override", "PATCH")  // Specify PATCH override

    // Construct JSON body and log it for debugging
    def jsonBody = """{
        "${C4CPricingFieldName}": "${C4CPricingFieldValue}"
    }"""
    messageLog.addAttachmentAsString("PATCH JSON Body", jsonBody, "application/json")

    patchConnection.outputStream.withWriter("UTF-8") { writer -> writer << jsonBody }

    def patchResponseCode = patchConnection.responseCode
    messageLog.addAttachmentAsString("PATCH Response Code", patchResponseCode.toString(), "text/plain")

    if (patchResponseCode == 204) {
        message.setBody("Patch operation successful")
    } else {
        def responseMessage = patchConnection.errorStream?.text
        messageLog.addAttachmentAsString("PATCH Error Response", responseMessage, "text/plain")
        throw new Exception("Patch operation failed: HTTP ${patchResponseCode}")
    }
*/
    return message
}

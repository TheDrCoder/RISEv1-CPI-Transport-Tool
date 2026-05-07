import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

def Message processData(Message message) {
    def body = message.getBody(java.lang.String) as String

    // Removed initial payload print statement

    def xmlParser = new XmlParser(false, false)
    def xml = xmlParser.parseText(body)
    println("Parsed XML successfully.")

    def ns1 = new groovy.xml.Namespace("http://sap.com/xi/XI/SplitAndMerge", 'ns1')
    def ns0 = new groovy.xml.Namespace("http://sap.com/xi/SAPGlobal20/Global", 'ns0')
    println("Namespaces defined.")

    def messagesNode = xml[ns1.Message2][0]
    if (messagesNode) {
        println("Found Message2 node.")

        def bulkRequestNode = messagesNode[ns0.BusinessPartnerSUITEBulkReplicateRequest][0]
        if (bulkRequestNode) {
            println("Found BusinessPartnerSUITEBulkReplicateRequest node.")

            // Print the structure of the bulkRequestNode
            println("Children of BusinessPartnerSUITEBulkReplicateRequest node:")
            bulkRequestNode.children().each { child ->
                println(child.name())
            }

            // Attempt to access BusinessPartnerSUITEReplicateRequestMessage directly
            def replicateRequestMessages = bulkRequestNode.'BusinessPartnerSUITEReplicateRequestMessage'
            println("Number of BusinessPartnerSUITEReplicateRequestMessage nodes: " + replicateRequestMessages.size())

            replicateRequestMessages.each { messageNode ->
                println("Processing BusinessPartnerSUITEReplicateRequestMessage.")
                def businessPartners = messageNode.'BusinessPartner'
                println("Number of BusinessPartner nodes: " + businessPartners.size())
                businessPartners.each { bpNode ->
                    println("Processing BusinessPartner.")
                    def roleCode = bpNode.'Role'.'RoleCode'.text()
                    println("RoleCode: " + roleCode)

                    def newCodeValue = getCodeValue(roleCode)
                    println("New NumberRangeIntervalBusinessPartnerGroupCode: " + newCodeValue)

                    def newElement = new Node(bpNode, 'NumberRangeIntervalBusinessPartnerGroupCode', newCodeValue)
                    println("Added new NumberRangeIntervalBusinessPartnerGroupCode element.")
                }
            }
        } else {
            println("BusinessPartnerSUITEBulkReplicateRequest node not found.")
        }
    } else {
        println("Message2 node not found.")
    }

    def writer = new StringWriter()
    def xmlNodePrinter = new XmlNodePrinter(new PrintWriter(writer))
    xmlNodePrinter.setPreserveWhitespace(true)
    xmlNodePrinter.print(xml)
    println("Converted XML back to string.")

    message.setBody(writer.toString())
    println("Final Payload: \n" + writer.toString())

    return message
}

def getCodeValue(roleCode) {
    switch (roleCode) {
        case "ZFLCU2":
            return "ZWE"
        case "BUP001":
            return "PBAP"
        default:
            return "ZBP"
    }
}

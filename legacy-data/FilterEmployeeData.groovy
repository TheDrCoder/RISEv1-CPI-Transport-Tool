import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

Message processData(Message message) {
    // Get the XML payload from the message
    def body = message.getBody(java.lang.String) as String

    // Parse the XML payload
    def xml
    try {
        xml = new XmlParser(false, false).parseText(body) // Disable namespaces and validation
        println "Debug: XML parsed successfully."
    } catch (Exception e) {
        println "Debug: Error parsing XML - ${e.message}"
        message.setBody(body)
        return message
    }

    // Locate the <E1PLOGI> node
    def e1plogi = xml.depthFirst().find { it.name() == 'E1PLOGI' }
    if (!e1plogi) {
        println "Debug: <E1PLOGI> node not found. Check XML structure."
        message.setBody(body)
        return message
    }

    println "Debug: <E1PLOGI> node found. Proceeding with filtering."

    // Filter <E1PITYP> segments
    def originalCount = e1plogi.children().findAll { it.name() == 'E1PITYP' }.size()
    println "Debug: Original <E1PITYP> count: ${originalCount}"

    def filteredE1PITYP = e1plogi.children().findAll { it.name() == 'E1PITYP' }.findAll { e1pityp ->
        def containsBegda1990 = e1pityp.children().findAll { it.name() == 'E1P0002' }.any { e1p0002 ->
            e1p0002.children().find { it.name() == 'BEGDA' }?.text()?.startsWith("1990")
        }
        if (containsBegda1990) {
            println "Debug: Filtering out <E1PITYP> with OBJID: ${e1pityp.children().find { it.name() == 'OBJID' }?.text()} because it contains BEGDA starting with 1990."
        }
        return !containsBegda1990
    }

    def filteredCount = filteredE1PITYP.size()
    println "Debug: Remaining <E1PITYP> count after filtering: ${filteredCount}"

    // Remove all <E1PITYP> nodes
    e1plogi.children().removeAll { it.name() == 'E1PITYP' }

    // Add back the filtered segments
    filteredE1PITYP.each { e1plogi.append(it) }

    // Convert the modified XML back to a string
    def writer = new StringWriter()
    new XmlNodePrinter(new PrintWriter(writer)).print(xml)
    def updatedXml = writer.toString()

    println "Debug: XML filtering process completed successfully."

    // Set the updated XML as the message body
    message.setBody(updatedXml)

    return message
}

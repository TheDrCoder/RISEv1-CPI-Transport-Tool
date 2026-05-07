import com.sap.gateway.ip.core.customdev.util.Message
import groovy.xml.*

def Message processData(Message message) {
    def xmlString = message.getBody(java.lang.String)

    // Parse the XML
    def xmlParser = new XmlSlurper().parseText(xmlString).declareNamespace(
        '': 'http://sap.com/xi/SAPGlobal20/Global', // Default namespace
        'xsi': 'http://www.w3.org/2001/XMLSchema-instance' // xsi namespace
    )

    // Process each BusinessPartnerRelationshipSUITEReplicateRequestMessage
    xmlParser.'**'.findAll { it.name() == 'BusinessPartnerRelationshipSUITEReplicateRequestMessage' }.each { relationshipMessage ->

        relationshipMessage.'**'.findAll { it.name() == 'ContactPerson' }.each { contactPerson ->

            def customerContact = contactPerson.CustomerContactPerson
            def supplierContact = contactPerson.SupplierContactPerson

            // Handle CustomerContactPerson.InternalID Replacement
            if (customerContact?.InternalID?.text()?.trim() in [null, '', '0000000000']) {
                def supplierID = supplierContact?.InternalID?.text()?.trim()
                if (supplierID) {
                    // Replace CustomerContactPerson with simplified structure
                    customerContact.replaceNode {
                        CustomerContactPerson {
                            mkp.declareNamespace(xsi: 'http://www.w3.org/2001/XMLSchema-instance')
                            InternalID(supplierID)
                        }
                    }

                    // Update the entire ContactPerson section
                    contactPerson.replaceNode {
                        ContactPerson(actionCode: "04", workplaceAddressListCompleteTransmissionIndicator: "true") {
                            mkp.declareNamespace(xsi: 'http://www.w3.org/2001/XMLSchema-instance')
                            BusinessPartnerFunctionTypeCode('', ['xsi:nil': 'true'])
                            BusinessPartnerFunctionalAreaCode('', ['xsi:nil': 'true'])
                            VIPReasonCode('', ['xsi:nil': 'true'])
                            CustomerContactPerson {
                                InternalID(supplierID)
                            }
                        }
                    }

                    println("Updated ContactPerson section with InternalID: ${supplierID}")
                }
            }

            // Handle RoleCode Update (if applicable)
            def roleCode = relationshipMessage.RoleCode?.text()?.trim()
            if (roleCode == "BUR001") {
                relationshipMessage.RoleCode.replaceNode {
                    RoleCode("Z001")
                }
                println("Updated RoleCode from BUR001 to Z001")
            }
        }
    }

    // Serialize and return the updated XML
    try {
        def updatedXmlString = XmlUtil.serialize(xmlParser)
        println("Serialized XML: ${updatedXmlString}")
        message.setBody(updatedXmlString)
    } catch (Exception e) {
        println("Serialization Error: ${e.message}")
        throw e
    }

    return message
}

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output indent="yes" />
<xsl:template match="@*|node()">
    <xsl:copy>
          <xsl:apply-templates select="@*|node()"/>
     </xsl:copy>
</xsl:template>
  <xsl:template match="Identification[(PartyIdentifierTypeCode = 'HCM028') or ((PartyIdentifierTypeCode = 'HCM030')) or ((PartyIdentifierTypeCode = 'HCM031'))
  or ((PartyIdentifierTypeCode = 'HCM032')) or ((PartyIdentifierTypeCode = 'HCM033'))] "/>
</xsl:stylesheet>

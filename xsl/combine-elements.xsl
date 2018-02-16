<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY functions "('arccos','arcsin','arctan','arg','cos','cosh','cot','coth','cov','csc','deg','det',
                       'dim','exp','gcd','glb','hom','lm','inf','int','ker','lg','lim','ln','log','lub',
                       'max','min','mod','Pr','Re','sev','sgn','sin','sinh','sup','tan','tanh','var')">
]>
<xsl:stylesheet 
	 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	 xmlns="http://www.w3.org/1998/Math/MathML"
	 xpath-default-namespace="http://www.w3.org/1998/Math/MathML"
	 version="2.0">
  <xsl:import href="identity.xsl"/>

  <xsl:param name="functions" select="&functions;"/>

  <xsl:template match="*[count(mtext) ge 2 or count(mi[@mathvariant = 'normal']) ge 2]" mode="combine-mtext">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:for-each-group  select="node()"
        group-adjacent="(
          .[
            @mathvariant = 'normal' or self::mtext[not(@mathvariant)]
          ][
            not(preceding-sibling::*[1]/local-name() = ('mtext','mi')) 
            or (every $a in ./@* except @mathvariant satisfies (
              (some $pa in preceding-sibling::*[1]/@* satisfies $pa = $a)
              or
              (some $pa in following-sibling::*[1]/@* satisfies $pa = $a)
            ))
          ]/local-name()[. = ('mtext', 'mi')], ''
          )[1]">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:element name="{current-grouping-key()}">
              <xsl:apply-templates select="@*" mode="#current"/>
              <xsl:value-of select="current-group()/text()"/>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates mode="#current" select="current-group()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="*[count(mn) ge 2]" mode="combine-mn">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:for-each-group 
        group-adjacent="local-name() = 'mn' and 
        (
          not(preceding-sibling::*[1] = mn) 
          or (every $a in @* satisfies (some $pa in preceding-sibling::*[1]/@* satisfies $pa = $a))
        )" select="node()">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:choose>
            <xsl:when test="current-group()[1]/@start-function">
              <mi mathvariant="normal">
                <xsl:apply-templates select="current-group()[1]/@* except @start-function"/>
                <xsl:value-of select="current-group()/text()"/>
              </mi>
            </xsl:when>
            <xsl:otherwise>
              <mn>
                <xsl:apply-templates select="current()[1]/@*"/>
                <xsl:value-of select="current-group()/text()"/>
              </mn>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="#current" select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <xsl:template match="mi/@start-function" mode="detect-functions"/>
  <xsl:template match="mn" mode="detect-functions">
    <xsl:variable name="self" select="."/>
    <xsl:analyze-string select="text()" regex="{string-join($functions,'|')}">
      <xsl:matching-substring>
        <mi>
          <xsl:apply-templates mode="#current" select="$self/@* except $self/@start-function"/>
          <xsl:value-of select="current()"/>
        </mi>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <mn>
          <xsl:apply-templates mode="#current" select="$self/@* except $self/@start-function"/>
          <xsl:value-of select="current()"/>
        </mn>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <xsl:template match="msub[following-sibling::*[1][self::msub]]" mode="combine-others">
    <xsl:variable name="self" select="."/>
    <xsl:variable name="following-msubs">
      <xsl:variable name="following-nodes" select="(following-sibling::node())"/>
      <xsl:for-each select="$following-nodes[not(preceding-sibling::*[not(self::msub)])]">
        <xsl:sequence select="."></xsl:sequence>
      </xsl:for-each>
    </xsl:variable>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="empty($following-msubs)">
          <xsl:apply-templates select="@*, node(), $following-msubs/*/node()" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <mrow>
            <xsl:apply-templates select="@*, node(), $following-msubs/*/node()" mode="#current"/>
          </mrow>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="msub[preceding-sibling::*[1][self::msub]]" mode="combine-others" priority="2"/>
  
  <xsl:template match="/" mode="combine-elements">
    <xsl:variable name="combine-others">
      <xsl:apply-templates mode="combine-others" select="."/>
    </xsl:variable>
    <xsl:variable name="combine-mn">
      <xsl:apply-templates mode="combine-mn" select="$combine-others"/>
    </xsl:variable>
    <xsl:variable name="combine-mtext">
      <xsl:apply-templates mode="combine-mtext" select="$combine-mn"/>
    </xsl:variable>
    <xsl:apply-templates mode="detect-functions" select="$combine-mtext"/>
  </xsl:template>

</xsl:stylesheet>

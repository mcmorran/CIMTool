<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:a="http://langdale.com.au/2005/Message#"
	xmlns:sawsdl="http://www.w3.org/ns/sawsdl">

	<xsl:output indent="yes" method="text" encoding="utf-8" />
	<xsl:param name="version"/>
	<xsl:param name="baseURI"/>
	<xsl:param name="envelope">Profile</xsl:param>

	<xsl:template name="ident">
		<xsl:param name="name" select="@name"/>
		<xsl:text>"</xsl:text><xsl:value-of select="$name"/><xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:param name="mridType">CHAR VARYING(30)</xsl:param>

	<xsl:template name="type">
		<xsl:text> </xsl:text>
		<xsl:choose>
			<xsl:when test="@xstype = 'string'">CHAR VARYING(30)</xsl:when>
			<xsl:when test="@xstype = 'integer' or @xstype = 'int'">INTEGER</xsl:when>
			<xsl:when test="@xstype = 'float'">FLOAT</xsl:when>
			<xsl:when test="@xstype = 'boolean'">CHAR(1)</xsl:when>
			<xsl:otherwise>CHAR VARYING(30)</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="notnull">
		<xsl:if test="@minOccurs > 0"> NOT NULL</xsl:if>
	</xsl:template>
	
	<xsl:template name="dedent">
		<xsl:text>
</xsl:text>
	</xsl:template>
	
	<xsl:template name="indent">
		<xsl:text>
	</xsl:text>
	</xsl:template>
	
	<xsl:template name="begin">
		<xsl:text> (</xsl:text>
		<xsl:call-template name="indent"/>
	</xsl:template>
	
	<xsl:template name="comma">
		<xsl:text>,</xsl:text>
		<xsl:call-template name="indent"/>
	</xsl:template>
	
	<xsl:template name="end">
		<xsl:call-template name="dedent"/>
		<xsl:text>);</xsl:text>
		<xsl:call-template name="dedent"/>
		<xsl:call-template name="indent"/>
	</xsl:template>

	<xsl:template match="a:Catalog">
		<!--  the top level template  -->
		<xsl:call-template name="dedent"/>
		<xsl:text>-- Schema for </xsl:text>
		<xsl:value-of select="$envelope" />
		<xsl:call-template name="dedent"/>
		<xsl:text>-- Generated by CIMTool http://cimtool.org</xsl:text>
		<xsl:call-template name="dedent"/>
		<xsl:call-template name="indent"/>
		<xsl:apply-templates/>
		<xsl:call-template name="dedent"/>
		<xsl:call-template name="indent"/>
		<xsl:apply-templates mode="constraints"/>
	</xsl:template>

	<xsl:template match="a:ComplexType|a:Root">
		<!-- a table -->
		<xsl:call-template name="annotate" />
		<xsl:call-template name="dedent"/> 
		<xsl:text>CREATE TABLE </xsl:text>
		<xsl:call-template name="ident"/> 
		<xsl:call-template name="begin"/>
		<xsl:text>"mRID" </xsl:text><value-of select="$mridType"/>
		<xsl:text> NOT NULL UNIQUE</xsl:text>
		<xsl:apply-templates/>
		<xsl:call-template name="end"/>
	</xsl:template>

	<xsl:template match="a:ComplexType|a:Root" mode="constraints" >
		<xsl:apply-templates mode="constraints"/>
	</xsl:template>
	
	<xsl:template match="a:SuperType" mode="constraints">
		<xsl:text>-- subclass-superclass constraint</xsl:text>
		<xsl:call-template name="dedent"/>
		<xsl:text>ALTER TABLE </xsl:text>
		<xsl:call-template name="ident">
			<xsl:with-param name="name" select="../@name"/>
		</xsl:call-template>
		<xsl:text> ADD FOREIGN KEY ( "mRID" ) REFERENCES </xsl:text>
		<xsl:call-template name="ident"/>
		<xsl:text> ( "mRID" );</xsl:text>
		<xsl:call-template name="dedent"/> 
	</xsl:template>

	<xsl:template match="a:EnumeratedType">
		<!-- a reference table for an enumeration -->
		<xsl:call-template name="annotate" />
		<xsl:call-template name="dedent"/> 
		<xsl:text>CREATE TABLE </xsl:text>
		<xsl:call-template name="ident"/> 
		<xsl:call-template name="begin"/>
		<xsl:text> "name" CHAR VARYING(30) UNIQUE</xsl:text>
		<xsl:call-template name="end"/>

		<xsl:variable name="name" select="@name"/>
		<xsl:for-each select="a:EnumeratedValue">
			<!-- inserts one value into a reference table -->
			<xsl:call-template name="annotate" />
			<xsl:call-template name="dedent"/>
			<xsl:text>INSERT INTO </xsl:text>
    		<xsl:call-template name="ident">
    			<xsl:with-param name="name" select="$name"/>
    		</xsl:call-template> 
			<xsl:text> ( "name" ) VALUES ( '</xsl:text>
			<xsl:value-of select="@name"/>
			<xsl:text>' );</xsl:text>
			<xsl:call-template name="indent"/>	   
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="a:Instance|a:Reference">
		<xsl:if test="@maxOccurs &lt;= 1 and @name != 'mRID'">
			<!-- a foreign key column -->
			<xsl:call-template name="comma"/>
			<xsl:call-template name="annotate" />
			<xsl:call-template name="ident"/>
			<xsl:text> </xsl:text><value-of select="$mridType"/>
			<xsl:call-template name="notnull"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="a:Instance|a:Reference" mode="constraints">
		<xsl:if test="@maxOccurs &lt;= 1 and @name != 'mRID'">
			<xsl:text>-- association constraint</xsl:text>
			<xsl:call-template name="dedent"/>
			<xsl:text>ALTER TABLE </xsl:text>
			<xsl:call-template name="ident">
				<xsl:with-param name="name" select="../@name"/>
			</xsl:call-template>
			<xsl:text> ADD FOREIGN KEY ( </xsl:text>
			<xsl:call-template name="ident"/>
			<xsl:text> ) REFERENCES </xsl:text>  
	   		<xsl:call-template name="ident">
				<xsl:with-param name="name" select="@type"/>
			</xsl:call-template> 
			<xsl:text> ( "mRID" );</xsl:text> 
			<xsl:call-template name="dedent"/> 
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="a:Enumerated">
		<!-- a foreign key column for a reference table -->
		<xsl:call-template name="comma"/>
		<xsl:call-template name="annotate" />
		<xsl:call-template name="ident"/>
		<xsl:text> CHAR VARYING(30)</xsl:text>
		<xsl:call-template name="notnull"/>
	</xsl:template>
	
	<xsl:template match="a:Enumerated" mode="constraints">
		<xsl:text>-- enumerated value constraint</xsl:text>
		<xsl:call-template name="dedent"/>
		<xsl:text>ALTER TABLE </xsl:text>
		<xsl:call-template name="ident">
			<xsl:with-param name="name" select="../@name"/>
		</xsl:call-template>
		<xsl:text> ADD FOREIGN KEY ( </xsl:text>
		<xsl:call-template name="ident"/>
		<xsl:text> ) REFERENCES </xsl:text>  
   		<xsl:call-template name="ident">
			<xsl:with-param name="name" select="@type"/>
		</xsl:call-template> 
		<xsl:text> ( "name" );</xsl:text> 
		<xsl:call-template name="dedent"/> 
	</xsl:template>

	<xsl:template match="a:Simple|a:Domain">
		<!-- a simple column  -->
		<xsl:if test="@maxOccurs &lt;= 1 and @name != 'mRID'">
			<xsl:call-template name="comma"/>
			<xsl:call-template name="annotate" />
			<xsl:call-template name="ident"/>
			<xsl:call-template name="type"/>
			<xsl:call-template name="notnull"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="annotate">
		<!--  generate and annotation -->
		<xsl:apply-templates mode="annotate"/>
	</xsl:template>

	<xsl:template match="a:Comment|a:Note" mode="annotate">
		<!--  generate human readable annotation -->
		<xsl:variable name="text" select="normalize-space()"/>
		<xsl:if test="string-length($text) > 0">
			<xsl:text>--  </xsl:text>
			<xsl:value-of select="$text"/>
			<xsl:call-template name="indent"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="text()">
		<!--  dont pass text through  -->
	</xsl:template>

	<xsl:template match="node()" mode="constraints">
		<!-- dont pass any defaults in constraints mode -->
	</xsl:template>

	<xsl:template match="node()" mode="annotate">
		<!-- dont pass any defaults in annotate mode -->
	</xsl:template>

</xsl:stylesheet>
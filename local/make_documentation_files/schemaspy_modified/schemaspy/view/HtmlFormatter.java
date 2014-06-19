/*
 * This file is a part of the SchemaSpy project (http://schemaspy.sourceforge.net).
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 John Currier
 *
 * SchemaSpy is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * SchemaSpy is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */
package schemaspy.view;

import java.io.IOException;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import schemaspy.Config;
import schemaspy.Revision;
import schemaspy.model.Database;
import schemaspy.model.Table;
import schemaspy.model.TableColumn;
import schemaspy.util.Dot;
import schemaspy.util.HtmlEncoder;
import schemaspy.util.LineWriter;

public class HtmlFormatter {
    protected final boolean encodeComments       = Config.getInstance().isEncodeCommentsEnabled();
    protected final boolean displayNumRows       = Config.getInstance().isNumRowsEnabled();
    private   final boolean isMetered            = Config.getInstance().isMeterEnabled();

    protected HtmlFormatter() {
    }//

    protected void writeHeader(Database db, Table table, String text, boolean showOrphans, List<String> javascript, LineWriter out) throws IOException {
        out.writeln("<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' 'http://www.w3.org/TR/html4/loose.dtd'>");
        out.writeln("<html>");
        out.writeln("<head>");
        out.writeln("  <!-- SchemaSpy rev " + new Revision() + " -->");
        out.write("  <title>SchemaSpy - ");
        out.write(getDescription(db, table, text, false));
        out.writeln("</title>");
        out.write("  <link rel=stylesheet href='");
        if (table != null)
            out.write("../");
        out.writeln("schemaSpy.css' type='text/css'>");
        out.writeln("  <link rel=stylesheet href='"+(table == null ? "" : "../") +"base.css' type='text/css'>");
        out.writeln("  <link rel=stylesheet href='"+(table == null ? "" : "../") +"tables.css' type='text/css'>");
        out.writeln("  <link rel=stylesheet href='"+(table == null ? "" : "../") +"grid.css' type='text/css'>");
        out.writeln("  <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=" + Config.getInstance().getCharset() + "'>");
        out.writeln("  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='" + (table == null ? "" : "../") + "jquery.js'></SCRIPT>");
        out.writeln("  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript' SRC='" + (table == null ? "" : "../") + "schemaSpy.js'></SCRIPT>");
        if (table != null) {
            out.writeln("  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
            out.writeln("    table='" + table + "';");
            out.writeln("  </SCRIPT>");
        }
        if (javascript != null) {
            out.writeln("  <SCRIPT LANGUAGE='JavaScript' TYPE='text/javascript'>");
            for (String line : javascript)
                out.writeln("    " + line);
            out.writeln("  </SCRIPT>");
        }
        out.writeln("</head>");
        out.writeln("<body>");
        writeTableOfContents(showOrphans, out);
        out.writeln("<div class='content' style='clear:both;'>");
        out.writeln("<div class='container'>");
        out.writeln("<table width='100%' border='0' cellpadding='0'>");
        out.writeln(" <tr>");
        out.write("  <td class='heading' valign='middle'>");
        out.write("<span class='header'>");
        if (table == null)
            out.write("Analysis of ");
        out.write(getDescription(db, table, text, true));
        out.write("</span>");
        if (table == null && db.getDescription() != null)
            out.write("<span class='description'>" + db.getDescription().replace("\\=", "=") + "</span>");

        String comments = table == null ? null : table.getComments();
        if (comments != null) {
            out.write("<div style='padding: 0px 4px;'>");
            if (encodeComments)
                for (int i = 0; i < comments.length(); ++i)
                    out.write(HtmlEncoder.encodeToken(comments.charAt(i)));
            else
                out.write(comments);
            out.writeln("</div><p>");
        }
        out.writeln("</td>");;
        //out.writeln("  <td class='heading' align='right' valign='top' title='John Currier - Creator of Cool Tools'><span class='indent'>Generated by</span><br><span class='indent'><span class='signature'><a href='http://schemaspy.sourceforge.net' target='_blank'>SchemaSpy</a></span></span></td>");
        out.writeln(" </tr>");
        out.writeln("</table>");
    }

    /**
     * Convenience method for all those formatters that don't deal with JavaScript
     */
    protected void writeHeader(Database db, Table table, String text, boolean showOrphans, LineWriter out) throws IOException {
        writeHeader(db, table, text, showOrphans, null, out);
    }

    protected void writeGeneratedBy(String connectTime, LineWriter html) throws IOException {
        html.write("<span class='container'>");
        html.write("Generated by <span class='signature'><a href='http://schemaspy.sourceforge.net' target='_blank'>SchemaSpy</a></span> on ");
        html.write(connectTime);
        html.writeln("</span>");
    }

    protected void writeTableOfContents(boolean showOrphans, LineWriter html) throws IOException {
        /*// don't forget to modify HtmlMultipleSchemasIndexPage with any changes to 'header' or 'headerHolder'
        String path = getPathToRoot();
        // have to use a table to deal with a horizontal scrollbar showing up inappropriately
        html.writeln("<table id='headerHolder' cellspacing='0' cellpadding='0'><tr><td>");
        html.writeln("<div id='header'>");
        html.writeln(" <ul>");
        if (Config.getInstance().isOneOfMultipleSchemas())
            html.writeln("  <li><a href='" + path + "../index.html' title='All Schemas Evaluated'>Schemas</a></li>");
        html.writeln("  <li" + (isMainIndex() ? " id='current'" : "") + "><a href='" + path + "index.html' title='All tables and views in the schema'>Tables</a></li>");
        html.writeln("  <li" + (isRelationshipsPage() ? " id='current'" : "") + "><a href='" + path + "relationships.html' title='Diagram of table relationships'>Relationships</a></li>");
        if (showOrphans)
            html.writeln("  <li" + (isOrphansPage() ? " id='current'" : "") + "><a href='" + path + "utilities.html' title='View of tables with neither parents nor children'>Utility&nbsp;Tables</a></li>");
        html.writeln("  <li" + (isConstraintsPage() ? " id='current'" : "") + "><a href='" + path + "constraints.html' title='Useful for diagnosing error messages that just give constraint name or number'>Constraints</a></li>");
        html.writeln("  <li" + (isAnomaliesPage() ? " id='current'" : "") + "><a href='" + path + "anomalies.html' title=\"Things that might not be quite right\">Anomalies</a></li>");
        html.writeln("  <li" + (isColumnsPage() ? " id='current'" : "") + "><a href='" + path + HtmlColumnsPage.getInstance().getColumnInfos().get(0) + "' title=\"All of the columns in the schema\">Columns</a></li>");
        html.writeln("  <li><a href='http://sourceforge.net/donate/index.php?group_id=137197' title='Please help keep SchemaSpy alive' target='_blank'>Donate</a></li>");
        html.writeln(" </ul>");
        html.writeln("</div>");
        html.writeln("</td></tr></table>");*/
        return;
    }
///////////////////////////////////////////////////////navbar/////////////////////////////////////////////////////////
    protected String getDescription(Database db, Table table, String text, boolean hoverHelp) {
        StringBuilder description = new StringBuilder();
        if (table != null) {
            if (table.isView())
                description.append("View ");
            else
                description.append("Table ");
        }
        if (hoverHelp)
            description.append("<span title='Database'>");
        description.append(db.getName());
        if (hoverHelp)
            description.append("</span>");
        if (db.getSchema() != null) {
            description.append('.');
            if (hoverHelp)
                description.append("<span title='Schema'>");
            description.append(db.getSchema());
            if (hoverHelp)
                description.append("</span>");
        }
        if (table != null) {
            description.append('.');
            if (hoverHelp)
                description.append("<span title='Table'>");
            description.append(table.getName());
            if (hoverHelp)
                description.append("</span>");
        }
        if (text != null) {
            description.append(" - ");
            description.append(text);
        }

        return description.toString();
    }

    protected boolean sourceForgeLogoEnabled() {
        return Config.getInstance().isLogoEnabled();
    }

    /*protected void writeLegend(boolean tableDetails, LineWriter out) throws IOException {
        writeLegend(tableDetails, true, out);
    }

    /*protected void writeLegend(boolean tableDetails, boolean diagramDetails, LineWriter out) throws IOException {
        out.writeln(" <table class='legend' border='0'>");
        out.writeln("  <tr>");
        out.writeln("   <td class='dataTable' valign='bottom'>Legend:</td>");
       // if (sourceForgeLogoEnabled())
           // out.writeln("   <td class='container' align='right' valign='top'><a href='http://sourceforge.net' target='_blank'><img src='http://sourceforge.net/sflogo.php?group_id=137197&amp;type=1' alt='SourceForge.net' border='0' height='31' width='88'></a></td>");
        out.writeln("  </tr>");
        out.writeln("  <tr><td class='container' colspan='2'>");
        out.writeln("   <table class='dataTable' border='1'>");
        out.writeln("    <tbody>");
        out.writeln("    <tr><td class='primaryKey'>Primary key columns</td></tr>");
        out.writeln("    <tr><td class='indexedColumn'>Columns with indexes</td></tr>");
        if (tableDetails)
            out.writeln("    <tr class='impliedRelationship'><td class='detail'><span class='impliedRelationship'>Implied relationships</span></td></tr>");
        // comment this out until I can figure out a clean way to embed image references
        //out.writeln("    <tr><td class='container'>Arrows go from children (foreign keys)" + (tableDetails ? "<br>" : " ") + "to parents (primary keys)</td></tr>");
        if (diagramDetails) {
            out.writeln("    <tr><td class='excludedColumn'>Excluded column relationships</td></tr>");
            if (!tableDetails)
                out.writeln("    <tr class='impliedRelationship'><td class='legendDetail'>Dashed lines show implied relationships</td></tr>");
            out.writeln("    <tr><td class='legendDetail'>&lt; <em>n</em> &gt; number of related tables</td></tr>");
        }
        out.writeln("   </table>");
        out.writeln("  </td></tr>");
        out.writeln(" </table>");
        writeFeedMe(out);
        out.writeln("&nbsp;");
       
    }*/
    ///////////////////////////////////////////////////////////////
    protected void writeLegend(LineWriter out) throws IOException{
        out.writeln("<div>");
        out.writeln("<span class='legend'>Legend:</span>");
        out.writeln("<span class='legend primaryKey'>Primary key columns</span>");
        out.writeln("<span class='legend indexedColumn'>Indexed columns</span>");
        out.writeln("</div>");

    }
    ////////////////////////////////////////////////////////////////////
    protected void writeFeedMe(LineWriter html) throws IOException {
        /*if (Config.getInstance().isAdsEnabled()) {
            StyleSheet css = StyleSheet.getInstance();

            html.writeln("<div style=\"margin-right: 2pt;\">");
            html.writeln("<script type=\"text/javascript\"><!--");
            html.writeln("google_ad_client = \"pub-9598353634003340\";");
            html.writeln("google_ad_channel =\"SchemaSpy-generated\";");
            html.writeln("google_ad_width = 234;");
            html.writeln("google_ad_height = 60;");
            html.writeln("google_ad_format = \"234x60_as\";");
            html.writeln("google_ad_type = \"text\";");
            html.writeln("google_color_border = \"" + css.getTableHeadBackground().substring(1) + "\";");
            html.writeln("google_color_link = \"" + css.getLinkColor().substring(1) + "\";");
            html.writeln("google_color_text = \"000000\";");

            html.writeln("//-->");
            html.writeln("</script>");
            html.writeln("<script type=\"text/javascript\"");
            html.writeln("src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\">");
            html.writeln("</script>");
            html.writeln("</div>");
        }*/
        return;
    }

    protected void writeExcludedColumns(Set<TableColumn> excludedColumns, Table table, LineWriter html) throws IOException {
        Set<TableColumn> notInDiagram;

        // diagram INCLUDES relationships directly connected to THIS table's excluded columns
        if (table == null) {
            notInDiagram = excludedColumns;
        } else {
            notInDiagram = new HashSet<TableColumn>();
            for (TableColumn column : excludedColumns) {
                if (column.isAllExcluded() || !column.getTable().equals(table)) {
                    notInDiagram.add(column);
                }
            }
        }

        if (notInDiagram.size() > 0) {
            html.writeln("<span class='excludedRelationship'>");
            html.writeln("<br>Excluded from diagram's relationships: ");
            for (TableColumn column : notInDiagram) {
                if (!column.getTable().equals(table)) {
                    html.write("<a href=\"" + getPathToRoot() + "tables/");
                    html.write(column.getTable().getName());
                    html.write(".html\">");
                    html.write(column.getTable().getName());
                    html.write(".");
                    html.write(column.getName());
                    html.writeln("</a>&nbsp;");
                }
            }
            html.writeln("</span>");
        }
    }

    protected void writeInvalidGraphvizInstallation(LineWriter html) throws IOException {
        html.writeln("<br>SchemaSpy was unable to generate a diagram of table relationships.");
        html.writeln("<br>SchemaSpy requires Graphviz " + Dot.getInstance().getSupportedVersions().substring(4) + " from <a href='http://www.graphviz.org' target='_blank'>www.graphviz.org</a>.");
    }

    protected void writeFooter(LineWriter html) throws IOException {
        html.writeln("</div>");
        if (isMetered) {
            html.writeln("<span style='float: right;' title='This link is only on the SchemaSpy sample pages'>");
            html.writeln("<!-- Site Meter -->");
            html.writeln("<script type='text/javascript' src='http://s28.sitemeter.com/js/counter.js?site=s28schemaspy'>");
            html.writeln("</script>");
            html.writeln("<noscript>");
            html.writeln("<a href='http://s28.sitemeter.com/stats.asp?site=s28schemaspy' target='_top'>");
            html.writeln("<img src='http://s28.sitemeter.com/meter.asp?site=s28schemaspy' alt='Site Meter' border='0'/></a>");
            html.writeln("</noscript>");
            html.writeln("<!-- Copyright (c)2006 Site Meter -->");
            html.writeln("</span>");
        }
        html.writeln("</body>");
        html.writeln("</html>");
    }

    /**
     * Override if your output doesn't live in the root directory.
     * If non blank must end with a trailing slash.
     *
     * @return String
     */
    protected String getPathToRoot() {
        return "";
    }

    /**
     * Override and return true if you're the main index page.
     *
     * @return boolean
     */
    protected boolean isMainIndex() {
        return false;
    }

    /**
     * Override and return true if you're the relationships page.
     *
     * @return boolean
     */
    protected boolean isRelationshipsPage() {
        return false;
    }

    /**
     * Override and return true if you're the orphans page.
     *
     * @return boolean
     */
    protected boolean isOrphansPage() {
        return false;
    }

    /**
     * Override and return true if you're the constraints page
     *
     * @return boolean
     */
    protected boolean isConstraintsPage() {
        return false;
    }

    /**
     * Override and return true if you're the anomalies page
     *
     * @return boolean
     */
    protected boolean isAnomaliesPage() {
        return false;
    }

    /**
     * Override and return true if you're the columns page
     *
     * @return boolean
     */
    protected boolean isColumnsPage() {
        return false;
    }
}

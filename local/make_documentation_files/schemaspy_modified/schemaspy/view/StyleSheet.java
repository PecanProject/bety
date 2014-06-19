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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.StringTokenizer;
import schemaspy.Config;
import schemaspy.model.InvalidConfigurationException;
import schemaspy.util.LineWriter;

/**
 * Represents our CSS style sheet (CSS) with accessors for important
 * data from that style sheet.
 * The idea is that the CSS that will be used to render the HTML pages
 * also determines the colors used in the generated ER diagrams.
 *
 * @author John Currier
 */
public class StyleSheet {
    private static StyleSheet instance;
    private final String css;
    private String bodyBackgroundColor;
    private String tableHeadBackgroundColor;
    private String tableBackgroundColor;
    private String linkColor;
    private String linkVisitedColor;
    private String primaryKeyBackgroundColor;
    private String indexedColumnBackgroundColor;
    private String selectedTableBackgroundColor;
    private String excludedColumnBackgroundColor;
    private String defaultColor="#FFFFFF";
    private final List<String> ids = new ArrayList<String>();

    private StyleSheet(BufferedReader cssReader) throws IOException {
        String lineSeparator = System.getProperty("line.separator");
        StringBuilder data = new StringBuilder();
        String line;

        while ((line = cssReader.readLine()) != null) {
            data.append(line);
            data.append(lineSeparator);
        }

        css = data.toString();
        //////////////////////////////REMOVE COMMENTS////////////////////////
        int startComment = data.indexOf("/*");
        while (startComment != -1) {
            int endComment = data.indexOf("*/");
            data.replace(startComment, endComment + 2, "");
            startComment = data.indexOf("/*");
        }
        ////////////////////////////////////////////////////////////////////////
        StringTokenizer tokenizer = new StringTokenizer(data.toString(), "{}");
        String id = null;
        while (tokenizer.hasMoreTokens()) {
            String token = tokenizer.nextToken().trim();
            if (id == null) {
                id = token.toLowerCase();
                ids.add(id);
            } 
            else {
                Map<String, String> attribs = parseAttributes(token);
                if (id.equals(".content"))
                    bodyBackgroundColor = attribs.get("background");
                else if (id.equals("th"))
                    tableHeadBackgroundColor = attribs.get("background-color");
                else if (id.equals("td"))
                    tableBackgroundColor = attribs.get("background-color");
                else if (id.equals(".primarykey"))
                    primaryKeyBackgroundColor = attribs.get("background");
                else if (id.equals(".indexedcolumn"))
                    indexedColumnBackgroundColor = attribs.get("background");
                else if (id.equals(".selectedtable"))
                    selectedTableBackgroundColor = attribs.get("background");
                else if (id.equals(".excludedcolumn"))
                    excludedColumnBackgroundColor = attribs.get("background");
                else if (id.equals("a:link"))
                    linkColor = attribs.get("color");
                else if (id.equals("a:visited"))
                    linkVisitedColor = attribs.get("color");
                id = null;
            }
        }
    }

    /**
     * Singleton accessor
     *
     * @return the singleton
     * @throws ParseException
     */
    public static StyleSheet getInstance() throws ParseException {
        if (instance == null) {
            try {
                instance = new StyleSheet(new BufferedReader(getReader(Config.getInstance().getCss())));//takes a file reader of the css
            } catch (IOException exc) {
                throw new ParseException(exc);
            }
        }

        return instance;
    }

    /**
     * Returns a {@link Reader} that can be used to read the contents
     * of the specified css.<p>
     * Search order is
     * <ol>
     * <li><code>cssName</code> as an explicitly-defined file</li>
     * <li><code>cssName</code> as a file in the user's home directory</li>
     * <li><code>cssName</code> as a resource from the class path</li>
     * </ol>
     *
     * @param cssName
     * @return
     * @throws IOException
     */
    private static Reader getReader(String cssName) throws IOException {
        File cssFile = new File(cssName);
        if (cssFile.exists())
            return new FileReader(cssFile);
        cssFile = new File(System.getProperty("user.dir"), cssName);
        if (cssFile.exists())
            return new FileReader(cssFile);

        InputStream cssStream = StyleSheet.class.getClassLoader().getResourceAsStream(cssName);
        if (cssStream == null)
            throw new ParseException("Unable to find requested style sheet: " + cssName);

        return new InputStreamReader(cssStream);
    }

    private Map<String, String> parseAttributes(String data) {
        Map<String, String> attribs = new HashMap<String, String>();

        try {
            StringTokenizer attrTokenizer = new StringTokenizer(data, ";");
            while (attrTokenizer.hasMoreTokens()) {
                StringTokenizer pairTokenizer = new StringTokenizer(attrTokenizer.nextToken(), ":");
                String attribute = pairTokenizer.nextToken().trim().toLowerCase();
                String value = pairTokenizer.nextToken().trim().toLowerCase();
                attribs.put(attribute, value);
            }
        } catch (NoSuchElementException badToken) {
            System.err.println("Failed to extract attributes from '" + data + "'");
            throw badToken;
        }

        return attribs;
    }

    /**
     * Write the contents of the original css to <code>out</code>.
     *
     * @param out
     * @throws IOException
     */
    public void write(LineWriter out) throws IOException {
        out.write(css);
    }

    public String getBodyBackground() {
        if (bodyBackgroundColor == null)
            ///throw new MissingCssPropertyException(".content", "background");
            bodyBackgroundColor=defaultColor;

        return bodyBackgroundColor;
    }

    public String getTableBackground() {
        if (tableBackgroundColor == null)
            //throw new MissingCssPropertyException("td", "background-color");
            tableBackgroundColor=defaultColor;

        return tableBackgroundColor;
    }

    public String getTableHeadBackground() {
        if (tableHeadBackgroundColor == null)
            //throw new MissingCssPropertyException("th", "background-color");
            tableHeadBackgroundColor=defaultColor;

        return tableHeadBackgroundColor;
    }

    public String getPrimaryKeyBackground() {
        if (primaryKeyBackgroundColor == null)
            //throw new MissingCssPropertyException(".primaryKey", "background");
            primaryKeyBackgroundColor=defaultColor;

        return primaryKeyBackgroundColor;
    }

    public String getIndexedColumnBackground() {
        if (indexedColumnBackgroundColor == null)
           // throw new MissingCssPropertyException(".indexedColumn", "background");
            indexedColumnBackgroundColor=defaultColor;

        return indexedColumnBackgroundColor;
    }

    public String getSelectedTableBackground() {
        if (selectedTableBackgroundColor == null)
            //throw new MissingCssPropertyException(".selectedTable", "background");
            selectedTableBackgroundColor=defaultColor;


        return selectedTableBackgroundColor;
    }

    public String getExcludedColumnBackgroundColor() {
        if (excludedColumnBackgroundColor == null)
            //throw new MissingCssPropertyException(".excludedColumn", "background");
            excludedColumnBackgroundColor=defaultColor;

        return excludedColumnBackgroundColor;
    }

    public String getLinkColor() {
        if (linkColor == null)
            //throw new MissingCssPropertyException("a:link", "color");
            linkColor="#000";

        return linkColor;
    }

    public String getLinkVisitedColor() {
        if (linkVisitedColor == null)
            //throw new MissingCssPropertyException("a:visited", "color");
            linkVisitedColor="#000";

        return linkVisitedColor;
    }

    /**
     * Indicates that a css property was missing
     */
    public static class MissingCssPropertyException extends InvalidConfigurationException {
        private static final long serialVersionUID = 1L;

        /**
         * @param cssSection name of the css section
         * @param propName name of the missing property in that section
         */
        public MissingCssPropertyException(String cssSection, String propName) {
            super("Required property '" + propName + "' was not found for the definition of '" + cssSection + "' in " + Config.getInstance().getCss());
        }
    }

    /**
     * Indicates an exception in parsing the css
     */
    public static class ParseException extends InvalidConfigurationException {
        private static final long serialVersionUID = 1L;

        /**
         * @param cause root exception that caused the failure
         */
        public ParseException(Exception cause) {
            super(cause);
        }

        /**
         * @param msg textual description of the failure
         */
        public ParseException(String msg) {
            super(msg);
        }
    }
}
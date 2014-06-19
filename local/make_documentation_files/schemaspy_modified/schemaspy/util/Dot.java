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
package schemaspy.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import schemaspy.Config;

public class Dot {
    private static Dot instance = new Dot();
    private final Version version;
    private final Version supportedVersion = new Version("2.2.1");
    private final Version badVersion = new Version("2.4");
    private final String lineSeparator = System.getProperty("line.separator");
    private String dotExe;
    private String format = "png";
    private String renderer;
    private final Set<String> validatedRenderers = Collections.synchronizedSet(new HashSet<String>());
    private final Set<String> invalidatedRenderers = Collections.synchronizedSet(new HashSet<String>());

    private Dot() {
        String versionText = null;
        // dot -V should return something similar to:
        //  dot version 2.8 (Fri Feb  3 22:38:53 UTC 2006)
        // or sometimes something like:
        //  dot - Graphviz version 2.9.20061004.0440 (Wed Oct 4 21:01:52 GMT 2006)
        String[] dotCommand = new String[] { getExe(), "-V" };

        try {
            Process process = Runtime.getRuntime().exec(dotCommand);
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            String versionLine = reader.readLine();

            // look for a number followed numbers or dots
            Matcher matcher = Pattern.compile("[0-9][0-9.]+").matcher(versionLine);
            if (matcher.find()) {
                versionText = matcher.group();
            } else {
                if (Config.getInstance().isHtmlGenerationEnabled()) {
                    System.err.println();
                    System.err.println("Invalid dot configuration detected.  '" +
                                        getDisplayableCommand(dotCommand) + "' returned:");
                    System.err.println("   " + versionLine);
                }
            }
        } catch (Exception validDotDoesntExist) {
            if (Config.getInstance().isHtmlGenerationEnabled()) {
                System.err.println("Failed to query Graphviz version information");
                System.err.println("  with: " + getDisplayableCommand(dotCommand));
                System.err.println("  " + validDotDoesntExist);
            }
        }

        version = new Version(versionText);
    }

    public static Dot getInstance() {
        return instance;
    }

    public boolean exists() {
        return version.toString() != null;
    }

    public Version getVersion() {
        return version;
    }

    public boolean isValid() {
        return exists() && (getVersion().equals(supportedVersion) || getVersion().compareTo(badVersion) > 0);
    }

    public String getSupportedVersions() {
        return "dot version " + supportedVersion + " or versions greater than " + badVersion;
    }

    public boolean supportsCenteredEastWestEdges() {
        return getVersion().compareTo(new Version("2.6")) >= 0;
    }

    /**
     * Set the image format to generate.  Defaults to <code>png</code>.
     * See <a href='http://www.graphviz.org/doc/info/output.html'>http://www.graphviz.org/doc/info/output.html</a>
     * for valid formats.
     *
     * @param format image format to generate
     */
    public void setFormat(String format) {
        this.format = format;
    }

    /**
     * @see #setFormat(String)
     * @return
     */
    public String getFormat() {
        return format;
    }

    /**
     * Returns true if the installed dot requires specifying :gd as a renderer.
     * This was added when Win 2.15 came out because it defaulted to Cairo, which produces
     * better quality output, but at a significant speed and size penalty.<p>
     *
     * The intent of this property is to determine if it's ok to tack ":gd" to
     * the format specifier.  Earlier versions didn't require it and didn't know
     * about the option.
     *
     * @return
     */
    public boolean requiresGdRenderer() {
        return getVersion().compareTo(new Version("2.12")) >= 0 && supportsRenderer(":gd");
    }

    /**
     * Set the renderer to use for the -Tformat[:renderer[:formatter]] dot option as specified
     * at <a href='http://www.graphviz.org/doc/info/command.html'>
     * http://www.graphviz.org/doc/info/command.html</a> where "format" is specified by
     * {@link #setFormat(String)}<p>
     * Note that the leading ":" is required while :formatter is optional.
     *
     * @param renderer
     */
    public void setRenderer(String renderer) {
        this.renderer = renderer;
    }

    public String getRenderer() {
        return renderer != null && supportsRenderer(renderer) ? renderer
            : (requiresGdRenderer() ? ":gd" : "");
    }

    /**
     * If <code>true</code> then generate output of "higher quality"
     * than the default ("lower quality").
     * Note that the default is intended to be "lower quality",
     * but various installations of Graphviz may have have different abilities.
     * That is, some might not have the "lower quality" libraries and others might
     * not have the "higher quality" libraries.
     */
    public void setHighQuality(boolean highQuality) {
        if (highQuality && supportsRenderer(":cairo")) {
            setRenderer(":cairo");
        } else if (supportsRenderer(":gd")) {
            setRenderer(":gd");
        }
    }

    /**
     * @see #setHighQuality(boolean)
     */
    public boolean isHighQuality() {
        return getRenderer().indexOf(":cairo") != -1;
    }

    /**
     * Returns <code>true</code> if the specified renderer is supported.
     * See {@link #setRenderer(String)} for renderer details.
     *
     * @param renderer
     * @return
     */
    public boolean supportsRenderer(@SuppressWarnings("hiding") String renderer) {
        if (!exists())
            return false;

        if (validatedRenderers.contains(renderer))
            return true;

        if (invalidatedRenderers.contains(renderer))
            return false;

        try {
            String[] dotCommand = new String[] {
                getExe(),
                "-T" + getFormat() + ':'
            };
            Process process = Runtime.getRuntime().exec(dotCommand);
            BufferedReader errors = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            String line;
            while ((line = errors.readLine()) != null) {
                if (line.contains(getFormat() + renderer)) {
                    validatedRenderers.add(renderer);
                }
            }
            process.waitFor();
        } catch (Exception exc) {
            exc.printStackTrace();
        }

        if (!validatedRenderers.contains(renderer)) {
            //System.err.println("\nFailed to validate " + getFormat() + " renderer '" + renderer + "'.  Reverting to detault renderer for " + getFormat() + '.');
            invalidatedRenderers.add(renderer);
            return false;
        }

        return true;
    }

    /**
     * Returns the executable to use to run dot
     *
     * @return
     */
    private String getExe() {
        if (dotExe == null)
        {
            File gv = Config.getInstance().getGraphvizDir();

            if (gv == null) {
                // default to finding dot in the PATH
                dotExe = "dot";
            } else {
                // pull dot from the Graphviz bin directory specified
                dotExe = new File(new File(gv, "bin"), "dot").toString();
            }
        }

        return dotExe;
    }

    /**
     * Using the specified .dot file generates an image returning the image's image map.
     */
    public String generateDiagram(File dotFile, File diagramFile) throws DotFailure {
        StringBuilder mapBuffer = new StringBuilder(1024);

        BufferedReader mapReader = null;
        // this one is for executing.  it can (hopefully) deal with funky things in filenames.
        String[] dotCommand = new String[] {
            getExe(),
            "-T" + getFormat() + getRenderer(),
            dotFile.toString(),
            "-o" + diagramFile,
            "-Tcmapx"
        };
        // this one is for display purposes ONLY.
        String commandLine = getDisplayableCommand(dotCommand);

        try {
            Process process = Runtime.getRuntime().exec(dotCommand);
            new ProcessOutputReader(commandLine, process.getErrorStream()).start();
            mapReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = mapReader.readLine()) != null) {
                mapBuffer.append(line);
                mapBuffer.append(lineSeparator);
            }
            int rc = process.waitFor();
            if (rc != 0)
                throw new DotFailure("'" + commandLine + "' failed with return code " + rc);
            if (!diagramFile.exists())
                throw new DotFailure("'" + commandLine + "' failed to create output file");

            // dot generates post-HTML 4.0.1 output...convert trailing />'s to >'s
            return mapBuffer.toString().replace("/>", ">");
        } catch (InterruptedException interrupted) {
            throw new RuntimeException(interrupted);
        } catch (DotFailure failed) {
            diagramFile.delete();
            throw failed;
        } catch (IOException failed) {
            diagramFile.delete();
            throw new DotFailure("'" + commandLine + "' failed with exception " + failed);
        } finally {
            if (mapReader != null) {
                try {
                    mapReader.close();
                } catch (IOException ignore) {}
            }
        }
    }

    public class DotFailure extends IOException {
        private static final long serialVersionUID = 3833743270181351987L;

        public DotFailure(String msg) {
            super(msg);
        }
    }

    private static String getDisplayableCommand(String[] command) {
        StringBuilder displayable = new StringBuilder();
        for (int i = 0; i < command.length; ++i) {
            displayable.append(command[i]);
            if (i + 1 < command.length)
                displayable.append(' ');
        }
        return displayable.toString();
    }

    private static class ProcessOutputReader extends Thread {
        private final BufferedReader processReader;
        private final String command;

        ProcessOutputReader(String command, InputStream processStream) {
            processReader = new BufferedReader(new InputStreamReader(processStream));
            this.command = command;
            setDaemon(true);
        }

        @Override
        public void run() {
            try {
                String line;
                while ((line = processReader.readLine()) != null) {
                    // don't report port id unrecognized or unrecognized port
                    if (line.indexOf("unrecognized") == -1 && line.indexOf("port") == -1)
                        System.err.println(command + ": " + line);
                }
            } catch (IOException ioException) {
                ioException.printStackTrace();
            } finally {
                try {
                    processReader.close();
                } catch (Exception exc) {
                    exc.printStackTrace(); // shouldn't ever get here...but...
                }
            }
        }
    }
}
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
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import schemaspy.Config;
import schemaspy.Revision;
import schemaspy.model.Database;
import schemaspy.model.ForeignKeyConstraint;
import schemaspy.model.Table;
import schemaspy.model.TableColumn;
import schemaspy.util.Dot;
import schemaspy.util.LineWriter;
import schemaspy.view.DotNode.DotNodeConfig;

/**
 * Format table data into .dot format to feed to Graphvis' dot program.
 *
 * @author John Currier
 */
public class DotFormatter {
    private static DotFormatter instance = new DotFormatter();
    private final int fontSize = Config.getInstance().getFontSize();

    /**
     * Singleton - prevent creation
     */
    private DotFormatter() {
    }

    public static DotFormatter getInstance() {
        return instance;
    }

    /**
     * Write real relationships (excluding implied) associated with the given table.<p>
     * Returns a set of the implied constraints that could have been included but weren't.
     */
    public Set<ForeignKeyConstraint> writeRealRelationships(Table table, boolean twoDegreesOfSeparation, WriteStats stats, LineWriter dot) throws IOException {
        return writeRelationships(table, twoDegreesOfSeparation, stats, false, dot);
    }

    /**
     * Write implied relationships associated with the given table
     */
    public void writeAllRelationships(Table table, boolean twoDegreesOfSeparation, WriteStats stats, LineWriter dot) throws IOException {
        writeRelationships(table, twoDegreesOfSeparation, stats, true, dot);
    }

    /**
     * Write relationships associated with the given table.<p>
     * Returns a set of the implied constraints that could have been included but weren't.
     */
    private Set<ForeignKeyConstraint> writeRelationships(Table table, boolean twoDegreesOfSeparation, WriteStats stats, boolean includeImplied, LineWriter dot) throws IOException {
        Set<Table> tablesWritten = new HashSet<Table>();
        Set<ForeignKeyConstraint> skippedImpliedConstraints = new HashSet<ForeignKeyConstraint>();

        DotConnectorFinder finder = DotConnectorFinder.getInstance();

        String diagramName = includeImplied ? "impliedTwoDegreesRelationshipsDiagram" : (twoDegreesOfSeparation ? "twoDegreesRelationshipsDiagram" : "oneDegreeRelationshipsDiagram");
        writeHeader(diagramName, true, dot);

        Set<Table> relatedTables = getImmediateRelatives(table, true, includeImplied, skippedImpliedConstraints);

        Set<DotConnector> connectors = new TreeSet<DotConnector>(finder.getRelatedConnectors(table, includeImplied));
        tablesWritten.add(table);

        Map<Table, DotNode> nodes = new TreeMap<Table, DotNode>();

        // write immediate relatives first
        for (Table relatedTable : relatedTables) {
            if (!tablesWritten.add(relatedTable))
                continue; // already written

            nodes.put(relatedTable, new DotNode(relatedTable, true, ""));
            connectors.addAll(finder.getRelatedConnectors(relatedTable, table, true, includeImplied));
        }

        // connect the edges that go directly to the target table
        // so they go to the target table's type column instead
        for (DotConnector connector : connectors) {
            if (connector.pointsTo(table))
                connector.connectToParentDetails();
        }

        Set<Table> allCousins = new HashSet<Table>();
        Set<DotConnector> allCousinConnectors = new TreeSet<DotConnector>();

        // next write 'cousins' (2nd degree of separation)
        if (twoDegreesOfSeparation) {
            for (Table relatedTable : relatedTables) {
                Set<Table> cousins = getImmediateRelatives(relatedTable, false, includeImplied, skippedImpliedConstraints);

                for (Table cousin : cousins) {
                    if (!tablesWritten.add(cousin))
                        continue; // already written

                    allCousinConnectors.addAll(finder.getRelatedConnectors(cousin, relatedTable, false, includeImplied));
                    nodes.put(cousin, new DotNode(cousin, false, ""));
                }

                allCousins.addAll(cousins);
            }
        }

        // glue together any 'participants' that aren't yet connected
        // note that this is the epitome of nested loops from hell
        List<Table> participants = new ArrayList<Table>(nodes.keySet());
        Iterator<Table> iter = participants.iterator();
        while (iter.hasNext()) {
            Table participantA = iter.next();
            iter.remove(); // cut down the combos as quickly as possible

            for (Table participantB : participants) {
                for (DotConnector connector : finder.getRelatedConnectors(participantA, participantB, false, includeImplied)) {
                    if (twoDegreesOfSeparation && (allCousins.contains(participantA) || allCousins.contains(participantB))) {
                        allCousinConnectors.add(connector);
                    } else {
                        connectors.add(connector);
                    }
                }
            }
        }

        markExcludedColumns(nodes, stats.getExcludedColumns());

        // now directly connect the loose ends to the title of the
        // 2nd degree of separation tables
        for (DotConnector connector : allCousinConnectors) {
            if (allCousins.contains(connector.getParentTable()) && !relatedTables.contains(connector.getParentTable()))
                connector.connectToParentTitle();
            if (allCousins.contains(connector.getChildTable()) && !relatedTables.contains(connector.getChildTable()))
                connector.connectToChildTitle();
        }

        // include the table itself
        nodes.put(table, new DotNode(table, ""));

        connectors.addAll(allCousinConnectors);
        for (DotConnector connector : connectors) {
            if (connector.isImplied()) {
                DotNode node = nodes.get(connector.getParentTable());
                if (node != null)
                    node.setShowImplied(true);
                node = nodes.get(connector.getChildTable());
                if (node != null)
                    node.setShowImplied(true);
            }
            dot.writeln(connector.toString());
        }

        for (DotNode node : nodes.values()) {
            dot.writeln(node.toString());
            stats.wroteTable(node.getTable());
        }

        dot.writeln("}");

        return skippedImpliedConstraints;
    }

    private Set<Table> getImmediateRelatives(Table table, boolean includeExcluded, boolean includeImplied, Set<ForeignKeyConstraint> skippedImpliedConstraints) {
        Set<TableColumn> relatedColumns = new HashSet<TableColumn>();

        for (TableColumn column : table.getColumns()) {
            if (column.isAllExcluded() || (!includeExcluded && column.isExcluded())) {
                continue;
            }

            for (TableColumn childColumn : column.getChildren()) {
                if (childColumn.isAllExcluded() || (!includeExcluded && childColumn.isExcluded())) {
                    continue;
                }

                ForeignKeyConstraint constraint = column.getChildConstraint(childColumn);
                if (includeImplied || !constraint.isImplied())
                    relatedColumns.add(childColumn);
                else
                    skippedImpliedConstraints.add(constraint);
            }

            for (TableColumn parentColumn : column.getParents()) {
                if (parentColumn.isAllExcluded() || (!includeExcluded && parentColumn.isExcluded())) {
                    continue;
                }

                ForeignKeyConstraint constraint = column.getParentConstraint(parentColumn);
                if (includeImplied || !constraint.isImplied())
                    relatedColumns.add(parentColumn);
                else
                    skippedImpliedConstraints.add(constraint);
            }
        }

        Set<Table> relatedTables = new HashSet<Table>();
        for (TableColumn column : relatedColumns)
            relatedTables.add(column.getTable());

        relatedTables.remove(table);

        return relatedTables;
    }

    private void writeHeader(String diagramName, boolean showLabel, LineWriter dot) throws IOException {
        dot.writeln("// dot " + Dot.getInstance().getVersion() + " on " + System.getProperty("os.name") + " " + System.getProperty("os.version"));
        dot.writeln("// SchemaSpy rev " + new Revision());
        dot.writeln("digraph \"" + diagramName + "\" {");
        dot.writeln("  graph [");
        boolean rankdirbug = Config.getInstance().isRankDirBugEnabled();
        if (!rankdirbug)
            dot.writeln("    rankdir=\"RL\"");
        dot.writeln("    bgcolor=\"" + StyleSheet.getInstance().getBodyBackground() + "\"");
        if (showLabel) {
            if (rankdirbug)
                dot.writeln("    label=\"\\nLayout is significantly better without '-rankdirbug' option\"");
            else
                dot.writeln("    label=\"\\nGenerated by SchemaSpy\"");
            dot.writeln("    labeljust=\"l\"");
        }
        dot.writeln("    nodesep=\"0.18\"");
        dot.writeln("    ranksep=\"0.46\"");
        dot.writeln("    fontname=\"" + Config.getInstance().getFont() + "\"");
        dot.writeln("    fontsize=\"" + fontSize + "\"");
        dot.writeln("  ];");
        dot.writeln("  node [");
        dot.writeln("    fontname=\"" + Config.getInstance().getFont() + "\"");
        dot.writeln("    fontsize=\"" + fontSize + "\"");
        dot.writeln("    shape=\"plaintext\"");
        dot.writeln("  ];");
        dot.writeln("  edge [");
        dot.writeln("    arrowsize=\"0.8\"");
        dot.writeln("  ];");
}

    public void writeRealRelationships(Database db, Collection<Table> tables, boolean compact, boolean showColumns, WriteStats stats, LineWriter dot) throws IOException {
        writeRelationships(db, tables, compact, showColumns, false, stats, dot);
    }

    /**
     * Returns <code>true</code> if it wrote any implied relationships
     */
    public boolean writeAllRelationships(Database db, Collection<Table> tables, boolean compact, boolean showColumns, WriteStats stats, LineWriter dot) throws IOException {
        return writeRelationships(db, tables, compact, showColumns, true, stats, dot);
    }

    private boolean writeRelationships(Database db, Collection<Table> tables, boolean compact, boolean showColumns, boolean includeImplied, WriteStats stats, LineWriter dot) throws IOException {
        DotConnectorFinder finder = DotConnectorFinder.getInstance();
        DotNodeConfig nodeConfig = showColumns ? new DotNodeConfig(!compact, false) : new DotNodeConfig();
        boolean wroteImplied = false;

        String diagramName;
        if (includeImplied) {
            if (compact)
                diagramName = "compactImpliedRelationshipsDiagram";
            else
                diagramName = "largeImpliedRelationshipsDiagram";
        } else {
            if (compact)
                diagramName = "compactRelationshipsDiagram";
            else
                diagramName = "largeRelationshipsDiagram";
        }
        writeHeader(diagramName, true, dot);

        Map<Table, DotNode> nodes = new TreeMap<Table, DotNode>();

        for (Table table : tables) {
            if (!table.isOrphan(includeImplied)) {
                nodes.put(table, new DotNode(table, "tables/", nodeConfig));
            }
        }

        for (Table table : db.getRemoteTables()) {
            nodes.put(table, new DotNode(table, "tables/", nodeConfig));
        }

        Set<DotConnector> connectors = new TreeSet<DotConnector>();

        for (DotNode node : nodes.values()) {
            connectors.addAll(finder.getRelatedConnectors(node.getTable(), includeImplied));
        }

        markExcludedColumns(nodes, stats.getExcludedColumns());

        for (DotNode node : nodes.values()) {
            Table table = node.getTable();

            dot.writeln(node.toString());
            stats.wroteTable(table);
            wroteImplied = wroteImplied || (includeImplied && table.isOrphan(false));
        }

        for (DotConnector connector : connectors) {
            dot.writeln(connector.toString());
        }

        dot.writeln("}");

        return wroteImplied;
    }

    private void markExcludedColumns(Map<Table, DotNode> nodes, Set<TableColumn> excludedColumns) {
        for (TableColumn column : excludedColumns) {
            DotNode node = nodes.get(column.getTable());
            if (node != null) {
                node.excludeColumn(column);
            }
        }
    }

    public void writeOrphan(Table table, LineWriter dot) throws IOException {
        writeHeader(table.getName(), false, dot);
        dot.writeln(new DotNode(table, true, "tables/").toString());
        dot.writeln("}");
    }
}

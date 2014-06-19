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
package schemaspy.model;

import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import schemaspy.Config;
import schemaspy.model.xml.ForeignKeyMeta;
import schemaspy.model.xml.TableColumnMeta;
import schemaspy.model.xml.TableMeta;
import schemaspy.util.CaseInsensitiveMap;

/**
 * A <code>Table</code> is one of the basic building blocks of SchemaSpy
 * that knows everything about the database table's metadata.
 *
 * @author John Currier
 */
public class Table implements Comparable<Table> {
    private final String schema;
    private final String name;
    protected final CaseInsensitiveMap<TableColumn> columns = new CaseInsensitiveMap<TableColumn>();
    private final List<TableColumn> primaryKeys = new ArrayList<TableColumn>();
    private final CaseInsensitiveMap<ForeignKeyConstraint> foreignKeys = new CaseInsensitiveMap<ForeignKeyConstraint>();
    private final CaseInsensitiveMap<TableIndex> indexes = new CaseInsensitiveMap<TableIndex>();
    private       Object id;
    private final Map<String, String> checkConstraints = new TreeMap<String, String>(String.CASE_INSENSITIVE_ORDER);
    private Integer numRows;
    protected final Database db;
    protected final Properties properties;
    private       String comments;
    private int maxChildren;
    private int maxParents;
    private final static Logger logger = Logger.getLogger(Table.class.getName());

    /**
     * Construct a table that knows everything about the database table's metadata
     *
     * @param db
     * @param schema
     * @param name
     * @param comments
     * @param properties
     * @param excludeIndirectColumns
     * @param excludeColumns
     * @throws SQLException
     */
    public Table(Database db, String schema, String name, String comments, Properties properties, Pattern excludeIndirectColumns, Pattern excludeColumns) throws SQLException {
        this.schema = schema;
        this.name = name;
        this.db = db;
        this.properties = properties;
        logger.fine("Creating " + getClass().getSimpleName().toLowerCase() + " " +
                schema == null ? name : (schema + '.' + name));
        setComments(comments);
        initColumns(excludeIndirectColumns, excludeColumns);
        initIndexes();
        initPrimaryKeys(db.getMetaData());
    }

    /**
     * "Connect" all of this table's foreign keys to their referenced primary keys
     * (and, in some cases, do the reverse as well).
     *
     * @param tables
     * @param excludeIndirectColumns
     * @param excludeColumns
     * @throws SQLException
     */
    public void connectForeignKeys(Map<String, Table> tables, Pattern excludeIndirectColumns, Pattern excludeColumns) throws SQLException {
        ResultSet rs = null;

        try {
            rs = db.getMetaData().getImportedKeys(null, getSchema(), getName());

            while (rs.next()) {
                addForeignKey(rs.getString("FK_NAME"), rs.getString("FKCOLUMN_NAME"),
                        rs.getString("PKTABLE_SCHEM"), rs.getString("PKTABLE_NAME"),
                        rs.getString("PKCOLUMN_NAME"),
                        rs.getInt("UPDATE_RULE"), rs.getInt("DELETE_RULE"),
                        tables, excludeIndirectColumns, excludeColumns);
            }
        } finally {
            if (rs != null)
                rs.close();
        }

        // also try to find all of the 'remote' tables in other schemas that
        // point to our primary keys (not necessary in the normal case
        // as we infer this from the opposite direction)
        if (getSchema() != null) {
            try {
                rs = db.getMetaData().getExportedKeys(null, getSchema(), getName());

                while (rs.next()) {
                    String otherSchema = rs.getString("FKTABLE_SCHEM");
                    if (!getSchema().equals(otherSchema))
                        db.addRemoteTable(otherSchema, rs.getString("FKTABLE_NAME"), getSchema(), properties, excludeIndirectColumns, excludeColumns);
                }
            } finally {
                if (rs != null)
                    rs.close();
            }
        }
    }

    /**
     * Get the foreign keys associated with this table
     *
     * @return
     */
    public Collection<ForeignKeyConstraint> getForeignKeys() {
        return Collections.unmodifiableCollection(foreignKeys.values());
    }

    /**
     * Add a check constraint to the table
     * (no real details, just name and textual representation)
     *
     * @param constraintName
     * @param text
     */
    public void addCheckConstraint(String constraintName, String text) {
        checkConstraints.put(constraintName, text);
    }

    /**
     * @param rs ResultSet from {@link DatabaseMetaData#getImportedKeys(String, String, String)}
     * rs.getString("FK_NAME");
     * rs.getString("FKCOLUMN_NAME");
     * rs.getString("PKTABLE_SCHEM");
     * rs.getString("PKTABLE_NAME");
     * rs.getString("PKCOLUMN_NAME");
     * @param tables Map
     * @param db
     * @throws SQLException
     */
    protected void addForeignKey(String fkName, String fkColName,
                        String pkTableSchema, String pkTableName, String pkColName,
                        int updateRule, int deleteRule,
                        Map<String, Table> tables,
                        Pattern excludeIndirectColumns, Pattern excludeColumns) throws SQLException {
        if (fkName == null)
            return;

        ForeignKeyConstraint foreignKey = foreignKeys.get(fkName);

        if (foreignKey == null) {
            foreignKey = new ForeignKeyConstraint(this, fkName, updateRule, deleteRule);

            foreignKeys.put(fkName, foreignKey);
        }

        TableColumn childColumn = getColumn(fkColName);
        if (childColumn != null) {
            foreignKey.addChildColumn(childColumn);

            Table parentTable = tables.get(pkTableName);
            String parentSchema = pkTableSchema;
            String baseSchema = Config.getInstance().getSchema();

            // if named table doesn't exist in this schema
            // or exists here but really referencing same named table in another schema
            if (parentTable == null ||
                    (baseSchema != null && parentSchema != null &&
                     !baseSchema.equals(parentSchema))) {
                parentTable = db.addRemoteTable(parentSchema, pkTableName, baseSchema,
                                        properties, excludeIndirectColumns, excludeColumns);
            }

            if (parentTable != null) {
                TableColumn parentColumn = parentTable.getColumn(pkColName);
                if (parentColumn != null) {
                    foreignKey.addParentColumn(parentColumn);

                    childColumn.addParent(parentColumn, foreignKey);
                    parentColumn.addChild(childColumn, foreignKey);
                } else {
                    logger.warning("Couldn't add FK '" + foreignKey.getName() + "' to table '" + this +
                                        "' - Column '" + pkColName + "' doesn't exist in table '" + parentTable + "'");
                }
            } else {
                logger.warning("Couldn't add FK '" + foreignKey.getName() + "' to table '" + this +
                                    "' - Unknown Referenced Table '" + pkTableName + "'");
            }
        } else {
            logger.warning("Couldn't add FK '" + foreignKey.getName() + "' to table '" + this +
                                "' - Column '" + fkColName + "' doesn't exist");
        }
    }

    /**
     * @param meta
     * @throws SQLException
     */
    private void initPrimaryKeys(DatabaseMetaData meta) throws SQLException {
        if (properties == null)
            return;

        ResultSet rs = null;

        try {
            rs = meta.getPrimaryKeys(null, getSchema(), getName());

            while (rs.next())
                setPrimaryColumn(rs);
        } finally {
            if (rs != null)
                rs.close();
        }
    }

    /**
     * @param rs
     * @throws SQLException
     */
    private void setPrimaryColumn(ResultSet rs) throws SQLException {
        String pkName = rs.getString("PK_NAME");
        if (pkName == null)
            return;

        TableIndex index = getIndex(pkName);
        if (index != null) {
            index.setIsPrimaryKey(true);
        }

        String columnName = rs.getString("COLUMN_NAME");

        setPrimaryColumn(getColumn(columnName));
    }

    /**
     * @param primaryColumn
     */
    void setPrimaryColumn(TableColumn primaryColumn) {
        primaryKeys.add(primaryColumn);
    }

    /**
     * @param excludeIndirectColumns
     * @param excludeColumns
     * @throws SQLException
     */
    private void initColumns(Pattern excludeIndirectColumns, Pattern excludeColumns) throws SQLException {
        ResultSet rs = null;

        synchronized (Table.class) {
            try {
                rs = db.getMetaData().getColumns(null, getSchema(), getName(), "%");

                while (rs.next())
                    addColumn(rs, excludeIndirectColumns, excludeColumns);
            } catch (SQLException exc) {
                class ColumnInitializationFailure extends SQLException {
                    private static final long serialVersionUID = 1L;

                    public ColumnInitializationFailure(SQLException failure) {
                        super("Failed to collect column details for " + (isView() ? "view" : "table") + " '" + getName() + "' in schema '" + getSchema() + "'");
                        initCause(failure);
                    }
                }

                throw new ColumnInitializationFailure(exc);
            } finally {
                if (rs != null)
                    rs.close();
            }
        }

        if (!isView() && !isRemote())
            initColumnAutoUpdate(false);
    }

    /**
     * @param forceQuotes
     * @throws SQLException
     */
    private void initColumnAutoUpdate(boolean forceQuotes) throws SQLException {
        ResultSet rs = null;
        PreparedStatement stmt = null;

        // we've got to get a result set with all the columns in it
        // so we can ask if the columns are auto updated
        // Ugh!!!  Should have been in DatabaseMetaData instead!!!
        StringBuilder sql = new StringBuilder("select * from ");
        if (getSchema() != null) {
            sql.append(getSchema());
            sql.append('.');
        }

        if (forceQuotes) {
            String quote = db.getMetaData().getIdentifierQuoteString().trim();
            sql.append(quote + getName() + quote);
        } else
            sql.append(db.getQuotedIdentifier(getName()));

        sql.append(" where 0 = 1");

        try {
            stmt = db.getMetaData().getConnection().prepareStatement(sql.toString());
            rs = stmt.executeQuery();

            ResultSetMetaData rsMeta = rs.getMetaData();
            for (int i = rsMeta.getColumnCount(); i > 0; --i) {
                TableColumn column = getColumn(rsMeta.getColumnName(i));
                column.setIsAutoUpdated(rsMeta.isAutoIncrement(i));
            }
        } catch (SQLException exc) {
            if (forceQuotes) {
                // don't completely choke just because we couldn't do this....
                logger.warning("Failed to determine auto increment status: " + exc);
                logger.warning("SQL: " + sql.toString());
            } else {
                initColumnAutoUpdate(true);
            }
        } finally {
            if (rs != null)
                rs.close();
            if (stmt != null)
                stmt.close();
        }
    }

    /**
     * @param rs - from {@link DatabaseMetaData#getColumns(String, String, String, String)}
     * @param excludeIndirectColumns
     * @param excludeColumns
     * @throws SQLException
     */
    protected void addColumn(ResultSet rs, Pattern excludeIndirectColumns, Pattern excludeColumns) throws SQLException {
        String columnName = rs.getString("COLUMN_NAME");

        if (columnName == null)
            return;

        if (getColumn(columnName) == null) {
            TableColumn column = new TableColumn(this, rs, excludeIndirectColumns, excludeColumns);

            columns.put(column.getName(), column);
        }
    }

    /**
     * Add a column that's defined in xml metadata.
     * Assumes that a column named colMeta.getName() doesn't already exist in <code>columns</code>.
     * @param colMeta
     * @return
     */
    protected TableColumn addColumn(TableColumnMeta colMeta) {
        TableColumn column = new TableColumn(this, colMeta);

        columns.put(column.getName(), column);

        return column;
    }

    /**
     * Initialize index information
     *
     * @throws SQLException
     */
    private void initIndexes() throws SQLException {
        if (isView() || isRemote())
            return;

        // first try to initialize using the index query spec'd in the .properties
        // do this first because some DB's (e.g. Oracle) do 'bad' things with getIndexInfo()
        // (they try to do a DDL analyze command that has some bad side-effects)
        if (initIndexes(properties.getProperty("selectIndexesSql")))
            return;

        // couldn't, so try the old fashioned approach
        ResultSet rs = null;

        try {
            rs = db.getMetaData().getIndexInfo(null, getSchema(), getName(), false, true);

            while (rs.next()) {
                if (rs.getShort("TYPE") != DatabaseMetaData.tableIndexStatistic)
                    addIndex(rs);
            }
        } catch (SQLException exc) {
            logger.warning("Unable to extract index info for table '" + getName() + "' in schema '" + getSchema() + "': " + exc);
        } finally {
            if (rs != null)
                rs.close();
        }
    }

    /**
     * Try to initialize index information based on the specified SQL
     *
     * @return boolean <code>true</code> if it worked, otherwise <code>false</code>
     */
    private boolean initIndexes(String selectIndexesSql) {
        if (selectIndexesSql == null)
            return false;

        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            stmt = db.prepareStatement(selectIndexesSql, getName());
            rs = stmt.executeQuery();

            while (rs.next()) {
                if (rs.getShort("TYPE") != DatabaseMetaData.tableIndexStatistic)
                    addIndex(rs);
            }
        } catch (SQLException sqlException) {
            logger.warning("Failed to query index information with SQL: " + selectIndexesSql);
            logger.warning(sqlException.toString());
            return false;
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (Exception exc) {
                    exc.printStackTrace();
                }
            }
            if (stmt != null)  {
                try {
                    stmt.close();
                } catch (Exception exc) {
                    exc.printStackTrace();
                }
            }
        }

        return true;
    }

    /**
     * @param indexName
     * @return
     */
    public TableIndex getIndex(String indexName) {
        return indexes.get(indexName);
    }

    /**
     * @param rs
     * @throws SQLException
     */
    private void addIndex(ResultSet rs) throws SQLException {
        String indexName = rs.getString("INDEX_NAME");

        if (indexName == null)
            return;

        TableIndex index = getIndex(indexName);

        if (index == null) {
            index = new TableIndex(rs);

            indexes.put(index.getName(), index);
        }

        index.addColumn(getColumn(rs.getString("COLUMN_NAME")), rs.getString("ASC_OR_DESC"));
    }

    /**
     * Returns the schema that the table belongs to
     *
     * @return
     */
    public String getSchema() {
        return schema;
    }

    /**
     * Returns the name of the table
     *
     * @return
     */
    public String getName() {
        return name;
    }

    /**
     * Object IDs are useful for tables such as DB/2 that many times
     * give error messages based on object ID and not name
     *
     * @param id
     */
    public void setId(Object id) {
        this.id = id;
    }

    /**
     * @see #setId(Object)
     *
     * @return
     */
    public Object getId() {
        return id;
    }

    /**
     * Returns the check constraints associated with this table
     *
     * @return
     */
    public Map<String, String> getCheckConstraints() {
        return checkConstraints;
    }

    /**
     * Returns the indexes that are applied to this table
     *
     * @return
     */
    public Set<TableIndex> getIndexes() {
        return new HashSet<TableIndex>(indexes.values());
    }

    /**
     * Returns a collection of table columns that have been identified as "primary"
     *
     * @return
     */
    public List<TableColumn> getPrimaryColumns() {
        return primaryKeys;
    }

    /**
     * @return Comments associated with this table, or <code>null</code> if none.
     */
    public String getComments() {
        return comments;
    }

    /**
     * Sets the comments that are associated with this table
     *
     * @param comments
     */
    public void setComments(String comments) {
        String cmts = (comments == null || comments.trim().length() == 0) ? null : comments.trim();

        // MySQL's InnoDB engine does some insane crap of storing erroneous details in
        // with table comments.  Here I attempt to strip the "crap" out without impacting
        // other databases.  Ideally this should happen in selectColumnCommentsSql (and
        // therefore isolate it to MySQL), but it's a bit too complex to do cleanly.
        if (cmts != null) {
            int crapIndex = cmts.indexOf("; InnoDB free: ");
            if (crapIndex == -1)
                crapIndex = cmts.startsWith("InnoDB free: ") ? 0 : -1;
            if (crapIndex != -1) {
                cmts = cmts.substring(0, crapIndex).trim();
                cmts = cmts.length() == 0 ? null : cmts;
            }
        }

        this.comments = cmts;
    }

    /**
     * Returns the {@link TableColumn} with the given name, or <code>null</code>
     * if it doesn't exist
     *
     * @param columnName
     * @return
     */
    public TableColumn getColumn(String columnName) {
        return columns.get(columnName);
    }

    /**
     * Returns <code>List</code> of <code>TableColumn</code>s in ascending column number order.
     *
     * @return
     */
    public List<TableColumn> getColumns() {
        Set<TableColumn> sorted = new TreeSet<TableColumn>(new ByColumnIdComparator());
        sorted.addAll(columns.values());
        return new ArrayList<TableColumn>(sorted);
    }

    /**
     * Returns <code>true</code> if this table references no other tables..<p/>
     * Used in dependency analysis.
     * @return
     */
    public boolean isRoot() {
        for (TableColumn column : columns.values()) {
            if (column.isForeignKey()) {
                return false;
            }
        }

        return true;
    }

    /**
     * Returns <code>true</code> if this table is referenced by no other tables.<p/>
     * Used in dependency analysis.
     * @return
     */
    public boolean isLeaf() {
        for (TableColumn column : columns.values()) {
            if (!column.getChildren().isEmpty()) {
                return false;
            }
        }

        return true;
    }

    /**
     * Returns the maximum number of parents that this table has had before
     * any had been removed during dependency analysis
     *
     * @return
     */
    public int getMaxParents() {
        return maxParents;
    }

    /**
     * Notification that's called to indicate that a parent has been added to
     * this table
     */
    public void addedParent() {
        maxParents++;
    }

    /**
     * "Unlink" all of the parent tables from this table
     */
    public void unlinkParents() {
        for (TableColumn column : columns.values()) {
            column.unlinkParents();
        }
    }

    /**
     * Returns the maximum number of children that this table has had before
     * any had been removed during dependency analysis
     *
     * @return
     */
    public int getMaxChildren() {
        return maxChildren;
    }

    /**
     * Notification that's called to indicate that a child has been added to
     * this table
     */
    public void addedChild() {
        maxChildren++;
    }

    /**
     * "Unlink" all of the child tables from this table
     */
    public void unlinkChildren() {
        for (TableColumn column : columns.values()) {
            column.unlinkChildren();
        }
    }

    /**
     * Remove a single self referencing constraint if one exists.
     *
     * @return
     */
    public ForeignKeyConstraint removeSelfReferencingConstraint() {
        return remove(getSelfReferencingConstraint());
    }

    /**
     * Remove the specified {@link ForeignKeyConstraint} from this table.<p>
     *
     * This is a more drastic removal solution that was proposed by Remke Rutgers
     *
     * @param constraint
     */
    private ForeignKeyConstraint remove(ForeignKeyConstraint constraint) {
        if (constraint != null) {
            for (int i = 0; i < constraint.getChildColumns().size(); i++) {
                TableColumn childColumn = constraint.getChildColumns().get(i);
                TableColumn parentColumn = constraint.getParentColumns().get(i);
                childColumn.removeParent(parentColumn);
                parentColumn.removeChild(childColumn);
            }
        }
        return constraint;
    }

    /**
     * Return a self referencing constraint if one exists
     *
     * @return
     */
    private ForeignKeyConstraint getSelfReferencingConstraint() {
        for (TableColumn column : columns.values()) {
            for (TableColumn parentColumn : column.getParents()) {
                if (compareTo(parentColumn.getTable()) == 0) {
                    return column.getParentConstraint(parentColumn);
                }
            }
        }
        return null;
    }

    /**
     * Remove any non-real foreign keys
     *
     * @return
     */
    public List<ForeignKeyConstraint> removeNonRealForeignKeys() {
        List<ForeignKeyConstraint> nonReals = new ArrayList<ForeignKeyConstraint>();

        for (TableColumn column : columns.values()) {
            for (TableColumn parentColumn : column.getParents()) {
                ForeignKeyConstraint constraint = column.getParentConstraint(parentColumn);
                if (constraint != null && !constraint.isReal()) {
                    nonReals.add(constraint);
                }
            }
        }

        // remove constraints outside of above loop to prevent
        // concurrent modification exceptions while iterating
        for (ForeignKeyConstraint constraint : nonReals) {
            remove(constraint);
        }

        return nonReals;
    }

    /**
     * Returns the number of tables that reference this table
     *
     * @return
     */
    public int getNumChildren() {
        int numChildren = 0;

        for (TableColumn column : columns.values()) {
            numChildren += column.getChildren().size();
        }

        return numChildren;
    }

    /**
     * Returns the number of non-implied children
     * @return
     */
    public int getNumNonImpliedChildren() {
        int numChildren = 0;

        for (TableColumn column : columns.values()) {
            for (TableColumn childColumn : column.getChildren()) {
                if (!column.getChildConstraint(childColumn).isImplied())
                    ++numChildren;
            }
        }

        return numChildren;
    }

    /**
     * Returns the number of tables that are referenced by this table
     *
     * @return
     */
    public int getNumParents() {
        int numParents = 0;

        for (TableColumn column : columns.values()) {
            numParents += column.getParents().size();
        }

        return numParents;
    }

    /**
     * Returns the number of non-implied parents
     *
     * @return
     */
    public int getNumNonImpliedParents() {
        int numParents = 0;

        for (TableColumn column : columns.values()) {
            for (TableColumn parentColumn : column.getParents()) {
                if (!column.getParentConstraint(parentColumn).isImplied())
                    ++numParents;
            }
        }

        return numParents;
    }

    /**
     * Remove one foreign key constraint.
     *
     * <p/>Used during dependency analysis phase.
     *
     * @return
     */
    public ForeignKeyConstraint removeAForeignKeyConstraint() {
        @SuppressWarnings("hiding")
        final List<TableColumn> columns = getColumns();
        int numParents = 0;
        int numChildren = 0;
        // remove either a child or parent, choosing which based on which has the
        // least number of foreign key associations (when either gets to zero then
        // the table can be pruned)
        for (TableColumn column : columns) {
            numParents += column.getParents().size();
            numChildren += column.getChildren().size();
        }

        for (TableColumn column : columns) {
            ForeignKeyConstraint constraint;
            if (numParents <= numChildren)
                constraint = column.removeAParentFKConstraint();
            else
                constraint = column.removeAChildFKConstraint();
            if (constraint != null)
                return constraint;
        }

        return null;
    }

    /**
     * Returns <code>true</code> if this is a view, <code>false</code> otherwise
     *
     * @return
     */
    public boolean isView() {
        return false;
    }

    /**
     * Returns <code>true</code> if this table is remote (in another schema), <code>false</code> otherwise
     * @return
     */
    public boolean isRemote() {
        return false;
    }

    /**
     * If this is a view it returns the SQL used to create the view (if it's available).
     * <code>null</code> if it's not a view or the SQL isn't available.
     * @return
     * @see #isView()
     */
    public String getViewSql() {
        return null;
    }

    /**
     * Returns the number of rows contained in this table, or -1 if unable to determine
     * the number of rows.
     *
     * @return
     */
    public int getNumRows() {
        if (numRows == null) {
            numRows = Config.getInstance().isNumRowsEnabled() ? fetchNumRows() : -1;
        }

        return numRows;
    }

    /**
     * Explicitly set the number of rows in this table
     *
     * @param numRows
     */
    public void setNumRows(int numRows) {
        this.numRows = numRows;
    }

    /**
     * Fetch the number of rows contained in this table.
     *
     * returns -1 if unable to successfully fetch the row count
     *
     * @param db Database
     * @return int
     * @throws SQLException
     */
    protected int fetchNumRows() {
        if (properties == null) // some "meta" tables don't have associated properties
            return 0;

        SQLException originalFailure = null;

        String sql = properties.getProperty("selectRowCountSql");
        if (sql != null) {
            PreparedStatement stmt = null;
            ResultSet rs = null;

            try {
                stmt = db.prepareStatement(sql, getName());
                rs = stmt.executeQuery();

                while (rs.next()) {
                    return rs.getInt("row_count");
                }
            } catch (SQLException sqlException) {
                // don't die just because this failed
            	originalFailure = sqlException;
            } finally {
                if (rs != null) {
                    try {
                        rs.close();
                    } catch (SQLException exc) {}
                }
                if (stmt != null) {
                    try {
                        stmt.close();
                    } catch (SQLException exc) {}
                }
            }
        }

        // if we get here then we either didn't have custom SQL or it didn't work
        try {
            // '*' should work best for the majority of cases
            return fetchNumRows("count(*)", false);
        } catch (SQLException try2Exception) {
            try {
                // except nested tables...try using '1' instead
                return fetchNumRows("count(1)", false);
            } catch (SQLException try3Exception) {
                logger.warning("Unable to extract the number of rows for table " + getName() + ", using '-1'");
                if (originalFailure != null)
                    logger.warning(originalFailure.toString());
                logger.warning(try2Exception.toString());
                logger.warning(try3Exception.toString());
                return -1;
            }
        }
    }

    protected int fetchNumRows(String clause, boolean forceQuotes) throws SQLException {
        PreparedStatement stmt = null;
        ResultSet rs = null;
        StringBuilder sql = new StringBuilder("select ");
        sql.append(clause);
        sql.append(" from ");
        if (getSchema() != null) {
            sql.append(getSchema());
            sql.append('.');
        }

        if (forceQuotes) {
            String quote = db.getMetaData().getIdentifierQuoteString().trim();
            sql.append(quote + getName() + quote);
        } else
            sql.append(db.getQuotedIdentifier(getName()));

        try {
            stmt = db.getConnection().prepareStatement(sql.toString());
            rs = stmt.executeQuery();
            while (rs.next()) {
                return rs.getInt(1);
            }
            return -1;
        } catch (SQLException exc) {
            if (forceQuotes) // we tried with and w/o quotes...fail this attempt
                throw exc;

            return fetchNumRows(clause, true);
        } finally {
            if (rs != null)
                rs.close();
            if (stmt != null)
                stmt.close();
        }
    }

    /**
     * Update the table with the specified XML-derived metadata
     *
     * @param tableMeta
     */
    public void update(TableMeta tableMeta) {
        String newComments = tableMeta.getComments();
        if (newComments != null) {
            comments = newComments;
        }

        for (TableColumnMeta colMeta : tableMeta.getColumns()) {
            TableColumn col = getColumn(colMeta.getName());
            if (col == null) {
                if (tableMeta.getRemoteSchema() == null) {
                    logger.warning("Unrecognized column '" + colMeta.getName() + "' for table '" + getName() + '\'');
                    continue;
                }

                col = addColumn(colMeta);
            }

            // update the column with the changes
            col.update(colMeta);
        }
    }

    /**
     * Same as {@link #connectForeignKeys(Map, Database, Properties, Pattern, Pattern)},
     * but uses XML-based metadata
     *
     * @param tableMeta
     * @param tables
     * @param remoteTables
     */
    public void connect(TableMeta tableMeta, Map<String, Table> tables, Map<String, Table> remoteTables) {
        for (TableColumnMeta colMeta : tableMeta.getColumns()) {
            TableColumn col = getColumn(colMeta.getName());

             // go thru the new foreign key defs and associate them with our columns
            for (ForeignKeyMeta fk : colMeta.getForeignKeys()) {
                Table parent = fk.getRemoteSchema() == null ? tables.get(fk.getTableName())
                                                            : remoteTables.get(fk.getRemoteSchema() + '.' + fk.getTableName());
                if (parent != null) {
                    TableColumn parentColumn = parent.getColumn(fk.getColumnName());

                    if (parentColumn == null) {
                        logger.warning(parent.getName() + '.' + fk.getColumnName() + " doesn't exist");
                    } else {
                        /**
                         * Merely instantiating a foreign key constraint ties it
                         * into its parent and child columns (& therefore their tables)
                         */
                        new ForeignKeyConstraint(parentColumn, col) {
                            @Override
                            public String getName() {
                                return "Defined in XML";
                            }
                        };
                    }
                } else {
                    logger.warning("Undefined table '" + fk.getTableName() + "' referenced by '" + getName() + '.' + col.getName() + '\'');
                }
            }
        }
    }

    @Override
    public String toString() {
        return getName();
    }

    /**
     * Returns <code>true</code> if this table has no relationships
     *
     * @param withImpliedRelationships boolean
     * @return boolean
     */
    public boolean isOrphan(boolean withImpliedRelationships) {
        if (withImpliedRelationships)
            return getMaxParents() == 0 && getMaxChildren() == 0;

        for (TableColumn column : columns.values()) {
            for (TableColumn parentColumn : column.getParents()) {
                if (!column.getParentConstraint(parentColumn).isImplied())
                    return false;
            }
            for (TableColumn childColumn : column.getChildren()) {
                if (!column.getChildConstraint(childColumn).isImplied())
                    return false;
            }
        }
        return true;
    }

    /**
     * Compare this table to another table.
     * Results are based on 1: identity, 2: table name, 3: schema name<p/>
     *
     * This implementation was put in place to deal with analyzing multiple
     * schemas that contain identically named tables.
     *
     * @see {@link Comparable#compareTo(Object)}
     */
    public int compareTo(Table other) {
        if (other == this)  // fast way out
            return 0;

        int rc = getName().compareToIgnoreCase(other.getName());
        if (rc == 0) {
            // should only get here if we're dealing with cross-schema references (rare)
            String ours = getSchema();
            String theirs = other.getSchema();
            if (ours != null && theirs != null)
                rc = ours.compareToIgnoreCase(theirs);
            else if (ours == null)
                rc = -1;
            else
                rc = 1;
        }

        return rc;
    }

    /**
     * Implementation of {@link Comparator} that sorts {@link TableColumn}s
     * by {@link TableColumn#getId() ID} (ignored if <code>null</code>)
     * followed by {@link TableColumn#getName() Name}.
     */
    private static class ByColumnIdComparator implements Comparator<TableColumn> {
        public int compare(TableColumn column1, TableColumn column2) {
            if (column1.getId() == null || column2.getId() == null)
                return column1.getName().compareToIgnoreCase(column2.getName());
            if (column1.getId() instanceof Number)
                return ((Number)column1.getId()).intValue() - ((Number)column2.getId()).intValue();
            return column1.getId().toString().compareToIgnoreCase(column2.getId().toString());
        }
    }
}
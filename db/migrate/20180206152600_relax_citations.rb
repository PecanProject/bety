class RelaxCitations < ActiveRecord::Migration
  def self.up
  	# Use longer "text" field
  	change_column :citations, :title, :text
  	change_column :citations, :journal, :text
    add_column :citations, :notes, :text

    # This constraint is draconian and totally unnecessary.
    # Other metadata should be plenty sufficient without well-formed page number
    execute %q{
        ALTER TABLE citations
            DROP CONSTRAINT well_formed_citation_page_spec;
    }
  end

  def self.down
  	change_column :citations, :title, :string
  	change_column :citations, :journal, :string
    remove_column :citations, :notes, :text
    execute %q{
        ALTER TABLE citations
            ADD CONSTRAINT well_formed_citation_page_spec CHECK (pg ~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$');
    }
  end
end

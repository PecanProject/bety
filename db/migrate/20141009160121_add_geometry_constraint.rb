class AddGeometryConstraint < ActiveRecord::Migration
  def self.up
    execute %{
      ALTER TABLE public.sites
        ADD CONSTRAINT enforce_valid_geom CHECK (st_isvalid(geometry))
    }
  end

  def self.down
    execute %{
      ALTER TABLE public.sites
        DROP CONSTRAINT enforce_valid_geom
    }
  end
end

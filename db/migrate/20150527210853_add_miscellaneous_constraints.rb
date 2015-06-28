class AddMiscellaneousConstraints < ActiveRecord::Migration
  def up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{
ALTER TABLE "treatments" ADD CONSTRAINT "fk_treatments_users_1" FOREIGN KEY ("user_id") REFERENCES "users" ("id");
ALTER TABLE projects ADD CONSTRAINT outdir_value_sanity_check CHECK (outdir ~ '^/');
    }
  end

  def down
    execute %q{
ALTER TABLE "treatments" DROP CONSTRAINT "fk_treatments_users_1";
ALTER TABLE projects DROP CONSTRAINT outdir_value_sanity_check;
    }
  end
end

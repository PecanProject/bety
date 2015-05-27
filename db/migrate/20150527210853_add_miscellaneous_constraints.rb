class AddMiscellaneousConstraints < ActiveRecord::Migration
  def up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{
ALTER TABLE "treatments" ADD CONSTRAINT "fk_treatments_users_1" FOREIGN KEY ("user_id") REFERENCES "users" ("id");
    }
  end

  def down
    execute %q{
ALTER TABLE "treatments" DROP CONSTRAINT "fk_treatments_users_1";
    }
  end
end

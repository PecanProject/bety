collection @row_set

# TO-DO (maybe): Allow a way to override this default value of locals so that
# :abbreviate_associations can be set to true instead or both
# :summarize_associations and :abbreviate_associations set to false (to get full
# association information).  Maybe change from using boolean-valued flags to
# some 3-valued option.
extends("api/beta/base/show")

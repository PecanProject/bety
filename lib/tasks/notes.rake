### This is modified from sample code at http://crypt.codemancers.com/posts/2013-07-12-redefine-rake-routes-to-add-your-own-custom-tag-in-Rails/ ###
### It is intended so users may spell "TODO" annotations in various ways.  It also adds some additional search tags and search directories.

# This block redefines SourceAnnotationExtractor#find so that it searches
# additional directories.
module SearchAdditionalDirectories
  # Add the spec and script directories to the default set:
  def find(dirs=%w(app config lib script test spec script))
    super(dirs)
  end
end
class SourceAnnotationExtractor
  prepend SearchAdditionalDirectories
end


# For re-defining the Rake task.
# Otherwise both the original version and this updated version are called.
task(:notes).clear

# Redefine the "notes" task to look for additional tags.
desc "Enumerate all annotations 
      (use notes:optimize, :fixme, :todo, :deprecation, :note for focus)"
task :notes do
  SourceAnnotationExtractor.enumerate "OPTIMIZE|FIXME|TODO|TO-DO|to-do|[Dd]eprecat(?:ion|ed?)|[Nn]ote|NOTE", 
                                      :tag => true
end

namespace :notes do
  task(:todo).clear
  task :todo do
    SourceAnnotationExtractor.enumerate "TODO|TO-DO|to-do", :tag => true
  end
  task :deprecation do
    SourceAnnotationExtractor.enumerate "[Dd]eprecat(?:ion|ed?)", :tag => true
  end
  task :note do
    SourceAnnotationExtractor.enumerate "[Nn]ote|NOTE"
  end  
end

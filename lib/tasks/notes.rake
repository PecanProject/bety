### This is modified from sample code at http://crypt.codemancers.com/posts/2013-07-12-redefine-rake-routes-to-add-your-own-custom-tag-in-Rails/ ###
### It is intended so users my spell "TODO" annotations in various ways.

# for re-defining the Rake task
# otherwise the previous Rake task is still called
task(:notes).clear

desc "Enumerate all annotations 
      (use notes:optimize, :fixme, :todo for focus)"
task :notes do
  SourceAnnotationExtractor.enumerate "OPTIMIZE|FIXME|TODO|TO-DO|to-do", 
                                      :tag => true
end

namespace :notes do
  task(:todo).clear
  task :todo do
    SourceAnnotationExtractor.enumerate "TODO|TO-DO|to-do", :tag => true
  end
end

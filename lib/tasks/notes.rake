### Sample Code from http://crypt.codemancers.com/posts/2013-07-12-redefine-rake-routes-to-add-your-own-custom-tag-in-Rails/ ###
# for re-defining the Rake task
# otherwise the previous Rake task is still called
task(:notes).clear

desc "Enumerate all annotations 
      (use notes:optimize, :fixme, :todo, :wtf for focus)"
task :notes do
  SourceAnnotationExtractor.enumerate "OPTIMIZE|FIXME|TODO|WTF", 
                                      :tag => true
end

namespace :notes do
  task(:wtf).clear
  task :wtf do
    SourceAnnotationExtractor.enumerate "WTF", :tag => true
  end
end

# This test is needed because we don't load YARD in all environments:
if defined? YARD
  # Define the "yard" task:
  YARD::Rake::YardocTask.new do |t|
    # Most options are set in the .yardopts file under the Rails root
    # directory rather than here.

    # Uncomment this to get a report of all undocumented methods:
    # t.stats_options = ['--list-undoc']
  end
end

# Make the doc:app task run yardoc instead of RDoc:
namespace :doc do
  task(:app).clear

  desc <<DESCRIPTION
Document the BETYdb app using the Yardoc tool.

Output will be in the doc/app directory.  Options are defined
in #{Rails.root.join(".yardopts")}.

Instead of running "rake doc:app" or "rake yard", you can run the
yardoc command.  This will allow for easily passing options on the
command line.  Run "yardoc --help" for a list of options.

DESCRIPTION
  task :app => [:yard, 'doc/trait_data_xml_schema/TraitData.html']
end

file 'doc/trait_data_xml_schema/TraitData.html' => ['doc/trait_data_xml_schema', 'app/lib/api/validation/TraitData.xsd', 'app/lib/api/validation/AssociationLookupTypes.xsd'] do

  main = Nokogiri.XML(File.read('app/lib/api/validation/TraitData.xsd'))
  included = Nokogiri.XML(File.read('app/lib/api/validation/AssociationLookupTypes.xsd'))

  # Combine the schema documents manually becuase xs3p.xsl doesn't
  # handle XML Schema's <include> element:
  main.root << included.root.children

  stylesheet = Nokogiri::XSLT(File.read('lib/tasks/xs3p-1.1.5/xs3p.xsl'))

  result = stylesheet.transform(main)

  result.write_to(File.open('doc/trait_data_xml_schema/TraitData.html', 'w'))
end

directory 'doc/trait_data_xml_schema'

module RawsHelper
  def access_levels(al)
    ["","1.Restricted",'2.EBI Researchers','3.External Researchers','4.Public'][al.to_i]
  end
end

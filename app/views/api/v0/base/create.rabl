object :data

if @new_trait_ids && @new_trait_ids.size != 0
  node(:ids_of_new_traits) do
    @new_trait_ids
  end
else
  node(:annotated_post_data) do
    @result
  end
end

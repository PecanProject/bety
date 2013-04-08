module TraitsHelper

  def checked_status_list(trait)
    if ( current_user.access_level < trait.access_level ) or ( trait.user_id == current_user.id ) or ( current_user.page_access_level <= 2 )
      if trait.checked == -1 and current_user.page_access_level > 2
        "<td>Failed QA/QC check</td>"
      else
        "<td>#{ select_tag 'checked-'+trait.id.to_s, options_for_select([['failed',-1],['unchecked',0],['passed',1]],trait.checked) }<span id='checked_notify-#{ trait.id }'></span></td>"
      end
    else
      ''
    end
  end

end

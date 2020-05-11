function check_saved_bot_reg(main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if isempty(layer)
    return;
end
tt_str=('Unsaved changes');
if curr_disp.Bot_changed_flag==1
    
    war_str='Bottom has been modified without being saved. Do you want save it?';
     choice=question_dialog_fig(main_figure,tt_str,war_str);
    % Handle response
    switch choice
        case 'Yes'
            layer.write_bot_to_bot_xml();
            %layer.save_bot_reg_to_db('bot',1,'reg',0);
    end
    
end

if curr_disp.Reg_changed_flag==1
    
    war_str='Regions have been modified without being saved. Do you want save them?';
     choice=question_dialog_fig(main_figure,tt_str,war_str);
    % Handle response
    switch choice
        case 'Yes'
            layer.write_reg_to_reg_xml();
            %layer.save_bot_reg_to_db('bot',0,'reg',1);
    end
end


end
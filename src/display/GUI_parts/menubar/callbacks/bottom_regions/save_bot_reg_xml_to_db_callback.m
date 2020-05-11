function save_bot_reg_xml_to_db_callback(~,~,main_figure,bot,reg)

layer = get_current_layer();

try
    if isempty(layer)
        return;
    end
    
    curr_disp=get_esp3_prop('curr_disp');
    
    if ~isempty(reg)
        if reg==0
            disp_perso(main_figure,'Saving Regions to XML');
        else
            disp_perso(main_figure,'Saving Regions to database');
        end
        layer.write_reg_to_reg_xml();
        curr_disp.Reg_changed_flag=2;
        if reg>0
            layer.save_bot_reg_to_db('bot',0,'reg',1);
            curr_disp.Reg_changed_flag=3;
        end
    end
    
    if ~isempty(bot)
        if bot==0
            disp_perso(main_figure,'Saving Bottom to XML');
        else
            disp_perso(main_figure,'Saving Bottom to database');
        end
        layer.write_bot_to_bot_xml();
        curr_disp.Bot_changed_flag=2;
        if bot>0
            layer.save_bot_reg_to_db('bot',1,'reg',0);
            curr_disp.Bot_changed_flag=3;
        end
    end
    
    load_logbook_tab_from_db(main_figure,1);
    
catch err
    print_errors_and_warnings(1,'error',err);
end

hide_status_bar(main_figure);

end



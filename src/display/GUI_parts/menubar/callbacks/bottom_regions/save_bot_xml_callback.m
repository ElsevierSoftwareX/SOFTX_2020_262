function save_bot_xml_callback(~,~,main_figure)
layer=get_current_layer();
layer.write_bot_to_bot_xml();
curr_disp=get_esp3_prop('curr_disp');
curr_disp.Bot_changed_flag=2;

end
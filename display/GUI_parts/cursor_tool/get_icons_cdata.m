function icon=get_icons_cdata(icon_dir)



icon.pointer=  icon_from_file(fullfile(icon_dir,'tool_pointer.png'));

icon.zin  = icon_from_file(fullfile(icon_dir,'tool_zoom_in.png'));

icon.zout = icon_from_file(fullfile(icon_dir,'tool_zoom_out.png'));

icon.fplot = icon_from_file(fullfile(icon_dir,'freq_plot.png'));

icon.bad_trans = icon_from_file(fullfile(icon_dir,'bad_trans.png'));

icon.pan = icon_from_file(fullfile(icon_dir,'pan.png'));

icon.ts_cal = icon_from_file(fullfile(icon_dir,'ts_cal.png'));

icon.eba_cal = icon_from_file(fullfile(icon_dir,'eba_cal.png'));

icon.edit_bot = icon_from_file(fullfile(icon_dir,'edit_bot.png'));

icon.eraser = icon_from_file(fullfile(icon_dir,'eraser.png'));

icon.edit_bot_spline = icon_from_file(fullfile(icon_dir,'edit_bot_spline.png'));

icon.folder = icon_from_file(fullfile(icon_dir,'folder_small.png'));

icon.del_lay = icon_from_file(fullfile(icon_dir,'delete.png'));

icon.undo = icon_from_file(fullfile(icon_dir,'undo.png'));
icon.redo = icon.undo(:,(16:-1:1),:);

icon.add = icon_from_file(fullfile(icon_dir,'add.png'));

icon.undock= icon_from_file(fullfile(icon_dir,'undock.png'));

icon.ruler= icon_from_file(fullfile(icon_dir,'ruler.png'));

icon.pan= icon_from_file(fullfile(icon_dir,'pan.png'));

icon.create_reg_rect= icon_from_file(fullfile(icon_dir,'create_reg_rect.png'));
icon.create_reg_poly= icon_from_file(fullfile(icon_dir,'create_reg_poly.png'));
icon.create_reg_vert= icon_from_file(fullfile(icon_dir,'create_reg_vert.png'));
icon.create_reg_horz= icon_from_file(fullfile(icon_dir,'create_reg_horz.png'));
icon.create_reg_hd= icon_from_file(fullfile(icon_dir,'create_reg_hd.png'));

icon.brush= icon_from_file(fullfile(icon_dir,'brush.png'));

icon.next_lay = icon_from_file(fullfile(icon_dir,'greenarrowicon.gif'));
icon.prev_lay = icon.next_lay(:,(16:-1:1),:);


end


function ic_data=icon_from_file(fname)
ic_data=zeros(16,16,3);
try
    if isfile(fname)
        ic_data=iconRead(fname);
    else
        warning('Could not read icon %s',fname);
    end
catch
    warning('Could not read icon %s',fname);
end
end

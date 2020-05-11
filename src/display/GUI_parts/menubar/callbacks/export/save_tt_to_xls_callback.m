function save_tt_to_xls_callback(~,~,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[path_lay,files] = layer.get_path_files();

[~,fname,~]=fileparts(files{1});
[trans_obj,idx_freq]=layer.get_trans(curr_disp);


file_path = path_lay{1};
[Filename,path_f] = uiputfile( {fullfile(file_path,sprintf('%s_TT_%.0f.xlsx',fname,curr_disp.Freq))}, 'Save Tracked Targets');

if Filename==0
    return;
end

file=fullfile(path_f,Filename);

load_bar_comp=show_status_bar(main_figure,0);
load_bar_comp.progress_bar.setText('Exporting tracked targets...');

trans_obj.save_tt_to_xls(file,-inf,inf);

load_bar_comp.progress_bar.setText('Done...');
pause(0.5);
hide_status_bar(main_figure);



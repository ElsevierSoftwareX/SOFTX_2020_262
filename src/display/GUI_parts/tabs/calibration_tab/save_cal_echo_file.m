function save_cal_echo_file()

layer=get_current_layer();
if ~isempty(layer)
    try
        cal_cw=extract_cal_to_apply(layer,layer.get_cal());
    catch err
        print_errors_and_warnings([],'error',err);
        disp_perso(main_figure,'Could not read calibration file');
        cal_cw=get_cal(layer);
    end
    [cal_path,~,~]=fileparts(layer.Filename{1});
    
    
    cal_file=fullfile(cal_path,'cal_echo.csv');
    
    cal_f=init_cal_struct(cal_file);
    
    if ~isempty(cal_f)
        idx_add=find(~ismember(cal_f.CID,cal_cw.CID));
    else
        idx_add=[];
    end
    fid=fopen(cal_file,'w');
    
    fprintf(fid,'%s,%s,%s,%s,%s,%s\n', 'FREQ', 'CID','G0', 'SACORRECT','EQA','alpha');
    for i=1:length(cal_cw.G0)
        fprintf(fid,'%.0f,%s,%.2f,%.2f,%.2f,%.2f\n',cal_cw.FREQ(i),cal_cw.CID{i},cal_cw.G0(i),cal_cw.SACORRECT(i),cal_cw.EQA(i),cal_cw.alpha(i));
    end
    
    for i=idx_add'
        fprintf(fid,'%.0f,%s,%.2f,%.2f,%.2f,%.2f\n',cal_f.FREQ(i),cal_f.CID{i},cal_f.G0(i),cal_f.SACORRECT(i),cal_f.EQA(i),cal_f.alpha(i));
    end
    
    fclose(fid);
end
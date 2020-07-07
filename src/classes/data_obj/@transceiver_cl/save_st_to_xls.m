function save_st_to_xls(trans_obj,file,full_signal,stt,ett)


if exist(file,'file')>0
    delete(file);
end

st=trans_obj.ST;

if isempty(st)||isempty(st.TS_comp)
    warndlg_perso([],'','No single targets to export');
    return;
end

algo_obj=get_algo_per_name(trans_obj,'SingleTarget');

varin=algo_obj.input_params_to_struct();

algo_sheet=[fieldnames(varin) struct2cell(varin)];

reg=region_cl.empty();
[data_struct_new,~,~] = reg.get_region_3D_echoes(trans_obj,'field','singletarget');

if isfield(data_struct_new,'lat')
    st.lat=data_struct_new.lat;
    st.lon=data_struct_new.lon;
    st.depth=data_struct_new.depth;
end


idx_rem = st.Time<stt|st.Time>ett;

st_trim=structfun(@(x) x(~idx_rem),st,'un',0);

st_sheet=struct_to_sheet(st_trim);
writetable(cell2table(algo_sheet),file,'WriteVariableNames',0,'Sheet','Parameters');
writetable(cell2table(st_sheet'),file,'WriteVariableNames',0,'Sheet','Single Targets');

if full_signal>0
    
    st_sig_tmp=trans_obj.get_st_sig('sp');
    
    for ii=1:numel(st.Ping_number)
        st_sig.(sprintf('st_%d',ii))= st_sig_tmp{ii};
    end
    st_sig_sheet=struct_to_sheet(st_sig);
    
    writetable(cell2table(st_sig_sheet'),file,'WriteVariableNames',0,'Sheet','Single Targets (signal)');
end

fprintf('Single targets saved to %s\n',file);


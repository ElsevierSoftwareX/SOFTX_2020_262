function save_tt_to_xls(trans_obj,file,stt,ett)

if exist(file,'file')>0
    delete(file);
end

st=trans_obj.ST;

if isempty(st)||isempty(st.TS_comp)||isempty(trans_obj.Tracks)
    warndlg_perso([],'','No tracks to export');
    return;
end


reg=region_cl.empty();
[data_struct_new,~,~] = reg.get_region_3D_echoes(trans_obj,'field','singletarget');

if isfield(data_struct_new,'lat')
    st.lat=data_struct_new.lat(:)';
    st.lon=data_struct_new.lon(:)';
    st.depth=data_struct_new.depth(:)';
end

algo_obj=get_algo_per_name(trans_obj,'SingleTarget');
algo_tt_obj=get_algo_per_name(trans_obj,'TrackTarget');

al_st_varin=algo_obj.input_params_to_struct();
al_tt_varin=algo_tt_obj.input_params_to_struct();

algo_sheet=[fieldnames(al_st_varin) struct2cell(al_st_varin)];
algo_tt_sheet=[fieldnames(al_tt_varin) struct2cell(al_tt_varin)];

idx_rem = st.Time<stt|st.Time>ett|isnan(st.Track_ID);

st_tracks=structfun(@(x) x(~idx_rem),st,'un',0);

tt_sheet=struct_to_sheet(st_tracks);

writetable(cell2table(algo_sheet),file,'WriteVariableNames',0,'Sheet','ST Parameters');
writetable(cell2table(algo_tt_sheet),file,'WriteVariableNames',0,'Sheet','TT Parameters');
writetable(cell2table(tt_sheet'),file,'WriteVariableNames',0,'Sheet','Tracked Targets');

fprintf('Tracked targets saved to %s\n',file);


function display_TS_range_pdf_cback(~,~)
esp3_obj=getappdata(groot,'esp3_obj');

update_survey_opts(esp3_obj.main_figure);

layer_obj=get_current_layer();

if isempty(layer_obj)
    return;
end

curr_disp=get_esp3_prop('curr_disp');
trans_obj=layer_obj.get_trans(curr_disp);
survey_options_obj=layer_obj.get_survey_options();

tt_table = trans_obj.ST;

if isempty(trans_obj.ST)||all(isnan(tt_table.Track_ID))
   return; 
end

[idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');

if alg_found
    varin=trans_obj.Algo(idx_alg).input_params_to_struct();
    xl=[varin.TS_threshold varin.TS_threshold_max];
else
    xl=curr_disp.getCaxField('singletarget');
end

uu=findgroups(tt_table.Track_ID);

mean_TS_per_track=splitapply(@(x) pow2db(mean(db2pow(x))),tt_table.TS_comp,uu);
mean_range_per_track=splitapply(@(x) pow2db(mean(db2pow(x))),tt_table.Target_range,uu);

[pdf,x_mat,y_mat]=pdf_2d_perso(mean_TS_per_track,mean_range_per_track,(xl(1):0.5:xl(2))',(0:survey_options_obj.Horizontal_slice_size:nanmax(mean_range_per_track)),'gauss');
cax=[prctile(pdf(pdf>0),50) prctile(pdf(pdf>0),99)];
%[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap('viridis');
[cmap,col_ax,~,col_grid,~,~,~]=init_cmap(curr_disp.Cmap);

f=new_echo_figure(esp3_obj.main_figure,'Name','TS/Range pdf');
ax=axes(f,'YDir','reverse','GridColor',col_grid,'Color',col_ax,'nextplot','add','box','on','TickLength',[0 0],'GridAlpha',0.05);
u=pcolor(ax,x_mat,y_mat,pdf);
u.FaceAlpha='flat';
u.FaceColor='flat';
u.AlphaData=pdf>=cax(1);
title(ax,'2D-PDF of tracked targets (TS/range)')
xlabel(ax,'TS(dB)');
ax.XLim=[nanmin(x_mat(:)) nanmax(x_mat(:))];
ax.YLim=[nanmin(y_mat(:)) nanmax(y_mat(:))];
ax.YAxis.TickLabelFormat='%.0fm';
caxis(ax,cax);
colormap(cmap);




end
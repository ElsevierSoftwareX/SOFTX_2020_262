function display_cal(~,~,main_figure)

layer=get_current_layer();

fig=new_echo_figure(main_figure,'Tag','calibration');

dx=1/8;
dy=1/10;
y=(1-2*dy)/3;
x=1-2*dx;

ax_1=axes(fig,'Box','on','Nextplot','add','position',[dx 2*y+dy x y]);
grid(ax_1,'on');
ylabel(ax_1,'G(dB)')
ax_1.XTickLabels={''};


ax_2=axes(fig,'Box','on','Nextplot','add','position',[dx y+dy x y]);
grid(ax_2,'on')
ylabel(ax_2,'BeamWidth(deg)')
ax_2.XTickLabels={''};

ax_3=axes(fig,'Box','on','Nextplot','add','position',[dx dy x y]);
grid(ax_3,'on')
ax_3.XAxis.TickLabelFormat  = '%d\kHz';
ylabel(ax_3,'EBA(dB)')


cal_cw=layer.get_cal();

plot(ax_1,cal_cw.FREQ(:)/1e3,cal_cw.G0(:),'ok');

plot(ax_2,cal_cw.FREQ(:)/1e3,cal_cw.BeamWidthAthwartship(:),'ok');
plot(ax_2,cal_cw.FREQ(:)/1e3,cal_cw.BeamWidthAlongship(:),'xk');

plot(ax_3,cal_cw.FREQ(:)/1e3,cal_cw.EQA(:),'ok');
plot(ax_3,cal_cw.FREQ(:)/1e3,cal_cw.EQA(:),'ok');

cal_fm_cell=layer.get_fm_cal([]);
f_vec_tot = cal_cw.FREQ;

f_start_tot=[];
f_end_tot=[];

for uui=1:numel(layer.Frequencies)
    
    cal=cal_fm_cell{uui};
    
    if isempty(cal)
        continue;
    end
    
    f_start_tot=union(f_start_tot,nanmin(layer.Transceivers(uui).get_params_value('FrequencyStart',1),layer.Transceivers(uui).get_params_value('FrequencyEnd',1)));
    f_end_tot=union(f_end_tot,nanmax(layer.Transceivers(uui).get_params_value('FrequencyStart',1),layer.Transceivers(uui).get_params_value('FrequencyEnd',1)));
    
    
    
    plot(ax_1,cal.freq_vec(:)/1e3,cal.Gf_th(:),'color',[0 0.8 0],'tag','theoritical');
    plot(ax_1,cal.freq_vec(:)/1e3,cal.Gf_file(:),'color',[0 0 0.8],'tag','file_value');
    plot(ax_1,cal.freq_vec(:)/1e3,cal.Gf(:),'color',[0.8 0 0],'tag','applied');
    
   
    plot(ax_2,cal.freq_vec(:)/1e3,cal.BeamWidthAlongship_f_th,'color',[0 0.8 0],'linestyle','--');
    plot(ax_2,cal.freq_vec(:)/1e3,cal.BeamWidthAlongship_f_file,'color',[0 0 0.8],'linestyle','--');
     plot(ax_2,cal.freq_vec/1e3,cal.BeamWidthAlongship_f_fit,'Color',[0.8 0 0],'linestyle','--');
     
    
    plot(ax_2,cal.freq_vec(:)/1e3,cal.BeamWidthAthwartship_f_th,'color',[0 0.8 0],'linestyle','-.');
    plot(ax_2,cal.freq_vec(:)/1e3,cal.BeamWidthAthwartship_f_file,'color',[0 0 0.8],'linestyle','-.');
    plot(ax_2,cal.freq_vec/1e3,cal.BeamWidthAthwartship_f_fit,'Color',[0.8 0 0],'linestyle','-.');
    
   
    plot(ax_3,cal.freq_vec(:)/1e3,cal.eq_beam_angle_f_th,'color',[0 0.8 0]);
    plot(ax_3,cal.freq_vec(:)/1e3,cal.eq_beam_angle_f_file,'color',[0 0 0.8]);
     plot(ax_3,cal.freq_vec/1e3,cal.eq_beam_angle_f,'color',[0.8 0 0]);
    if uui==1
        new_ylim2=[nanmin(cal.BeamWidthAthwartship_f_th)*0.8 nanmax(cal.BeamWidthAlongship_f_th)*1.1];
        new_ylim3=[1.1*nanmin(cal.eq_beam_angle_f) 0.9*nanmax(cal.eq_beam_angle_f)];
    else
        new_ylim2=[nanmin(cal.BeamWidthAthwartship_f_th)*0.8 nanmax(cal.BeamWidthAlongship_f_th)*1.1];
        old_ylim2=get(ax_2,'YLim');
        new_ylim2=[nanmin(old_ylim2(1),new_ylim2(1)) nanmax(old_ylim2(2),new_ylim2(2))];
        
        new_ylim3=[1.1*nanmin(cal.eq_beam_angle_f) 0.9*nanmax(cal.eq_beam_angle_f)];
        old_ylim3=get(ax_3,'YLim');
        new_ylim3=[nanmin(old_ylim3(1),new_ylim3(1)) nanmax(old_ylim3(2),new_ylim3(2))];
    end
    
    ylim(ax_2,new_ylim2);
    ylim(ax_3,new_ylim3);
    f_vec_tot=union(f_vec_tot,cal.freq_vec);
end
f_grid_tot=union(f_start_tot,f_end_tot);
f_grid_tot=union(f_grid_tot,cal_cw.FREQ);

linkaxes([ax_1 ax_2 ax_3],'x');
xlim(ax_1,[nanmin(f_vec_tot/1e3)-10 nanmax(f_vec_tot/1e3)+10]);
ax_1.XTick=unique(f_grid_tot)/1e3;
ax_2.XTick=unique(f_grid_tot)/1e3;
ax_3.XTick=unique(f_grid_tot)/1e3;

if numel(ax_1.Children)>=4
    th=findobj(ax_1,'Tag','theoritical');
    app=findobj(ax_1,'Tag','applied');
    fv=findobj(ax_1,'Tag','file_value');
    legend([th(1) fv(1) app(1)],{'Theoritical' 'File value' 'Used'},'Location','northoutside','Orientation','horizontal')
end


end
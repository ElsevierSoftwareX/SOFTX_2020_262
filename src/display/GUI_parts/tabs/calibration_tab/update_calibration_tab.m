function update_calibration_tab(main_figure)

calibration_tab_comp=getappdata(main_figure,'Calibration_tab');
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    return;
end

[trans_obj,~]=layer.get_trans(curr_disp);

set(calibration_tab_comp.calibration_txt,'String',sprintf('Current Frequency: %.0f kHz',curr_disp.Freq/1e3));

if any(strcmp(layer.Filetype,{'ASL'}))
    set(calibration_tab_comp.G0,'Enable','off');
    set(calibration_tab_comp.SACORRECT,'Enable','off');
end
cal_cw=get_cal(trans_obj);
set(calibration_tab_comp.G0,'string',num2str(cal_cw.G0,'%.2f'));
set(calibration_tab_comp.SACORRECT,'string',num2str(cal_cw.SACORRECT,'%.2f'));
set(calibration_tab_comp.EQA,'string',num2str(cal_cw.EQA,'%.2f'));
set(calibration_tab_comp.G0,'Enable','on');
set(calibration_tab_comp.fm_proc,'Enable','on');
set(calibration_tab_comp.EQA,'Enable','on');
set(calibration_tab_comp.cw_proc,'Enable','on');

switch trans_obj.Mode
    case 'CW'        
        set(calibration_tab_comp.SACORRECT,'Enable','on');
    case 'FM'
        set(calibration_tab_comp.SACORRECT,'Enable','off');
end

field={'EQA','SACORRECT','G0'};
for ifif=1:numel(field)
    delete(calibration_tab_comp.(['ax_' field{ifif}]).Children);
end

cal_cw=layer.get_cal();


plot(calibration_tab_comp.ax_G0,cal_cw.FREQ/1e3,cal_cw.G0,'ok');
plot(calibration_tab_comp.ax_SACORRECT,cal_cw.FREQ/1e3,cal_cw.SACORRECT,'or');
plot(calibration_tab_comp.ax_EQA,cal_cw.FREQ/1e3,cal_cw.EQA,'ob');

f_vec_tot = cal_cw.FREQ;

cal_fm_cell=layer.get_fm_cal([]);

for uui=1:numel(layer.Frequencies)
    
    cal=cal_fm_cell{uui};
    if isempty(cal)
        continue;
    end
    
    plot(calibration_tab_comp.ax_G0,cal.freq_vec(:)/1e3,cal.Gf(:),'color',[0.8 0 0]);
    plot(calibration_tab_comp.ax_G0,cal.freq_vec(:)/1e3,cal.Gf_th(:),'color',[0 0.8 0]);
    plot(calibration_tab_comp.ax_G0,cal.freq_vec(:)/1e3,cal.Gf_file(:),'color',[0 0 0.8]);
    
    plot(calibration_tab_comp.ax_EQA,cal.freq_vec/1e3,cal.eq_beam_angle_f,'color',[0.8 0 0]);
    plot(calibration_tab_comp.ax_EQA,cal.freq_vec(:)/1e3,cal.eq_beam_angle_f_th,'color',[0 0.8 0]);
    plot(calibration_tab_comp.ax_EQA,cal.freq_vec(:)/1e3,cal.eq_beam_angle_f_file,'color',[0 0 0.8]);
    
    f_vec_tot=union(f_vec_tot,cal.freq_vec);

end

xl=[nanmin(f_vec_tot)/1e3 nanmax(f_vec_tot)/1e3];
xl=(xl+abs(diff(xl))*[-0.1 0.1]).*[(1-sign(xl(1))*0.05) (1+sign(xl(2))*0.05)];

if diff(xl)>0
    calibration_tab_comp.ax_G0.XLim=xl;
else
    calibration_tab_comp.ax_G0.XLim=xl+[-1 +1];
end
[~,~,f_nom,f_start,f_end]=layer.get_freq_min_max_nom_start_end();
calibration_tab_comp.ax_G0.XTick=unique([f_nom f_start f_end])/1e3;

for ifif=1:numel(field)
    yd=[calibration_tab_comp.(['ax_' field{ifif}]).Children(:).YData];
    
    yl=[nanmin(yd) nanmax(yd)];
    yl=(yl+abs(diff(yl))*[-0.1 0.1]).*[(1-sign(yl(1))*0.05) (1+sign(yl(2))*0.05)];
    if diff(yl)>0
        calibration_tab_comp.(['ax_' field{ifif}]).YLim=yl;
    else
       calibration_tab_comp.(['ax_' field{ifif}]).YLim=yl+[-1 +1]; 
    end
end



setappdata(main_figure,'Calibration_tab',calibration_tab_comp);

end
